# Adding a Scalar Encrypted-Domain Type

The one reference for adding a scalar encrypted-domain type (`int4`, `int2`,
and future ordered numeric scalars). The **top half** (§§1–4) is the path you
follow to add a type; the **reference half** (§§5–7) is the detail behind it —
the generated surface, its invariants, and how the generator itself works.
Read top-down to ship a type; drop into the reference half when something
breaks or you need the *why*.

A scalar encrypted-domain type is a family of concrete `jsonb` domains in the
**`eql_v3`** schema (`eql_v3.<token>`, `eql_v3.<token>_eq`,
`eql_v3.<token>_ord`, …), dropped by `DROP SCHEMA eql_v3 CASCADE` and surviving
an `eql_v2` uninstall. Their extractors, comparison wrappers, and MIN/MAX
aggregates also live in `eql_v3`; the searchable-encrypted-metadata (SEM)
index-term types they return (`eql_v3.hmac_256`,
`eql_v3.ore_block_u64_8_256`) are **also `eql_v3`** — hand-written under
`src/v3/sem/`. The whole v3 surface is self-contained: it owns every type it
needs and has no runtime dependency on `eql_v2` (CI gates this — see §6).

The whole SQL surface is **generated** from a single Rust source of truth: the
`CATALOG` const in [`crates/eql-scalars/src/lib.rs`](../../crates/eql-scalars/src/lib.rs),
rendered by the [`eql-codegen`](../../crates/eql-codegen/) crate. There is no
TOML manifest and no Python — adding a type is adding one `ScalarSpec` row,
validated by the compiler plus catalog `#[test]`s. The reference type is
`eql_v3.int4`. **`text` and `jsonb` are out of scope** for this materializer
(see §7).

---

## 1. TL;DR — the one path

To add a scalar type `<T>` (e.g. `int8`), with Rust type `<R>` (e.g. `i64`):

1. **Add a `ScalarSpec` row to `eql_scalars::CATALOG`** — `token`, `kind`,
   `domains`, `fixtures` (§2). If the type needs a new scalar width, add a
   `ScalarKind` variant first; if it needs new term behaviour, that goes in the
   `Term` enum's `impl`, never in catalog data.
2. **Materialise the value list** — `int_values!(<T_UPPER>_VALUES, <R>, <T_UPPER>);`
   next to `CATALOG`, pinned by a `values_tests` assertion (§2). This is the
   single source the SQLx matrix reads; there is no generated `<T>_values.rs`.
3. **Wire the SQLx matrix oracle** — copy the seven small registrations from the
   `int4` reference (§3).
4. **Regenerate** — `cargo run -p eql-codegen` (or just `mise run build`, which
   runs the generator first). One run regenerates *every* catalog type; there is
   no per-type codegen task. The generated `*_{types,functions,operators,aggregates}.sql`
   are gitignored and never committed.
5. **Snapshot the matrix inventory** — `mise run test:matrix:inventory` (§3).
6. **Verify** — `mise run test:codegen`, the relevant SQLx suites, and the
   PostgreSQL matrix (§4).

Things you do **not** do:

- **Don't commit generated SQL.** `*_types.sql` / `*_functions.sql` /
  `*_operators.sql` / `*_aggregates.sql` are gitignored; the catalog plus the
  renderers are the source of truth. Change the catalog and rebuild — never
  hand-edit generated SQL.
- **Don't add a `tests/codegen/reference/<T>/` baseline.** `int4` is the sole
  golden master (§4).
- **Don't edit `mise.toml`, the CI workflow, `pin_search_path.sql`, or
  `splinter.sh`** for an ordinary type — they recognise the generated surface
  intrinsically (§5, §6). The exception is a brand-new *term* whose extractor
  has a new name (§5).

Hand-written SQL beyond the fixed surface goes in
`src/v3/scalars/<T>/<T>_extensions.sql` with explicit `-- REQUIRE:` edges
— and **that file IS committed** (§5).

---

## 2. The catalog row (`ScalarSpec`)

A scalar type is one `ScalarSpec` row in
[`crates/eql-scalars/src/lib.rs`](../../crates/eql-scalars/src/lib.rs):

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
    fixtures: INT4_FIXTURES,
}
```

The fields, all enforced by the type system and the catalog `#[test]`s rather
than a runtime validator:

- **`token`** — the type token (`int4`); supplies `<T>` everywhere. Each
  domain's full name is `token` + `suffix` (`ScalarSpec::domain_name`), pinned by
  `every_domain_name_starts_with_its_token`.
- **`kind`** — a `ScalarKind` (`I16` / `I32` / `I64` / `Numeric` / `Text` /
  `Jsonb`), carrying the Rust type name, the `MIN`/`MAX`/zero symbols, and the
  numeric bounds. Only the integer kinds have an i128 range with `Min`/`Max`/`Zero`
  sentinels; the bounded accessors `panic!` on the others (a misuse guard gated
  by `is_int()`). **If `<T>` needs a new scalar width, add a `ScalarKind`
  variant** (rust-type name, `MIN`/`MAX`/zero symbols, bounds) with unit tests
  over its `impl` methods.
- **`domains`** — a non-empty `&[DomainSpec]` (pinned by
  `every_type_has_at_least_one_domain`), each a `suffix` + the fixed `&[Term]` it
  carries. The storage domain is `suffix: ""` with no terms; `_eq => [Term::Hm]`;
  `_ord` and `_ord_ore => [Term::Ore]`. A `DomainSpec` declares nothing else — no
  extractor names, no operator lists, no REQUIRE edges. Every behavioural fact
  comes from the `Term` enum.
- **`fixtures`** — the type's plaintext fixture list (see below).

**Terms** are fixed by the `Term` enum (`crates/eql-scalars/src/lib.rs`). The
`json_key` / `extractor` / `returns` / `ctor` values are the cross-schema SQL
contract — changing one is a generated-SQL behaviour change, not a refactor:

| Term  | JSON key | Extractor   | Returns                          | Operators                  |
| ----- | -------- | ----------- | -------------------------------- | -------------------------- |
| `Hm`  | `hm`     | `eq_term`   | `eql_v3.hmac_256`                | `=` `<>`                   |
| `Ore` | `ob`     | `ord_term`  | `eql_v3.ore_block_u64_8_256`     | `=` `<>` `<` `<=` `>` `>=` |

A type that needs a non-ORE equality term on an ordered domain needs a **new
`Term`**, not a catalog flag. Adding a term is a code change to the `Term`
enum's `impl` methods (`json_key`, `extractor`, `returns`, `ctor`, `role`,
`operators`, `requires`) with matching `#[test]`s (`term_tests` /
`term_helper_tests`) — never a free-form catalog field.

**Twins.** `int4_ord` and `int4_ord_ore` both carry `&[Term::Ore]`. The
generator emits them as independent domains with byte-identical SQL modulo type
name (`ordered_files_byte_identical_modulo_typename`). Twins let callers choose
a name that documents intent ("ordered, regardless of mechanism" vs "ordered via
ORE block") without committing to one term family in a future migration.

**Order is significant.** The generator iterates `CATALOG` in order (driving
generation order), and iterates each spec's `domains` slice in order — that
order shows up in the generated `<token>_types.sql` `DO` block. Order the slice
the way you want the output to read.

### Fixtures — single-sourcing the value list

The `fixtures` field is an ordered `&[Fixture]` — the single source of truth
for the type's plaintext list, consumed by both the SQLx fixture generator and
the matrix oracle. A `Fixture` is value-kind tagged: `Min` / `Max` / `Zero` (the
integer matrix pivots, resolved per-kind), `Int(i128)` (an integer literal), and
`Numeric` / `Text` / `Jsonb` string variants. The `fixtures!` macro
range-checks each `Int` literal against the kind at compile time (`N(-40000)`
for an `i16` kind does not compile):

```rust
const INT4_FIXTURES: &[Fixture] = fixtures!(int i32;
    Min, N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17), N(25),
    N(42), N(50), N(100), N(250), N(1000), N(9999), Max);
```

Catalog `#[test]`s enforce a **distinct-plaintext contract** plus the
matrix-pivot requirement:

- `fixture_values_are_distinct_by_resolved_number` rejects duplicates against
  the *resolved* value, so both copy-paste dups and sentinel/literal aliases
  (`Min` alongside the same number) fail;
- `fixtures_include_min_max_and_zero` requires `Min`, `Max`, and zero for
  integer kinds — the matrix uses those three as comparison pivots and fetches
  each one's ciphertext from the fixture via `fetch_fixture_payload`, which fails
  loudly if the row is absent;
- `every_fixture_value_is_within_kind_bounds` keeps every resolved value in
  range.

These are the compile/test-time analogue of the old `load_spec` validation.
Beyond the pivots, choose values so range operators produce distinguishable
result counts, include useful boundaries, and cover omitted-term negative cases.

The plaintext list is **not** rendered to a generated file. The `int_values!`
macro (next to `CATALOG`) materialises a `Fixture` list into a typed `pub const
<T_UPPER>_VALUES: &[<rust_type>]` at compile time (`INT4_VALUES`, `INT2_VALUES`):

```rust
int_values!(INT4_VALUES, i32, INT4);
```

Both consumers reference that single symbol — the fixture generator
(`fixtures::eql_v2_<T>::spec`) and the matrix oracle's `fixture_values()` — so
the oracle cannot drift from the values the generator encrypts. There is no
committed `<T>_values.rs`: a Rust source of truth does not round-trip through
generated Rust. Pin the exact materialised list with a `values_tests` assertion.

### Temporal kinds — string-backed fixtures and the pivot trait

A **temporal** scalar (the `date` reference; `timestamptz` follows the same
shape) is *ordered but non-integer*, so it diverges from the integer path in
three places — all in the catalog/harness, never the SQL codegen (domains stay
jsonb-backed and token-driven):

- **String-backed fixtures.** `eql-scalars` stays zero-dependency, so the
  catalog stores ISO strings (`Fixture::Date("1970-01-01")`), not `chrono`
  values. There is **no** `int_values!` / `<T>_VALUES` const for a temporal kind
  (chrono constructors are not `const`). The SQLx harness parses the catalog
  strings into a `LazyLock<Vec<chrono::NaiveDate>>` and exposes them via a
  `date_values()` accessor; `ScalarType::fixture_values()` returns a borrow of
  that. The fixtures must include the three pivot plaintexts verbatim — for
  `date`: `"1900-01-01"` (min), `"1970-01-01"` (zero = `NaiveDate::default()`),
  `"2099-12-31"` (max) — guarded by `temporal_fixtures_include_pivot_plaintexts`.
- **The pivot trait, not `Self::MIN`/`MAX`.** `ScalarType::fixture_values()` is a
  method (not a `const`), and the comparison pivots come from
  `ScalarType::min_pivot()` / `max_pivot()` (zero stays `Default::default()`).
  Integer impls return `Self::MIN`/`Self::MAX` (emitted by the proc-macro);
  temporal impls return explicit sentinel dates and are **hand-written** in
  `scalar_domains.rs` (the macro emits only integer impls). `to_sql_literal` is
  overridden to single-quote the value (`'1970-01-01'`), since a bare `Display`
  date is not a valid SQL literal.
- **The sqlx `chrono` feature.** The test crate enables sqlx's `chrono` feature
  (and depends on `chrono` directly) so `Encode`/`Decode`/`Type` resolve for
  `NaiveDate`. The integer-only fixture asserts (`<T>::MIN`, `contains(&0)`,
  `v < 0`) are stamped only for `int` entries; temporal entries stamp a
  pivot-presence assert instead (the `kind` discriminator on `scalar_fixture!`).

---

## 3. Wire the SQLx matrix oracle

The generated SQL is enough to *install* the domains, but the
`ordered_numeric_matrix!` suite only runs once the Rust harness knows about the
scalar. `<R>` is the scalar's Rust type (`i32` for `int4`, `i16` for `int2`).
There are now **two** registrations:

| File | Add |
|------|-----|
| `tests/sqlx/src/scalar_types.rs` | One `<T> => <R>` line in the `scalar_types!` list (e.g. `int8 => i64,`). This single line drives the `impl ScalarType`, the `eql_v2_<T>` fixture module, the `ordered_numeric_matrix!` suite, and the `generate_for_token` arm — all generated by the `eql-tests-macros` proc-macros. |
| `tests/sqlx/src/fixtures/eql_plaintext.rs` | A sealed `EqlPlaintext` impl for `<R>`: `impl Sealed for <R> {}` and `impl EqlPlaintext for <R>` carrying just `const KIND: ScalarKind` plus the value-typed `to_plaintext` → the right `Plaintext` variant. `CAST` and `PLAINTEXT_SQL_TYPE` are **derived** from `KIND` via the `cast_for_kind` / `plaintext_sql_type_for_kind` `const fn` defaults, so a brand-new integer kind needs an arm in those two helpers — not a per-type const. Keep the three `#[test]`s (cast / sql-type / to_plaintext) mirroring the existing ones. |

The single `<T> => <R>` line in `scalar_types.rs` is the harness source of
truth. The four code-generators (`emit_scalar_type_impls`,
`emit_scalar_fixture_modules`, `emit_scalar_matrix_suites`,
`emit_fixture_dispatch`) are pure functions of that list, invoked at each call
site via `scalar_types!(<mode>)`; there are four because proc-macros emit into
the crate/module where they're invoked and the pieces span the `eql-tests` lib,
the `encrypted_domain` test binary, and the `generate_all_fixtures` test binary.
See the `scalar_types.rs` module docs and `crates/eql-tests-macros/src/lib.rs`.

Forget the harness line and the matrix simply does not run for the type — the
matrix inventory cross-check (below) surfaces it, because the catalog has the
type but the binary has no `scalars::<T>::` tests. A catalog token absent from
the `scalar_types!` list also fails the `generate_for_token` catch-all loudly
at fixture-generation time.

The coverage these registrations unlock comes from the `ordered_numeric_matrix!`
convention wrapper in `tests/sqlx/src/matrix.rs`: one `impl ScalarType` plus a
single invocation taking `suite`, `scalar`, and `eql_type`. The matrix derives
its comparison pivots — the scalar's `MIN`, `MAX`, and zero
(`Default::default()`) — from the type rather than a hand-written list, so the
invocation carries no pivot argument. Equality-only scalars use the sibling
`eq_only_scalar_matrix!`. The `matrix.rs` module header is the canonical,
current list of the categories the matrix emits (sanity, correctness,
cross-shape, supported-NULL, blocker raises, index engagement, ORDER BY, ORDER
BY USING) — read it rather than duplicating a count here. For ordered `int4`,
keep the assertion that distinct plaintext values produce distinct ORE blocks;
do not add assertions for term behaviour the catalog does not promise.

### Matrix coverage inventory snapshot

The *set of test names* the matrix emits is guarded by **one** committed,
token-normalized snapshot at `tests/sqlx/snapshots/matrix_tests.txt` — the
sorted inventory of every `scalars::<T>::*` test name with the type token
replaced by the literal `<T>`. (The per-type `<T>_matrix_tests.txt` files are
gone: they were byte-identical modulo the token, so one canonical set plus a
per-type normalize-and-compare carries the same signal at a fraction of the
committed surface.) This is the guard that catches a silently dropped, renamed,
or `#[cfg]`-gated matrix test — a behaviour the SQLx assertions cannot see (a
deleted test just stops running). The snapshot is a committed test baseline,
**not** gitignored generated SQL.

`mise run test:matrix:inventory` discovers the present scalar types from the
`encrypted_domain` binary's `--list`, normalizes each type's token to `<T>`,
asserts every type's set equals the canonical snapshot, and cross-checks the
discovered type set against `cargo run -p eql-codegen -- list-types` (the
catalog is the single source). You do **not** edit a per-type snapshot or touch
`mise.toml` / the CI workflow — you only regenerate the one `matrix_tests.txt`
when the macro's emitted name set itself changes. A catalog type missing its
matrix wiring fails the cross-check. The CI `matrix-coverage` job gates it.
**`tests/sqlx/snapshots/README.md` is the source of truth** for the mechanics
(pinned feature set, the catalog cross-check, the CI diff, and when to
regenerate).

---

## 4. Regenerate, snapshot & verify

Regeneration is deterministic: identical catalog + renderers produce
byte-identical SQL. If `mise run build` produces unexpected output, the change
is in `crates/eql-scalars/src` (catalog/terms) or `crates/eql-codegen/src`
(renderers) — not run-to-run variation.

Run, in order:

- `cargo run -p eql-codegen` (optional; refreshes all generated SQL from the
  catalog before a full build)
- `mise run test:codegen` (`cargo test -p eql-scalars -p eql-codegen`)
- `mise run test:matrix:inventory` (matrix inventory + catalog cross-check; no
  database)
- `mise run clean && mise run build` (regenerates every type's SQL from the
  catalog first, then builds the release artefacts — a bare build can leave
  stale `release/*.sql`)
- the relevant SQLx suites
- `mise run test` across supported PostgreSQL versions
- `mise run --output prefix test:splinter --postgres 17` after a PostgreSQL 17
  install has built EQL

The CI codegen job is a prerequisite of the PostgreSQL test matrix, so
generated-SQL drift is caught before database tests run.

**Why no per-type golden baseline.** Do **not** add a
`tests/codegen/reference/<T>/` baseline. `int4` is the sole golden master for
the type-generic generator: the templates are pure token substitution, so a
per-type baseline can only fail where `int4`'s already would. Drift protection
for a new type comes from the `int4` reference (shared templates + `Term` enum),
the catalog `values_tests` pinning the materialised `<T>_VALUES`, the
catalog/generator `#[test]`s, and the `ordered_numeric_matrix!` SQLx suite
(behaviour, not bytes).

---

## 5. The generated surface — what correct output looks like

This is the contract the generated SQL satisfies. You normally never read it to
*add* a type — read it when a test fails or you're extending the surface.

### Domains and CHECK constraints

The generator emits `src/v3/scalars/<T>/<T>_types.sql` (gitignored;
materialised on every build) with one idempotent `DO $$ ... $$` block. Every
domain is a concrete domain over `jsonb` in the `eql_v3` schema — **never**
`CREATE DOMAIN a AS b` over another generated domain (PostgreSQL resolves
operators against the underlying base type, bypassing the fixed surface). Each
domain's `CHECK` requires:

- fixed envelope keys `v` and `i`;
- ciphertext key `c`;
- catalog JSON keys for the listed terms;
- the envelope version value `VALUE->>'v' = '2'`, matching the repo-wide
  `eql_v2._encrypted_check_v` rule (`src/encrypted/constraints.sql`).

So a domain with `&[Term::Ore]` requires `v`, `i`, `c`, and `ob` present, with
`v` pinned to `2`. Beyond key presence and the version value, a malformed term
can still fail later inside its extractor.

### Extractors, wrappers, and blockers

Extractor names and return types come from the `Term` enum. Generated extractors
and supported comparison wrappers are inline-friendly SQL functions:

```sql
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT ... $$;
```

They must **not** carry a pinned `search_path` — a `SET` clause disables
inlining and reverts index-backed queries to seq scans. The build tooling
recognises these functions structurally, so the generator emits no
`eql-inline-critical` markers. (Aggregate state functions are the one deliberate
exception — see below.)

Unsupported operators route to **blockers**, which are `LANGUAGE plpgsql`,
`IMMUTABLE`, `PARALLEL SAFE`, and intentionally **not `STRICT`**:

- **`plpgsql`, not `sql`.** A `LANGUAGE sql` body is inlinable, and the planner
  could elide the call when the result is provably unused (dead `CASE` branch,
  folded predicate), letting a blocked operator appear to succeed. `plpgsql` is
  opaque to the planner, so the call — and its `RAISE` — always survives.
- **Not `STRICT`.** A `STRICT` blocker lets PostgreSQL skip the body and return
  `NULL` on a `NULL` argument, silently bypassing the unsupported-operator
  exception.

### Operators

Every generated domain declares supported scalar comparison operators plus
blockers for the native `jsonb` operator surface PostgreSQL could otherwise
reach through domain-to-base-type fallback. The surface is a fixed 20 operators
(`crates/eql-codegen/src/operator_surface.rs`, `OPERATORS`), each with its
PostgreSQL-shaped signatures, summing to **44 `CREATE OPERATOR` statements per
domain**:

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

Whether an operator routes to a wrapper or a blocker is a per-domain decision
driven by the domain's terms (`Term::operators_for_terms`), not a property of
the operator. Supported operators are emitted with full planner metadata
(`COMMUTATOR`, `NEGATOR`, `RESTRICT`, `JOIN` selectivity estimators) backing
onto inlinable wrappers; everything else carries minimal metadata backing onto
blockers. Path operators always back onto blockers — neither current term
enables them — and the native `jsonb` operators are blocker-only.

The wrapper/blocker split per domain (the 44-operator total never moves):

| Domain terms     | Extractors | Wrappers | Blockers | Functions | Operators |
| ---------------- | ---------: | -------: | -------: | --------: | --------: |
| none             |          0 |        0 |       44 |        44 |        44 |
| `&[Term::Hm]`    |          1 (`eq_term`)  |  6 | 38 | 45 | 44 |
| `&[Term::Ore]`   |          1 (`ord_term`) | 18 | 26 | 45 | 44 |

Six wrappers for `Hm` = `=` and `<>` × three shapes; eighteen for `Ore` = six
operators × three shapes.

**Untyped-literal resolver edge.** PostgreSQL's operator resolver still prefers
the built-in `jsonb` operator for untyped string literals in forms such as
`payload::eql_v3.int4 ? 'c'`. Use typed parameters or explicit casts
(`? 'c'::text`, bound text parameters) to route those forms to the generated
blocker. A live-DB structural guard
(`tests/sqlx/tests/encrypted_domain/family/jsonb_operator_surface.rs`) queries
`pg_operator` for every operator with a `jsonb` argument and asserts the set is
a subset of the enumerated surface, so a future PostgreSQL version that adds a
`jsonb` operator nobody enumerated fails the test rather than silently routing an
encrypted column to native plaintext-`jsonb` semantics.

### Aggregates

Each ordered (ord-capable) domain additionally gets a generated
`<domain>_aggregates.sql`: two state functions (`eql_v3.min_sfunc`,
`eql_v3.max_sfunc`) and two aggregates (`eql_v3.min(<domain>)`,
`eql_v3.max(<domain>)`). Comparison routes through the domain's `<` / `>`
operator (the ORE block term — no decryption). The state functions are `LANGUAGE
plpgsql IMMUTABLE STRICT PARALLEL SAFE` **with** a pinned `SET search_path` —
the one place the "no pinned `search_path`" rule does not apply, because
aggregate transition functions are never index expressions. `STRICT` makes
PostgreSQL seed the running state with the first non-NULL value and skip NULLs,
so an all-NULL group returns NULL. Each `CREATE AGGREGATE` declares
`combinefunc = <sfunc>` and `parallel = safe`: min/max are associative, so the
state function doubles as the combine function, enabling partial and parallel
aggregation on large `GROUP BY` ORE workloads with no decryption. Storage-only
and equality-only domains have no comparator and emit no aggregate file.

### Indexing

Do not create operator classes on generated domains. Index through the
extractor, whose return type already carries a default opclass:

```sql
CREATE INDEX ... ON table_name USING btree (eql_v3.ord_term(col));
CREATE INDEX ... ON table_name USING hash  (eql_v3.eq_term(col));
```

`ore` depends on `src/v3/sem/ore_block_u64_8_256/functions.sql` and
`src/v3/sem/ore_block_u64_8_256/operators.sql`; `hm` depends on
`src/v3/sem/hmac_256/functions.sql`.

### Extension files

Optional hand-written SQL beyond the fixed surface belongs in
`src/v3/scalars/<T>/<T>_extensions.sql`. The generator never creates,
lists, headers, or cleans it; it must declare its own `-- REQUIRE:` edges
(usually to `<T>_types.sql` and whichever generated function or operator file it
extends). Use it for cross-domain casts, helper functions, or type-specific
constraints. Unlike the generated siblings, **`<T>_extensions.sql` IS
committed.** (Neither `int4` nor `int2` ships one today.)

`tasks/pin_search_path.sql` describes the fallback marker for inline-critical
extension functions that take no domain argument and so escape the structural
skip:

```sql
COMMENT ON FUNCTION eql_v2.my_helper(...) IS 'eql-inline-critical: ...';
```

The generator never emits this marker; every function it produces takes a domain
argument and is covered by the structural skip intrinsically.

### Invariants the generator enforces

The generator's job is partly to write SQL and partly to make incorrect SQL
unreachable. Invariants encoded in the renderers / templates and guarded by
`#[test]`s in `crates/eql-codegen/src/generate.rs`:

- **Blockers are never `STRICT` and always `plpgsql`** — the
  unsupported-operator template emits each blocker as `IMMUTABLE PARALLEL SAFE` /
  `LANGUAGE plpgsql` without `STRICT`
  (`blockers_are_never_strict_and_always_plpgsql`).
- **Wrappers and extractors are inlinable SQL** — `LANGUAGE sql IMMUTABLE STRICT
  PARALLEL SAFE`, single-statement `SELECT`, no `SET search_path`
  (`inlinable_functions_have_no_set_search_path`).
- **Aggregate state functions are the deliberate exception** — `plpgsql` *with*
  a pinned `SET search_path` (`aggregate_state_functions_are_plpgsql_not_inlinable`).
- **SQL-literal injection is structurally prevented** — every interpolated
  single-quoted literal passes through `sql_str`
  (`crates/eql-codegen/src/consts.rs`), which doubles embedded single quotes.
- **No domain-over-domain** — every domain is `CREATE DOMAIN eql_v3.<name> AS
  jsonb` (`types_file_has_all_four_domains`).
- **No operator class on a domain** — the generator emits operators, not
  operator classes.
- **Ownership boundary** — `is_generated` recognises owned files by their header
  marker; `ensure_generated_paths_writable` refuses to overwrite anything else,
  and `clean_generated_files` deletes only marked files
  (`crates/eql-codegen/src/writer.rs`). A hand-written file at a generated path
  is a hard error, not a silent clobber.

### Lint and test integration

Two pieces of build tooling recognise the generated output without per-type
edits:

- **`tasks/pin_search_path.sql`** — structural skip identifies encrypted-domain
  functions by language (`sql`), volatility (`IMMUTABLE`), and a jsonb-backed
  `DOMAIN` argument in the `eql_v3` schema. New scalar types need no edit.
- **`tasks/test/splinter.sh`** — name-based allowlist. The converged wrapper /
  extractor names (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `eq_term`, `ord_term`)
  plus the generated `min` / `max` aggregates are already covered by
  `eql_v3`-schema entries. A new scalar type inherits coverage; **only a new
  term whose extractor has a new name requires a splinter entry.**

---

## 6. Generator internals — the machine

You need this section only when **modifying the generator itself**, not when
adding a type.

### Why a generator

A single scalar type emits several hundred SQL declarations across eleven files:
four domains, three extractors, dozens of wrappers and blockers, 176 `CREATE
OPERATOR` statements (44 per domain), and MIN/MAX aggregates per ordered domain.
The shape is mechanical and the invariants are unforgiving — a `STRICT` blocker
silently bypasses its exception; a pinned `search_path` reverts queries to seq
scans. The generator exists so each new type adds one `CATALOG` row rather than
ninety hand-written declarations that must agree with each other and with
`pin_search_path.sql`, `tasks/test/splinter.sh`, and
`src/v3/scalars/functions.sql`.

### Pipeline

`eql-codegen` is a small Rust crate with a binary entry point. The generator
runs as `cargo run -p eql-codegen` (no subcommand), which calls
`generate::generate_all` (`crates/eql-codegen/src/generate.rs`) over every row of
`eql_scalars::CATALOG`, writing each type's SQL into
`src/v3/scalars/<token>/`. A second subcommand, `cargo run -p eql-codegen
-- list-types`, prints the catalog tokens one per line (consumed by the fixture
and matrix-inventory enumeration). `main` (`crates/eql-codegen/src/main.rs`)
recognises exactly these two forms; any other argument is a usage error.

The generator targets the `eql_v3` schema throughout: `CORE_SCHEMA = "eql_v3"`
(`crates/eql-codegen/src/consts.rs`) qualifies both the domain families and the
SEM index-term types the extractors return (`eql_v3.hmac_256`,
`eql_v3.ore_block_u64_8_256`), so no generated SQL references `eql_v2`.

`tasks/build.sh` runs `cargo run -p eql-codegen` at the start of every `mise run
build`, so the generated SQL is never checked in. (The build first sweeps every
generated `*_{types,functions,operators,aggregates}.sql` under
`src/v3/scalars` so a type removed from `CATALOG` cannot leave orphans the
`src/**/*.sql` build glob would pick up; hand-written `*_extensions.sql` is
preserved by the name patterns.)

Stages, in order (`generate_all` → `generate_type`):

1. **Read the catalog.** `eql_scalars::CATALOG` is the in-binary source of truth
   — a `&[ScalarSpec]`. There is no parse/validate stage at generation time: the
   catalog is validated at compile time (an undefined `Term` or unknown
   `ScalarKind` does not compile) and by the catalog `#[test]`s, so the data is
   already well-formed by the time `generate_all` runs.
2. **Resolve terms.** For each `DomainSpec`, the `Term` enum's `impl` methods
   supply the extractor name, return type, JSON envelope key, supported
   operators, and the SQL `-- REQUIRE:` edges those terms imply
   (`Term::operators_for_terms`, `term_json_keys`, `term_requires`,
   `extractor_for_operator`, `role_for_terms`).
3. **Render.** `render_types_file`, `render_functions_file`,
   `render_operators_file`, and `render_aggregates_file` (the last only for
   ordered domains) build the context structs in
   `crates/eql-codegen/src/context.rs` and render them through embedded
   **minijinja** templates (`crates/eql-codegen/templates/*.j2`, compiled in via
   `include_str!` — no runtime file IO). The structural shape of each declaration
   is split between the context builders (Rust) and the templates (Jinja).
4. **Write.** `clean_generated_files` first deletes every generated `.sql` in the
   target directory (recognised by the header marker) so an abandoned domain
   disappears on the next regeneration; `ensure_generated_paths_writable` then
   refuses to proceed if any target path is a hand-written file lacking the
   marker; `write_generated_file` writes each rendered body verbatim
   (`crates/eql-codegen/src/writer.rs`). The template emits the `-- AUTOMATICALLY
   GENERATED FILE.` marker as its own first line, so the writer does not prepend
   a header — it only uses the marker to recognise files it owns.

There is no caching layer and no incremental mode. Each run regenerates every
output for every catalog type from scratch.

### Generated outputs

For a type with `D` domains of which `A` are ordered, the generator writes `1 +
2D + A` SQL files into `src/v3/scalars/<token>/`. For `int4` (`D = 4`, `A =
2`): eleven SQL files. The outputs are gitignored
(`.gitignore` excludes `src/v3/scalars/*/*_{types,functions,operators,aggregates}.sql`)
and regenerated at the start of every build.

| File                              | Content                                                                                  |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| `<token>_types.sql`               | Single idempotent `DO` block creating every domain; each `CHECK` pins the payload version (`VALUE->>'v' = '2'`) and required envelope/ciphertext/term keys; one `--! @brief` per domain |
| `<domain>_functions.sql`          | One extractor per unique term, then 44 wrappers-or-blockers covering the surface         |
| `<domain>_operators.sql`          | 44 `CREATE OPERATOR` statements with planner metadata on supported ops                   |
| `<domain>_aggregates.sql`         | MIN/MAX state functions + `CREATE AGGREGATE`; emitted only for ordered domains           |

Every file opens with the `-- AUTOMATICALLY GENERATED FILE.` marker (the
project-wide marker `docs:validate` greps on to skip generated SQL —
`crates/eql-codegen/src/consts.rs`), declares its `-- REQUIRE:` edges in
dependency order (types files require `src/v3/schema.sql`; function files require
`src/v3/schema.sql`, the types file, and
`src/v3/scalars/functions.sql` plus each term's `requires` set; operator
files require `src/v3/schema.sql`, the types file, and their domain's function
file; aggregate files require `src/v3/schema.sql`, the types file, and their
domain's function and operator files), and carries Doxygen `--! @file` /
`--! @brief` headers.

### Generator tests and the parity gate

The generator's tests are Rust, run by `mise run test:codegen` (`cargo test -p
eql-scalars -p eql-codegen`) — no database. `mise run test:crates` adds `cargo
clippy ... -D warnings`.

- **`eql-scalars` unit tests** — `rust_tests`, `term_tests`,
  `term_helper_tests`, `fixture_tests`, `catalog_tests`, `invariant_tests`,
  `values_tests` over `CATALOG`, the `Term` / `ScalarKind` / `Fixture` impls, and
  the materialised `<T>_VALUES` consts.
- **`eql-codegen` unit tests** — file counts, language/volatility invariants,
  escaping guards, and twin byte-identity
  (`crates/eql-codegen/src/generate.rs` `#[cfg(test)]`).
- **The parity gate** — `mise run codegen:parity` (`tasks/codegen-parity.sh`).
  It runs the generator into the real tree, then (1) compares the int4 generated
  SQL **file set** against the golden under `tests/codegen/reference/int4/*.sql`,
  excluding committed hand-written files (`comm -23` of `ls` against `git
  ls-files`), so an extra or dropped generated file fails; and (2) diffs each
  golden file **byte-for-byte** against its generated counterpart, after dropping
  the golden's single leading `-- REFERENCE:` provenance line (`tail -n +2`). The
  same byte-for-byte assertion runs in-crate as
  `crates/eql-codegen/tests/parity.rs`
  (`rust_generator_matches_int4_golden_files`). The golden reference — not any
  Python oracle — is the sole contract that survives generator refactors.

CI runs these in three jobs in `.github/workflows/test-eql.yml`: `rust-crates`
(`Rust workspace crates`, runs `mise run test:crates`), `codegen`
(`Encrypted-domain codegen`, runs `mise run codegen:parity`), and
`matrix-coverage` (`Matrix coverage inventory`, runs `mise run
test:matrix:inventory`). The codegen job is a prerequisite of the PostgreSQL
test matrix.

Adding a new **term** is a bigger move than adding a type: edit the `Term` enum's
`impl` methods, add `#[test]`s, audit `splinter.sh` for a name collision if the
extractor name is new, and — because it changes the int4 surface — update the
golden reference under `tests/codegen/reference/int4/`.

---

## 7. Out of scope — `text` and `jsonb`

`text` and `jsonb` are **not** materialised through this generator. The
`ScalarKind` enum carries `Text` / `Numeric` / `Jsonb` variants and the
`Fixture` enum carries their string-backed shapes at the capability layer, but
`CATALOG` declares only the ordered scalars today — the fixed-width integers
(`int2` / `int4` / `int8`) and the temporal `date` — so no `text` / `jsonb` SQL
surface is generated. Text and JSONB encrypted behaviour lives on the composite
`eql_v2_encrypted` type and its hand-written operator surface in `src/encrypted/`
and `src/operators/`, not the scalar materializer. `jsonb` in particular needs a
separate SQL design beyond this ordered-scalar materializer.
