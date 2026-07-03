# SQL support matrix for EQL

This page summarises which SQL operators and language features work against EQL-encrypted columns, and which encrypted-domain **type** each one requires.

EQL ships its searchable-encryption surface as PostgreSQL **domains in the `eql_v3` schema**:

- **per-scalar encrypted-domain types** — `eql_v3.integer`, `eql_v3.text`, `eql_v3.timestamp`, … — one family of domain *variants* per scalar; and
- **an encrypted-JSON document type** — `eql_v3.json` — for structured-encryption (ste_vec) JSONB.

The capability of a column is fixed by the **domain variant you type it as**. There is no database-side `add_search_config` / `add_column` step: which index terms travel in a value's payload is decided by the encryption client ([CipherStash Proxy](https://github.com/cipherstash/proxy) / [Protect.js](https://github.com/cipherstash/protectjs)), and the column's domain variant is what makes the matching operators resolve. Unsupported operators are not silent no-ops — they route to blocker functions that `RAISE` an "operator not supported" exception (a `NULL` operand still raises; the blockers are deliberately not `STRICT`).

---

## Encrypted-domain scalar types (`eql_v3.<T>`)

Each scalar type `<T>` is a family of `jsonb`-backed domains in `eql_v3`. The catalog scalar tokens that ship today are:

`smallint`, `integer`, `bigint`, `numeric`, `real`, `double`, `date`, `timestamp`, `text`, `boolean`.

(See [Adding a Scalar Encrypted-Domain Type](./adding-a-scalar-encrypted-domain-type.md) for how the family is generated.) The domains live in the `eql_v3` schema — `DROP SCHEMA eql_v3 CASCADE` removes them — and their extracted index-term types are the self-contained `eql_v3` SEM types (`eql_v3.hmac_256`, `eql_v3.ore_block_256`, `eql_v3.bloom_filter`).

Every scalar generates a storage-only variant plus the query variants its capabilities allow:

| Domain variant                | Index term carried        | Extractor (for indexing) | `=` `<>` | `<` `<=` `>` `>=` | `MIN` / `MAX` | `@>` `<@` |
| ----------------------------- | ------------------------- | ------------------------ | :------: | :---------------: | :-----------: | :-------: |
| `eql_v3.<T>`                  | none (storage only)       | —                        |    ❌    |        ❌         |      ❌       |    ❌     |
| `eql_v3.<T>_eq`               | `hm` (hmac_256)           | `eql_v3.eq_term(col)`    |    ✅    |        ❌         |      ❌       |    ❌     |
| `eql_v3.<T>_ord` / `_ord_ore` | `ob` (ore_block_256)      | `eql_v3.ord_term(col)`   |    ✅    |        ✅         |      ✅       |    ❌     |
| `eql_v3.text_match`           | `bf` (bloom_filter)       | `eql_v3.match_term(col)` |    ❌    |        ❌         |      ❌       |    ✅\*   |
| `eql_v3.text_search`          | `hm` + `ob` + `bf`        | all three extractors     |    ✅    |        ✅         |      ✅       |    ✅\*   |

\* On `text_match` / `text_search`, `@>` / `<@` are **bloom-filter token containment** (probabilistic ngram match), **not** JSONB containment and **not** SQL `LIKE`. See [Indexing](#indexing).

Notes:

- The bare `eql_v3.<T>` variant carries no index term and **blocks every comparison operator** — it is storage / decryption only. Type the column as `_eq` or `_ord` (or cast at the call site, e.g. `col::eql_v3.integer_ord`) when you need to query.
- `_ord` and `_ord_ore` are **twins**: byte-identical surfaces backed by the ORE block term. Pick the name that documents intent ("ordered" vs "ordered via ORE block"); both support the full ordered surface and the `MIN` / `MAX` aggregates.
- `=` / `<>` is the only searchable surface for `_eq`. On `_ord` variants the equality operators are available too (alongside the ordered ones).
- `boolean` is **storage-only** by design — a two-value column has too little cardinality for any searchable index to be safe, so it ships only `eql_v3.boolean` (no `_eq` / `_ord`).
- `LIKE` / `ILIKE` (`~~` / `~~*`) and the native JSONB operators are **blocked on every scalar domain variant** — they are meaningless on a scalar payload. Text matching is the bloom-filter `@>` on `text_match`, not `LIKE`.
- `MIN` / `MAX` are exposed only on the ordered variants, as `eql_v3.min(eql_v3.<T>_ord)` / `eql_v3.max(...)` (and the `_ord_ore` twin) — see [EQL Functions Reference](./eql-functions.md#eql_v3min--eql_v3max-per-domain).

---

## SQL operator support

A ✅ means the operator resolves on a column typed as that domain variant. A ❌ means the operator is blocked (it raises) for that variant.

| SQL operator              | Meaning                        | `eql_v3.<T>` | `_eq` | `_ord` / `_ord_ore` | `text_match` | `text_search` |
| ------------------------- | ------------------------------ | :----------: | :---: | :-----------------: | :----------: | :-----------: |
| `=`                       | Equality                       |      ❌      |  ✅   |         ✅          |      ❌      |      ✅       |
| `<>` / `!=`               | Inequality                     |      ❌      |  ✅   |         ✅          |      ❌      |      ✅       |
| `<` `<=` `>` `>=`         | Ordered comparison             |      ❌      |  ❌   |         ✅          |      ❌      |      ✅       |
| `@>` / `<@`               | Bloom-filter token containment |      ❌      |  ❌   |         ❌          |      ✅      |      ✅       |
| `LIKE` `ILIKE` (`~~`/`~~*`) | SQL pattern match            |      ❌      |  ❌   |         ❌          |      ❌      |      ❌       |
| `IS NULL` / `IS NOT NULL` | Null check                     |      ✅      |  ✅   |         ✅          |      ✅      |      ✅       |

Notes:

- A SQL `NULL` column value is not encrypted, so `IS NULL` / `IS NOT NULL` always work regardless of variant.
- `@>` / `<@` on `text_match` / `text_search` test whether the encrypted text **contains** the (encrypted) search terms via the bloom filter. This replaces the old `LIKE`/`ILIKE`-on-`match`-index recipe: there is no `LIKE` on encrypted text — use `@>`.

---

## SQL syntax / feature support

This matrix covers higher-level SQL constructs. As above, ✅ requires the column to be typed as a variant that carries the necessary term.

| SQL feature                          | Notes                                                                                  | Required variant |
| ------------------------------------ | -------------------------------------------------------------------------------------- | ---------------- |
| `WHERE col = …` / `<>`               |                                                                                        | `_eq`, `_ord`, `text_search` |
| `WHERE col <` / `<=` / `>` / `>=`    |                                                                                        | `_ord`, `text_search` |
| `WHERE col BETWEEN … AND …`          | desugars to `>=` and `<=`                                                               | `_ord`, `text_search` |
| `WHERE col @> …`                     | bloom-filter token containment (text), or document containment (`eql_v3.json`)         | `text_match`, `text_search`, `eql_v3.json` |
| `WHERE col IN (…)`                   | desugars to `=`                                                                         | `_eq`, `_ord`, `text_search` |
| `ORDER BY col`                       | meaningful only with an ORE term                                                        | `_ord`, `text_search` |
| `GROUP BY col` / `DISTINCT`          | needs an equality term                                                                  | `_eq`, `_ord`, `text_search` |
| `MIN(col)` / `MAX(col)`              | `eql_v3.min(eql_v3.<T>_ord)` / `max` — type the column as `_ord` or cast at the call site (`eql_v3.min(col::eql_v3.integer_ord)`) | `_ord` |
| `COUNT(col)` / `COUNT(DISTINCT col)` | plain `COUNT(col)` needs no term; `DISTINCT` needs an equality term                     | any / `_eq` for `DISTINCT` |
| `JOIN … ON lhs.col = rhs.col`        | both sides must share the same keyset and a matching variant                            | `_eq`, `_ord`, `text_search` |

Notes:

- **Cross-column / cross-table comparisons** (joins, `IN (subquery)`, set-operation dedup) require both sides to have been encrypted with the *same* keyset and a matching variant.
- **`ORDER BY`** without an ORE term will not produce a meaningful order — type the column as an `_ord` variant when ordering matters.
- **Aggregates beyond `MIN` / `MAX`** (`SUM`, `AVG`, …) are not supported on encrypted values — decrypt at the application boundary and aggregate client-side.
- **Parameter binding**: CipherStash Proxy rewrites bound parameters so the encrypted operator and any functional indexes are selected. When bypassing the proxy, type the parameter (`$1::eql_v3.integer_ord`) so the encrypted operator resolves rather than the native `jsonb` one.

---

## Indexing

`eql_v3` indexes through a **functional index on the term extractor**, never an operator class on a column. The extractor's return type carries a default opclass, and the extractors are inlinable, so bare-form queries (`WHERE col = $1`, `ORDER BY col`) engage the index:

```sql
-- Equality (hash index on eq_term)
CREATE INDEX users_email_eq ON users USING hash (eql_v3.eq_term(encrypted_email));

-- Ordering / range (btree index on ord_term)
CREATE INDEX events_at_ord ON events USING btree (eql_v3.ord_term(encrypted_at));

-- Text match (bloom containment — GIN on match_term)
CREATE INDEX users_name_match ON users USING gin (eql_v3.match_term(encrypted_name));
```

See [Database Indexes for Encrypted Columns](./database-indexes.md) for the full recipes, GIN containment, and performance guidance.

---

## `eql_v3.json`: structured encryption for JSON

`eql_v3.json` is the encrypted-JSON document domain (built on the structured-encryption "ste_vec" model). A JSONB document is encrypted into a searchable vector (`sv`) of terms — one element per path inside the document — each carrying:

- `s` — a deterministic **selector** hash for the JSON path (always present); and
- one or more **value terms** depending on the JSON type of the leaf at that path.

Selectors locate a path; value terms let EQL compare the value at that path.

### Index terms by JSON node type

The search capabilities available on a value extracted via `->` or `eql_v3.jsonb_path_query` are determined by the terms emitted for that node type.

| JSON node type           | Value terms (alongside `s`)                       | Equality (`=`, `<>`, `GROUP BY`) | Ordering (`<` … `>=`, `ORDER BY`, `MIN`/`MAX`) |
| ------------------------ | ------------------------------------------------- | :------------------------------: | :--------------------------------------------: |
| Object `{ … }`           | `hm`                                              | ✅                               | ❌                                             |
| Array `[ … ]`            | `hm` on the container; each element also appears as its own `sv` entry with its own leaf terms | ✅ | ❌                          |
| String `"…"`             | `hm`, `ocv` (variable-width CLLW ORE)             | ✅                               | ✅                                             |
| Number (integer/numeric) | `hm`, `ocf` (fixed-width CLLW ORE)                | ✅                               | ✅                                             |
| Boolean / JSON null      | `hm`                                              | ✅                               | ❌                                             |

`hm` supports equality only; `ocv` / `ocf` are CLLW ORE terms that preserve order *and* collapse to equality on matching keys. JSON `null` here refers to a `null` literal *inside* the document — a SQL `NULL` column is not encrypted at all.

### Operators and functions on `eql_v3.json`

| SQL form                         | Resolves to                                        | Returns / notes |
| -------------------------------- | -------------------------------------------------- | --------------- |
| `doc @> needle` / `needle <@ doc` | `eql_v3."@>"` / `eql_v3."<@"`                      | document containment; GIN-indexable via `eql_v3.to_ste_vec_query(doc)::jsonb` — see [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment). `needle` must be typed (`$1::eql_v3.jsonb_query`, another `eql_v3.json`, or an `eql_v3.jsonb_entry`). |
| `doc -> 'sel'::text` / `doc -> N` | `eql_v3."->"`                                     | field / 0-based array-element access; returns `eql_v3.jsonb_entry`. |
| `doc ->> 'sel'::text`            | `eql_v3."->>"`                                     | the matching entry serialized as `text` (ciphertext JSON, **not** decrypted plaintext). |
| extracted-leaf `=` `<>`          | `eql_v3.eq_term(eql_v3.jsonb_entry)`             | equality on a value extracted via `->` (e.g. `doc -> 'sel'::text = $1`). |
| extracted-leaf `<` `<=` `>` `>=` | `eql_v3.ore_cllw(eql_v3.jsonb_entry)`            | ordered comparison on an extracted String / Number leaf. |
| `MIN` / `MAX` of extracted leaf  | `eql_v3.min(eql_v3.jsonb_entry)` / `max`         | over an extracted ordered leaf. |
| `eql_v3.jsonb_path_query(doc, sel)` | path query                                      | set-returning; yields encrypted entries. Also `jsonb_path_query_first`, `jsonb_path_exists`. |
| `eql_v3.jsonb_array_length/elements/elements_text(doc)` | array helpers                  | length / set-returning elements / element text. |

> **Typed operands (important).** The selector / needle operand must carry a **known type** — a typed parameter (`$1`, which the Proxy supplies) or an explicit cast (`doc -> 'sel'::text`, `$1::eql_v3.jsonb_query`). A bare untyped literal (`doc -> 'sel'`) resolves to the **native `jsonb` operator** (PostgreSQL reduces the `eql_v3.json` domain to its `jsonb` base type for an unknown-typed RHS) and silently returns native jsonb semantics instead of the encrypted operator.

### Blocked JSONB operators

These native PostgreSQL JSONB operators are **blocked** on `eql_v3.json` (they `RAISE`, rather than falling through to native whole-document semantics): root-document `=` `<>` `<` `<=` `>` `>=`, and `?`, `?|`, `?&`, `@?`, `@@`, `#>`, `#>>`, `-`, `#-`, `||`. Use containment (`@>`), field access (`->` / `->>`), or the `eql_v3.jsonb_path_*` functions instead.

See [EQL with JSON and JSONB](./json-support.md) for worked examples.

---

## See also

- [EQL Functions Reference](./eql-functions.md) — full list of functions and operators.
- [Database Indexes for Encrypted Columns](./database-indexes.md) — functional-index and GIN recipes, plus performance guidance.
- [EQL with JSON and JSONB](./json-support.md) — end-to-end `eql_v3.json` examples.
- Client-side searchable-encryption configuration — [Protect.js schema reference](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md) and [CipherStash Proxy](https://github.com/cipherstash/proxy).

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20sql-support.md)
