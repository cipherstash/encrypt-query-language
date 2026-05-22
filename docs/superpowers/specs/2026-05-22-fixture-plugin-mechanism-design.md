# Fixture plug-in mechanism — design

**Date:** 2026-05-22
**Status:** Draft — under review
**Branch:** `foundation/fixtures-and-bench` (PR #224)
**Related:** PR #225 (`int4/variant-family`) consumes this mechanism

## Problem

PR #224 is the foundation layer for the encrypted-domain stack. It carries the
fixture-generation mechanism and the int4 fixture that exercises it. We want
#224 to ship a **reusable, type-checked mechanism** — a clear way for any
subsequent branch to plug in a new encrypted dataset — with the int4 fixture as
its first worked example. The int4 fixture stays here: it is plain `jsonb` data,
testable with vanilla SQL, and independent of the EQL domain types that the next
branch in the stack (#225) layers on top.

The current mechanism is a set of bash scripts driving `psql` and `docker`. It
works, but the contract is informal — a new fixture means copying a ~90-line
script and getting a six-positional-argument `dump_fixture_table` call right —
and it carries the `\bind` extended-protocol workaround for negative integer
literals that every future fixture author would have to understand and replicate.

## Decision: generate fixtures in Rust

The fixtures are *consumed* by Rust/SQLx tests (`tests/sqlx/`). SQLx is already a
dependency. Generating them in Rust too means:

- **The `\bind` quirk disappears.** SQLx uses the PostgreSQL extended query
  protocol natively; `.bind(-100i32)` sends a typed binary parameter. The
  negative-integer problem does not exist.
- **The plug-in contract is type-checked** — a builder the compiler validates,
  not "set these magic shell variables."
- **Producer and consumer share one language**, one connection library, one set
  of types.

The one residual risk — that Proxy treats SQLx's extended-protocol parameters
identically to psql's `\bind` — is contained by the generator's full round-trip:
if Proxy diverges, generation fails loudly before anything is committed.

Container lifecycle (`proxy:up` / `proxy:down` / `proxy:logs`) stays as mise
tasks — genuine Docker orchestration. The split: **mise owns the containers;
Rust owns the data.**

## Scope

### #224 (this branch) — the mechanism and the int4 fixture

**Delete:**

- `tasks/fixtures/_generate_common.sh` — replaced by the Rust framework
- `tasks/fixtures/generate_encrypted_int4.sh` — replaced by the Rust int4 fixture module
- `tasks/fixtures/encrypted_int4_schema.sql` — the schema is now generated
- `tests/sqlx/migrations/009_install_encrypted_int4_fixture.sql` — the int4
  fixture leaves `migrations/` for a SQLx fixture script (see below)
- `docs/superpowers/specs/2026-05-12-encrypted-domain-types-design.md` — see note below
- the `fixture:int:generate` task in `tasks/fixtures.toml`

**Add (source):**

- `tests/sqlx/src/fixtures/` — the Rust fixture framework (builder, `EqlPlaintext`
  trait, driver, schema generation, fixture-script rendering)
- `tests/sqlx/src/fixtures/eql_v2_int4.rs` — the int4 fixture: the framework's
  first worked example and its proof
- `pub mod fixtures;` in `tests/sqlx/src/lib.rs` — the one-line module wiring
- `#[cfg(test)]` unit tests for the framework's pure logic
- `tests/sqlx/tests/eql_v2_int4_fixture_tests.rs` — vanilla-SQL tests over the
  generated fixture (no domain type required — `payload` is `jsonb`)
- a `fixture-gen` feature in `tests/sqlx/Cargo.toml`
- a generic `fixture:generate <name>` task in `tasks/fixtures.toml`

**Generated, committed artifact:**

- `tests/sqlx/fixtures/eql_v2_int4.sql` — the int4 fixture script, produced by
  `mise run fixture:generate eql_v2_int4` and committed. A SQLx fixture script
  (not a numbered migration), consumed opt-in via
  `#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_int4")))]`.
- an `eql_v2_int4` section in `tests/sqlx/fixtures/FIXTURE_SCHEMA.md` — schema
  plus a dependency-graph entry, per the repo's documented "Adding New Fixtures"
  process. Unlike its neighbours, the committed `eql_v2_int4.sql` is plain SQL
  with no EQL dependency.

**Keep, untouched:** `proxy:up` / `proxy:down` / `proxy:logs`,
`tests/docker-compose.proxy.yml`, and the bench dataset tooling.

> **Note on deleting the 05-12 spec.** It designs three prototype types —
> `encrypted_text`, `encrypted_jsonb`, `encrypted_int4`. Only the int4 design is
> carried forward (by #225). The `encrypted_text` / `encrypted_jsonb` designs
> are not superseded — they remain in #210's spike branch, which #224's PR
> description explicitly preserves as "the full spike." Deletion from this
> branch is intentional on that basis.

### #225 (follow-up, out of scope for this task)

#225 adds the EQL domain types (`eql_v2_int4`, `eql_v2_int4_eq`,
`eql_v2_int4_ord`, `eql_v2_int4_ord_ore`) and the type-aware operator tests,
consuming the int4 fixture via per-query casts (`payload::eql_v2_int4_ord_ore`).
Two updates #225's plans need: (1) reference the table as `fixtures.eql_v2_int4`
(their plans currently say `encrypted_int4_plaintext`); (2) the fixture is now a
SQLx fixture script, so each int4 test opts in with
`#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_int4")))]` instead
of relying on an always-applied migration. The `plaintext` column is retained,
so value-based filtering (`WHERE plaintext = 42`) is unaffected. This downstream
churn is accepted.

## The framework

### The uniform model

One table per fixture, in a dedicated `fixtures` schema, named for the fixture:
`fixtures.<name>` — for int4, **`fixtures.eql_v2_int4`**. (The SQL schema
`fixtures` is distinct from `tests/sqlx/fixtures/`, the directory of SQLx fixture
*scripts* — same word, different namespace.)

The dedicated schema is required, not cosmetic. #225 creates a
`public.eql_v2_int4` domain; in PostgreSQL a table also occupies the type
namespace, so a `public.eql_v2_int4` table and the domain cannot coexist. The
`fixtures` schema keeps every fixture table out of the `public` type/domain
namespace permanently.

Columns — `fixtures.<name> (id, plaintext, payload)`:

- `id BIGINT` — explicit, `index + 1`; row `id = N` ⇄ the Nth generated value.
- `plaintext <T>` — the cleartext value. **The in-table oracle**: consuming
  tests filter `WHERE plaintext = N` directly. Because the column is present,
  no Rust value constant needs to be shared between generator and consumers —
  the table carries its own ground truth.
- `payload <column-type>` — the encrypted value. Its committed SQL type is a
  fixture parameter: **`jsonb` in #224** (no domain types exist yet); a
  downstream fixture may declare a domain type instead.

The committed fixture is **one table** — `fixtures.eql_v2_int4 (id, plaintext,
payload)`. The generator additionally uses a **transient working table** on the
live database — created and dropped within a single generation run — that shares
the fixture's column layout but differs in two mechanism-level ways:

1. **Name and schema.** The committed fixture is `fixtures.eql_v2_int4`. The
   working table is `public._fixture_eql_v2_int4` — a reserved `_fixture_<name>`
   name in `public`. Two constraints force this. `eql_v2.add_search_config`
   treats its `table_name` argument as a single unqualified identifier (it
   `%I`-quotes it, `ALTER TABLE`s it under a `public` search_path, and keys
   config by the bare string Proxy matches on), so the working table must be an
   unqualified `public` name. And a `public.eql_v2_int4` working table would
   collide with #225's `public.eql_v2_int4` domain — a table occupies the type
   namespace — the moment the generator is re-run against a domain-bearing EQL
   build (the generator is durable, and #225 stacks directly on top). The
   `_fixture_` prefix sits outside the `eql_v2_*` domain namespace, so generation
   is collision-proof regardless of which EQL build the generation database
   carries. The working-table name is cosmetic — it surfaces only in the inert
   `i` metadata (below).
2. **`payload` column type.** `eql_v2_encrypted` on the working table (so Proxy
   encrypts inserts into it); the declared `column-type` (`jsonb`) in the
   committed fixture.

The working table is plumbing — never committed, never consumed. The fixture
artifact consumers see is the single `fixtures.eql_v2_int4` table.

### The builder

`FixtureSpec<T>`, generic over the Rust plaintext type `T`. The entire int4
fixture definition:

```rust
FixtureSpec::new("eql_v2_int4")
    .index("unique")          // drives  =  <>
    .index("ore")             // drives  <  <=  >  >=
    .column_type("jsonb")     // committed `payload` type; no domains exist in #224
    .values(VALUES)           // &[i32]
    .run().await
```

`T` (`i32`) is inferred from `.values()`. Everything else is **convention,
derived from the fixture name** — there is no output-path or filename parameter:

- the table is `fixtures.eql_v2_int4` (schema fixed; table name = the fixture name);
- the generated script is `tests/sqlx/fixtures/eql_v2_int4.sql` (`fixtures/<name>.sql`);
- the SQLx fixture is referenced as `scripts("eql_v2_int4")`.

What stays explicit is only what cannot be derived: the indexes, the committed
`payload` column type, and the data.

### The `EqlPlaintext` trait

The EQL search-config cast — the `cast_as` argument to `add_search_config` — is
derived from `T`, not passed by hand:

```rust
trait EqlPlaintext {
    const CAST: &'static str;   // e.g. "int"
}
impl EqlPlaintext for i32 { const CAST: &'static str = "int"; }
```

#224 ships the trait and the `i32` impl only (`CAST = "int"`, verified against
the existing fixture schema). Impls for other plaintext types land with the
fixtures that introduce them.

Three distinct types are in play, and the design keeps them separate: the Rust
value type `T` (`i32`), the EQL cast `T::CAST` (`"int"` — an `add_search_config`
argument), and `.column_type()` (the committed `payload` column's SQL type —
`jsonb`).

### Schema generation

The framework generates the table schema — no hand-written `.sql` file. On the
live generation database, against the transient working table:

```sql
DROP TABLE IF EXISTS public._fixture_eql_v2_int4;
CREATE TABLE public._fixture_eql_v2_int4 (
    id BIGINT PRIMARY KEY,
    plaintext INTEGER NOT NULL,
    payload eql_v2_encrypted
);
-- per index, idempotent:
SELECT eql_v2.remove_search_config('_fixture_eql_v2_int4', 'payload', '<index>') WHERE EXISTS ( … );
SELECT eql_v2.add_search_config('_fixture_eql_v2_int4', 'payload', '<index>', '<cast>');
```

The committed fixture script `tests/sqlx/fixtures/eql_v2_int4.sql` renders the
same table in the `fixtures` schema:

```sql
CREATE SCHEMA IF NOT EXISTS fixtures;
DROP TABLE IF EXISTS fixtures.eql_v2_int4;
CREATE TABLE fixtures.eql_v2_int4 (
    id BIGINT PRIMARY KEY,
    plaintext INTEGER NOT NULL,
    payload jsonb NOT NULL
);
-- + the rendered INSERTs
```

### The driver — `.run()`

1. Build two typed `PgConnectOptions` (direct Postgres, Proxy) from `POSTGRES_*`
   / `PROXY_PORT` env vars — separate typed fields, no DSN string.
2. Direct connection → apply the generated `public._fixture_eql_v2_int4` schema.
3. `docker restart cipherstash-proxy` via `std::process::Command`, then poll a
   Proxy connection (~60s); on timeout, dump `docker logs` and fail. (Proxy
   caches its encrypt config at connection-handler init; it must reconnect to
   pick up the new `add_search_config`.)
4. Proxy connection → per value, with explicit `id`:
   `INSERT INTO _fixture_eql_v2_int4 (id, plaintext, payload) VALUES (…)` — the value
   bound into both `plaintext` (stored plain) and `payload` (Proxy encrypts it).
   Native extended protocol; negative integers and other types just work.
5. Direct connection → render rows via server-side literal escaping:
   `SELECT format('INSERT INTO fixtures.eql_v2_int4 (id, plaintext, payload) VALUES (%L, %L, %L::jsonb);', id, plaintext, (payload).data::text) … ORDER BY id`.
6. Write the fixture script to `tests/sqlx/fixtures/<name>.sql` — path derived
   from the fixture name — with a generated `AUTO-GENERATED` header, `CREATE
   SCHEMA` / `DROP` / `CREATE TABLE`, then the rendered `INSERT`s. An existing
   script for this fixture is overwritten in place.

Error handling is `anyhow::Result` end to end with `.context(...)` — a generator
is a developer tool; a clear crash beats a partial fixture.

### SQL generation safety

The framework builds SQL from the fixture name, index names, the EQL cast, and
the committed column type. Rust's type system does not make a `&str` a safe SQL
token, so the framework enforces it explicitly:

- **Identifiers.** The fixture `name` is used as a SQL identifier (the
  `fixtures.<name>` and `_fixture_<name>` tables, `CREATE` / `DROP`) and as the
  generated filename. It is validated at `FixtureSpec` construction against
  `^[a-z][a-z0-9_]*$`; a violation is a hard error before any SQL is generated.
  The `fixtures` schema, the `_fixture_` prefix, and the `id` / `plaintext` /
  `payload` column names are fixed literals.
- **The committed column type (`.column_type`).** It is interpolated as a SQL
  type token (`CREATE TABLE … payload <column-type>`), so it is validated at
  `FixtureSpec` construction against a strict allowlist — **`{ jsonb }` for
  #224**. Extending the framework to domain-typed columns means extending that
  allowlist (each entry a validated, optionally schema-qualified type token);
  until then, anything but `jsonb` is a hard error.
- **`add_search_config` arguments.** The table name, column name, index name,
  and the EQL cast (`T::CAST`) are all `text` arguments — each is rendered as a
  quoted SQL string literal (`%L`), never as a bare token. `add_search_config`
  additionally validates `cast_as` server-side against EQL's cast allowlist
  (`text, int, small_int, …`). The framework also asserts `T::CAST` and every
  index name against that allowlist / the identifier charset at construction,
  for a clear early error.
- **Row values.** Never interpolated by Rust — rendered server-side via
  `format('%L', …)`.

No name, type, cast, index, or value reaches generated SQL unescaped or
unvalidated.

### Generated payload metadata

Each encrypted `payload` is a JSONB object from Proxy: ciphertext (`c`), the
equality term (`hm`), the ORE term (`ob`), and an `i` object —
`"i": {"c": <column>, "t": <table>}` — recording the generation table/column.
With the generator's `public._fixture_eql_v2_int4` table and `payload` column,
`i` reflects those names.

This is inert. Across the whole EQL source, `i` is touched only by
`eql_v2._encrypted_check_i` / `_encrypted_check_i_ct` (which validate the keys
*exist*, never their values) and `eql_v2.meta_data()` (which copies `i` out). No
operator, comparison, or cast resolves `i`; equality keys on `hm`, ordering on
`ob`. The current fixture already proves it — its `i.t` names a table absent
from the test database, yet the fixture is consumed without error.

## The plug-in surface

A fixture is exactly one file — `tests/sqlx/src/fixtures/<name>.rs` — holding the
value list, the `spec()`, and a feature-gated generator test:

```rust
// tests/sqlx/src/fixtures/eql_v2_int4.rs   (#224 — the reference fixture)
const VALUES: &[i32] = &[-100, -1, 1, 2, 5, 10, 17, 25, 42, 50, 100, 250, 1000, 9999];

pub fn spec() -> FixtureSpec<i32> {
    FixtureSpec::new("eql_v2_int4")
        .index("unique").index("ore")
        .column_type("jsonb")
        .values(VALUES)
}

#[cfg(feature = "fixture-gen")]
#[tokio::test]
#[ignore = "generator — run via `mise run fixture:generate`"]
async fn generate() -> anyhow::Result<()> {
    spec().run().await
}
```

`#[cfg(feature = "fixture-gen")]` means the generator test does not compile
unless that feature is on — `cargo test`, CI, and `cargo test -- --ignored`
never see it. `#[ignore]` is a second guard: firing it needs *both* the feature
*and* `--ignored`.

Consuming tests opt into the generated fixture script and filter on the
`plaintext` column:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_int4")))]
async fn some_test(pool: PgPool) -> Result<()> {
    // SELECT … FROM fixtures.eql_v2_int4 WHERE plaintext = 42
}
```

#224's `eql_v2_int4_fixture_tests.rs` reads `fixtures.eql_v2_int4` with vanilla
SQL; #225's type-aware tests cast `payload` per query. Neither imports a Rust
value constant — the `plaintext` column is the shared ground truth.

Adding a fixture is: one new `src/fixtures/<name>.rs` file, one `pub mod <name>;`
line in `src/fixtures/mod.rs`, and — if its plaintext type is new — one
`impl EqlPlaintext`. The generated `tests/sqlx/fixtures/<name>.sql` is committed.
No edits to the framework.

### Invocation

A generic mise task in `tasks/fixtures.toml`. It must run **inside the crate
directory** — there is no root `Cargo.toml`, so `cargo` is invoked from
`tests/sqlx`, matching the existing `test:schema` / `test:sqlx:watch` tasks:

```
[tasks."fixture:generate"]
dir = "{{config_root}}/tests/sqlx"
run = "cargo test --features fixture-gen --lib \
         fixtures::<fixture>::generate -- --ignored --exact --nocapture"
```

Invoked as `mise run fixture:generate eql_v2_int4`, with the fixture name passed
as a task argument (exact mise argument-templating settled in the implementation
plan). Prerequisites: `mise run proxy:up`, and a Postgres with EQL installed.

## Testing strategy

Three layers, all in #224:

- **Framework pure logic — `#[cfg(test)]` unit tests**, no database, no Proxy:
  schema-SQL generation, fixture-script rendering, identifier/cast validation,
  `EqlPlaintext::CAST` mapping.
- **The generator** — `mise run fixture:generate eql_v2_int4` runs the full
  Proxy round-trip (driver steps 3–5) and produces the committed
  `tests/sqlx/fixtures/eql_v2_int4.sql`. A developer runs it when the fixture
  changes; not CI (CI has no Proxy).
- **The generated fixture — vanilla-SQL integration tests** in
  `eql_v2_int4_fixture_tests.rs`, each
  `#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_int4")))]`:
  row count, every `payload` carries the expected `hm` and `ob` terms,
  `plaintext`-to-structure correspondence. No domain type required — `payload`
  is `jsonb`. These run in normal `cargo test`.

The test split with #225 is clean: **#224 verifies the fixture data is
structurally well-formed; #225 verifies the domain operators behave correctly on
it.**

## Review findings — how this design addresses them

The #224 review posted six inline threads. None are fixed in the branch yet.

| Finding | How implementing this design addresses it |
|---|---|
| 1 — `encrypted_int4` OPE/ORE & `hm` | Two parts. (a) OPE→ORE terminology — resolved: the regenerated fixture and its generator carry `ORE block terms`. (b) coderdan's "no need for `hm`" — considered and **declined**: #225's plan (`2026-05-20-…md:1374`) keeps `hm` because the shared `payload` also feeds `eql_v2_int4_eq`, which routes equality through `hm`; ordered variants ignore it. The fixture's `.index("unique")` is deliberate. |
| 2 — `.env.example` "use `npx stash auth login`" | Out of scope — bench tooling. Stays open as an independent fix. |
| 3 — `bench.toml` teardown `--env-file` | Out of scope — bench tooling. Stays open as an independent fix. |
| 4 — `_generate_common.sh` DSN credentials | The file is deleted; the Rust driver builds typed `PgConnectOptions`, so no DSN string exists. |
| 5 — `generate.sh` hardcoded credentials | Out of scope — bench tooling. Stays open as an independent fix. |
| 6 — migration 009 OPE/ORE comment | The stale bash `migrations/009` is deleted; the fixture is regenerated as `tests/sqlx/fixtures/eql_v2_int4.sql` with a correct `ORE block terms` header. |

## Out of scope

- The EQL `int4` domain types and their type-aware operator tests — #225.
- The 100k-row bench dataset generator (`tests/benchmarks/generate.sh`) — stays
  bash; review findings 2, 3, 5 against bench tooling stay open as a separate fix.
- A raw-SQL schema escape hatch for exotic fixtures — YAGNI; add it when a
  fixture actually needs a schema the generator cannot express.
- `EqlPlaintext` impls beyond `i32` — each lands with the fixture that needs it.
