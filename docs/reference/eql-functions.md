# EQL Functions Reference

A reference for the functions and operators EQL exposes for querying encrypted data in PostgreSQL. The surface lives in the **`eql_v3`** schema and is organised around the per-scalar encrypted-domain types (`eql_v3.<T>` and variants) and the encrypted-JSON document type (`eql_v3.json`).

> **There is no database-side configuration API.** Which index terms a value carries is chosen by the encryption client ([CipherStash Proxy](https://github.com/cipherstash/proxy) / [Protect.js](https://github.com/cipherstash/protectjs)); a column's capability is fixed by the **domain variant** you type it as. See [SQL support matrix](./sql-support.md) for the variant/operator table.

## Table of Contents

- [Operators](#operators)
- [Function Equivalents](#function-equivalents)
- [Index Term Extraction](#index-term-extraction)
- [Encrypted JSON (`eql_v3.json`)](#encrypted-json-eql_v3json)
- [Aggregate Functions](#aggregate-functions)

---

## Operators

EQL overloads standard PostgreSQL operators on the encrypted-domain types. Type the column as the variant that carries the term, and the operator resolves (and engages a matching [functional index](./database-indexes.md)). Operands must be typed — a typed parameter (`$1`, supplied by the Proxy) or an explicit cast — or they fall through to native `jsonb`.

### Equality — `=` `<>`

On `eql_v3.<T>_eq`, `eql_v3.<T>_ord` / `_ord_ore`, and `eql_v3.text_search` (carry an `hm` term):

```sql
SELECT * FROM users WHERE encrypted_email = $1;
SELECT * FROM users WHERE encrypted_email = $1::eql_v3.text_eq;
SELECT * FROM users WHERE encrypted_email <> $1;
```

### Range — `<` `<=` `>` `>=`

On `eql_v3.<T>_ord` / `_ord_ore` and `eql_v3.text_search` (carry an `ob` ORE term):

```sql
SELECT * FROM events WHERE encrypted_at <  $1::eql_v3.timestamp_ord;
SELECT * FROM events WHERE encrypted_at >= $1::eql_v3.timestamp_ord;

-- Ordering (write the sort key as the extractor to engage the index — see Database Indexes)
SELECT * FROM events ORDER BY eql_v3.ord_term(encrypted_at) DESC;
```

### Text match — `@>` `<@`

On `eql_v3.text_match` / `eql_v3.text_search` (carry a `bf` bloom term). This is **probabilistic ngram-bloom containment**, not SQL `LIKE` and not JSONB containment:

```sql
SELECT * FROM docs WHERE encrypted_content @> $1::eql_v3.text_match;
```

`LIKE` / `ILIKE` (`~~` / `~~*`) are **not** part of the `eql_v3` surface — use `@>`.

### JSON containment / path — `eql_v3.json`

`@>` / `<@`, `->` / `->>`, and the path functions on `eql_v3.json` are documented in [EQL with JSON and JSONB](./json-support.md).

---

## Function Equivalents

For environments that cannot use custom operators (e.g. some managed platforms), each operator has a function form, generated per domain variant. They take the same domain types as the operators above:

```sql
eql_v3.eq(a, b)   -- =        (on _eq / _ord / text_search)
eql_v3.neq(a, b)  -- <>
eql_v3.lt(a, b)   -- <        (on _ord / _ord_ore / text_search)
eql_v3.lte(a, b)  -- <=
eql_v3.gt(a, b)   -- >
eql_v3.gte(a, b)  -- >=
eql_v3.contains(a, b)       -- @>  (on text_match / text_search / eql_v3.json)
eql_v3.contained_by(a, b)   -- <@
```

**Example:**

```sql
SELECT * FROM users WHERE eql_v3.eq(encrypted_email, $1::eql_v3.text_eq);
SELECT * FROM events WHERE eql_v3.lt(encrypted_at, $1::eql_v3.timestamp_ord);
```

There are no `like` / `ilike` function forms — text matching is `eql_v3.contains` (`@>`) on a `text_match` value.

---

## Index Term Extraction

These extract the index term from an encrypted-domain value. They are generated per eq/ord/match-capable variant of every scalar type, are inlinable (so a functional index on the extractor engages), and return the self-contained `eql_v3` SEM index-term types. See [Adding a Scalar Encrypted-Domain Type](./adding-a-scalar-encrypted-domain-type.md).

```sql
-- Equality term (hm)
eql_v3.eq_term(a eql_v3.integer_eq)        RETURNS eql_v3.hmac_256
-- Ordering term (ob)
eql_v3.ord_term(a eql_v3.integer_ord)      RETURNS eql_v3.ore_block_256
eql_v3.ord_term(a eql_v3.integer_ord_ore)  RETURNS eql_v3.ore_block_256
-- Text-match term (bf)
eql_v3.match_term(a eql_v3.text_match)  RETURNS eql_v3.bloom_filter
```

**Example — functional indexes on the extracted terms** (see [Database Indexes](./database-indexes.md)):

```sql
CREATE INDEX ON users USING hash  (eql_v3.eq_term(salary_eq));
CREATE INDEX ON users USING btree (eql_v3.ord_term(salary_ord));
CREATE INDEX ON users USING gin   (eql_v3.match_term(name_match));
```

> The full per-domain operator / wrapper / blocker surface (and the `eql_v3.<T>` / `_eq` / `_ord` / `_ord_ore` domain types themselves) is documented in [SQL support](./sql-support.md#encrypted-domain-scalar-types-eql_v3t) and the [scalar encrypted-domain type reference](./adding-a-scalar-encrypted-domain-type.md).

The `eql_v3.json` document type extracts entry-level terms with `eql_v3.eq_term(eql_v3.jsonb_entry)` and `eql_v3.ore_cllw(eql_v3.jsonb_entry)` — see [json-support.md](./json-support.md).

---

## Encrypted JSON (`eql_v3.json`)

The full encrypted-JSONB function surface — containment, `->` / `->>`, `eql_v3.jsonb_path_query` / `_first` / `_exists`, `eql_v3.jsonb_array_length` / `_elements` / `_elements_text`, `eql_v3.to_ste_vec_query`, `eql_v3.ste_vec_contains`, and the GIN helpers — is documented in **[EQL with JSON and JSONB](./json-support.md)**.

---

## Aggregate Functions

### `eql_v3.min()` / `eql_v3.max()` (per-domain)

Returns the minimum or maximum encrypted value on an ordered encrypted-domain column. Defined per ord-capable variant of every scalar type (`eql_v3.<T>_ord`, `eql_v3.<T>_ord_ore`); the input type selects the aggregate via PostgreSQL's overload resolution.

```sql
-- integer — generated for every ordered variant of every scalar type.
eql_v3.min(eql_v3.integer_ord)      RETURNS eql_v3.integer_ord
eql_v3.max(eql_v3.integer_ord)      RETURNS eql_v3.integer_ord
eql_v3.min(eql_v3.integer_ord_ore)  RETURNS eql_v3.integer_ord_ore
eql_v3.max(eql_v3.integer_ord_ore)  RETURNS eql_v3.integer_ord_ore
```

Comparison routes through the variant's `<` / `>` operator, which uses the ORE block term — no decryption. The state function is `STRICT`, so `NULL` inputs are skipped and an all-`NULL` input set returns `NULL`.

**Example:**

```sql
-- ord-capable column (e.g. price_encrypted typed as eql_v3.integer_ord)
SELECT eql_v3.min(price_encrypted) FROM products;
SELECT eql_v3.max(price_encrypted) FROM products WHERE category = 'electronics';

-- On a generic jsonb column, cast to the right domain
SELECT eql_v3.min(price_jsonb::eql_v3.integer_ord) FROM products;
```

`MIN` / `MAX` over a value extracted from an `eql_v3.json` document use `eql_v3.min(eql_v3.jsonb_entry)` / `max` — see [json-support.md](./json-support.md).

`SUM` / `AVG` and other arithmetic aggregates are **not** supported on encrypted columns (they would require homomorphic encryption) — decrypt at the application boundary. `MIN` / `MAX` only need comparator-revealing terms.

**See also:** [SQL support matrix](./sql-support.md) for the per-variant capability table.

---

## See Also

- [EQL Configuration Tutorial](../tutorials/proxy-configuration.md) — setting up encrypted columns end to end.
- [Database Indexes](./database-indexes.md) — functional-index recipes and performance.
- [JSON/JSONB Support](./json-support.md) — `eql_v3.json` worked examples.
- [SQL support matrix](./sql-support.md) — operators by domain variant.
- [Payload / wire format](../../crates/eql-bindings/README.md) — canonical encrypted-payload wire types (envelope + index terms).
- Client-side index configuration — [Protect.js schema reference](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md).

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20eql-functions.md)
