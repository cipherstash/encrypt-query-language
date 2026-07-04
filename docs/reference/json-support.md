# EQL with JSON and JSONB

EQL encrypts, decrypts, and searches JSON / JSONB documents using structured encryption (ste_vec), exposed as the **`eql_v3.json`** document domain. An `eql_v3.json` column stores an encrypted document whose every path is searchable — without decryption — via containment, field/array access, and entry-level equality / range on extracted leaves.

## On this page

- [Storing encrypted JSON](#storing-encrypted-json)
- [Typed operands (important)](#typed-operands-important)
- [Querying `eql_v3.json`](#querying-eql_v3json)
  - [Containment queries (`@>`, `<@`)](#containment-queries)
  - [Field extraction (`jsonb_path_query`)](#field-extraction-jsonb_path_query)
  - [JSON path operators (`->`, `->>`)](#json-path-operators)
  - [Array operations](#array-operations)
  - [Grouping data](#grouping-data)
- [`eql_v3` functions for JSONB and ste_vec](#eql_v3-functions-for-jsonb-and-ste_vec)
- [How ste_vec indexing works](#how-ste_vec-indexing-works)

## Storing encrypted JSON

Type the column as `eql_v3.json`. There is no database-side `add_search_config` step — which terms a document carries is decided by the encryption client ([CipherStash Proxy](https://github.com/cipherstash/proxy) / [CipherStash Stack](https://github.com/cipherstash/stack)); typing the column as `eql_v3.json` is what makes the encrypted operators and functions resolve.

```sql
CREATE TABLE users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  encrypted_json eql_v3.json
);
```

Insert and read through CipherStash Proxy or CipherStash Stack, which encrypt the document into the ste_vec payload on write and decrypt it on read:

```sql
SELECT encrypted_json FROM users;   -- decrypted by the client on the way out
```

The stored value is the encrypted ste_vec document — an envelope (`v`, `i`, `c`) plus the `sv` array of encrypted, per-path terms.

## Typed operands (important)

`eql_v3.json` is a PostgreSQL **domain over `jsonb`**. PostgreSQL resolves `domain OP untyped_literal` to the **native** `jsonb` operator, because it flattens the domain to its base type when the right-hand side is an unknown-typed literal. A bare literal therefore **bypasses the encrypted operator (and the blockers) and silently returns native jsonb semantics** — typically a root-key lookup that yields `NULL` — instead of querying the encrypted document or raising.

Always give the operand a known type:

```sql
-- ✅ correct — typed operand resolves to the eql_v3 operator
WHERE doc -> 'email'::text = $1
WHERE doc @> $1::eql_v3.jsonb_query
WHERE doc -> $1            -- a text parameter (the CipherStash Proxy interface)

-- ⚠ wrong — bare untyped literal resolves to native jsonb -> text, returns NULL
WHERE doc -> 'email'
```

This is **intrinsic to the domain type-kind**, not a bug: the only way to remove it would be to make `eql_v3.json` a base type (losing free `jsonb` interop). The CipherStash Proxy always passes typed parameters, so applications routing through the Proxy are unaffected; the caveat matters only for hand-written ad-hoc SQL.

## Querying `eql_v3.json`

### Containment queries (`@>`, `<@`)

`@>` tests whether the encrypted document contains a structure; `<@` is the reverse. The needle must be **typed** — another `eql_v3.json`, an `eql_v3.jsonb_query`, or an `eql_v3.jsonb_entry`:

```sql
SELECT * FROM examples
WHERE encrypted_json @> $1::eql_v3.jsonb_query;
```

This is the encrypted equivalent of the plaintext `jsonb_column @> '{"top":{"nested":["a"]}}'`.

For large tables, back containment with a GIN index. The typed `@>` overload inlines to a native `jsonb @>` over `eql_v3.to_ste_vec_query(col)::jsonb`, so a GIN index on the same expression engages:

```sql
CREATE INDEX examples_json_gin
  ON examples USING gin (eql_v3.to_ste_vec_query(encrypted_json)::jsonb jsonb_path_ops);
ANALYZE examples;

SELECT * FROM examples WHERE encrypted_json @> $1::eql_v3.jsonb_query;
```

See [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment) for the full setup.

### Field extraction (`jsonb_path_query`)

Extract fields by **selector hash** — a deterministic identifier the crypto layer emits for a JSON path (not a path string like `$.field`). Selectors are generated during encryption by CipherStash Proxy / CipherStash Stack.

```sql
-- All entries matching a selector
SELECT eql_v3.jsonb_path_query(encrypted_json, 'abc123def456...') FROM examples;

-- First match only
SELECT eql_v3.jsonb_path_query_first(encrypted_json, 'abc123def456...') FROM examples;

-- Does the selector exist?
SELECT eql_v3.jsonb_path_exists(encrypted_json, 'abc123def456...') FROM examples;
```

### JSON path operators (`->`, `->>`)

`->` returns the matched entry as an `eql_v3.jsonb_entry`; `->>` returns it serialized as `text` (ciphertext JSON, not decrypted plaintext). The selector operand must be typed:

```sql
-- Field access by selector (returns eql_v3.jsonb_entry)
SELECT encrypted_json -> 'selector_hash'::text FROM examples;

-- Field access as text (returns the entry as ciphertext text)
SELECT encrypted_json ->> 'selector_hash'::text FROM examples;

-- Array element by 0-based index (returns eql_v3.jsonb_entry)
SELECT encrypted_json -> 0 FROM examples;
```

The extracted `eql_v3.jsonb_entry` is itself comparable: `=` / `<>` resolve via `eql_v3.eq_term`, and `<` / `<=` / `>` / `>=` via `eql_v3.ore_cllw` (on String / Number leaves):

```sql
SELECT * FROM examples
WHERE encrypted_json -> 'email_selector'::text = $1::eql_v3.jsonb_entry;
```

### Array operations

```sql
-- Length of an encrypted array node
SELECT eql_v3.jsonb_array_length(encrypted_array_field) FROM examples;

-- Elements as encrypted entries
SELECT eql_v3.jsonb_array_elements(encrypted_array_field) FROM examples;

-- Elements as ciphertext text
SELECT eql_v3.jsonb_array_elements_text(encrypted_array_field) FROM examples;
```

### Grouping data

Group on the extracted entry's equality term, `eql_v3.eq_term`. A functional hash index on the same expression engages the lookup (see [Field-level equality index](./database-indexes.md#field-level-equality-index-ste_vec-elements)):

```sql
SELECT eql_v3.eq_term(encrypted_json -> 'color_selector'::text) AS color, COUNT(*)
FROM examples
GROUP BY eql_v3.eq_term(encrypted_json -> 'color_selector'::text);
```

`MIN` / `MAX` over an extracted ordered leaf use the `eql_v3.min(eql_v3.jsonb_entry)` / `max` aggregates.

## `eql_v3` functions for JSONB and ste_vec

### Core functions

- **`eql_v3.ste_vec(val jsonb) RETURNS jsonb[]`** — extracts the ste_vec index array from an encrypted payload.
- **`eql_v3.ste_vec_contains(a eql_v3.json, b eql_v3.json) RETURNS boolean`** — true if all ste_vec terms in `b` exist in `a`; backs the `@>` operator.
- **`eql_v3.to_ste_vec_query(val eql_v3.json) RETURNS eql_v3.jsonb_query`** — the GIN-indexable query shape `@>` inlines to.
- **`eql_v3.meta_data(val jsonb)`**, **`eql_v3.ciphertext(val jsonb)`**, **`eql_v3.selector(val jsonb)` / `(entry eql_v3.jsonb_entry)`** — envelope / ciphertext / selector accessors.

### Path query functions

- **`eql_v3.jsonb_path_query(val jsonb, selector text)`** — entries matching the selector.
- **`eql_v3.jsonb_path_query_first(val jsonb, selector text)`** — first match.
- **`eql_v3.jsonb_path_exists(val jsonb, selector text) RETURNS boolean`** — selector presence.

### Array functions

- **`eql_v3.jsonb_array_length(val jsonb) RETURNS integer`**
- **`eql_v3.jsonb_array_elements(val jsonb)`**
- **`eql_v3.jsonb_array_elements_text(val jsonb) RETURNS SETOF text`**

### Entry comparison / aggregate

- **`eql_v3.eq_term(entry eql_v3.jsonb_entry)`** — equality term (backs `=` / `<>` / `GROUP BY`).
- **`eql_v3.ore_cllw(entry eql_v3.jsonb_entry)`** — ordering term (backs `<` … `>=`); **`eql_v3.has_ore_cllw(entry)`** reports whether the leaf carries one.
- **`eql_v3.min(eql_v3.jsonb_entry)` / `eql_v3.max(...)`** — MIN / MAX over an extracted ordered leaf.

For GIN-indexable JSONB containment, see [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment) (`eql_v3.to_ste_vec_query(col)::jsonb jsonb_path_ops`).

### Blocked operators

The native `jsonb` operators `?`, `?|`, `?&`, `@?`, `@@`, `#>`, `#>>`, `-`, `#-`, `||`, and root-document `=` `<>` `<` `<=` `>` `>=` are **blocked** on `eql_v3.json` — they `RAISE` rather than running plaintext-jsonb semantics on the encrypted payload. Use containment, field access, or the `eql_v3.jsonb_path_*` functions instead.

## How ste_vec indexing works

Structured Encryption (ste_vec) makes a JSONB document searchable by:

1. **Flattening the structure** — each unique path to a leaf gets a deterministic selector hash.
2. **Encrypting terms** — each path and value is encrypted into per-path terms (`hm` for equality; `oc` CLLW ORE for ordered String / Number leaves).
3. **Storing the `sv` array** — all encrypted terms live in the document's `sv` vector.

**Example document:**

```json
{
  "account": {
    "email": "alice@example.com",
    "roles": ["admin", "owner"]
  }
}
```

**Creates selectors for** `$` (root), `$.account`, `$.account.email` (and its value), `$.account.roles` (and each role value).

**Querying:** containment (`@>`) checks that all required encrypted terms exist in the target's `sv` array:

```sql
-- Find records where account.email = "alice@example.com"
WHERE encrypted_data @> $1::eql_v3.jsonb_query;
```

Encryption and selector generation are handled by CipherStash Proxy or CipherStash Stack, not by EQL directly.

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20json-support.md)
