# Encrypted-Domain Code Generator

How `tasks/codegen/` turns a TOML manifest into the SQL surface for a
scalar encrypted-domain type. This document describes the generator
itself — its inputs, stages, outputs, and the invariants it enforces.
The contract those outputs must satisfy is in
[`encrypted-domain-implementation-spec.md`](./encrypted-domain-implementation-spec.md);
this file describes the machine that produces them.

The reference type is `eql_v3.int4` (PR #239). `text` and `jsonb` are
outside scope.

## 1. Why a generator

A single scalar encrypted-domain type emits several hundred SQL
declarations across eleven files: four domains, three extractors, dozens
of comparison wrappers and blockers, 176 `CREATE OPERATOR` statements (44
per domain), and MIN/MAX aggregates for every ordered domain. The shape
is mechanical and
the invariants are unforgiving — a `STRICT` blocker silently bypasses
its exception, a pinned `search_path` disables inlining and reverts
queries to seq scans. The generator exists so each new scalar type adds
one TOML file rather than ninety hand-written declarations that must
agree with each other and with `pin_search_path.sql`,
`tasks/test/splinter.sh`, and `src/encrypted_domain/functions.sql`.

## 2. Pipeline

`tasks/codegen/` is a small Python package. Entry point:
`python -m tasks.codegen.generate <token>`, wrapped by
`mise run codegen:domain <token>` (`tasks/codegen/domain.sh:10`).
`tasks/build.sh` invokes the same entry point for every manifest at
the start of every `mise run build`, so the generated SQL is never
checked in — the TOML manifest is the source of truth.

Stages, in order:

1. **Load manifest** — `spec.load_spec(toml_path)` reads
   `tasks/codegen/types/<token>.toml`, validates the `[domain]` table,
   validates the token and every domain name as SQL identifiers
   (`_SQL_IDENTIFIER`, `spec.py:12`), checks each domain name starts with the
   filename token, resolves every listed term against `terms.TERM_CATALOG`,
   and parses the optional `[fixture]` table (`_load_fixture_values`,
   `spec.py:36`). Returns a `TypeSpec` (`tasks/codegen/spec.py:98`).
2. **Resolve terms** — for each `DomainSpec`, `terms.require_terms`
   maps catalog names (`hm`, `ore`) to `Term` records carrying the
   extractor name, return type, JSON envelope key, supported
   operators, and the SQL `-- REQUIRE:` edges those terms imply
   (`tasks/codegen/terms.py:57-88`).
3. **Render** — `generate.render_types_file`,
   `generate.render_functions_file`, `generate.render_operators_file`,
   and `generate.render_aggregates_file` (the last only for ordered
   domains) build SQL strings via the per-construct functions in
   `templates.py`; when the manifest declares a `[fixture]` table,
   `templates.render_fixture_values_rs` also renders the committed Rust
   value const. No template engine — plain f-strings, with the structural
   shape of each declaration encoded in code (`tasks/codegen/generate.py`).
4. **Write** — `writer.write_generated_file` prefixes every SQL output with
   the `AUTO-GENERATED — DO NOT EDIT` header (`templates.py:13-17`) and
   refuses to overwrite any pre-existing file that lacks that marker
   (`tasks/codegen/writer.py:67`). The committed Rust value const is written
   by `writer.write_generated_rs` (`writer.py:78`) with its own Rust
   `AUTO-GENERATED` header. `generate_type` cleans stale generated files in
   the target directory before rewriting so an abandoned domain disappears on
   the next regeneration (`generate.py:221`).

There is no caching layer, no incremental mode, and no rewriting of
hand-written files. Each invocation regenerates every output for one
type from a single manifest.

## 3. Manifest format

```toml
[domain]
int4         = []
int4_eq      = ["hm"]
int4_ord_ore = ["ore"]
int4_ord     = ["ore"]
```

Rules enforced by `spec.load_spec`:

- The filename stem is the **type token** (`int4` here). It must match
  the CLI argument and prefix every domain name.
- The TOML must have a non-empty `[domain]` table at the top level. The
  only other recognised top-level key is the optional `[fixture]` table
  (see §3a).
- The filename token and every domain key must be valid lowercase SQL
  identifiers (`^[a-z][a-z0-9_]*$`); anything else raises `SpecError`.
- Each domain key must equal the token or start with `<token>_`.
- Each value must be a list of strings, and each string must be a key
  in `terms.TERM_CATALOG`. Unknown terms raise `SpecError`.

The `[domain]` table declares nothing else — no extractor names, no
operator lists, no REQUIRE edges. Every behavioural fact comes from the
term catalog.

Domains may be **twinned** (`int4_ord` and `int4_ord_ore` both carry
`["ore"]`). The generator emits them as independent domains with
byte-identical SQL modulo type name. Twins exist so callers can choose
a name that documents intent ("ordered, regardless of mechanism" vs
"ordered via ORE block") without committing to one term family in a
future migration.

Manifest order is significant. The generator iterates domains in their
declared TOML order (`generate.py:48`), and that order shows up in the
generated `<token>_types.sql` `DO` block.

### 3a. Optional `[fixture]` table

```toml
[fixture]
values = ["MIN", "-1", "ZERO", "1", "MAX"]
```

A type may declare an ordered `[fixture] values` list — the single source
of truth for the committed Rust const
`tests/sqlx/src/fixtures/<token>_values.rs`, consumed by the SQLx fixture
generator and the matrix oracle. `_load_fixture_values` (`spec.py:36`)
requires a non-empty list of string tokens; each resolves through the
scalar-kind catalog (`scalars.py`) — the sentinels `MIN` / `MAX` / `ZERO`
plus any numeric literal in the type's representable range. Validation
enforces a **distinct-plaintext contract**: duplicates are rejected against
the *resolved numeric* value, so both copy-paste token dups (`"1", "1"`) and
sentinel/literal aliases (`"MIN"` alongside the same number) raise
`SpecError` — and the set **must include MIN, MAX, and zero** (the matrix
comparison pivots). Unlike the gitignored SQL surface, `<token>_values.rs`
**is committed** (its rendering is deterministic), and CI regenerates it and
runs `git diff --exit-code` to catch an un-regenerated manifest edit. See
implementation spec §9 for the authoring guidance.

## 4. Term catalog

`tasks/codegen/terms.py:25-49` defines every term the materializer
recognises. A term is a frozen dataclass:

```python
Term(
    name="hm",                              # manifest key
    json_key="hm",                          # envelope payload key
    extractor="eq_term",                    # SQL extractor function name
    returns="eql_v2.hmac_256",              # extractor return type
    ctor="hmac_256",                        # eql_v2 constructor in jsonb
    role="eq",                              # file-header phrasing
    operators=("=", "<>"),                  # operators this term enables
    requires=("src/hmac_256/functions.sql",) # SQL REQUIRE edges
)
```

Current catalog:

| Term  | JSON key | Extractor   | Returns                          | Operators                          |
| ----- | -------- | ----------- | -------------------------------- | ---------------------------------- |
| `hm`  | `hm`     | `eq_term`   | `eql_v2.hmac_256`                | `=` `<>`                           |
| `ore` | `ob`     | `ord_term`  | `eql_v2.ore_block_u64_8_256`     | `=` `<>` `<` `<=` `>` `>=`         |

Adding a term is a code change to `terms.py` with matching tests in
`test_terms.py` — never a free-form manifest field. The catalog is the
only source of operator support, extractor identity, and REQUIRE edges;
the manifest is a thin selector over it.

## 5. The operator surface

`tasks/codegen/operator_surface.py` enumerates the surface every generated
domain declares:

- **Supported-capable comparisons**: `=` `<>` `<` `<=` `>` `>=` `@>` `<@`
- **Path blockers**: `->` `->>`
- **Native `jsonb` fallback blockers**: `?` `?|` `?&` `@?` `@@` `#>` `#>>` `-` `#-` `||`

Comparison and path operators keep the historical three-argument shapes:

- Symmetric: `(domain, domain)`, `(domain, jsonb)`, `(jsonb, domain)`
- Path: `(domain, text)`, `(domain, integer)`, `(jsonb, domain)`

Native `jsonb` fallback blockers use only the shapes PostgreSQL exposes
for `jsonb` itself, for a total of **44 `CREATE OPERATOR` statements per
domain**. Supported operators are emitted with full planner metadata
(`COMMUTATOR`, `NEGATOR`, `RESTRICT`, `JOIN` selectivity estimators) and
back onto inlinable wrappers; unsupported operators carry minimal metadata
and back onto blockers.

Path operators always back onto blockers — neither current term
enables them. The additional native `jsonb` operators are blocker-only.
Untyped string literals are a PostgreSQL resolver edge: `? 'c'` can still
select the built-in `jsonb` operator, while `? 'c'::text` and bound text
parameters select the generated blocker.

The union of these three lists is `KNOWN_JSONB_OPERATORS`. A live-DB
structural guard
(`tests/sqlx/tests/encrypted_domain/family/jsonb_operator_surface.rs`)
queries `pg_operator` for every operator with a `jsonb` argument and asserts
the set is a subset of this union, so a future PostgreSQL version that adds a
`jsonb` operator nobody enumerated here fails the test rather than silently
routing an encrypted column to native plaintext-`jsonb` semantics.
`test_operator_surface.py` pins the Python union; the Rust test mirrors it.

## 6. Generated outputs

For a manifest with `D` domains of which `A` are ordered (ord-capable),
the generator writes `1 + 2D + A` SQL files into
`src/encrypted_domain/<token>/`, plus — when the manifest carries a
`[fixture]` table — one committed Rust const at
`tests/sqlx/src/fixtures/<token>_values.rs`. For `int4` (`D = 4`, `A = 2`):
eleven SQL files and one Rust file. The SQL outputs are gitignored — `tasks/build.sh` regenerates them at the
start of every build from each `tasks/codegen/types/<token>.toml`,
`mise run codegen:domain <token>` refreshes a single type manually, and
`mise run codegen:domain:all` regenerates every type in one invocation (the
same `generate.py --all` enumeration the build uses). The manifest plus
`tasks/codegen/terms.py` are the source of truth.

| File                              | Content                                                                                  |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| `<token>_types.sql`               | Single idempotent `DO` block creating every domain; each domain `CHECK` pins the payload version (`VALUE->>'v' = '2'`) and required envelope/ciphertext/term keys; one `--! @brief` per domain |
| `<domain>_functions.sql`          | One extractor per unique term, then 44 wrappers-or-blockers covering the surface         |
| `<domain>_operators.sql`          | 44 `CREATE OPERATOR` statements with planner metadata on supported ops                   |
| `<domain>_aggregates.sql`         | MIN/MAX state functions + `CREATE AGGREGATE`; emitted only for ordered (ord-capable) domains |

Every file:

- Opens with the `AUTO-GENERATED — DO NOT EDIT` header
  (`templates.py:13-17`).
- Declares its `-- REQUIRE:` edges in dependency order — types files
  require `src/schema.sql`; function files require schema, types, and
  `src/encrypted_domain/functions.sql` plus each term's `requires` set;
  operator files require schema, types, and their domain's function
  file; aggregate files require schema, types, and their domain's
  function and operator files.
- Carries Doxygen `--! @file` / `--! @brief` headers describing its
  role.

### Function-count totals per domain

| Domain terms | Extractors | Wrappers | Blockers | Functions | Operators |
| ------------ | ---------: | -------: | -------: | --------: | --------: |
| none         |          0 |        0 |       44 |        44 |        44 |
| `["hm"]`     |          1 |        6 |       38 |        45 |        44 |
| `["ore"]`    |          1 |       18 |       26 |        45 |        44 |

Six wrappers for `hm` = `=` and `<>` × three shapes. Eighteen for `ore`
= six operators × three shapes. The 44-operator total never moves; the
wrapper/blocker split is what shifts, and native `jsonb` fallback
operators are always blockers.

The table above covers `<domain>_functions.sql` only. Ordered domains
additionally emit `<domain>_aggregates.sql` — two state functions
(`min_sfunc`, `max_sfunc`) and two `CREATE AGGREGATE` declarations
(`eql_v3.min`, `eql_v3.max`). Each aggregate declares
`combinefunc = <sfunc>` and `parallel = safe`: min/max are associative, so
the state function doubles as the combine function, enabling partial and
parallel aggregation on large `GROUP BY` ORE workloads with no decryption.

## 7. Invariants the generator enforces

The generator's job is partly to write SQL and partly to make
incorrect SQL unreachable. Invariants encoded in code:

- **Blockers are never `STRICT`.** `render_blocker_bool`,
  `render_blocker_path`, and `render_blocker_native` emit
  `IMMUTABLE PARALLEL SAFE` without the
  `STRICT` qualifier (`templates.py:263-345`), so a `NULL`
  argument still reaches the `RAISE` and the unsupported-operator
  exception fires. There is no code path that produces a strict
  blocker.
- **Wrappers are inlinable SQL.** `render_wrapper` and
  `render_extractor` emit `LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE`
  with a single-statement `SELECT` and no `SET search_path`
  (`templates.py:218-260`). `pin_search_path.sql:265-290`
  catches them structurally and leaves them unpinned.
- **Aggregate state functions are the deliberate exception.**
  `render_aggregate` emits `min_sfunc` / `max_sfunc` as
  `LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE` *with* a pinned
  `SET search_path` (`templates.py:379-452`). They are aggregate transition
  functions, not index expressions, so pinning is correct; the generated
  `min` / `max` aggregates are allowlisted by name in `splinter.sh`. The
  aggregates are `parallel = safe` with the sfunc reused as `combinefunc`.
- **SQL-literal injection is structurally prevented.** Every string
  interpolated into a single-quoted SQL literal — payload keys, operator
  symbols, domain names in `RAISE` messages — passes through `_sql_str`
  (`templates.py:46`), which doubles embedded single quotes. Today's catalog
  strings are all quote-free so it is a no-op, but it guarantees a future
  quote-bearing catalog string cannot break out of its literal.
- **No domain-over-domain.** Every domain is `CREATE DOMAIN eql_v3.<name>
  AS jsonb`, never `AS <some_other_domain>` (`templates.py:72`). PostgreSQL
  resolves operators against the underlying base type; a derived domain
  would silently bypass the fixed operator surface.
- **No operator class on a domain.** The generator emits operators,
  not operator classes. Callers index through the extractor function
  (e.g. `USING btree (eql_v3.ord_term(col))`), whose return type
  already carries a default opclass.
- **Ownership boundary.** `writer.is_generated` recognises owned files
  by their header line and refuses to overwrite anything else
  (`writer.py:20-26`, `44-53`). A hand-written file at a generated
  path is a hard error, not a silent clobber. Stale generated files
  for removed domains are cleaned before the new files land
  (`writer.py:29-41`).

## 8. Extension files

`<token>_extensions.sql` is the hand-written sibling. The generator
never creates, lists, or cleans it; it has no auto-generated header
and must declare its own `-- REQUIRE:` edges. Use it for behaviour
that's specific to the type and not part of the fixed surface — e.g.
cross-domain casts, helper functions, type-specific constraints.

`pin_search_path.sql:291-302` describes the fallback marker for
inline-critical extension functions that take no domain argument and
so escape the structural skip:

```sql
COMMENT ON FUNCTION eql_v2.my_helper(...) IS 'eql-inline-critical: ...';
```

The generator does **not** emit this marker; every function it
produces takes a domain argument and is covered by the structural skip
intrinsically.

## 9. Lint and test integration

The generator depends on two pieces of build tooling recognising its
output without per-type edits:

- **`tasks/pin_search_path.sql:265-290`** — structural skip identifies
  encrypted-domain functions by language (`sql`), volatility
  (`IMMUTABLE`), and the presence of at least one argument typed as a
  jsonb-backed `DOMAIN` in the `eql_v3` schema. New scalar types
  need no edit here.
- **`tasks/test/splinter.sh`** — name-based allowlist. The converged
  wrapper names (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `eq_term`,
  `ord_term`) are already covered by entries originally added for
  `ste_vec_entry` and friends (`splinter.sh:87-104`). Splinter matches
  by name only, so a new scalar type that uses the catalog extractors
  inherits coverage. Adding a new term whose extractor has a new name
  requires a splinter entry.

## 10. Tests

`mise run test:codegen` runs the generator test suite — `pytest
tasks/codegen` — with no database required:

- `test_spec.py`, `test_terms.py`, `test_scalars.py`,
  `test_operator_surface.py`, `test_templates.py`, `test_writer.py` — unit
  tests per module.
- `test_generate.py` — end-to-end rendering tests asserting file
  counts and structural shape.
- `test_against_reference.py` — byte-for-byte match of in-memory
  `render_*_file` output against a hand-reviewed (header-stripped)
  reference under `tests/codegen/reference/int4/`. Runs anywhere
  without depending on materialised `src/encrypted_domain/<T>/`. The
  reference fixture is the human-readable contract that survives
  generator refactors.

The codegen suite is a prerequisite of the PostgreSQL test matrix
(`tasks/test.sh`), so generated-SQL drift fails CI before any database
test runs.

## 11. Adding a new scalar type

The end-to-end shape from a generator perspective:

1. **Author** `tasks/codegen/types/<token>.toml`. Domain names must
   start with the token; term names must already exist in
   `terms.TERM_CATALOG`. If `<token>` is a new scalar kind, first register
   a `ScalarKind` in `scalars.py` — `load_spec` resolves the scalar before
   anything else, so an unregistered token raises
   `ScalarError: unknown scalar token '<token>'`.
2. **Regenerate**. Either run `mise run codegen:domain <token>` while
   iterating, or just `mise run build` — the build regenerates every
   manifest first. The generator cleans stale generated files, writes
   new ones, and refuses any hand-written file at a generated path.
   Generated `*_types.sql` / `*_functions.sql` / `*_operators.sql` are
   gitignored and never committed.
3. **Hand-write** `<token>_extensions.sql` if the type needs SQL
   beyond the fixed surface. Add `eql-inline-critical` markers only on
   inline-critical helpers that take no domain argument. This file IS
   committed.
4. **Build picks it up automatically** — `tasks/build.sh` regenerates
   before computing the `tsort` graph, so the new files appear in the
   dependency walk via the `-- REQUIRE:` edges the generator emits.
5. **Test.** Do **not** add a `tests/codegen/reference/<token>/` baseline.
   `int4` is the sole golden master for the type-generic generator: the SQL
   templates are pure token substitution and the only type-specific rendering
   is `<token>_values.rs`, so a per-type baseline can only fail where `int4`'s
   already would. Drift protection for the new type comes from the `int4`
   reference (shared templates + `terms.py`), the committed `<token>_values.rs`
   const guarded by the codegen staleness check, the `<token>` cases in
   `test_scalars.py`, and the `ordered_numeric_matrix!` SQLx suite (behaviour,
   not bytes). Run `mise run test:codegen`, the relevant SQLx suites, and the
   PostgreSQL matrix.
6. **Snapshot the matrix inventory.** Run `mise run test:matrix:inventory`
   and commit the new `tests/sqlx/snapshots/<token>_matrix_tests.txt` — the
   sorted list of the type's `scalars::<token>::*` test names. CI's
   `matrix-coverage` job `git diff --exit-code`s it (like `<token>_values.rs`)
   to catch a silently dropped or renamed matrix test. The snapshot is a
   committed test baseline, not gitignored generated SQL. See
   `tests/sqlx/snapshots/README.md`.

Adding a new **term** is a bigger move — edit `terms.py`, add tests,
audit `splinter.sh` for a name collision, and update the reference
fixture under `tests/codegen/reference/`.

## 12. Out of scope

`text` and `jsonb` are not materialised through this generator. There
is no guard preventing a `text.toml` from being authored; the catalog
simply lacks the term shape those types would need. Text and JSONB
encrypted behaviour lives on the composite `eql_v2_encrypted` type and
its hand-written operator surface in `src/encrypted/` and
`src/operators/`, not the scalar materializer.
