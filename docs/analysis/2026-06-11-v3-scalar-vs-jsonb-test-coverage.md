# EQL v3 Test Coverage: Scalar Domains vs JSONB (SteVec)

**Date:** 2026-06-11
**Scope:** Comparison of behaviour-test coverage between the generated scalar encrypted-domain families (`eql_v3.int4`, `int2`, `int8`, `date`, `timestamptz`, `text`) and the hand-written encrypted-JSONB / SteVec document surface (`eql_v3.json`).
**Question driving the analysis:** Does v3 have a *complete behaviour suite*, and is coverage uniform across surfaces?

---

## TL;DR

- **The scalar matrix is the gold standard.** Ordered scalar types are tested by a fully templated matrix (`tests/sqlx/src/matrix.rs`) emitting **211 ordered-suite tests per ordered type**; equality-only types emit **51 tests per eq-only type**. It is positive-behaviour dense: equality, ordering, aggregates, `ORDER BY`, `COUNT`, index cost-preference, planner metadata, NULL propagation, blocker paths, and crypto-integrity invariants.
- **JSONB is the outlier, not the rule.** The SteVec surface is hand-written (`tests/sqlx/tests/v3_jsonb_tests.rs` + `v3_jsonb_operator_surface_tests.rs`, **72 snapshot tests total: 67 main + 5 operator-surface**). It has strong *blocker* and *operator-surface* coverage but lacks a scalar-style positive behaviour matrix for aggregates, `ORDER BY`, `COUNT`, and cost-preference.
- **The jsonb analysis does NOT transfer to the scalars.** If anything the relationship is inverted: the scalars are *more* complete than jsonb.
- **Two real gaps for "complete v3 behaviour suite":** (1) bring jsonb to parity (or give it a parallel completeness checklist, since it is a genuinely different document regime); (2) add a dedicated positive composition matrix for realistic multi-clause queries across v3 surfaces.

---

## 1. The two test regimes

| | Scalar domains | JSONB (SteVec) |
|---|---|---|
| **Surface** | Generated `eql_v3.<T>` / `_eq` / `_ord` / `_ord_ore` domains | Hand-written `eql_v3.json` domain + `ste_vec_entry` / `ste_vec_query` |
| **Source of tests** | Templated macro `scalar_matrix!` → `scalars::<T>::*` | Hand-written `v3_jsonb_tests.rs` + `v3_jsonb_operator_surface_tests.rs` |
| **Macro location** | `tests/sqlx/src/matrix.rs` (2763 lines) | n/a (hand-written) |
| **Snapshot** | `tests/sqlx/snapshots/matrix_tests.txt` (211) + `matrix_tests_eq_only.txt` (51) | `tests/sqlx/snapshots/v3_jsonb_tests.txt` (72 = 67 main + 5 operator-surface) |
| **Tests / type** | 211 per ordered type; 51 per eq-only type; `text_match` is outside this matrix | 72 (single document surface) |
| **Fixture** | Generated via cipherstash-client + `FixtureSpec`, gitignored (`eql_scalars::*_VALUES`, `temporal_values!`) | Generated via hand-written `FixtureSpec<serde_json::Value>` in `generate_all_fixtures`; gitignored `tests/sqlx/fixtures/v3_ste_vec.sql` |
| **Catalog driven?** | Yes — `crates/eql-scalars::CATALOG` | No scalar catalog row — bespoke document `FixtureSpec` |

---

## 2. Behaviour coverage matrix

Legend: ✅ covered · ⚠️ partial · ❌ absent

| Behaviour / query pattern | JSONB (SteVec) | Scalar matrix |
|---|---|---|
| Equality `=` `<>` | ✅ hm + oc correctness | ✅ 3 pivots × 3 arg-shapes, correctness + cross-shape |
| Ordering `<` `<=` `>` `>=` | ✅ ORE-CLLW ladder (total order) | ✅ same density per Ord / OrdOre domain |
| Containment `@>` `<@` | ✅ hm-only / oc-only / mixed needles + 3 negatives | ✅ asserted **blocked** on scalar domains (not a scalar capability) |
| Field extraction `->` `->>` | ✅ text + int index, NULL propagation | ✅ asserted **blocked** (path ops not valid on scalars) |
| Path query fns (`jsonb_path_query`/`_first`/`_exists`) | ✅ match/miss/first/exists | n/a |
| Array ops (`array_length`/`elements`/`_text`) | ✅ incl. non-array-raises | n/a |
| `min` / `max` aggregate | ❌ **none** | ✅ + GROUP BY + NULL variants (all-null / empty / mixed) + parallel-safe; typecheck asserts non-ord variants reject `eql_v3.min/max` |
| `ORDER BY` ASC/DESC/NULLS | ⚠️ no scalar-style behaviour matrix; ORE-extracted `ORDER BY` index engagement exists | ✅ ASC/DESC with and without WHERE, plus ASC/DESC NULLS FIRST/LAST, + `ORDER BY ... USING` rejection of non-default ops |
| `COUNT` (`COUNT(value)`, path cast, `DISTINCT extractor`) | ⚠️ no scalar-parity count behaviour suite; `count(*)` and `count(DISTINCT ...)` appear in fixture/oracle assertions | ✅ 3 shapes |
| Index engagement | ✅ GIN (`@>`) + BTREE (ORE-extracted `ORDER BY`) engage | ✅ btree + hash for `eq_term`, btree for `ord_term`, JSON-EXPLAIN tree-walk |
| Index **cost preference** (planner *prefers* index) | ❌ **none** | ✅ always-on ordered `_ord` default-btree case; broader scale-preference sweep under `cfg(feature = "scale")` |
| Planner metadata (COMMUTATOR/NEGATOR/RESTRICT/JOIN) | ⚠️ partial | ✅ asserted per supported op × 3 arg shapes |
| Blocker completeness vs native operator surface | ✅ native-operator catalog guard + explicit blocker-signature/runtime blocker tests | ⚠️ generated surface creates 44 operator signatures per domain, but behavioural matrix blockers cover core comparison/containment blockers, typed-column blockers, path blockers, and native-absent LIKE/ILIKE checks rather than every generated signature |
| NULL propagation on supported ops | ⚠️ D6 covers entry comparisons and containment signatures plus arrow accessor NULLs; not exhaustive for every supported operator/position | ✅ every supported scalar op, left/right/both positions |
| Payload schema / domain CHECK | ✅ per type (json / entry / query) | ✅ per variant (required keys `v`,`i`,`c` + term keys) |
| Crypto-integrity invariants | ⚠️ via indexed queries | ✅ OrdOre **ORE injectivity** + Ord **equality-routes-through-`ob`-not-`hm`** |
| Root-document comparison blocked | ✅ all 6 ops, cross-checked | n/a |
| Existence `?` `?|` `?&` / JSONPath `@?` `@@` / `#>` `#>>` / `-` `#-` `||` | ✅ all asserted **blocked** | ⚠️ generated scalar blockers exist, but the matrix does not behaviorally sweep this full JSON-style signature set per domain |

**Reading the table:** the scalar matrix already exercises the positive behaviour categories where jsonb still lacks a scalar-style parity suite (aggregates, `ORDER BY`, `COUNT`, cost preference). The scalars are more complete than jsonb.

---

## 3. The scalar matrix in detail

**Macro nesting:** `scalar_matrix!` → `scalar_domain_matrix!` → 16 category macros → leaf-case macros (`tests/sqlx/src/matrix.rs`).

**Invocation shapes:**
- `caps = [eq, ord]` — ordered scalars (int2/int4/int8/date/text): generates Storage + Eq + Ord + OrdOre with full `=`/`<>`/`<`/`<=`/`>`/`>=` surface.
- `caps = [eq]` — equality-only (timestamptz): Storage + Eq only; ordering operators are blockers.

**Emitted behaviour categories** (with generated test-name shape and assertion):

| Category | Test name shape | Asserts |
|---|---|---|
| sanity | `matrix_<T>_<D>_sanity` | domain spec non-empty; fixture table is `fixtures.*` |
| correctness | `matrix_<T>_<D>_<OP>_pivot_<PIV>_correctness` | `WHERE col op pivot` returns expected rows (3 pivots: min/mid/max) |
| cross_shape | `..._cross_shape` | `(d,d)`, `(d,j)`, `(j,d)` arg shapes all return correct counts |
| supported_null | `..._supported_null` | STRICT wrappers propagate NULL on left/right/both |
| blocker | `..._blocker` | configured unsupported comparison/containment ops raise on 3 shapes × 3 NULL positions |
| payload_check | `..._payload_check` | domain CHECK rejects missing keys / non-object |
| path_op_blockers | `..._path_op_blockers` | `->`, `->>` raise blocker |
| native_absent_ops | `..._native_absent_ops` | `~~`/`~~*` (LIKE/ILIKE) resolve to "operator does not exist" |
| typed_column_blocker | `..._typed_column_blocker` | bare `WHERE col op col` raises via column-typed path |
| planner_metadata | `..._planner_metadata_<group>` | COMMUTATOR/NEGATOR/RESTRICT/JOIN present on all supported ops × 3 shapes |
| index_engages | `..._index_engages_<btree\|hash>` | functional index used (JSON EXPLAIN, `enable_seqscan=off`) |
| scale_preference(_default) | `..._scale_preference[_default_btree]` | planner *prefers* index at ~5000 rows, realistic cost |
| fixture_shape | `matrix_<T>_fixture_shape` | row count, sequential ids, plaintext ORDER BY = FIXTURE_VALUES, payload term types, version=2, distinct hm count |
| ord_routes_through_ob | `..._ord_routes_through_ob` | equality on Ord routes via `ord_term` (ob), never HMAC |
| ore_injectivity | `..._ore_injectivity` | zero equality collisions for distinct fixture rows |
| order_by | `..._order_by_<mode>` | ASC/DESC with and without WHERE, plus ASC/DESC NULLS FIRST/LAST |
| order_by_using | `..._order_by_using_<op>_rejects` | non-default operators rejected in `USING` |
| aggregate (min/max) | `..._aggregate_<func>[_<null_variant>]` | correct encrypted result; all-null / empty / mixed-null variants |
| aggregate_group_by | `..._aggregate_group_by_<func>` | GROUP BY with min/max |
| aggregate_parallel | `..._aggregate_parallel_safe` | aggregates marked PARALLEL SAFE |
| aggregate_typecheck | `..._aggregate_typecheck_<func>` | Storage/Eq variants do not support `eql_v3.min/max` |
| count | `..._count_<shape>` | `COUNT(value)` on typed temp column, `COUNT(payload::<domain>)` path cast, `COUNT(DISTINCT extractor(value))` |

**Per-domain test distribution** (from `matrix_tests.txt`): Storage 17, Eq 33, Ord 80, OrdOre 80, plus 1 fixture-shape per ordered suite.

---

## 4. Which v3 types are wired

| Type | Kind | Domains | Fixtures | Status |
|---|---|---|---|---|
| **int4** | I32 | Storage/Eq/Ord/OrdOre | 17 (`INT4_VALUES`) | Fully wired (reference impl) |
| **int2** | I16 | Storage/Eq/Ord/OrdOre | 19 | Fully wired |
| **int8** | I64 | Storage/Eq/Ord/OrdOre | 19 | Fully wired |
| **date** | Date | Storage/Eq/Ord/OrdOre | 16 ISO strings (3 pivots) | Fully wired |
| **timestamptz** | Timestamptz | Storage/Eq | 15 RFC3339 (3 pivots) | Fully wired, **equality-only** |
| **text** | Text | Storage/Eq/**Match**/Ord/OrdOre | 11 strings | Fully wired, **+ Bloom `_match`** |
| numeric | Numeric | — | — | Planned (catalog kind, no SQL surface) |
| **jsonb** | Jsonb | `eql_v3.json` (hand-written) | generated `v3_ste_vec.sql` via document `FixtureSpec` | **Out of scope** for scalar materializer; separate regime |

**timestamptz is equality-only on purpose:** cipherstash encrypts timestamps at 12-block ORE width, but EQL's only ORE comparator is hardcoded 8-block — enabling ordering would mis-sort. Deferred until a wide-ORE term exists.

**text adds a Match domain:** carries a Bloom term for `@>` / `<@` containment; behavioural Match suites are hand-written outside the `scalars::<T>` matrix. Matrix claims about planner metadata, blockers, aggregate, order, and count coverage apply to the scalar Storage/Eq/Ord/OrdOre variants, not to `text_match`. Empty string is deliberately excluded from fixtures (encrypts to an empty ORE term, undefined comparison — issue #262).

---

## 5. Catalog & term model (why the matrix is uniform)

Source of truth: `crates/eql-scalars/src` (`CATALOG`). Adding a type is one `ScalarSpec` row + a value list; codegen (`crates/eql-codegen`) regenerates byte-identical SQL each build.

**Term capabilities** (`crates/eql-scalars/src/term.rs`, unit-tested in `tests.rs`):

| Term | Key | Extractor → type | Provides | Operators |
|---|---|---|---|---|
| `Hm` | `hm` | `eq_term` → `eql_v3.hmac_256` | equality | `=` `<>` |
| `Ore` | `ob` | `ord_term` → `eql_v3.ore_block_256` | equality + ordering | `=` `<>` `<` `<=` `>` `>=` |
| `Bloom` | `bf` | `match_term` → `eql_v3.bloom_filter` | containment | `@>` `<@` |

Domain → role: empty ⇒ Storage, first term `Hm` ⇒ Eq, `Ore` ⇒ Ord, `Bloom` ⇒ Match.

**Generated surface per domain:** domain definition + CHECK, extractors (inlinable `LANGUAGE sql`), supported-op wrappers (inlinable), **blockers** (`LANGUAGE plpgsql`, NOT STRICT — opaque to planner so the `RAISE` always survives), 44 `CREATE OPERATOR`s, and `min`/`max` aggregates for ord-capable domains. Blocker count per domain: Storage 44, Eq 38, Ord 26, Match 38.

**Behavioural blocker coverage caveat:** the scalar matrix does not execute every generated operator signature per domain. It covers the important caller-visible blocker classes: unsupported comparison/containment operators, typed-column `col op col` blockers, scalar path blockers (`->`, `->>`), and native-absent LIKE/ILIKE resolution. It does not sweep every generated JSON-style signature such as `?`, `?|`, `?&`, `@?`, `@@`, `#>`, `#>>`, `-`, `#-`, and `||` for every scalar domain.

---

## 6. Gaps

### 6a. JSONB-specific gaps (vs the scalar gold standard)

> **Update (2026-06-11): the entry-level behaviour gaps below are now CLOSED** by reusing the scalar behaviour matrix for jsonb **entry** comparisons. A `JsonbEntryInt4` view type (`tests/sqlx/src/jsonb_entry.rs`) delegates the int4 oracle but reaches its comparable value by extracting the entry at the `$.field` selector (`payload -> SELECTOR`) and casting to `eql_v3.ste_vec_entry`; a reduced `jsonb_entry_matrix!` (in `tests/sqlx/src/matrix.rs`) runs the reusable leaf drivers against the `v3_doc_int4` fixture (`tests/sqlx/src/fixtures/v3_doc_int4.rs`, one encrypted `{"field": <int4>}` document per `INT4_VALUES`, int4 oracle column). Now covered for entries: **correctness** (`=`/`<>`/`<`/`<=`/`>`/`>=`), **NULL propagation**, scalar-style **`ORDER BY`** (direction × `NULLS FIRST/LAST` × `WHERE`) and **`ORDER BY USING` rejection**, scalar-parity **`COUNT`** (typed-column / path-cast / `COUNT(DISTINCT ore_cllw)`), **index engagement** on the `eql_v3.ore_cllw` functional btree (validity, `enable_seqscan=off`), entry-specific **ORE-CLLW injectivity** and fixture-shape invariants, and (via `src/v3/jsonb/aggregates.sql`) **`min`/`max` aggregates** with group-by and parallel-safety. The names are pinned by `tests/sqlx/snapshots/matrix_jsonb_entry_tests.txt` (`mise run test:matrix:inventory:jsonb_entry`). Original gap list, annotated:

- ✅ ~~No `min`/`max` aggregate behaviour.~~ — `eql_v3.min`/`max` on `ste_vec_entry`, swept by the entry matrix's aggregate dimension.
- ✅ ~~No scalar-style `ORDER BY` direction/NULLS behaviour matrix~~ — full direction × NULLS × filter matrix over `eql_v3.ore_cllw((payload -> sel))`.
- ✅ ~~No scalar-parity `COUNT` behaviour suite~~ — typed-column / path-cast / `COUNT(DISTINCT extractor)` for the entry.
- ❌ No index **cost-preference** proof (only *engagement* at `enable_seqscan=off`). Still open — the entry index test is validity-only, matching the scalar default (cost-preference is the `#[cfg(feature = "scale")]` gate, not wired for entries).
- ✅ ~~NULL propagation … not exhaustively for every supported operator/position~~ — the entry matrix sweeps all six comparison operators' STRICT NULL propagation (left/right/both).
- ⚠️ Operator-surface coverage is strong but incomplete: for example `->>(eql_v3.json, integer)` is implemented/tested elsewhere but omitted from the expected-signatures guard. (Document-shaped; outside the entry matrix.)

The remaining entry-level gap is index **cost-preference** (deliberately scale-gated, off in PR CI, for entries as for scalars). Document-shaped behaviours — containment (`@>`/`<@`), path query, array ops, the operator-surface guard, the cross-shape `(entry, jsonb)` flatten — stay hand-written in `v3_jsonb_tests` / `v3_jsonb_operator_surface_tests`: they have no scalar analogue. Cross-surface composition (6b) is still open.

The handoff/plan documents (`docs/handoff/2026-06-10-v3-jsonb-fixture-alignment.md`, `docs/superpowers/plans/2026-06-10-v3-jsonb-generated-fixture.md`) are useful historical context for the fixture-generation transition, but should not be read as evidence that fixture generation remains open.

> Caveat: jsonb is a **document** regime, not an orderable scalar. Some matrix behaviours (`ORDER BY col`, scalar `min`/`max`) do not map cleanly. Parity should mean "an equivalent completeness checklist," not "literally run the scalar matrix."

### 6b. Shared composition gaps (not covered by a dedicated positive matrix)
The matrix proves each operator/aggregate in isolation and covers some building blocks (including scalar prepared bindings and casts), but not a dedicated suite for realistic multi-clause compositions:
- Positive JOIN on encrypted equality. This is distinct from scalar typed-column *blocker* tests and from ORE self-join/injectivity checks.
- `SELECT DISTINCT` result sets (scalar coverage includes `COUNT(DISTINCT extractor)`, not projected distinct rows).
- `LIMIT` / `OFFSET` interaction with `ORDER BY`.
- CTEs (`WITH`) / subqueries with encrypted scalars.
- Prepared-statement parameter binding as an explicit composition scenario (scalar tests already exercise bound parameters).
- Cast chains to/from encrypted domains as explicit composition scenarios (scalar tests already exercise path casts such as `payload::<domain>`).
- Range-predicate fusion (`col > a AND col < b`) selectivity.

---

## 7. Recommendations

1. ✅ **jsonb behaviour-parity checklist — DONE for entries (2026-06-11).** jsonb **entry** comparisons now join the matrix harness via `jsonb_entry_matrix!` + the `v3_doc_int4` fixture + the `JsonbEntryInt4` view type (see the 6a update): aggregate behaviour, scalar-style `ORDER BY` over `eql_v3.ore_cllw`, scalar-parity `COUNT`, index engagement, plus entry-specific ORE-CLLW injectivity and fixture-shape. Only the index **cost-preference** test remains (scale-gated, as for scalars). Document-shaped behaviours stay tracked against the document regime in the hand-written suites.
2. **Close JSONB operator-surface guard drift.** Add the implemented `->>(eql_v3.json, integer)` signature to the expected-signatures guard, or document why the guard intentionally excludes it.
3. **Add a composition-test layer** that applies to every wired type at once (positive equality JOIN / DISTINCT / LIMIT+ORDER BY / CTE / explicit param-binding scenario / explicit cast-chain scenario). Highest leverage: hang it off the existing scalar harness for Storage/Eq/Ord/OrdOre, then extend to jsonb where the document model has an equivalent.

---

## 8. Key file references

- Scalar matrix macro: `tests/sqlx/src/matrix.rs`
- Scalar type dispatch: `tests/sqlx/src/scalar_types.rs`, `tests/sqlx/src/scalar_domains.rs`
- Scalar snapshots: `tests/sqlx/snapshots/matrix_tests.txt`, `matrix_tests_eq_only.txt`
- Catalog & terms: `crates/eql-scalars/src/{lib.rs,term.rs,spec.rs,kind.rs,fixture.rs,tests.rs}`
- Codegen: `crates/eql-codegen/src/{generate.rs,operator_surface.rs,context.rs,consts.rs}`
- JSONB tests: `tests/sqlx/tests/v3_jsonb_tests.rs`, `v3_jsonb_operator_surface_tests.rs`
- JSONB snapshot: `tests/sqlx/snapshots/v3_jsonb_tests.txt`
- JSONB fixture spec/generator: `tests/sqlx/src/fixtures/v3_ste_vec.rs`, `tests/sqlx/tests/generate_all_fixtures.rs`
- JSONB generated fixture output: `tests/sqlx/fixtures/v3_ste_vec.sql` (gitignored)
- JSONB-**entry** behaviour matrix: `jsonb_entry_matrix!` (`tests/sqlx/src/matrix.rs`), view type `tests/sqlx/src/jsonb_entry.rs`, suite `tests/sqlx/tests/encrypted_domain/jsonb_entry.rs`, snapshot `tests/sqlx/snapshots/matrix_jsonb_entry_tests.txt` (gate `mise run test:matrix:inventory:jsonb_entry`)
- JSONB-entry fixture: `tests/sqlx/src/fixtures/v3_doc_int4.rs`, output `tests/sqlx/fixtures/v3_doc_int4.sql` (gitignored)
- JSONB-entry aggregates: `src/v3/jsonb/aggregates.sql`
- Adding-a-scalar reference: `docs/reference/adding-a-scalar-encrypted-domain-type.md`
- JSONB fixture historical handoff/plan: `docs/handoff/2026-06-10-v3-jsonb-fixture-alignment.md`, `docs/superpowers/plans/2026-06-10-v3-jsonb-generated-fixture.md`
