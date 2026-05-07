# SQL support matrix for EQL

This page summarises which SQL operators and language features work against `eql_v2_encrypted` columns/values, and which EQL searchable-encryption index (configured via [`eql_v2.add_search_config`](./index-config.md)) each one requires.

EQL ships five search index kinds that encrypt data in ways that preserve specific query capabilities:

| Search index (config `index_name`) | Underlying encrypted term(s) | Enables                                                |
| ---------------------------------- | ---------------------------- | ------------------------------------------------------ |
| `unique`                           | `hmac_256` (`hm`) or `blake3` (`b3`) | Exact equality                                         |
| `ore`                              | `ore_block_u64_8_256` (`ob`) | Ordered comparison (`<`, `<=`, `=`, `>`, `>=`), range (`BETWEEN`), `ORDER BY`, aggregates (`MIN`/`MAX`)     |
| `ope`                              | `ope_cllw_u64_65` (`opf`) or `ope_cllw_var_8` (`opv`) | Ordered comparison (`<`, `<=`, `=`, `>`, `>=`), range (`BETWEEN`), `ORDER BY`, aggregates (`MIN`/`MAX`) — see note below |
| `match`                            | `bloom_filter` (`bf`)        | Substring / token matching via `LIKE` / `ILIKE`        |
| `ste_vec`                          | Structured encryption (`sv`) | JSONB containment and JSONB path / field access        |

> **`ore` vs `ope`** — both index kinds support the same ordered-comparison surface. `ore` (Order-Revealing Encryption) is the default. `ope` (CLLW Order-Preserving Encryption) is an alternative for environments that need plain lexicographic byte comparison (e.g. pluggable storage that cannot run a custom comparator). On a column configured for `ope`, `eql_v2.compare()` and the `<` / `<=` / `>` / `>=` operators dispatch to OPE terms automatically.


Every column must also be registered with `eql_v2.add_column(...)` — that alone gives the column storage and decryption, but none of the operators below will produce results until at least one search index is added for the operation you need.

---

## SQL operator support

Each row lists an operator that EQL either implements natively on `eql_v2_encrypted` or that CipherStash Proxy rewrites into an EQL equivalent. A ✅ means the operator is supported on a column when that index is configured. A ❌ means the index does not support the operator (the database will either error, return no rows, or fall back to a scan that decrypts nothing useful).

| SQL operator                      | Meaning                         | `unique` | `ore` | `ope` | `match` | `ste_vec` |
| --------------------------------- | ------------------------------- | :------: | :---: | :---: | :-----: | :-------: |
| `=`                               | Equality                        |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `<>` / `!=`                       | Inequality                      |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `<`                               | Less than                       |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `<=`                              | Less than or equal              |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `>`                               | Greater than                    |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `>=`                              | Greater than or equal           |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `LIKE` (`~~`)                     | Case-sensitive pattern match    |    ❌    |  ❌   |  ❌   |   ✅    |    ❌     |
| `NOT LIKE` (`!~~`)                | Negated case-sensitive match    |    ❌    |  ❌   |  ❌   |   ✅    |    ❌     |
| `ILIKE` (`~~*`)                   | Case-insensitive pattern match  |    ❌    |  ❌   |  ❌   |   ✅\*  |    ❌     |
| `NOT ILIKE` (`!~~*`)              | Negated case-insensitive match  |    ❌    |  ❌   |  ❌   |   ✅\*  |    ❌     |
| `@>`                              | JSONB contains                  |    ❌    |  ❌   |  ❌   |   ❌    |    ✅     |
| `<@`                              | JSONB is contained by           |    ❌    |  ❌   |  ❌   |   ❌    |    ✅     |
| `->` (text, int, encrypted)       | JSONB field / element access    |    ❌    |  ❌   |  ❌   |   ❌    |    ✅     |
| `->>`                             | JSONB field as text (ciphertext) |   ❌    |  ❌   |  ❌   |   ❌    |    ✅     |
| `IS NULL` / `IS NOT NULL`         | Null check                      |    ✅    |  ✅   |  ✅   |   ✅    |    ✅     |

\* Case-insensitivity for `ILIKE` / `NOT ILIKE` is only effective when the `match` index is configured with a case-normalising token filter (e.g. `{"token_filters": [{"kind": "downcase"}]}`). Without it, `ILIKE` behaves identically to `LIKE` on the encrypted terms.

Notes:

- Binary operators have overloads that accept `jsonb` literals on either side; CipherStash Proxy typically rewrites those to `::eql_v2_encrypted` casts so the encrypted operator is selected.
- `=` and `<>` on a column that has **only** a `ste_vec` index will not match anything useful — the underlying comparison requires `hm`, `b3`, `ob`, `opf`, or `opv` terms. Configure `unique` (or `ore` / `ope`) alongside `ste_vec` if you need equality on the outer value.
- JSONB path operators (`->`, `->>`) return an `eql_v2_encrypted` value (or ciphertext for `->>`). The value they return is itself searchable only if the parent `ste_vec` index covers that path.

### Unsupported JSONB operators

The following PostgreSQL JSONB operators are **not** implemented for `eql_v2_encrypted`.

`?`, `?&`, `?|`, `@?`, `@@`

Use the equivalent [`jsonb_path_query`](#jsonb-functions-and-selectors-enabled-by-ste_vec) or containment patterns instead.

---

## SQL syntax / feature support

This matrix covers higher-level SQL constructs rather than individual operators. As above, ✅ requires the listed index to be configured on the column; ❌ means the construct cannot be used against that column (without first decrypting via CipherStash Proxy or Protect.js).

| SQL feature                        | Notes      | `unique` | `ore` | `ope` | `match` | `ste_vec` |
| ---------------------------------- | ------------------------------------- | :------: | :---: | :---: | :-----: | :-------: |
| `WHERE col = …` / `<>`             |                                   |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `WHERE col <` / `<=` / `>` / `>=`  |                                  |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `WHERE col BETWEEN … AND …`        | desugars to `>=` and `<=`     |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `WHERE col LIKE …` / `NOT LIKE`    |                           |    ❌    |  ❌   |  ❌   |   ✅    |    ❌     |
| `WHERE col ILIKE …` / `NOT ILIKE`  | requires `downcase` filter      |    ❌    |  ❌   |  ❌   |   ✅    |    ❌     |
| `WHERE col IN (…)`                 |               |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `WHERE col @> …` / `<@ …`          |                              |    ❌    |  ❌   |  ❌   |   ❌    |    ✅     |
| `ORDER BY col`                     |                                  |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `GROUP BY col`                     | requires `unique` on the whole column; `ore` / `ope` not yet supported (see note below). Extracted JSON paths have separate caveats — see [ste_vec section](#index-terms-by-json-node-type). |    ✅    |  ❌   |  ❌   |   ❌    |    ❌     |
| `DISTINCT` / `DISTINCT ON (col)`   | `unique`, `ore`, or `ope`                                  |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `HAVING`                           | same index requirements as the predicates used in `HAVING` (see operator matrix) | varies | varies | varies | varies | varies |
| `MIN(col)` / `MAX(col)`            |                                  |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `COUNT(col)` / `COUNT(DISTINCT col)` | `ore` / `ope` or `unique` for `DISTINCT`; none for plain `COUNT(col)` |    ✅    |  ✅   |  ✅   |   ✅    |    ✅     |
| `JOIN … ON lhs.col = rhs.col`      | same index and keyset on both sides      |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `JOIN … ON lhs.col < rhs.col` etc. | same index and keyset on both sides     |    ❌    |  ✅   |  ✅   |   ❌    |    ❌     |
| `UNION` / `EXCEPT` / `INTERSECT` (set operations) |                          |    ✅    |  ✅   |  ✅   |   ❌    |    ❌     |
| `IS NULL` / `IS NOT NULL`          | works because `NULL` values are not encrypted |   ✅    |  ✅   |  ✅   |   ✅    |    ✅     |
| Window functions over encrypted columns | works like the equivalent clauses in normal SQL (e.g. window `ORDER BY` needs `ore` or `ope`) | varies | varies | varies | varies | varies |

Notes:

- **Cross-column / cross-table comparisons** (joins, `IN (subquery)`, `UNION` dedup, etc.) require both sides to have been encrypted with the *same* keyset and the matching search index. Encrypted values from different `ste_vec` prefixes are deliberately incomparable.
- **`GROUP BY`** on encrypted columns relies on an operator class which currently only supports encrypted values with a `unique` index term. This is a surprising limitation because it would be natural to expect `ore` / `ope` index terms to also work. This limitation will be lifted in the future. See [Database Indexes](./database-indexes.md#group-by) for performance considerations.
- **`ORDER BY`** without an `ore` or `ope` index will still *run* (the EQL `compare` function has a deterministic literal fallback to avoid btree errors), but the resulting order is not meaningful. Configure `ore` (or `ope`) whenever ordering matters.
- **Aggregates beyond `MIN`/`MAX`** (e.g. `SUM`, `AVG`) are not supported on encrypted values — decrypt and perform those aggregate operations on the client-side instead.
- **Parameter binding**: CipherStash Proxy rewrites bound parameters in `WHERE`, `JOIN`, and `RETURNING` clauses with `::JSONB::eql_v2_encrypted` casts so that the encrypted operator and any B-tree / GIN indexes are selected. Writing those casts yourself is only required when bypassing the proxy.

---

## ste_vec: structured encryption for JSON

The `ste_vec` index turns a JSONB document into a searchable vector (the `sv` array) of encrypted terms. Each element of `sv` corresponds to one path inside the document and carries:

- `s` — a deterministic **selector** hash for the JSON path (always present).
- One or more **value terms** that depend on the JSON type of the leaf at that path.

Selectors let EQL locate a path; value terms let it compare the value at that path. The tables below cover (1) which value terms each JSON node type produces — i.e. which operators are possible on each node type via ste_vec alone — and (2) which standard PostgreSQL JSONB functions and selectors CipherStash Proxy rewrites to their ste_vec-backed EQL equivalents.

### Index terms by JSON node type

For each path in the document, ste_vec emits an element whose value terms depend on the type of the JSON leaf. The search capabilities available on a value extracted via `->` or `jsonb_path_query` are determined by those terms.

| JSON node type          | Value terms emitted (alongside `s`) | Equality (`=`, `<>`, `IN`, `GROUP BY`) | Ordering (`<`, `<=`, `>`, `>=`, `BETWEEN`, `ORDER BY`, `MIN`/`MAX`) |
| ----------------------- | ----------------------------------- | :------------------------------------: | :-----------------------------------------------------------------: |
| Object `{ ... }`        | `b3` (blake3)                       | ✅                                     | ❌                                                                  |
| Array `[ ... ]`         | `b3` on the container; each element also appears as its own `sv` entry, flagged `"a": 1`, carrying the terms for its own leaf type | ✅ (structural equality and containment) | ❌                                                      |
| String `"..."`          | `ocv` (variable-width CLLW ORE)     | ✅                                     | ✅                                                                  |
| Number (`integer`, `numeric`, …) | `ocf` (fixed-width CLLW ORE, `u64_8`) | ✅                               | ✅                                                                  |
| Boolean `true` / `false` | `b3`                               | ✅                                     | ❌                                                                  |
| Null (JSON `null`)      | `b3`                                | ✅                                     | ❌                                                                  |

Notes:

- **`b3`** (blake3) is a deterministic hash — it supports equality only. **`ocv`** and **`ocf`** are CLLW Order-Revealing Encryption terms; they preserve order *and* collapse to equality when two operands share the same key.
- The "Equality" and "Ordering" columns describe what is possible on a value **extracted from the JSON document** (e.g. via `encrypted_json->'selector' = …` or `ORDER BY jsonb_path_query(...)`). The outer `eql_v2_encrypted` column still needs a sibling `unique` / `ore` index if you want `WHERE col = …` on the whole document — see [Operators section notes](#sql-operator-support).
- **`GROUP BY` caveat**: the current btree operator class for `eql_v2_encrypted` only groups on `b3` / `hm` terms. `GROUP BY` on an extracted **string** or **number** path therefore does not work via ste_vec alone — add a `unique` index to that path if you need it. Object, array, boolean, and null paths group fine via ste_vec.
- **JSON null vs SQL NULL**: the row above refers to JSON `null` literals *inside* the document. A SQL `NULL` column value is not encrypted at all, so `IS NULL` / `IS NOT NULL` always work regardless of the index configuration.

### JSONB functions and selectors enabled by ste_vec

When the `ste_vec` index is configured, CipherStash Proxy rewrites these standard PostgreSQL JSONB functions, selectors, and aggregates to their `eql_v2` equivalents so they operate on encrypted JSON. The "Also requires" column lists any *additional* capability that must be present on the extracted node (see the table above).

| Function / selector                      | Rewritten to                                    | Also requires                                                                 | Notes                                                                  |
| ---------------------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `jsonb_path_query(col, path)`            | `eql_v2.jsonb_path_query(col, selector)`        | —                                                                             | Set-returning; yields `eql_v2_encrypted`. Paths become selector hashes. |
| `jsonb_path_query_first(col, path)`      | `eql_v2.jsonb_path_query_first(...)`            | —                                                                             | Returns `eql_v2_encrypted`.                                             |
| `jsonb_path_exists(col, path)`           | `eql_v2.jsonb_path_exists(...)`                 | —                                                                             | Returns `boolean`.                                                      |
| `col -> 'field'` / `col -> N`            | ste_vec path / array-element access             | —                                                                             | Returns `eql_v2_encrypted`. `N` is a 0-based index into an array node.  |
| `col ->> 'field'`                        | ste_vec path as ciphertext text                 | —                                                                             | Returns the **ciphertext** as `text` (not plaintext).                   |
| `col @> value` / `value <@ col`          | ste_vec containment (via `@>` / `<@`)           | —                                                                             | GIN-indexable via `eql_v2.jsonb_array(col)` — see [Database Indexes](./database-indexes.md#gin-indexes-for-jsonb-containment). |
| `jsonb_array_length(arr)`                | `eql_v2.jsonb_array_length(arr)`                | Path must resolve to a JSON array node                                        | Returns `integer`.                                                      |
| `jsonb_array_elements(arr)`              | `eql_v2.jsonb_array_elements(arr)`              | Path must resolve to a JSON array node                                        | Set-returning; yields `eql_v2_encrypted`.                               |
| `jsonb_array_elements_text(arr)`         | `eql_v2.jsonb_array_elements_text(arr)`         | Path must resolve to a JSON array node                                        | Set-returning; yields ciphertext as `text`.                             |
| `COUNT(col)`                             | plain `count(*)`                                | —                                                                             | No encrypted term required.                                             |
| `COUNT(DISTINCT col)`                    | deterministic dedup                             | An extracted node that emits `b3`, `ocv`, or `ocf` (or a `unique` / `ore` index on the outer column) | A ste_vec-extracted leaf dedups via `b3` (Object / Array / Bool / Null) or `ocv` / `ocf` (String / Number). `ope` is never emitted by ste_vec extraction; it only applies to the outer column. |
| `MIN(col)` / `MAX(col)`                  | `eql_v2` ORE/OPE aggregates                     | A ste_vec-extracted String / Number node (`ocv` / `ocf`), **or** a sibling `ore` / `ope` index on the outer column | ste_vec extraction can only produce `ocv` / `ocf` ordering terms. Whole-column ordering uses the outer-column `ore` or `ope` index. |

Additionally, `eql_v2.jsonb_array`, `eql_v2.jsonb_contains`, and `eql_v2.jsonb_contained_by` are EQL helpers (not automatic rewrites) used when building **GIN-indexed** containment queries. See [GIN Indexes for JSONB Containment](./database-indexes.md#gin-indexes-for-jsonb-containment) for the full setup.

See [EQL with JSON and JSONB](./json-support.md) for worked examples of each function.

---

## See also

- [EQL Functions Reference](./eql-functions.md) — full list of functions and operators.
- [EQL index configuration for CipherStash Proxy](./index-config.md) — how to add / modify / remove search indexes.
- [Database Indexes for Encrypted Columns](./database-indexes.md) — B-tree and GIN index guidance for PostgreSQL.
- [EQL with JSON and JSONB](./json-support.md) — end-to-end examples of `ste_vec` usage.

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20sql-support.md)
