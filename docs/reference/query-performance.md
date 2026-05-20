# Writing fast queries against EQL columns

This guide is about getting query performance out of EQL-encrypted columns that's competitive with plain-PostgreSQL workloads. It explains the two practical ingredients — **functional indexes** and **operator inlining** — and shows how to combine them across the common query shapes (`=`, `<` / `>`, `ORDER BY`, `GROUP BY`, `LIKE`, JSONB containment, ste_vec field-level access).

If you remember nothing else: **use functional indexes**, and **let bare-form predicates do the work** wherever possible. Reach for the extractor form when (a) you need an index for a query shape that the natural form can't drive (`ORDER BY` on the encrypted column), or (b) your column's term configuration falls outside the canonical Block ORE / HMAC pair.

---

## 1. Why functional indexes

The two recipes for putting a PostgreSQL index on an `eql_v2_encrypted` column are:

| Recipe | Shape | Example |
| --- | --- | --- |
| **Functional** *(canonical)* | Index over a deterministic extractor that yields a small per-row term | `CREATE INDEX … ON users (eql_v2.hmac_256(email_encrypted));` |
| **Operator class** *(legacy)* | Index over the whole `eql_v2_encrypted` column via a custom btree opclass | `CREATE INDEX … ON users (email_encrypted eql_v2.encrypted_operator_class);` |

The operator-class recipe ships with EQL and still works, but functional indexes are the recommended path for new schemas because:

1. **Small leaves.** A functional index on `eql_v2.hmac_256(col)` stores only the 32-byte HMAC per row. The operator-class index stores the entire encrypted payload (often kilobytes), inflating the btree and risking the `index row size N exceeds btree version 4 maximum 2704` error on full-payload columns.
2. **No superuser required.** Functional indexes work on Supabase and managed PostgreSQL installations that don't ship the `eql_v2.encrypted_operator_class`.
3. **The planner can match them structurally.** EQL's operators on `eql_v2_encrypted` (`=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `ILIKE`, `@>`, `<@`) are now inlinable SQL functions whose bodies reduce to a comparison on the extracted term. The planner inlines the operator at planning time, rewrites the predicate into the same expression as the index, and uses the index — without any query rewriting on the caller's side.

See [database-indexes.md](./database-indexes.md) for the full enumeration of functional-index recipes. The short list:

```sql
-- Equality
CREATE INDEX … USING hash (eql_v2.hmac_256(col));

-- Range / ORDER BY (Block ORE)
CREATE INDEX … ON tbl (eql_v2.ore_block_u64_8_256(col));
-- DEFAULT opclass is eql_v2.ore_block_u64_8_256_operator_class; no annotation needed.

-- LIKE / ILIKE
CREATE INDEX … USING GIN (eql_v2.bloom_filter(col));

-- JSONB containment / ste_vec
CREATE INDEX … USING GIN (eql_v2.jsonb_array(col));

-- Field-level equality from an ste_vec document
-- Per-selector (one index per hot path):
CREATE INDEX … USING hash (eql_v2.hmac_256(col, '<selector-hash>'));
-- All-selector (one index covers every sv element with an hm term):
CREATE INDEX … USING GIN (eql_v2.hmac_256_terms(col));
```

Always run `ANALYZE` after creating an index. PostgreSQL's planner uses table statistics to decide whether an index lookup beats a sequential scan — without stats, it'll often choose the seq scan even when an index would be cheaper.

---

## 2. Operator inlining: the mechanics

PostgreSQL inlines a SQL function when **all** of these conditions hold:

- `LANGUAGE sql` (not `plpgsql`).
- The body is a single `SELECT` returning the same type the function declares.
- No `SET` clause on the function definition (in particular, no `SET search_path = …`).
- Declared volatility (`IMMUTABLE` / `STABLE` / `VOLATILE`) is at least as restrictive as anything the body calls into.

When the planner inlines an operator, it replaces the operator's function call with the body. So `WHERE col = $1` — where `=` is `eql_v2."="(eql_v2_encrypted, eql_v2_encrypted)` — becomes `WHERE eql_v2.hmac_256(col) = eql_v2.hmac_256($1)` during planning. The planner then matches that rewritten expression against indexes.

The matching is **syntactic on the expression tree**: the function OID and argument shape on the predicate's LHS must equal the function OID and argument shape on the index's defining expression. The planner does not reason about semantic equivalence — `eql_v2.hmac_256(col)` and `col` are different trees, so an index on the former can't satisfy a predicate that mentions only the latter (without inlining first).

This is why pinning `search_path` on an EQL operator function via `ALTER FUNCTION … SET search_path = …` would kill inlining and silently revert bare-form queries to sequential scans. EQL's build pins `search_path` on every `eql_v2.*` function for the Supabase `function_search_path_mutable` lint, with an explicit allowlist for the operator wrappers that need to stay inlinable. The current allowlist covers `=`, `<>`, `<`, `<=`, `>`, `>=`, `~~`, `~~*`, `@>`, `<@` and the helpers they delegate into.

### How to verify inlining is working

`EXPLAIN` is the canonical check. With inlining engaged, the plan's `Index Cond:` or `Filter:` line shows the **rewritten** expression — i.e. the extractor form — not the operator you wrote. For example:

```
Index Scan using users_email_hmac_idx on users
  Index Cond: ((eql_v2.hmac_256(email_encrypted))::text = (eql_v2.hmac_256('...'::eql_v2_encrypted))::text)
```

If you see the *operator* in the plan rather than the *extractor* (`Filter: (col < '...'::eql_v2_encrypted)`), inlining isn't happening. Common causes:

- The function has a `SET` clause (`\df+ eql_v2.…` will show `proconfig`).
- The function is `plpgsql` (look at `prolang`).
- An inner helper that the operator body calls is `VOLATILE` or has a `SET` clause — inlining is transitive, so an inlinable wrapper around a non-inlinable helper still won't inline.
- The planner thinks a different plan is cheaper (e.g. an `ORDER BY pk LIMIT n` driving the primary-key index instead of your functional index). Force the question with `SET enable_seqscan = off` or stronger selectivity to see if the planner *can* use the index.

---

## 3. Natural form vs extractor form

The operators ship with three overloads each — `(encrypted, encrypted)`, `(encrypted, jsonb)`, `(jsonb, encrypted)` — so all three predicate shapes inline equivalently. After inlining, `col = $1`, `col = '{…}'::jsonb` and `'{…}'::jsonb = col` all reduce to the same canonical expression. There's no perf penalty for any of those bindings; pick whichever fits your client.

**Natural form.** Write the query the way you would for an unencrypted column. The operator inlines, the canonical extractor appears in the predicate, and the functional index matches structurally.

```sql
SELECT * FROM users WHERE email_encrypted = $1;
SELECT * FROM events WHERE encrypted_at < $1;
SELECT * FROM products WHERE encrypted_name LIKE $1;
```

**Extractor form.** Write the extractor explicitly on both sides. This is the canonical pattern for query shapes where the natural form's operator isn't inlinable, or where you want to control which term type drives the comparison (e.g. on a column with multiple ORE encodings).

```sql
SELECT * FROM users
  WHERE eql_v2.hmac_256(email_encrypted) = eql_v2.hmac_256($1::jsonb);
```

**Hybrid form.** Natural form in the `WHERE` clause, extractor form in `ORDER BY`. This is the pragmatic shape for ordered range queries because it lets the index satisfy both the predicate filter *and* the sort key (see §4).

```sql
SELECT * FROM events
  WHERE encrypted_at < $1
  ORDER BY eql_v2.ore_block_u64_8_256(encrypted_at)
  LIMIT 100;
```

### When to use which

For columns configured with the canonical term for the query shape (HMAC for equality, Block ORE for ranges, bloom filter for `LIKE`, ste_vec for containment), the natural form is the right default. It reads cleanly, ORMs and PostgREST emit it without coaxing, and the planner does the rewriting transparently.

Reach for the extractor form when:

- **The column doesn't carry the canonical term for the natural-form operator.** E.g. a column configured with `ore_cllw_u64_8` instead of `ore_block_u64_8_256` will raise from the natural-form `<` after the range-operator inlining — write `WHERE eql_v2.ore_cllw_u64_8(col) < eql_v2.ore_cllw_u64_8($1::jsonb)` instead.
- **You want a sort key that the index can satisfy without a Sort node** (see §4).
- **You want a per-field index on an ste_vec document** — the field-level recipes (`eql_v2.hmac_256(col, '<selector>')` and `eql_v2.hmac_256_terms(col)`) only work in extractor form because the selector isn't part of any natural-form SQL operator.
- **You're debugging a plan and want to bypass the inlining question entirely.** Plans with the extractor written out leave nothing to inference; the predicate matches the index by direct text identity.

---

## 4. `ORDER BY`: the sort-key trap

Functional indexes can satisfy `ORDER BY` only when the sort key **syntactically matches** the index expression. The planner doesn't reason about monotonicity, so an index over `eql_v2.ore_block_u64_8_256(col)` will not satisfy `ORDER BY col` directly even though ORE is order-preserving.

Three query shapes to compare:

```sql
-- (a) Natural form
SELECT * FROM events
  WHERE encrypted_at < $1
  ORDER BY encrypted_at
  LIMIT 10;

-- (b) Hybrid: natural WHERE, extractor ORDER BY
SELECT * FROM events
  WHERE encrypted_at < $1
  ORDER BY eql_v2.ore_block_u64_8_256(encrypted_at)
  LIMIT 10;

-- (c) Fully extractor
SELECT * FROM events
  WHERE eql_v2.ore_block_u64_8_256(encrypted_at) < eql_v2.ore_block_u64_8_256($1::jsonb)
  ORDER BY eql_v2.ore_block_u64_8_256(encrypted_at)
  LIMIT 10;
```

With a functional Block ORE index in place (`CREATE INDEX … ON events (eql_v2.ore_block_u64_8_256(encrypted_at))`), the plans differ:

- **(a) Natural** — `Bitmap Index Scan` via the inlined `<`, plus a `Sort` (Top-N because of the `LIMIT`) by `encrypted_at`. The sort key doesn't match the index expression, so the Sort can't be eliminated. Each comparison inside the Sort step uses the inlined ORE-term path — but you still do one per post-WHERE row.
- **(b) Hybrid** — `Index Scan` over the functional ORE index, walking it in order. No `Sort` node. The `WHERE` is satisfied by `Index Cond` and rows stream out of the index already in the desired order.
- **(c) Fully extractor** — same plan as (b). The natural-form `<` inlines into the same predicate shape, so the planner can't tell (b) and (c) apart after planning.

Empirically on the bench tables, with `WHERE value < $1 … LIMIT 10` (selectivity around 0.5):

| Rows | (a) natural | (b) hybrid | (c) fully extractor |
| --- | --- | --- | --- |
| 100k | ~880 ms | <2 ms | <2 ms |
| 1M   | ~8.8 s  | ~1 ms  | ~1 ms  |

The natural-form Top-N scales linearly with the number of rows passing `WHERE` — at 1M with our selectivity that's ~500k inlined ORE-term comparisons in the Sort step, which is several seconds even when each comparison is cheap. **For ordered range queries on encrypted columns, write the `ORDER BY` in extractor form.** It's the same plan as (c) post-inlining; only the source-level syntax differs.

The bench suite (`cipherstash/benches`) keeps only the hybrid scenario for this reason: (a) is the trap this section warns about, and (c) plans identically to (b) — measuring all three only inflates the run cost without surfacing a new behaviour.

### 4.1 Field-level `ORDER BY` (ste_vec elements)

Same trap, same fix at the sv-element level. With a Standard-mode `ste_vec` index the orderable term on each sv element is `oc` (ORE CLLW), and the canonical recipe is a functional btree on the *extractor* applied to a selector:

```sql
-- Build a functional ORE-CLLW index on the orderable sv element
CREATE INDEX users_age_oc_idx
  ON users (eql_v2.ore_cllw(data_encrypted -> '<age-selector>'::text));
ANALYZE users;
```

(The `eql_v2.ore_cllw_ops` opclass is `DEFAULT FOR TYPE eql_v2.ore_cllw`, so no explicit opclass annotation is needed.)

Three query shapes at the field level:

```sql
-- (a) Bare form — Seq Scan + Top-N sort, linear in table size
SELECT id FROM users
  ORDER BY (data_encrypted -> '<age-selector>'::text)
  LIMIT 10;

-- (b) Extractor form — Index Scan, walks the btree in order
SELECT id FROM users
  ORDER BY eql_v2.ore_cllw(data_encrypted -> '<age-selector>'::text)
  LIMIT 10;
```

The bare form (a) doesn't engage the index even when it's present. `eql_v2."->"` is `plpgsql` (it walks the `sv` array picking the matching selector), and the planner can't see through a plpgsql function call to match the sort key against the indexed expression. The plan is always Seq Scan + Top-N — at 1M rows that's ~20 s versus ~1 ms with the extractor form, which is the entire point of the index.

For the same reason the JSON bench suite (`cipherstash/benches`, `benches/json.rs`) does not include a `field_order/bare` scenario. The functional form is the documented recipe; measuring the bare form just demonstrates the cost of *not* following it, which is fixture noise rather than a meaningful EQL performance signal.

**For ordered field-level queries on encrypted JSON, write `ORDER BY` against the extractor.** This is the only field-level shape that scales.

---

## 5. Equality and `GROUP BY` / `DISTINCT`

Equality is the simplest case: `WHERE col = $1` on a column with a `unique` search index (i.e. carrying an `hm` HMAC term) and a functional hash index on `eql_v2.hmac_256(col)` will engage the index transparently.

```sql
SELECT eql_v2.add_search_config('users', 'email_encrypted', 'unique', 'text');
-- proxy / client encrypts data through this column …
CREATE INDEX users_email_hmac_idx ON users USING hash (eql_v2.hmac_256(email_encrypted));
ANALYZE users;

SELECT * FROM users WHERE email_encrypted = $1;
-- Index Scan using users_email_hmac_idx
--   Index Cond: ((eql_v2.hmac_256(email_encrypted))::text = (eql_v2.hmac_256(...))::text)
```

**`GROUP BY` is a different beast — and the extractor form is the only recipe that scales.** Use it. Even at moderate row counts the natural form's plan choice degrades pathologically; the extractor form sidesteps the trap entirely and works the same way on every Postgres deployment, including Supabase and managed services where you can't tune `work_mem`.

The canonical recipe for `GROUP BY` (and `DISTINCT`, and `IN (subquery)`, and hash joins) on an encrypted column:

```sql
SELECT eql_v2.hmac_256(email_encrypted), count(*)
  FROM users
  GROUP BY eql_v2.hmac_256(email_encrypted);
```

Why this is the right shape:

- **The group key is small.** `eql_v2.hmac_256(col)` returns a 32-byte HMAC. At 1M rows the in-memory hash table is well under 100 MB, which fits inside the default `work_mem = 4MB` per partition many times over — so the planner picks `HashAggregate` reliably, without any deployment-wide tuning.
- **The extractor inlines.** `eql_v2.hmac_256(val)` is a single-statement SQL function whose body is essentially `(val).data ->> 'hm'`. The planner folds it into the aggregation, so each row pays a single jsonb lookup. No plpgsql function-call overhead per row, no opaque dispatch.
- **It matches a functional index.** If you have a `unique` search config on the column and a `CREATE INDEX … USING hash (eql_v2.hmac_256(col))` — the same index you'd build for fast equality — `IN (subquery)` and hash joins against `eql_v2.hmac_256(col)` can use it directly. `GROUP BY` itself doesn't use the index (hash aggregation is in-memory, not index-driven), but everything else that hashes against the same key does.

### Why the natural form doesn't scale

The natural form looks fine on paper:

```sql
-- Avoid. Falls into the work_mem / planner trap below.
SELECT email_encrypted, count(*)
  FROM users
  GROUP BY email_encrypted;
```

The trap is in the planner's cost model. PostgreSQL has two aggregation strategies — `HashAggregate` (in-memory hash table keyed by the GROUP BY expression) and `GroupAggregate` (sort the input, then collapse adjacent equal rows). The planner picks between them on cost, and the cost model is *very* sensitive to the size of the group key — because the hash table for HashAggregate has to fit in `work_mem`.

On an encrypted column, the natural-form key is the entire `eql_v2_encrypted` payload — typically 1-2 KB per row. At 100k rows the planner estimates a 100-200 MB hash table, which exceeds the default `work_mem = 4MB` by two orders of magnitude. The planner refuses HashAggregate and falls back to GroupAggregate. GroupAggregate sorts the input, which means an O(N log N) pass over kilobyte-sized rows — the per-comparison cost is small (the `=` operator is inlinable SQL post-2.3, so each comparison reduces to a 32-byte HMAC comparison), but the sort still dominates wall-clock time and spills to disk past `work_mem`.

Measured at 100k rows on the bench tables:

| Query form | Plan | Time |
| --- | --- | --- |
| `GROUP BY col` (natural, default 4 MB work_mem) | GroupAggregate + Sort (disk spill) | ~29 s |
| `GROUP BY col` (natural, work_mem bumped to 256 MB) | HashAggregate | ~780 ms |
| `GROUP BY eql_v2.hmac_256(col)` (extractor) | HashAggregate | ~80 ms |

Bumping `work_mem` recovers the natural form from "minutes" to "sub-second" by changing the planner's choice — a 37× improvement just from one setting. The extractor form is another ~10× on top of that and doesn't depend on a deployment-wide knob. At 1M rows the natural form's GroupAggregate sort takes around 4 minutes even with `work_mem = 512MB`; the extractor form stays sub-second.

The takeaway: write the extractor form. If you have a query you can't rewrite (an ORM that's GROUP BY-ing the raw column, a third-party report tool), bumping `work_mem` to a size that fits the estimated hash table is the rescue knob — but don't make that the design.

### `DISTINCT` and ste_vec field-level

`DISTINCT col` follows the same rules — `SELECT DISTINCT eql_v2.hmac_256(col) FROM tbl` is the recipe. If you only need set membership and not the original encrypted value back, the extractor form is what you want regardless of table size.

For ste_vec documents, field-level `GROUP BY` works analogously:

```sql
SELECT eql_v2.hmac_256(data_encrypted, '<selector-hash>'), count(*)
  FROM users
  GROUP BY eql_v2.hmac_256(data_encrypted, '<selector-hash>');
```

If multiple selectors are aggregated hot, prefer the per-selector hash index over each. If many selectors are needed and a single index is preferable, build a GIN index over `eql_v2.hmac_256_terms(col)` and use containment queries (`@>`) — though that path is for filtering rather than `GROUP BY`.

---

## 6. `LIKE` / `ILIKE` (bloom filter)

The bloom filter index handles substring and token-style pattern matching. The natural form inlines through `~~` (the underlying operator behind `LIKE`):

```sql
SELECT eql_v2.add_search_config('users', 'name_encrypted', 'match', 'text');
-- repopulate column through the proxy …
CREATE INDEX users_name_bloom_idx
  ON users USING GIN (eql_v2.bloom_filter(name_encrypted));
ANALYZE users;

SELECT * FROM users WHERE name_encrypted LIKE $1;
-- Bitmap Index Scan on users_name_bloom_idx
--   Index Cond: (eql_v2.bloom_filter(name_encrypted) @> eql_v2.bloom_filter('...'::eql_v2_encrypted))
```

Bloom filters return a probabilistic superset — the planner reads "this row *might* match" from the bitmap, and PostgreSQL re-checks the original predicate on each candidate row. The recheck step uses the inlined bloom-filter containment, not a string match. The bloom filter is configured at column-config time (`{"token_filters": [{"kind": "ngram", "token_length": …}]}` etc.); see [index-config.md](./index-config.md).

Case-insensitivity (`ILIKE`) is only effective when the match index is configured with a `downcase` token filter. Without it, `ILIKE` behaves identically to `LIKE` because the bloom filter has no notion of case post-encryption.

---

## 7. JSONB containment, ste_vec, and field-level extraction

For encrypted JSONB documents (`ste_vec` indexes), the canonical pattern is GIN over `eql_v2.jsonb_array(col)`:

```sql
SELECT eql_v2.add_search_config('orders', 'data_encrypted', 'ste_vec', 'jsonb');
CREATE INDEX orders_data_gin_idx
  ON orders USING GIN (eql_v2.jsonb_array(data_encrypted));
ANALYZE orders;

-- Document-level containment
SELECT * FROM orders WHERE data_encrypted @> $1::jsonb;
-- Bitmap Index Scan on orders_data_gin_idx
--   Index Cond: (eql_v2.jsonb_array(data_encrypted) @> eql_v2.jsonb_array('...'::eql_v2_encrypted))
```

For field-level lookups (`data_encrypted->'email' = $1`), use the per-selector hash recipe for hot paths and the all-selector GIN recipe for everything else. Both are described in §1; both require the extractor form because the selector isn't part of any native SQL operator.

`eql_v2.jsonb_path_query`, `_first`, and `_exists` are inlinable SQL functions that walk the `sv` array filtering by selector. Use them when you need the full sub-payload back; use `eql_v2.hmac_256(col, '<selector>')` when you only need an equality check on the selector's value.

---

## 8. A short list of common pitfalls

- **Index created before data was populated through the proxy.** EQL search-config + functional index is a two-phase process: configure the index, repopulate the column through the proxy so the encrypted terms land in the payload, *then* `CREATE INDEX … ANALYZE`. The other order silently leaves the index without the values it needs.
- **`ANALYZE` not run.** PostgreSQL's planner uses table statistics. Small tables get sequential scans even when an index would be cheaper, but on larger tables a missing `ANALYZE` can also mask an index that *should* be picked.
- **Stale opclass index alongside a functional index.** If you migrate an old schema from `eql_v2.encrypted_operator_class` to functional indexes, drop the old opclass index. Two btree indexes on the same column compete for cache and double the maintenance cost on writes.
- **Pinning `search_path` on an EQL function.** Adding `SET search_path = …` to an `eql_v2.*` function disables inlining and reverts queries through that function to sequential scans. The EQL build allowlists operator wrappers that must stay inlinable; if you're customising the install, preserve that allowlist.
- **`ORDER BY` on the natural form expecting an `Index Scan`.** The Sort node is required (§4). If you need it gone, switch the `ORDER BY` to extractor form.
- **`=` / `<>` returning zero rows silently on a column without `hm`.** Equality requires the column to carry an `hm` HMAC term. Without it, `eql_v2.hmac_256(col)` returns NULL and the operator comparison evaluates to NULL — false in a WHERE context. `eql_v2.hash_encrypted` (the discriminator behind `GROUP BY` / `DISTINCT` / hash joins) doesn't raise on missing `hm` either — it falls back to hashing the encrypted payload bytes, which keeps the aggregate's hash table from degrading to O(N²) on a single NULL bucket but no longer gives you a runtime smoke signal. Audit at config time instead: `SELECT eql_v2.has_hmac_256(col) FROM tbl LIMIT 1`.
- **`GROUP BY` on the raw encrypted column at scale.** §5 details the trap, but it's worth repeating in pitfalls form: `GROUP BY col` on an `eql_v2_encrypted` column past ~10k rows falls into GroupAggregate-with-disk-spill territory because the natural-form key is 1-2 KB per row and the hash table can't fit in `work_mem`. Write `GROUP BY eql_v2.hmac_256(col)` instead. The extractor form is the only `GROUP BY` recipe that holds up at production scale on default Postgres settings.
- **Range queries (`<`, `<=`, `>`, `>=`) on columns with only `ore_cllw_*` or OPE terms.** The range operators are Block ORE only post-2.3 (see [U-005 in v2.3.md](../upgrading/v2.3.md#u-005-range-operators-are-block-ore-only)). Migrate the column to `ore` or switch the query to the extractor form for the relevant CLLW / OPE encoding.

---

## 9. Diagnosing performance with `EXPLAIN`

The first move on any slow EQL query is `EXPLAIN (COSTS OFF)`. Look for:

- **`Index Scan using <your-index>`** — the planner is using the functional index. ✓
- **`Bitmap Index Scan on <your-index>`** — same, for set-style predicates (`@>`, `LIKE`). ✓
- **`Index Cond:`** — the inlined predicate matched the index expression. Should reference the extractor (`eql_v2.hmac_256(…)`, `eql_v2.ore_block_u64_8_256(…)`, …), not the raw operator.
- **`Seq Scan`** — sequential scan, no index used. Investigate.
- **`Filter:`** showing the raw operator (`col < '…'::eql_v2_encrypted`) — inlining didn't happen. See §2's troubleshooting list.
- **`Sort` node above an Index Scan** — natural-form `ORDER BY`; expected for that shape. Switch to hybrid form (§4) to eliminate it.

Once a plan looks right, repeat with `EXPLAIN ANALYZE` to measure actual timings. The bottleneck on a working plan is usually the per-row evaluation cost (extractor → comparison → recheck), so a clean plan with bad timing usually means a missing inlining step somewhere in the chain — re-run §2's checks on the helper functions.

---

## See also

- [Database Indexes for Encrypted Columns](./database-indexes.md) — index recipes and creation order.
- [SQL support matrix](./sql-support.md) — which operators work against which search-config kinds.
- [EQL index configuration](./index-config.md) — `add_search_config` reference.
- [Upgrading to v2.3](../upgrading/v2.3.md) — the operator-inlining contract that this guide depends on (U-002, U-005).
