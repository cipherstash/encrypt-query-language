# Encrypted-Domain Code Generator

How the Rust `eql-codegen` crate turns the `eql-scalars` catalog into the
SQL surface for a scalar encrypted-domain type. This document describes
the generator itself — its inputs, stages, outputs, and the invariants it
enforces. The contract those outputs must satisfy is in
[`encrypted-domain-implementation-spec.md`](./encrypted-domain-implementation-spec.md);
this file describes the machine that produces them.

The reference type is `eql_v3.int4`. `text` and `jsonb` are outside scope.

The generator is **Rust, not Python**. There is no TOML manifest, no
`tasks/codegen/` package, no `terms.py`/`templates.py`/`spec.py`. The
source of truth is the `CATALOG` const in
[`crates/eql-scalars/src/lib.rs`](../../crates/eql-scalars/src/lib.rs);
the renderers live in [`crates/eql-codegen/`](../../crates/eql-codegen/).
Adding a scalar type is adding a `ScalarSpec` row to `CATALOG`, validated
by the compiler plus catalog `#[test]`s — never an edit to free-form
manifest data.

## 1. Why a generator

A single scalar encrypted-domain type emits several hundred SQL
declarations across eleven files: four domains, three extractors, dozens
of comparison wrappers and blockers, 176 `CREATE OPERATOR` statements (44
per domain), and MIN/MAX aggregates for every ordered domain. The shape
is mechanical and the invariants are unforgiving — a `STRICT` blocker
silently bypasses its exception, a pinned `search_path` disables inlining
and reverts queries to seq scans. The generator exists so each new scalar
type adds one `CATALOG` row rather than ninety hand-written declarations
that must agree with each other and with `pin_search_path.sql`,
`tasks/test/splinter.sh`, and `src/encrypted_domain/functions.sql`.

## 2. Pipeline

`eql-codegen` is a small Rust crate with a binary entry point. The
generator runs as `cargo run -p eql-codegen` (no subcommand), which calls
`generate::generate_all` (`crates/eql-codegen/src/generate.rs`) over every
row of `eql_scalars::CATALOG`, writing each type's SQL into
`src/encrypted_domain/<token>/`. A second subcommand,
`cargo run -p eql-codegen -- list-types`, prints the catalog tokens one per
line (consumed by the fixture and matrix-inventory enumeration). The
binary's `main` (`crates/eql-codegen/src/main.rs`) recognises exactly these
two forms; any other argument is a usage error.

`tasks/build.sh` runs `cargo run -p eql-codegen` at the start of every
`mise run build`, so the generated SQL is never checked in — the catalog
is the source of truth. (The build first sweeps every generated
`*_{types,functions,operators,aggregates}.sql` under `src/encrypted_domain`
so a type removed from `CATALOG` cannot leave orphans the `src/**/*.sql`
build glob would pick up; hand-written `*_extensions.sql` is preserved by
the name patterns.)

Stages, in order (`generate_all` → `generate_type`):

1. **Read the catalog.** `eql_scalars::CATALOG` is the in-binary source of
   truth — a `&[ScalarSpec]`, each row a `token`, a `ScalarKind`, an
   ordered `&[DomainSpec]`, and a `&[Fixture]` list
   (`crates/eql-scalars/src/lib.rs`). There is no parse/validate stage at
   generation time: the catalog is validated at compile time (an undefined
   `Term` or unknown `ScalarKind` does not compile) and by the catalog
   `#[test]`s, so by the time `generate_all` runs the data is already
   well-formed.
2. **Resolve terms.** For each `DomainSpec`, the `Term` enum's `impl`
   methods supply the extractor name, return type, JSON envelope key,
   supported operators, and the SQL `-- REQUIRE:` edges those terms imply
   (`Term::operators_for_terms`, `term_json_keys`, `term_requires`,
   `extractor_for_operator`, `role_for_terms` — `crates/eql-scalars/src/lib.rs`).
3. **Render.** `render_types_file`, `render_functions_file`,
   `render_operators_file`, and `render_aggregates_file` (the last only for
   ordered domains) build the context structs in
   `crates/eql-codegen/src/context.rs` and render them through embedded
   **minijinja** templates (`crates/eql-codegen/templates/*.j2`,
   compiled in via `include_str!` — no runtime file IO). The structural
   shape of each declaration is split between the context builders (Rust)
   and the templates (Jinja).
4. **Write.** `clean_generated_files` first deletes every generated `.sql`
   in the target directory (recognised by the header marker) so an
   abandoned domain disappears on the next regeneration;
   `ensure_generated_paths_writable` then refuses to proceed if any target
   path is a hand-written file lacking the marker; `write_generated_file`
   writes each rendered body verbatim (`crates/eql-codegen/src/writer.rs`).
   The template emits the `-- AUTOMATICALLY GENERATED FILE.` marker as its
   own first line, so the writer does not prepend a header — it only uses
   the marker to recognise files it owns.

There is no caching layer and no incremental mode. Each `cargo run -p
eql-codegen` regenerates every output for every catalog type from scratch.
Regeneration is deterministic: identical catalog + renderers produce
byte-identical SQL.

## 3. Catalog format

A scalar type is one `ScalarSpec` row
(`crates/eql-scalars/src/lib.rs`):

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

Structural rules, enforced by the type system and the catalog `#[test]`s
rather than a runtime validator:

- `token` supplies the **type token** (`int4` here). Each domain's full
  name is `token` + `suffix`; `ScalarSpec::domain_name` makes the old
  "domain name must start with the token" rule structural, and
  `every_domain_name_starts_with_its_token` pins it.
- `kind` is a `ScalarKind` (`I16` / `I32` / `I64` / `Numeric` / `Text` /
  `Jsonb`), which carries the Rust type name, the `MIN`/`MAX`/zero symbols,
  and the numeric bounds. Only the integer kinds have an i128 range with
  `Min`/`Max`/`Zero` sentinels; the bounded accessors `panic!` on the
  others (a misuse guard, gated by `is_int()`).
- `domains` is a non-empty `&[DomainSpec]` (pinned by
  `every_type_has_at_least_one_domain`). Each `DomainSpec` is a `suffix`
  plus a `&[Term]`; the storage domain is `suffix: ""` with no terms.
- `fixtures` is a `&[Fixture]` (see §3a).

The `DomainSpec` declares nothing else — no extractor names, no operator
lists, no REQUIRE edges. Every behavioural fact comes from the `Term`
enum.

Domains may be **twinned** (`int4_ord` and `int4_ord_ore` both carry
`&[Term::Ore]`). The generator emits them as independent domains with
byte-identical SQL modulo type name (`ordered_files_byte_identical_modulo_typename`).
Twins exist so callers can choose a name that documents intent ("ordered,
regardless of mechanism" vs "ordered via ORE block") without committing to
one term family in a future migration.

Catalog order is significant. The generator iterates `CATALOG` in order
(driving generation order), and iterates each spec's `domains` slice in
order — that order shows up in the generated `<token>_types.sql` `DO` block.

### 3a. The `fixtures` field

The `fixtures` field is an ordered `&[Fixture]` — the single source of
truth for the type's plaintext fixture list, consumed by the SQLx fixture
generator and the matrix oracle. A `Fixture` is value-kind tagged:
`Min` / `Max` / `Zero` (the integer matrix pivots, resolved per-kind),
`Int(i128)` (an integer literal), and `Numeric`/`Text`/`Jsonb` string
variants. The `fixtures!` macro range-checks each `Int` literal against the
kind at compile time (`N(-40000)` for an `i16` kind does not compile):

```rust
const INT4_FIXTURES: &[Fixture] = fixtures!(int i32;
    Min, N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17), N(25),
    N(42), N(50), N(100), N(250), N(1000), N(9999), Max);
```

Catalog `#[test]`s enforce a **distinct-plaintext contract** plus the
matrix-pivot requirement: `fixture_values_are_distinct_by_resolved_number`
rejects duplicates against the resolved value (so both copy-paste dups and
sentinel/literal aliases fail), `fixtures_include_min_max_and_zero` requires
`Min`, `Max`, and zero for integer kinds, and
`every_fixture_value_is_within_kind_bounds` keeps every resolved value in
range. These are the compile/test-time analogue of the old `load_spec`
validation.

The plaintext value list is **not** rendered to a generated file. The
`int_values!` macro (next to `CATALOG`) materialises a `Fixture` list into
a typed `pub const <T_UPPER>_VALUES: &[<rust_type>]` at compile time
(`INT4_VALUES`, `INT2_VALUES`). Both consumers reference that single symbol
— the fixture generator and the matrix oracle's `FIXTURE_VALUES` — so the
oracle cannot drift from the values the generator encrypts. There is no
committed `<token>_values.rs`: a Rust source of truth does not round-trip
through generated Rust. (The old generated, committed file is gone.) The
exact materialised list is pinned by the catalog's `values_tests`.

## 4. Term catalog

The `Term` enum (`crates/eql-scalars/src/lib.rs`) defines every term the
materializer recognises. The `json_key`/`extractor`/`returns`/`ctor`
values are the cross-schema SQL contract — changing one is a generated-SQL
behaviour change, not a refactor.

| Term  | JSON key | Extractor   | Returns                          | Operators                  |
| ----- | -------- | ----------- | -------------------------------- | -------------------------- |
| `Hm`  | `hm`     | `eq_term`   | `eql_v2.hmac_256`                | `=` `<>`                   |
| `Ore` | `ob`     | `ord_term`  | `eql_v2.ore_block_u64_8_256`     | `=` `<>` `<` `<=` `>` `>=` |

The index-term return types (`eql_v2.hmac_256`,
`eql_v2.ore_block_u64_8_256`) live in `eql_v2` and are referenced
cross-schema; the domains, extractors, and wrappers live in `eql_v3`.

Adding a term is a code change to the `Term` enum's `impl` methods
(`json_key`, `extractor`, `returns`, `ctor`, `role`, `operators`,
`requires`) with matching `#[test]`s (`term_tests` / `term_helper_tests`)
— never a free-form catalog field. The `Term` enum is the only source of
operator support, extractor identity, and REQUIRE edges; a `DomainSpec` is
a thin selector over it.

## 5. The operator surface

`crates/eql-codegen/src/operator_surface.rs` enumerates the 20-operator
surface every generated domain declares (`OPERATORS`):

- **Comparison operators**: `=` `<>` `<` `<=` `>` `>=` `@>` `<@`
- **Path-selector operators**: `->` `->>`
- **Native `jsonb` operators**: `?` `?|` `?&` `@?` `@@` `#>` `#>>` `-` `#-` `||`

Each operator carries its PostgreSQL-shaped signatures. The comparison
operators use the three symmetric shapes — `(domain, domain)`,
`(domain, jsonb)`, `(jsonb, domain)`; the path and native operators use
only the shapes PostgreSQL exposes for `jsonb` itself. Summed across all
20 operators, that is **44 `CREATE OPERATOR` statements per domain**
(`operators_file_has_forty_four`).

Whether an operator routes to a wrapper or a blocker is a per-domain
decision driven by the domain's terms (`Term::operators_for_terms`), not a
property of the operator. Supported operators are emitted with full planner
metadata (`COMMUTATOR`, `NEGATOR`, `RESTRICT`, `JOIN` selectivity
estimators) and back onto inlinable wrappers; unsupported operators carry
minimal metadata and back onto blockers (`operator_entry` only renders
metadata when the operator is supported on that domain).

Path operators always back onto blockers — neither current term enables
them. The native `jsonb` operators are blocker-only. Untyped string
literals are a PostgreSQL resolver edge: `? 'c'` can still select the
built-in `jsonb` operator, while `? 'c'::text` and bound text parameters
select the generated blocker.

A live-DB structural guard
(`tests/sqlx/tests/encrypted_domain/family/jsonb_operator_surface.rs`)
queries `pg_operator` for every operator with a `jsonb` argument and
asserts the set is a subset of the surface this module enumerates, so a
future PostgreSQL version that adds a `jsonb` operator nobody enumerated
here fails the test rather than silently routing an encrypted column to
native plaintext-`jsonb` semantics. The `operator_surface` unit tests pin
the Rust surface (20 operators, signatures, metadata); the live-DB test
mirrors it.

## 6. Generated outputs

For a type with `D` domains of which `A` are ordered (ord-capable), the
generator writes `1 + 2D + A` SQL files into
`src/encrypted_domain/<token>/`. For `int4` (`D = 4`, `A = 2`): eleven SQL
files. The SQL outputs are **gitignored** —
`.gitignore` excludes `src/encrypted_domain/*/*_{types,functions,operators,aggregates}.sql`,
and `tasks/build.sh` regenerates them at the start of every build. There is
**no per-type codegen task**: one `cargo run -p eql-codegen` regenerates
every catalog type in a single deterministic run.

| File                              | Content                                                                                  |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| `<token>_types.sql`               | Single idempotent `DO` block creating every domain; each domain `CHECK` pins the payload version (`VALUE->>'v' = '2'`) and required envelope/ciphertext/term keys; one `--! @brief` per domain |
| `<domain>_functions.sql`          | One extractor per unique term, then 44 wrappers-or-blockers covering the surface         |
| `<domain>_operators.sql`          | 44 `CREATE OPERATOR` statements with planner metadata on supported ops                   |
| `<domain>_aggregates.sql`         | MIN/MAX state functions + `CREATE AGGREGATE`; emitted only for ordered (ord-capable) domains |

Every file:

- Opens with the `-- AUTOMATICALLY GENERATED FILE.` marker (the project-wide
  marker `docs:validate` greps on to skip generated SQL —
  `crates/eql-codegen/src/consts.rs`).
- Declares its `-- REQUIRE:` edges in dependency order — types files
  require `src/schema-v3.sql`; function files require schema, types, and
  `src/encrypted_domain/functions.sql` plus each term's `requires` set;
  operator files require `src/schema-v3.sql`, types, and their domain's
  function file; aggregate files require `src/schema-v3.sql`, types, and
  their domain's function and operator files.
- Carries Doxygen `--! @file` / `--! @brief` headers describing its role.

### Function-count totals per domain

| Domain terms     | Extractors | Wrappers | Blockers | Functions | Operators |
| ---------------- | ---------: | -------: | -------: | --------: | --------: |
| none             |          0 |        0 |       44 |        44 |        44 |
| `&[Term::Hm]`    |          1 |        6 |       38 |        45 |        44 |
| `&[Term::Ore]`   |          1 |       18 |       26 |        45 |        44 |

Six wrappers for `Hm` = `=` and `<>` × three shapes. Eighteen for `Ore`
= six operators × three shapes. The 44-operator total never moves; the
wrapper/blocker split is what shifts, and native `jsonb` fallback
operators are always blockers. (Pinned by `storage_functions_file_is_all_blockers`,
`eq_functions_file_counts`, `ore_functions_file_counts`.)

The table above covers `<domain>_functions.sql` only. Ordered domains
additionally emit `<domain>_aggregates.sql` — two state functions
(`min_sfunc`, `max_sfunc`) and two `CREATE AGGREGATE` declarations
(`eql_v3.min`, `eql_v3.max`). Each aggregate declares
`combinefunc = <sfunc>` and `parallel = safe`: min/max are associative, so
the state function doubles as the combine function, enabling partial and
parallel aggregation on large `GROUP BY` ORE workloads with no decryption.

## 7. Invariants the generator enforces

The generator's job is partly to write SQL and partly to make incorrect
SQL unreachable. Invariants encoded in the renderers / templates and
guarded by `#[test]`s in `crates/eql-codegen/src/generate.rs`:

- **Blockers are never `STRICT` and always `plpgsql`.** The
  unsupported-operator template emits each blocker as `IMMUTABLE PARALLEL
  SAFE` / `LANGUAGE plpgsql` without `STRICT`, so a `NULL` argument still
  reaches the `RAISE`. `blockers_are_never_strict_and_always_plpgsql`
  asserts the storage domain (all blockers) contains no `STRICT` and as
  many `LANGUAGE plpgsql` as `CREATE FUNCTION`. A `LANGUAGE sql` blocker
  would be inlinable and could be elided when the result is provably
  unused; `plpgsql` is opaque to the planner so the `RAISE` survives.
- **Wrappers and extractors are inlinable SQL.** They emit `LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE` with a single-statement `SELECT` and **no
  `SET search_path`** (`inlinable_functions_have_no_set_search_path`). A
  pinned `search_path` disables inlining. `tasks/pin_search_path.sql`
  recognises these functions structurally — by language (`sql`), volatility
  (`IMMUTABLE`), and a jsonb-backed `DOMAIN` argument in the `eql_v3`
  schema — and leaves them unpinned, with no per-type edit.
- **Aggregate state functions are the deliberate exception.** `min_sfunc` /
  `max_sfunc` are `LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE` *with*
  a pinned `SET search_path` (`aggregate_state_functions_are_plpgsql_not_inlinable`).
  They are aggregate transition functions, not index expressions, so
  pinning is correct; the generated `min` / `max` aggregates are
  allowlisted by name in `splinter.sh`.
- **SQL-literal injection is structurally prevented.** Every string
  interpolated into a single-quoted SQL literal — payload keys, operator
  symbols, domain names in `RAISE` messages — passes through `sql_str`
  (`crates/eql-codegen/src/consts.rs`), which doubles embedded single
  quotes. Today's catalog strings are all quote-free so it is a no-op, but
  it guarantees a future quote-bearing string cannot break out of its
  literal (`unsupported_entry_preserves_operator_literal_and_domain_lit_is_escaped`,
  `domain_block_escapes_quote_bearing_name`).
- **No domain-over-domain.** Every domain is `CREATE DOMAIN eql_v3.<name>
  AS jsonb`, never `AS <some_other_domain>` (`types_file_has_all_four_domains`).
  PostgreSQL resolves operators against the underlying base type; a derived
  domain would silently bypass the fixed operator surface.
- **No operator class on a domain.** The generator emits operators, not
  operator classes. Callers index through the extractor function (e.g.
  `USING btree (eql_v3.ord_term(col))`), whose return type already carries
  a default opclass.
- **Ownership boundary.** `is_generated` recognises owned files by their
  header marker; `ensure_generated_paths_writable` refuses to overwrite
  anything else, and `clean_generated_files` deletes only files carrying
  the marker (`crates/eql-codegen/src/writer.rs`). A hand-written file at a
  generated path is a hard error, not a silent clobber. Stale generated
  files for removed domains are cleaned before the new files land.

## 8. Extension files

`<token>_extensions.sql` is the hand-written sibling. The generator never
creates, lists, or cleans it; it has no auto-generated header and must
declare its own `-- REQUIRE:` edges. Use it for behaviour that's specific
to the type and not part of the fixed surface — e.g. cross-domain casts,
helper functions, type-specific constraints. Unlike the generated
siblings, `<token>_extensions.sql` IS committed. (Neither `int4` nor `int2`
ships one today — there is no committed `*_extensions.sql` in the tree.)

`tasks/pin_search_path.sql` describes the fallback marker for
inline-critical extension functions that take no domain argument and so
escape the structural skip:

```sql
COMMENT ON FUNCTION eql_v2.my_helper(...) IS 'eql-inline-critical: ...';
```

The generator does **not** emit this marker; every function it produces
takes a domain argument and is covered by the structural skip
intrinsically.

## 9. Lint and test integration

The generator depends on two pieces of build tooling recognising its
output without per-type edits:

- **`tasks/pin_search_path.sql`** — structural skip identifies
  encrypted-domain functions by language (`sql`), volatility (`IMMUTABLE`),
  and the presence of at least one argument typed as a jsonb-backed
  `DOMAIN` in the `eql_v3` schema. New scalar types need no edit here.
- **`tasks/test/splinter.sh`** — name-based allowlist. The converged
  wrapper / extractor names (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`,
  `eq_term`, `ord_term`) plus the generated `min` / `max` aggregates are
  covered by `eql_v3`-schema entries. Splinter matches by name only, so a
  new scalar type that uses the catalog extractors inherits coverage.
  Adding a new term whose extractor has a new name requires a splinter
  entry.

## 10. Tests

The generator's tests are Rust, run by `mise run test:codegen`
(`cargo test -p eql-scalars -p eql-codegen`) — no database required. The
broader `mise run test:crates` adds `cargo clippy ... -D warnings`.

- **`eql-scalars` unit tests** — `rust_tests`, `term_tests`,
  `term_helper_tests`, `fixture_tests`, `catalog_tests`, `invariant_tests`,
  `values_tests` over `CATALOG`, the `Term`/`ScalarKind`/`Fixture` impls,
  and the materialised `<T>_VALUES` consts
  (`crates/eql-scalars/src/lib.rs`).
- **`eql-codegen` unit tests** — file counts, language/volatility
  invariants, escaping guards, and twin byte-identity
  (`crates/eql-codegen/src/generate.rs` `#[cfg(test)]` module).
- **The parity gate** — `mise run codegen:parity`
  (`tasks/codegen-parity.sh`). It runs `cargo run -p eql-codegen` into the
  real tree, then:
  1. compares the int4 generated SQL **file set** against the golden under
     `tests/codegen/reference/int4/*.sql`, excluding committed hand-written
     files (`comm -23` of `ls` against `git ls-files`), so an extra or
     dropped generated file fails; and
  2. diffs each golden file **byte-for-byte** against its generated
     counterpart, after dropping the golden's single leading
     `-- REFERENCE:` provenance line (`tail -n +2`). Both bodies start with
     the `-- AUTOMATICALLY GENERATED FILE.` marker, so no header strip is
     needed.
  The same byte-for-byte assertion runs in-crate as
  `crates/eql-codegen/tests/parity.rs` (`rust_generator_matches_int4_golden_files`)
  and in the `generate.rs` golden tests. The golden reference — not any
  Python oracle — is the sole contract that survives generator refactors.

CI runs these in three jobs in `.github/workflows/test-eql.yml`: the
`test:crates` job (`Rust workspace crates`) compiles/lints/tests the
crates, the `codegen` job (`Encrypted-domain codegen`) runs `mise run
codegen:parity`, and the `matrix-coverage` job runs `mise run
test:matrix:inventory`. The codegen job is a prerequisite of the
PostgreSQL test matrix, so generated-SQL drift fails CI before any database
test runs.

## 11. Adding a new scalar type

From a generator perspective:

1. **Add a `ScalarSpec` row to `eql_scalars::CATALOG`**
   (`crates/eql-scalars/src/lib.rs`) — `token`, `kind`, the `domains`
   slice, and the `fixtures` list. Term names must be `Term` variants and
   the kind must be a `ScalarKind` variant, or it does not compile. If the
   type needs a new scalar width, add a `ScalarKind` variant (with its
   rust-type name, `MIN`/`MAX`/zero symbols, and bounds) and unit-test its
   `impl`. New term behaviour belongs in the `Term` enum's `impl`, not in
   catalog data.
2. **Materialise the value list** with `int_values!(<T_UPPER>_VALUES, <R>,
   <T_UPPER>);` next to `CATALOG`, and pin it with a `values_tests`
   assertion. This is the single source the SQLx matrix reads as
   `FIXTURE_VALUES`. There is nothing to regenerate-and-commit on the test
   side — it is a compile-time const, not a generated file.
3. **Regenerate.** `cargo run -p eql-codegen` (or just `mise run build` —
   the build runs the generator first). One run regenerates every catalog
   type; there is no per-type codegen task. The generated
   `*_{types,functions,operators,aggregates}.sql` are gitignored and never
   committed.
4. **Hand-write** `<token>_extensions.sql` if the type needs SQL beyond the
   fixed surface, with explicit `-- REQUIRE:` edges. This file IS committed.
5. **Do not add a `tests/codegen/reference/<token>/` baseline.** `int4` is
   the sole golden master for the type-generic generator: the templates are
   pure token substitution, so a per-type baseline can only fail where
   `int4`'s already would. Drift protection for the new type comes from the
   `int4` reference (shared templates + `Term` enum), the catalog
   `values_tests` pinning the materialised `<T>_VALUES`, the
   catalog/generator `#[test]`s, and the `ordered_numeric_matrix!` SQLx
   suite (behaviour, not bytes).
6. **Wire the SQLx matrix oracle and snapshot the inventory.** The
   implementation spec §2 lists the hand-maintained registration files.
   Then run `mise run test:matrix:inventory`: it normalizes each present
   type's `scalars::<token>::*` test-name set to `<T>`, asserts it equals
   the single canonical `tests/sqlx/snapshots/matrix_tests.txt`, and
   cross-checks the present type set against `cargo run -p eql-codegen --
   list-types`. There is **no per-type snapshot** — the per-type
   `<T>_matrix_tests.txt` files were collapsed into one token-normalized
   snapshot. You only regenerate `matrix_tests.txt` when the macro's
   emitted name set itself changes. A catalog type added without its matrix
   wiring fails the cross-check (catalog has the type, binary has no
   `scalars::<token>::` tests). See `tests/sqlx/snapshots/README.md` and
   the implementation spec §2 / §8.

Adding a new **term** is a bigger move — edit the `Term` enum's `impl`
methods, add `#[test]`s, audit `splinter.sh` for a name collision if the
extractor name is new, and (because it changes the int4 surface) update the
golden reference under `tests/codegen/reference/int4/`.

## 12. Out of scope

`text` and `jsonb` are not materialised through this generator. The
`ScalarKind` enum carries `Text`/`Numeric`/`Jsonb` variants and the
`Fixture` enum carries their string-backed shapes at the capability layer,
but `CATALOG` declares only the integer scalars today, so no `text`/`jsonb`
SQL surface is generated. Text and JSONB encrypted behaviour lives on the
composite `eql_v2_encrypted` type and its hand-written operator surface in
`src/encrypted/` and `src/operators/`, not the scalar materializer.
`jsonb` in particular needs a separate SQL design beyond this
ordered-scalar materializer.
