# EQL with JSON and JSONB

EQL encrypts, decrypts, and searches JSON / JSONB documents using structured encryption (ste_vec), exposed as the **`public.eql_v3_json_search`** document domain. A `public.eql_v3_json_search` column stores an encrypted document whose every path is searchable — without decryption — via containment, field/array access, and entry-level equality / range on extracted leaves.

## On this page

- [Storing encrypted JSON](#storing-encrypted-json)
- [Typed operands (important)](#typed-operands-important)
- [Querying `public.eql_v3_json_search`](#querying-publiceql_v3_json_search)
  - [Containment queries (`@>`, `<@`)](#containment-queries--)
  - [Field extraction (`jsonb_path_query`)](#field-extraction-jsonb_path_query)
  - [JSON path operators (`->`, `->>`)](#json-path-operators----)
  - [Array operations](#array-operations)
  - [Grouping data](#grouping-data)
- [`eql_v3` functions for JSONB and ste_vec](#eql_v3-functions-for-jsonb-and-ste_vec)
- [How ste_vec indexing works](#how-ste_vec-indexing-works)

## Storing encrypted JSON

Type the column as `public.eql_v3_json_search`. There is no database-side `add_search_config` step — which terms a document carries is decided by the encryption client ([CipherStash Proxy](https://github.com/cipherstash/proxy) / [CipherStash Stack](https://github.com/cipherstash/stack)); typing the column as `public.eql_v3_json_search` is what makes the encrypted operators and functions resolve.

```sql
CREATE TABLE users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  encrypted_json public.eql_v3_json_search
);
```

Insert and read through CipherStash Proxy or CipherStash Stack, which encrypt the document into the ste_vec payload on write and decrypt it on read:

```sql
SELECT encrypted_json FROM users;   -- decrypted by the client on the way out
```

The stored value is the encrypted ste_vec document — an envelope (`v`, `i`, `c`) plus the `sv` array of encrypted, per-path terms.

## Typed operands (important)

`public.eql_v3_json_search` is a PostgreSQL **domain over `jsonb`**. PostgreSQL resolves `domain OP untyped_literal` to the **native** `jsonb` operator, because it flattens the domain to its base type when the right-hand side is an unknown-typed literal. A bare literal therefore **bypasses the encrypted operator (and the blockers) and silently returns native jsonb semantics** — typically a root-key lookup that yields `NULL` — instead of querying the encrypted document or raising.

Always give the operand a known type:

```sql
-- ✅ correct — typed operand resolves to the eql_v3 operator
WHERE doc -> 'email'::text = $1
WHERE doc @> $1::eql_v3.query_json
WHERE doc -> $1            -- a text parameter (the CipherStash Proxy interface)

-- ⚠ wrong — bare untyped literal resolves to native jsonb -> text, returns NULL
WHERE doc -> 'email'
```

This is **intrinsic to the domain type-kind**, not a bug: the only way to remove it would be to make `public.eql_v3_json_search` a base type (losing free `jsonb` interop). The CipherStash Proxy always passes typed parameters, so applications routing through the Proxy are unaffected; the caveat matters only for hand-written ad-hoc SQL.

## Querying `public.eql_v3_json_search`

### Containment queries (`@>`, `<@`)

`@>` tests whether the encrypted document contains a structure; `<@` is the reverse. The needle must be **typed** — another `public.eql_v3_json_search`, an `eql_v3.query_json`, or an `public.eql_v3_json_entry`:

```sql
SELECT * FROM examples
WHERE encrypted_json @> $1::eql_v3.query_json;
```

This is the encrypted equivalent of the plaintext `jsonb_column @> '{"top":{"nested":["a"]}}'`.

For large tables, back containment with a GIN index. The typed `@>` overload inlines to a native `jsonb @>` over `eql_v3.to_ste_vec_query(col)::jsonb`, so a GIN index on the same expression engages:

```sql
CREATE INDEX examples_json_gin
  ON examples USING gin (eql_v3.to_ste_vec_query(encrypted_json)::jsonb jsonb_path_ops);
ANALYZE examples;

SELECT * FROM examples WHERE encrypted_json @> $1::eql_v3.query_json;
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

`->` returns the matched entry as an `public.eql_v3_json_entry`; `->>` returns it serialized as `text` (ciphertext JSON, not decrypted plaintext). The selector operand must be typed:

```sql
-- Field access by selector (returns public.eql_v3_json_entry)
SELECT encrypted_json -> 'selector_hash'::text FROM examples;

-- Field access as text (returns the entry as ciphertext text)
SELECT encrypted_json ->> 'selector_hash'::text FROM examples;

-- Array element by 0-based index (returns public.eql_v3_json_entry)
SELECT encrypted_json -> 0 FROM examples;
```

The extracted `public.eql_v3_json_entry` is itself comparable: `=` / `<>` resolve via `eql_v3.eq_term`, and `<` / `<=` / `>` / `>=` via `eql_v3.ord_term` (on String / Number leaves):

```sql
SELECT * FROM examples
WHERE encrypted_json -> 'email_selector'::text = $1::public.eql_v3_json_entry;
```

### Selector-with-constraint queries (index-accelerated)

An extracted leaf also compares directly against a **per-type query operand** in natural operator form, so a single-field constraint (`col -> '$.age' > 21`) is expressible without a whole-entry needle — and matches a functional index on `eql_v3.ord_term`:

```sql
SELECT * FROM examples
WHERE encrypted_json -> 'age_selector'::text  >  $1::eql_v3.query_integer_ord;   -- range
SELECT * FROM examples
WHERE encrypted_json -> 'age_selector'::text  =  $1::eql_v3.query_integer_ord;   -- equality
SELECT * FROM examples
WHERE encrypted_json -> 'name_selector'::text >  $1::eql_v3.query_text_ord;       -- text: ORDERING ONLY
```

Both sides resolve through `eql_v3.ord_term` — byte-comparison on the deterministic CLLW-OPE `op` term. A functional index `USING btree (eql_v3.ord_term(encrypted_json -> 'selector'::text))` engages for every one of them.

Which comparisons you get depends on the leaf's type:

| leaf type | operators | why |
|---|---|---|
| number (`integer`, `bigint`, `date`, `timestamp`, `numeric`, `real`, `double`) | `=` `<>` `<` `<=` `>` `>=` | `op` encodes the value through `orderable_to_u64`, a bijection — so `op` equality is exact |
| string (`text`) | `<` `<=` `>` `>=` only | `op` encodes the **collated** value, so equality on it is not exact — see below |

The operands carrying `op` are `eql_v3.query_<T>_ord` and its explicit twin `eql_v3.query_<T>_ord_ope`. Operands whose index terms an extracted leaf cannot produce are not bound at all: `eql_v3.query_<T>_eq` (HMAC only), `eql_v3.query_<T>_ord_ore` / `query_text_search_ore` (block-ORE), `eql_v3.query_text_match` (Bloom), and `eql_v3.query_text_search` — a leaf carries no `match_term`, so SteVec has no match/bloom capability and `search` offers nothing over `_ord` while demanding an inert `bf`.

> **Note.** There is no `eql_v3.query_<T>_eq` operator on `public.eql_v3_json_entry` for any type. A JSON scalar leaf carries only the `op` term — never a per-value equality (`hm`) term. (For `text`, `eql_v3.query_text_ord` still requires an `hm` key to satisfy its domain CHECK, because the same operand type also serves scalar `text` columns; when querying a JSON leaf that `hm` is not part of the comparison.)

> **⚠️ `=` and `<>` are not available on a `text` leaf — they raise `operator is not supported`.** A string leaf's `op` term encodes the value *after collation*: cipherstash-client normalises with NFKC and then strips every character that is not alphanumeric, whitespace, or ASCII punctuation. So `"café"` and `"cafe"`, `"Müller"` and `"Muller"`, `"user@exämple.com"` and `"user@example.com"` all produce the **same** `op` term. An `=` built on it would silently return rows whose plaintext differs, so EQL does not offer one. Ordering is unaffected — a collated order is the intended semantic, and it is the same order scalar `text_ord` columns use. To match a string field exactly, query the document with containment (`@>`), whose `hm` terms are exact.

> **The operand must be encrypted for the same column, and as the same JSON scalar type, as the leaf.** Field scoping comes from the `->` extraction, not from the operand: an `op` term encodes the plaintext and the column, and carries no selector (only `hm` terms do). So one operand is comparable against whichever leaf you extract — which also means an operand encrypted for a *different column*, or for a different JSON scalar type (a number term against a string leaf), has non-corresponding term bytes and **silently returns zero rows with no error**. The SQL layer only compares terms and cannot detect the mismatch; keeping the operand's column and type aligned with the leaf is the client's / CipherStash Proxy's responsibility.

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

`MIN` / `MAX` over an extracted ordered leaf use the `eql_v3.min(public.eql_v3_json_entry)` / `max` aggregates.

## `eql_v3` functions for JSONB and ste_vec

### Core functions

- **`eql_v3.ste_vec(val jsonb) RETURNS jsonb[]`** — extracts the ste_vec index array from an encrypted payload.
- **`eql_v3.ste_vec_contains(a public.eql_v3_json_search, b public.eql_v3_json_search) RETURNS boolean`** — true if all ste_vec terms in `b` exist in `a`; backs the `@>` operator.
- **`eql_v3.to_ste_vec_query(val public.eql_v3_json_search) RETURNS eql_v3.query_json`** — the GIN-indexable query shape `@>` inlines to.
- **`eql_v3.meta_data(val jsonb)`**, **`eql_v3.ciphertext(val jsonb)`**, **`eql_v3.selector(val jsonb)` / `(entry public.eql_v3_json_entry)`** — envelope / ciphertext / selector accessors.

### Path query functions

- **`eql_v3.jsonb_path_query(val jsonb, selector text)`** — entries matching the selector.
- **`eql_v3.jsonb_path_query_first(val jsonb, selector text)`** — first match.
- **`eql_v3.jsonb_path_exists(val jsonb, selector text) RETURNS boolean`** — selector presence.

### Array functions

- **`eql_v3.jsonb_array_length(val jsonb) RETURNS integer`**
- **`eql_v3.jsonb_array_elements(val jsonb)`**
- **`eql_v3.jsonb_array_elements_text(val jsonb) RETURNS SETOF text`**

### Entry comparison / aggregate

- **`eql_v3.eq_term(entry public.eql_v3_json_entry)`** — equality term (backs `=` / `<>` / `GROUP BY`).
- **`eql_v3.ord_term(entry public.eql_v3_json_entry)`** — ordering term (backs `<` … `>=`); returns SQL `NULL` when the leaf carries no `op` term.
- **`eql_v3.min(public.eql_v3_json_entry)` / `eql_v3.max(...)`** — MIN / MAX over an extracted ordered leaf.

For GIN-indexable JSONB containment, see [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment) (`eql_v3.to_ste_vec_query(col)::jsonb jsonb_path_ops`).

### Blocked operators

The native `jsonb` operators `?`, `?|`, `?&`, `@?`, `@@`, `#>`, `#>>`, `-`, `#-`, `||`, and root-document `=` `<>` `<` `<=` `>` `>=` are **blocked** on `public.eql_v3_json_search` — they `RAISE` rather than running plaintext-jsonb semantics on the encrypted payload. Use containment, field access, or the `eql_v3.jsonb_path_*` functions instead.

## How ste_vec indexing works

Structured Encryption (ste_vec) makes a JSONB document searchable by:

1. **Flattening the structure** — each unique path to a leaf gets a deterministic selector hash.
2. **Encrypting terms** — each path and value is encrypted into per-path terms (`hm` for equality; `op` CLLW OPE for ordered String / Number leaves).
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
WHERE encrypted_data @> $1::eql_v3.query_json;
```

Encryption and selector generation are handled by CipherStash Proxy or CipherStash Stack, not by EQL directly.

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20json-support.md)
