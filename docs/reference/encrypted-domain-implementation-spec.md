# Encrypted Domain Type Implementation Spec

This is the scalar encrypted-domain generator contract used by `int4`.
It applies to scalar domains whose searchable payloads are represented by
the fixed `Term` catalog in `crates/eql-scalars/src`.

`text` and `jsonb` are outside this scalar materializer.

## 1. Model

Each generated domain is a concrete `jsonb` domain in the `eql_v3`
schema named `eql_v3.<domain>` (dropped by `DROP SCHEMA eql_v3 CASCADE`;
survives an `eql_v2` uninstall). A type's catalog row is intentionally
small — a `ScalarSpec` whose `domains` field lists each generated domain
as a `DomainSpec` (a `suffix` plus the fixed terms it carries):

```rust
ScalarSpec {
    token: "int4",
    kind: ScalarKind::I32,
    domains: &[
        DomainSpec { suffix: "",         terms: &[] },
        DomainSpec { suffix: "_eq",      terms: &[Term::Hm] },
        DomainSpec { suffix: "_ord_ore", terms: &[Term::Ore] },
        DomainSpec { suffix: "_ord",     terms: &[Term::Ore] },
    ],
    fixtures: &[/* see §9 */],
}
```

The `token` supplies the type token; each domain's full name is `token`
+ `suffix`. The generator emits domains in the order the `domains` slice
declares them, so order the slice the way you want the generated output to
read. Term capabilities are fixed by the `Term` enum
(`crates/eql-scalars/src`):

| Term | JSON key | Extractor | Return type | Supported operators |
|---|---|---|---|---|
| `Hm` | `hm` | `eq_term` | `eql_v2.hmac_256` | `=` / `<>` |
| `Ore` | `ob` | `ord_term` | `eql_v2.ore_block_u64_8_256` | `=` / `<>` / `<` / `<=` / `>` / `>=` |

For current `int4`, domains carrying `Ore` use JSON key `ob`, extractor
`ord_term`, and the ORE block supports equality plus ordering. A type
that needs a non-ORE equality term on an ordered domain needs a new
`Term` design, not a catalog flag.

The row above declares two ordered domains, `int4_ord` and
`int4_ord_ore`, carrying the same term. They are intentional twins: the
generator emits byte-identical SQL (modulo type name) so callers can pick
a name that documents intent without committing to a term family in a
future migration.

## 2. Checklist

- [ ] Add a row to the Rust catalog `eql-scalars::CATALOG`
      (`crates/eql-scalars/src/lib.rs`). A `ScalarSpec` declares:

      - `token` — the type token (e.g. `int8`); supplies `<T>` everywhere.
      - `kind` — the `ScalarKind` (`I16` / `I32` / `I64`), which carries the
        Rust type name, the `MIN`/`MAX`/zero symbols, and the numeric bounds.
      - `domains` — a `&[DomainSpec]`, each a `suffix` + the fixed `Term`s it
        carries. The storage domain is suffix `""` with no terms; `_eq => [Hm]`;
        `_ord` and `_ord_ore => [Ore]`.
      - `fixtures` — the `Fixture` value list (see §9). It MUST include `Min`,
        `Max`, and zero.

      Terms determine operator support: `Hm` provides `=` / `<>`; `Ore`
      provides `=` / `<>` / `<` / `<=` / `>` / `>=`. There is no TOML manifest
      and no Python: the catalog is the source of truth, validated by the
      compiler (an undefined `Term` or unknown `ScalarKind` is a compile error)
      plus catalog `#[test]`s over `CATALOG`.
- [ ] Materialise the type's plaintext fixture list as a typed const next to
      `CATALOG`: add `int_values!(<T_UPPER>_VALUES, <R>, <T_UPPER>);` (e.g.
      `int_values!(INT8_VALUES, i64, INT8);`). The macro resolves the row's
      `Fixture` list into a compile-time `&'static [<R>]` — the single source the
      SQLx matrix reads as `FIXTURE_VALUES`. Pin the exact list with a
      `values_tests` assertion. This replaces the old generated, committed
      `<T>_values.rs`.
- [ ] **If `<T>` needs a new scalar width**, add a `ScalarKind` enum variant in
      `crates/eql-scalars/src/lib.rs` with its rust-type name, `MIN`/`MAX`/zero
      symbols, and numeric bounds, and unit-test its `impl` methods. New term
      behaviour likewise belongs in the `Term` enum's `impl` methods with tests
      — not in free-form catalog data.
- [ ] Run `cargo run -p eql-codegen` to materialise the generated SQL
      (`src/encrypted_domain/<T>/<T>_{types,functions,operators,aggregates}.sql`,
      gitignored), or just `mise run build` — every build runs the generator
      first. There is no per-type codegen task: one run generates every type from
      `CATALOG`. The plaintext fixture list is **not** generated — it is
      materialised from the catalog row at compile time (see the next step), so
      there is nothing to regenerate-and-commit on the test side.
- [ ] Generated `*_types.sql` / `*_functions.sql` / `*_operators.sql` /
      `*_aggregates.sql` are gitignored and never committed. The catalog
      (`eql-scalars::CATALOG`) plus the `eql-codegen` renderers are the source
      of truth. Change the catalog and rebuild; do not hand-edit generated SQL.
- [ ] Put optional hand-written SQL in
      `src/encrypted_domain/<T>/<T>_extensions.sql` with explicit
      `-- REQUIRE:` edges. This file IS committed.
- [ ] Do **not** add a `tests/codegen/reference/<T>/` baseline. `int4` is the
      single golden master for the type-generic generator: the SQL templates are
      pure token substitution, so a per-type baseline can only fail when `int4`'s
      already would. Drift protection for the new type comes from the `int4`
      reference, the catalog `values_tests` pinning the materialised
      `eql_scalars::<T>_VALUES` const, the catalog/generator `#[test]`s
      (`cargo test -p eql-scalars -p eql-codegen`), and the
      `ordered_numeric_matrix!` SQLx suite (behaviour, not bytes).
- [ ] Wire the SQLx matrix oracle. The generated SQL is enough to install the
      domains, but the `ordered_numeric_matrix!` suite only runs once the Rust
      harness knows about the scalar. Copy each piece from the `int4`
      reference — these are hand-maintained registration lists (the Phase-4
      `scalar_types!` registry, a separate plan, will collapse them):

      | File | Add |
      |------|-----|
      | `tests/sqlx/src/fixtures/eql_plaintext.rs` | A sealed `EqlPlaintext` impl for the scalar's Rust type: `impl Sealed for <R> {}`, a `PlaintextSqlType` const for its base column type, `impl EqlPlaintext for <R>` (`CAST`, `PLAINTEXT_SQL_TYPE`, `to_plaintext` → the right `Plaintext` variant), plus the two `#[test]` casts. |
      | `tests/sqlx/src/fixtures/eql_v2_<T>.rs` | `use eql_scalars::<T_UPPER>_VALUES as VALUES;` then `crate::scalar_fixture!("eql_v2_<T>", <R>, VALUES);`. |
      | `tests/sqlx/src/fixtures/mod.rs` | `pub mod eql_v2_<T>;`. |
      | `tests/sqlx/tests/generate_all_fixtures.rs` | An arm in `generate_for_token`: `"<T>" => fixtures::eql_v2_<T>::spec().run().await,`. The match is exhaustive over the catalog — a catalog token with no arm fails the generator loudly. |
      | `tests/sqlx/src/scalar_domains.rs` | `impl ScalarType for <R>` — `PG_TYPE` (the base PG type, e.g. `"int8"`) and `FIXTURE_VALUES = eql_scalars::<T_UPPER>_VALUES`. |
      | `tests/sqlx/tests/encrypted_domain/scalars/<T>.rs` | `ordered_numeric_matrix! { suite = <T>, scalar = <R>, eql_type = "eql_v2_<T>" }`. |
      | `tests/sqlx/tests/encrypted_domain/scalars/mod.rs` | `pub mod <T>;`. |

      `<R>` is the scalar's Rust type (`i32` for `int4`, `i16` for `int2`).
      Forget one and the matrix simply does not run for the type — the matrix
      inventory cross-check (next step) surfaces it, because the catalog has the
      type but the binary has no `scalars::<T>::` tests.
- [ ] Run `mise run test:matrix:inventory`. It verifies every present type's
      token-normalized `scalars::<T>::*` name set equals the single canonical
      `tests/sqlx/snapshots/matrix_tests.txt`, and cross-checks the present type
      set against `cargo run -p eql-codegen -- list-types`. You do **not** edit a
      per-type snapshot — there is one canonical snapshot; you only regenerate it
      when the macro's emitted name set itself changes. A catalog type missing
      its matrix wiring fails the cross-check. See §8 and
      `tests/sqlx/snapshots/README.md`.
- [ ] Run `mise run test:codegen` (`cargo test -p eql-scalars -p eql-codegen`),
      the relevant SQLx suites, and the PostgreSQL matrix before merging.

## 3. Domain Generation

The generator emits `src/encrypted_domain/<T>/<T>_types.sql` (gitignored;
materialised on every `mise run build` and every `cargo run -p eql-codegen`)
with one idempotent `DO $$ ... $$` block. Domain `CHECK`
constraints always require:

- fixed envelope keys `v` and `i`;
- ciphertext key `c`;
- catalog JSON keys for the listed terms;
- the envelope version value: `VALUE->>'v' = '2'`, matching the repo-wide
  `eql_v2._encrypted_check_v` rule (`src/encrypted/constraints.sql`).

For example, a domain with `["ore"]` requires `v`, `i`, `c`, and `ob` present,
with `v` pinned to `2`. Beyond key presence and the version value, a malformed
term can still fail later inside its extractor unless a future catalog design
adds stronger validation.

Every generated domain is a concrete domain over `jsonb` in the `eql_v3`
schema. Do not define one generated domain over another generated domain;
PostgreSQL resolves operators against the underlying base type in ways
that bypass the fixed operator surface.

## 4. Extractors And Wrappers

Extractor names and return types come from the `Term` enum
(`crates/eql-scalars/src`), not from catalog data. Generated extractors and
supported comparison wrappers are inline-friendly SQL functions:

```sql
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT ... $$;
```

Extractors and comparison wrappers must not carry a pinned `search_path`
— a `SET` clause disables inlining and reverts index-backed queries to
seq scans. The build tooling recognises these generated functions
structurally, so the generator does not emit `eql-inline-critical`
markers. Aggregate state functions are the one deliberate exception — see
§5 — because they are never index expressions.

Unsupported operators route to blockers. Blockers are `plpgsql`,
`IMMUTABLE`, `PARALLEL SAFE`, and intentionally not `STRICT`. Both
choices are deliberate:

- **`plpgsql`, not `sql`.** A `LANGUAGE sql` body would be inlinable, and
  the planner could elide the call when the result is provably unused
  (dead `CASE` branch, folded predicate), letting a blocked operator
  appear to succeed. `plpgsql` is opaque to the planner, so the call —
  and its `RAISE` — always survives.
- **Not `STRICT`.** A `STRICT` blocker lets PostgreSQL skip the body and
  return `NULL` on a `NULL` argument, silently bypassing the
  unsupported-operator exception.

## 5. Operators

Every generated domain declares supported scalar comparison operators plus
blockers for the native `jsonb` operator surface that PostgreSQL could
otherwise reach through domain-to-base-type fallback. Each domain emits
44 `CREATE OPERATOR` statements. Supported operators route to wrappers;
everything else routes to blockers.

| Operators | Forms |
|---|---|
| `=` `<>` `<` `<=` `>` `>=` `@>` `<@` | `(domain, domain)` · `(domain, jsonb)` · `(jsonb, domain)` |
| `->` `->>` | `(domain, text)` · `(domain, integer)` · `(jsonb, domain)` |
| `?` | `(domain, text)` |
| `?\|` `?&` | `(domain, text[])` |
| `@?` `@@` | `(domain, jsonpath)` |
| `#>` `#>>` `#-` | `(domain, text[])` |
| `-` | `(domain, text)` · `(domain, integer)` · `(domain, text[])` |
| `\|\|` | `(domain, domain)` · `(domain, jsonb)` · `(jsonb, domain)` |

Function counts:

| Domain terms | Extractors | Wrappers | Blockers | Functions | Operators |
|---|---:|---:|---:|---:|---:|
| none | 0 | 0 | 44 | 44 | 44 |
| `hm` | 1 (`eq_term`) | 6 | 38 | 45 | 44 |
| `ore` | 1 (`ord_term`) | 18 | 26 | 45 | 44 |

Supported comparison operators carry planner metadata such as
`COMMUTATOR`, `NEGATOR`, `RESTRICT`, and `JOIN`. Blocker operators keep
minimal metadata because they should never be planner-visible supported
paths.

PostgreSQL's operator resolver still prefers the built-in `jsonb` operator
for untyped string literals in forms such as `payload::eql_v3.int4 ? 'c'`.
Use typed parameters or explicit casts (`'c'::text`) to route those forms
to the generated blocker. The generated surface blocks the typed native
operator shapes exposed by the catalog.

### Aggregates

Each ordered (ord-capable) domain additionally gets a generated
`<domain>_aggregates.sql` file declaring `MIN` / `MAX`:

- two state functions, `eql_v3.min_sfunc` and `eql_v3.max_sfunc`, and
- two aggregates, `eql_v3.min(<domain>)` and `eql_v3.max(<domain>)`.

Comparison routes through the domain's `<` / `>` operator (the ORE block
term — no decryption). The state functions are `LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE` **with** a pinned `SET search_path`. This is
the one place the "no pinned `search_path`" rule of §4 does not apply:
aggregate transition functions are never index expressions, so pinning is
correct. `STRICT` makes PostgreSQL seed the running state with the first
non-NULL value and skip NULLs, so an all-NULL group returns NULL.

Each `CREATE AGGREGATE` declares `combinefunc = <sfunc>` and
`parallel = safe`: min/max are associative, so the state function doubles as
the combine function, and with a `PARALLEL SAFE` sfunc/combinefunc
PostgreSQL can use partial and parallel aggregation on the large `GROUP BY`
ORE workloads these aggregates exist to serve — still with no decryption.
Storage-only and equality-only domains have no comparator and emit no
aggregate file.

## 6. Extension Files

Optional hand-written SQL beyond the fixed scalar surface belongs in:

```text
src/encrypted_domain/<T>/<T>_extensions.sql
```

The generator must not create this file, list it in the catalog, add an
auto-generated header, or clean it during regeneration. The file must
declare its own `-- REQUIRE:` edges, usually to `<T>_types.sql` and
whichever generated function or operator file it extends. Unlike the
generated siblings, `<T>_extensions.sql` IS committed.

## 7. Indexing

Do not create operator classes on generated domains. Index through
the extractor:

```sql
CREATE INDEX ... ON table_name USING btree (eql_v3.ord_term(col));
CREATE INDEX ... ON table_name USING hash (eql_v3.eq_term(col));
```

The extractor return type must already have the needed PostgreSQL access
method support. `ore` depends on
`src/ore_block_u64_8_256/functions.sql` and
`src/ore_block_u64_8_256/operators.sql`; `hm` depends on
`src/hmac_256/functions.sql`.

## 8. Tests

Cover each generated domain with SQLx tests appropriate to its terms:

- supported operators return correct rows for all argument forms;
- unsupported operators raise the expected error for all forms;
- blockers raise on `NULL` input;
- supported wrappers return `NULL` for `NULL` operands;
- functional indexes engage and return correct rows;
- constant-on-left comparisons engage the index where applicable;
- domain `CHECK` rejects non-object and under-populated payloads;
- real typed columns are tested, not only cast literals;
- generated ordered-domain twins remain byte-identical modulo type name
  (the shared generator is anchored by the `int4` golden master in
  `tests/codegen/reference/int4/` via the eql-codegen parity test;
  new types add no baseline of their own — see §2).

For ordered numeric scalars this coverage is generated by the
`ordered_numeric_matrix!` convention wrapper in `tests/sqlx/src/matrix.rs`:
one `impl ScalarType` (`tests/sqlx/src/scalar_domains.rs`) plus a single
invocation taking `suite`, `scalar`, and `eql_type`. The matrix derives
its comparison pivots — the scalar's `MIN`, `MAX`, and zero
(`Default::default()`) — from the type rather than a hand-written list, so
the invocation carries no pivot argument. Equality-only scalars use the
sibling `eq_only_scalar_matrix!`. The `matrix.rs` module header is the
canonical, current list of the test categories the matrix emits (sanity,
correctness, cross-shape, supported-NULL, blocker raises, index engagement,
ORDER BY, ORDER BY USING) — read it rather than maintaining a duplicate
count here.

For ordered `int4`, keep the assertion that distinct plaintext values
produce distinct ORE blocks. Do not add assertions for term behavior that
the catalog does not promise.

### Matrix coverage inventory snapshot

The *set of test names* the matrix emits is guarded by ONE committed,
token-normalized snapshot at `tests/sqlx/snapshots/matrix_tests.txt` — the
sorted inventory of every `scalars::<T>::*` test name with the type token
replaced by the literal `<T>`. (The per-type `<T>_matrix_tests.txt` files are
gone: they were byte-identical modulo the token, so one canonical set plus a
per-type normalize-and-compare carries the same signal at a fraction of the
committed surface.) This is the guard that catches a silently dropped, renamed,
or `#[cfg]`-gated matrix test, a behaviour the SQLx assertions above cannot see.
The snapshot is a committed test baseline, **not** gitignored generated SQL.

`mise run test:matrix:inventory` discovers the present scalar types from the
`encrypted_domain` binary's `--list`, normalizes each type's token to `<T>`,
asserts every type's set equals the canonical snapshot, and cross-checks the
discovered type set against `cargo run -p eql-codegen -- list-types` (the catalog
is the single source). The CI `matrix-coverage` job gates it. **`tests/sqlx/snapshots/README.md`
is the source of truth** for the mechanics (pinned feature set, the catalog
cross-check, the CI diff, and when to regenerate); see it rather than
duplicating the detail here.

## 9. Fixtures

Fixture generation should use real encrypted payloads produced through
CipherStash Proxy. A single payload table may carry every term needed by
the generated domains for that type. For `int4`, the payloads carry `c`,
`hm`, and `ob`; the equality domain reads `hm`, and ordered domains read
`ob`.

Choose values so range operators produce distinguishable result counts,
include useful boundaries, and cover omitted-term negative cases. For a
scalar driven by `ordered_numeric_matrix!`, the fixture **must** include
the type's `MIN`, `MAX`, and zero (`Default::default()`): the matrix uses
those three as comparison pivots and fetches each one's ciphertext from the
fixture via `fetch_fixture_payload`, which fails loudly if the row is
absent.

### Single-sourcing the value list

The plaintext value list is declared **once**, in the catalog row's `fixtures`
field, and materialised into a typed Rust const — never hand-maintained in two
places:

```rust
fixtures: &[Fixture::Min, Fixture::N(-100), Fixture::N(-1), Fixture::Zero,
            Fixture::N(1), Fixture::N(2), Fixture::N(5), Fixture::N(10),
            Fixture::N(17), Fixture::N(25), Fixture::N(42), Fixture::N(50),
            Fixture::N(100), Fixture::N(250), Fixture::N(1000),
            Fixture::N(9999), Fixture::Max],
```

`Fixture::Min` / `Fixture::Max` / `Fixture::Zero` resolve to the scalar's Rust
named consts (for `int4`: `i32::MIN`, `i32::MAX`, `0`); every `Fixture::N(_)` is
a numeric literal validated against the `ScalarKind`'s representable range by a
catalog `#[test]` (`numeric_value` is infallible, so the range check is the
explicit invariant `every_fixture_value_is_within_kind_bounds`). The same test
enforces the matrix invariant: the set **must** include `Min`, `Max`, and zero,
or the test fails (the compile-time analogue of the old `load_spec` validation).

The `int_values!` macro (in `crates/eql-scalars/src/lib.rs`) materialises that
`Fixture` list into a `pub const <T_UPPER>_VALUES: &[<rust_type>]` at compile
time, sitting next to `CATALOG`. Both consumers reference that single symbol —
the fixture generator (`fixtures::eql_v2_<T>::spec`) and the matrix oracle
(`impl ScalarType for <rust> { const FIXTURE_VALUES = eql_scalars::<T_UPPER>_VALUES }`)
— so the oracle cannot drift from the values the generator encrypts. There is no
generated `<T>_values.rs`: a Rust source of truth does not round-trip through
generated Rust. The exact list is pinned by a `values_tests` assertion, and the
`Fixture`-list invariants (`Min`/`Max`/zero present, in-bounds) by the catalog
`#[test]`s.

## 10. Build And Verification

- `cargo run -p eql-codegen` (optional; refreshes all generated SQL from the
  catalog before a full build)
- `mise run test:codegen` (`cargo test -p eql-scalars -p eql-codegen`)
- `mise run clean && mise run build` (regenerates every type's SQL from
  the catalog first, then builds the release artefacts)
- relevant SQLx suites
- `mise run test` across supported PostgreSQL versions
- `mise run --output prefix test:splinter --postgres 17` after a
  PostgreSQL 17 install has built EQL

The CI codegen job should remain a prerequisite of the PostgreSQL test
matrix so generated SQL drift is caught before database tests run.
