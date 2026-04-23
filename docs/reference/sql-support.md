# SQL support matrix for EQL

This page summarises which SQL operators and language features work against `eql_v2_encrypted` columns/values, and which EQL searchable-encryption index (configured via [`eql_v2.add_search_config`](./index-config.md)) each one requires.

EQL ships four search index kinds that encrypt data in ways that preserve specific query capabilities:

| Search index (config `index_name`) | Underlying encrypted term(s) | Enables                                                |
| ---------------------------------- | ---------------------------- | ------------------------------------------------------ |
| `unique`                           | `hmac_256` (`hm`) or `blake3` (`b3`) | Exact equality                                         |
| `ore`                              | `ore_block_u64_8_256` (`ob`) | Ordered comparison (`<`, `<=`, `=`, `>`, `>=`), range (`BETWEEN`), `ORDER BY`, aggregates (`MIN`/`MAX`)     |
| `match`                            | `bloom_filter` (`bf`)        | Substring / token matching via `LIKE` / `ILIKE`        |
| `ste_vec`                          | Structured encryption (`sv`) | JSONB containment and JSONB path / field access        |


Every column must also be registered with `eql_v2.add_column(...)` — that alone gives the column storage and decryption, but none of the operators below will produce results until at least one search index is added for the operation you need.

---

## SQL operator support

Each row lists an operator that EQL either implements natively on `eql_v2_encrypted` or that CipherStash Proxy rewrites into an EQL equivalent. A ✅ means the operator is supported on a column when that index is configured. A ❌ means the index does not support the operator (the database will either error, return no rows, or fall back to a scan that decrypts nothing useful).

| SQL operator                      | Meaning                         | `unique` | `ore` | `match` | `ste_vec` |
| --------------------------------- | ------------------------------- | :------: | :---: | :-----: | :-------: |
| `=`                               | Equality                        |    ✅    |  ✅   |   ❌    |    ❌     |
| `<>` / `!=`                       | Inequality                      |    ✅    |  ✅   |   ❌    |    ❌     |
| `<`                               | Less than                       |    ❌    |  ✅   |   ❌    |    ❌     |
| `<=`                              | Less than or equal              |    ❌    |  ✅   |   ❌    |    ❌     |
| `>`                               | Greater than                    |    ❌    |  ✅   |   ❌    |    ❌     |
| `>=`                              | Greater than or equal           |    ❌    |  ✅   |   ❌    |    ❌     |
| `LIKE` (`~~`)                     | Case-sensitive pattern match    |    ❌    |  ❌   |   ✅    |    ❌     |
| `NOT LIKE` (`!~~`)                | Negated case-sensitive match    |    ❌    |  ❌   |   ✅    |    ❌     |
| `ILIKE` (`~~*`)                   | Case-insensitive pattern match  |    ❌    |  ❌   |   ✅\*  |    ❌     |
| `NOT ILIKE` (`!~~*`)              | Negated case-insensitive match  |    ❌    |  ❌   |   ✅\*  |    ❌     |
| `@>`                              | JSONB contains                  |    ❌    |  ❌   |   ❌    |    ✅     |
| `<@`                              | JSONB is contained by           |    ❌    |  ❌   |   ❌    |    ✅     |
| `->` (text, int, encrypted)       | JSONB field / element access    |    ❌    |  ❌   |   ❌    |    ✅     |
| `->>`                             | JSONB field as text (ciphertext) |   ❌    |  ❌   |   ❌    |    ✅     |
| `IS NULL` / `IS NOT NULL`         | Null check                      |    ✅    |  ✅   |   ✅    |    ✅     |

\* Case-insensitivity for `ILIKE` / `NOT ILIKE` is only effective when the `match` index is configured with a case-normalising token filter (e.g. `{"token_filters": [{"kind": "downcase"}]}`). Without it, `ILIKE` behaves identically to `LIKE` on the encrypted terms.

Notes:

- Binary operators have overloads that accept `jsonb` literals on either side; CipherStash Proxy typically rewrites those to `::eql_v2_encrypted` casts so the encrypted operator is selected.
- `=` and `<>` on a column that has **only** a `ste_vec` index will not match anything useful — the underlying comparison requires `hm`, `b3`, or `ob` terms. Configure `unique` (or `ore`) alongside `ste_vec` if you need equality on the outer value.
- JSONB path operators (`->`, `->>`) return an `eql_v2_encrypted` value (or ciphertext for `->>`). The value they return is itself searchable only if the parent `ste_vec` index covers that path.

### Unsupported JSONB operators

The following PostgreSQL JSONB operators are **not** implemented for `eql_v2_encrypted`.

`?`, `?&`, `?|`, `@?`, `@@`

Use the equivalent [`jsonb_path_query`](#supported-jsonb-functions) or containment patterns instead.

---

## SQL syntax / feature support

This matrix covers higher-level SQL constructs rather than individual operators. As above, ✅ requires the listed index to be configured on the column; ❌ means the construct cannot be used against that column (without first decrypting via CipherStash Proxy or Protect.js).

| SQL feature                        | Notes      | `unique` | `ore` | `match` | `ste_vec` |
| ---------------------------------- | ------------------------------------- | :------: | :---: | :-----: | :-------: |
| `WHERE col = …` / `<>`             |                                   |    ✅    |  ✅   |   ❌    |    ❌     |
| `WHERE col <` / `<=` / `>` / `>=`  |                                  |    ❌    |  ✅   |   ❌    |    ❌     |
| `WHERE col BETWEEN … AND …`        | desugars to `>=` and `<=`     |    ❌    |  ✅   |   ❌    |    ❌     |
| `WHERE col LIKE …` / `NOT LIKE`    |                           |    ❌    |  ❌   |   ✅    |    ❌     |
| `WHERE col ILIKE …` / `NOT ILIKE`  | requires `downcase` filter      |    ❌    |  ❌   |   ✅    |    ❌     |
| `WHERE col IN (…)`                 |               |    ✅    |  ✅   |   ❌    |    ❌     |
| `WHERE col @> …` / `<@ …`          |                              |    ❌    |  ❌   |   ❌    |    ✅     |
| `ORDER BY col`                     |                                  |    ❌    |  ✅   |   ❌    |    ❌     |
| `GROUP BY col`                     | equality is insufficient - currently works with `unique` or `ste_vec`-indexed `jsonb` `Bool`, `Null`, `{ .. }` or `[ .. ]` terms                   |    ✅    |  ❌   |   ❌    |    ❌     |
| `DISTINCT` / `DISTINCT ON (col)`   | `unique` or `ore`                                  |    ✅    |  ✅   |   ❌    |    ❌     |
| `HAVING`          |   see operator matrix   |  |
| `MIN(col)` / `MAX(col)`            |                                  |    ❌    |  ✅   |   ❌    |    ❌     |
| `COUNT(col)` / `COUNT(DISTINCT col)` | `ore` or `unique` for `DISTINCT`; none for plain `COUNT(col)` |    ✅    |  ✅   |   ✅    |    ✅     |
| `JOIN … ON lhs.col = rhs.col`      | same index and keyset on both sides      |    ✅    |  ✅   |   ❌    |    ❌     |
| `JOIN … ON lhs.col < rhs.col` etc. | same index and keyset on both sides     |    ❌    |  ✅   |   ❌    |    ❌     |
| `UNION` / `EXCEPT` / `INTERSECT` (set operations) |  |    ✅    |  ✅   |   ❌    |    ❌     |
| `IS NULL` / `IS NOT NULL`          | works because `NULL` values are not encrypted              |        |     |       |         |
| Window functions over encrypted columns | works identically as the same clause in "normal" SQL (e.g. `ORDER BY` needs `ore`) | see rows above |

Notes:

- **Cross-column / cross-table comparisons** (joins, `IN (subquery)`, `UNION` dedup, etc.) require both sides to have been encrypted with the *same* keyset and the matching search index. Encrypted values from different `ste_vec` prefixes are deliberately incomparable.
- **`GROUP BY`** on encrypted columns relies on an operator class which currently only supports encrypted values with a `unique` index term. This is a surprising limitation because it would be natural to expect `ore` index terms to also work. This limitation will be lifted in the future. See [Database Indexes](./database-indexes.md#group-by) for performance considerations.
- **`ORDER BY`** without an `ore` index will still *run* (the EQL `compare` function has a deterministic literal fallback to avoid btree errors), but the resulting order is not meaningful. Configure `ore` whenever ordering matters.
- **Aggregates beyond `MIN`/`MAX`** (e.g. `SUM`, `AVG`) are not supported on encrypted values — decrypt and perform those aggregate operations on the client-side instead.
- **Parameter binding**: CipherStash Proxy rewrites bound parameters in `WHERE`, `JOIN`, and `RETURNING` clauses with `::JSONB::eql_v2_encrypted` casts so that the encrypted operator and any B-tree / GIN indexes are selected. Writing those casts yourself is only required when bypassing the proxy.

### Supported JSONB functions

When the `ste_vec` index is configured, CipherStash Proxy rewrites the following standard PostgreSQL functions to their `eql_v2` equivalents so they can operate on encrypted JSON:

| Function                        | Index required | Notes                                                  |
| ------------------------------- | -------------- | ------------------------------------------------------ |
| `jsonb_path_query`              | `ste_vec`      | Returns `eql_v2_encrypted`.                            |
| `jsonb_path_query_first`        | `ste_vec`      | Returns `eql_v2_encrypted`.                            |
| `jsonb_path_exists`             | `ste_vec`      | Returns `boolean`.                                     |
| `jsonb_array_length`            | `ste_vec`      | Returns `integer`.                                     |
| `jsonb_array_elements`          | `ste_vec`      | Set-returning; yields `eql_v2_encrypted`.              |
| `jsonb_array_elements_text`     | `ste_vec`      | Set-returning; yields `eql_v2_encrypted`.              |
| `jsonb_array`                   | `ste_vec`      | EQL helper that exposes the `sv` array for GIN indexing. |
| `jsonb_contains` / `jsonb_contained_by` | `ste_vec` | GIN-indexable containment. See [Database Indexes](./database-indexes.md#gin-indexes-for-jsonb-containment). |

`COUNT`, `MIN`, and `MAX` are also rewritten to their `eql_v2` aggregate equivalents where applicable. `MIN`/`MAX` require `ore`. `COUNT` has no encrypted index requirement, but `COUNT(DISTINCT <col>)` requires a `unique` or `ore` index term on the column.

---

## See also

- [EQL Functions Reference](./eql-functions.md) — full list of functions and operators.
- [EQL index configuration for CipherStash Proxy](./index-config.md) — how to add / modify / remove search indexes.
- [Database Indexes for Encrypted Columns](./database-indexes.md) — B-tree and GIN index guidance for PostgreSQL.
- [EQL with JSON and JSONB](./json-support.md) — end-to-end examples of `ste_vec` usage.

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20sql-support.md)
