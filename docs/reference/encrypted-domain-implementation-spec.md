# Encrypted domain type — implementation spec

A consolidated, type-agnostic spec and checklist for implementing an
encrypted-domain type family in EQL. The pattern is the one established
by `eql_v2_int4` (PR #225); this document generalises it so the same
mechanics can be applied to `int8`, `bool`, `date`, `float`/`double`,
`numeric`, `timestamp`, and `jsonb`.

**Audience:** contributors adding a new encrypted-domain type.
**Reference implementation:** `src/encrypted_domain/int4/`,
`tests/sqlx/tests/encrypted_int4*`.

---

## 1. The model

An encrypted-domain type is a **family of jsonb-backed PostgreSQL
domains**, one domain per operator/index-term **capability**. The
capability is encoded in the domain name:

| Domain name            | Capability                          | Capability terms |
|------------------------|-------------------------------------|------------------|
| `eql_v2_<T>`           | storage only — every operator raises | `c`             |
| `eql_v2_<T>_eq`        | equality (`=`, `<>`)                 | `c`, `hm`       |
| `eql_v2_<T>_ord`       | equality + ordering (`=` `<>` `<` `<=` `>` `>=`) | `c`, `ob` |
| `eql_v2_<T>_ord_<scheme>` | as `_ord`, scheme-explicit name   | `c`, `ob`       |

A caller picks the domain whose capability matches the searches they
need; an unmatched operator **raises** rather than silently falling
through to native `jsonb` behaviour.

Every domain also carries the EQL envelope keys (`v`, `i`) in addition
to the capability terms above, and **each domain enforces a `CHECK`
constraint** requiring the envelope plus its capability terms — a
malformed payload is rejected at the point it is cast into the domain
(§3).

### What is fixed vs. what each type decides

**Fixed by this spec (the mechanics):** how domains are declared, the
inlinability rules, the operator surface and arg-shapes, the
no-opclass-on-domains rule, the test structure, the fixture format, and
the coverage bar. Sections 4–10 below.

**Decided per type (its own design step):** which variants the family
has, the payload terms each variant carries, and the index/equality
scheme. These depend on the type's encryption scheme and are **not**
mechanical. Examples of decisions the int4 family made that do **not**
transfer automatically:

- int4's ordered variants carry `c`, `ob` and **drop `hm`** because ORE
  on a full-domain `int4` is lossless — the order term doubles as an
  exact equality term. A type whose ORE is **lossy**, or whose domain is
  not fully covered (candidates: `float`/`double`, `numeric`), must keep
  `hm` on its ordered variants and route `=`/`<>` through `eq_term`, not
  `ord_term`.
- int4 ships two ordered domains (`_ord` and `_ord_ore`) as mechanical
  twins. A type with a single ordering scheme needs only `_ord`.
- `jsonb` does not fit the scalar storage/eq/ord shape; see §11.

Resolve these before writing code, and record them in a short
type-specific design note. Everything else follows the checklist.

---

## 2. Implementation checklist

Work top to bottom. Each item links to its reference section.

### Design (per type — resolve first)
- [ ] Choose the variant set and each variant's payload terms (§1).
- [ ] Confirm whether ORE is lossless for this type — decides whether
      ordered variants carry `hm` and where `=`/`<>` route (§1, §4).
- [ ] Pick the index-term type(s) the extractors will return — they
      must already carry a default operator class (§4).

### Types
- [ ] Declare every domain in `src/encrypted_domain/types.sql` as an
      idempotent `CREATE DOMAIN public.<name> AS jsonb` with a `CHECK`
      constraint enforcing the envelope (`v`, `i`) plus the variant's
      capability terms (§3).

### Per variant — functions, then operators
- [ ] `src/encrypted_domain/<T>/<T>_<variant>_functions.sql`: the
      extractor (eq/ord variants), the inlinable comparison wrappers for
      supported operators, and the blockers for every unsupported
      operator (§5, §6).
- [ ] `src/encrypted_domain/<T>/<T>_<variant>_operators.sql`: a
      `CREATE OPERATOR` for every operator × arg-shape (§6).
- [ ] Add `-- REQUIRE:` headers to every file (§9).

### Wiring
- [ ] Allowlist every inlinable function in `tasks/pin_search_path.sql`
      and `tasks/test/splinter.sh` (§5).
- [ ] `mise run clean && mise run build` — clean first, a bare build can
      leave stale `release/*.sql` (§9).
- [ ] Confirm the Supabase and Protect build variants still build (§9).

### Tests & fixtures
- [ ] Fixture generator `tasks/fixtures/generate_encrypted_<T>.sh` and
      its generated migration
      `tests/sqlx/migrations/0NN_install_encrypted_<T>_fixture.sql` (§8).
- [ ] One SQLx suite per variant,
      `tests/sqlx/tests/encrypted_<T>[_variant]_tests.rs` (§7).
- [ ] A twin-sync `#[test]` if any variant is a mechanical twin (§7).
- [ ] Meet the coverage bar in §10.
- [ ] `mise run test` green on PostgreSQL 14–17.

### Documentation
- [ ] Reference page, walkthrough, `CHANGELOG.md` `[Unreleased]` entry,
      and a `docs/upgrading/v<x>.md` upgrade note (§9).

---

## 3. Reference — Type definitions

- **One domain per capability**, all `AS jsonb`, all in the **`public`**
  schema. Public placement matches `public.eql_v2_encrypted`: user table
  columns depend on stable public type names, while implementation
  functions and operators live in `eql_v2`. `tasks/uninstall.sql` drops
  `eql_v2` but leaves the public domains in place.
- **Declare idempotently.** All domains for a type go in
  `src/encrypted_domain/types.sql`, inside one `DO $$ … $$` block:

  ```sql
  DO $$
  BEGIN
    IF NOT EXISTS (
      SELECT 1 FROM pg_type
      WHERE typname = 'eql_v2_<T>' AND typnamespace = 'public'::regnamespace
    ) THEN
      CREATE DOMAIN public.eql_v2_<T> AS jsonb
        CHECK (
          jsonb_typeof(VALUE) = 'object'
          AND VALUE ? 'v' AND VALUE ? 'i' AND VALUE ? 'c'
        );
    END IF;
    -- … one IF NOT EXISTS block per variant …
  END
  $$;
  ```

- **Every domain carries a `CHECK` constraint.** The payload must be a
  `jsonb` object carrying the EQL envelope (`v`, `i`), the ciphertext
  (`c`), **and every capability term the variant relies on** — `hm` for
  an `_eq` variant, `ob` for an `_ord` variant. The constraint is
  enforced when a value is cast into the domain, so a malformed or
  under-populated payload is rejected at write time rather than failing
  obscurely inside an extractor later. The storage variant requires only
  `v`, `i`, `c`; each capability variant adds its term:

  ```sql
  CREATE DOMAIN public.eql_v2_<T>_eq AS jsonb
    CHECK (
      jsonb_typeof(VALUE) = 'object'
      AND VALUE ? 'v' AND VALUE ? 'i' AND VALUE ? 'c' AND VALUE ? 'hm'
    );
  ```

- **Every domain is a concrete domain over `jsonb`.** Do **not** declare
  one domain as a domain over another (`CREATE DOMAIN a AS b`). The
  int4 verification spike showed PostgreSQL resolves operators against
  the *ultimate base type* (`jsonb`), so a domain-over-domain does not
  inherit the base domain's operator surface — ordered operators fall
  through to native `jsonb` comparison and blockers do not engage. Two
  domains with the same capability (e.g. `_ord` and `_ord_ore`) are each
  a separate concrete domain over `jsonb` carrying their own operator
  surface; keep them in sync with a twin-sync test (§7).
- **Payload terms** are a per-variant assumption, documented in each
  file's `--! @file` header (e.g. *"Payload-term assumption: `c`, `hm`."*).

---

## 4. Reference — Operator classes

**Do not create an operator class on a domain type.** An opclass on a
public domain is a footgun and bloats the index — it stores the whole
`jsonb` payload rather than the compact index term.

Instead, index through a **functional index on an extractor function**:

- The extractor (`eq_term` / `ord_term`) returns an **internal
  index-term type that already carries a default operator class**. The
  exact return type is per-extractor — what matters is that it has a
  default opclass for the access method you need:
  - `eql_v2.ord_term(col)` returns `eql_v2.ore_block_u64_8_256`, which
    carries `main`'s `DEFAULT FOR TYPE … USING btree` operator class.
    `CREATE INDEX … USING btree (eql_v2.ord_term(col))` binds it
    automatically — no opclass annotation.
  - The `eq_term` overload on a scalar variant (e.g.
    `eql_v2.eq_term(eql_v2_<T>_eq)`) returns `eql_v2.hmac_256` (a domain
    over `text`); the `eq_term` overload on a `ste_vec` entry returns
    `bytea`. Both `text` and `bytea` have default btree/hash opclasses,
    so `USING hash` or `USING btree (eql_v2.eq_term(col))` engages
    equality either way. Pick the return type to match an existing
    opclass — do not invent one.
- A type implementer therefore creates **no operator class at all**. The
  extractor is the bridge: pick a return type that already has the
  opclass you need.

**Build caveat:** the internal ORE composite operator class is excluded
from the **Supabase** build variant, so ordered columns have **no
indexed range on Supabase** (seq-scan). Note this in the upgrade doc.

---

## 5. Reference — Inlinable function constraints

The functional index only engages on a bare `WHERE col <op> $1` if the
comparison wrapper **inlines** so the planner can fold
`col <op> $1` into `extractor(col) <op> extractor($1)` and match it
against the stored index expression. This splits every variant's
functions into two strictly-separated classes.

### Inlinable: extractors and comparison wrappers

Applies to `eq_term` / `ord_term` and every supported-operator wrapper.

```sql
CREATE FUNCTION eql_v2.<name>(…)
RETURNS <type>
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT … $$;
```

Hard requirements — all four are needed for PostgreSQL to inline:

- `LANGUAGE sql` — PL/pgSQL is never inlined.
- A **single-statement** `SELECT` body.
- `IMMUTABLE` — also required for use as a functional-index expression.
- **No `SET` clause** (no pinned `search_path` / `proconfig`). A pinned
  `search_path` disables SQL-function inlining.

Also `STRICT` and `PARALLEL SAFE`. `STRICT` gives standard three-valued
logic: `col <op> NULL` yields `NULL`.

Wrapper bodies are one-liners over the extractor:

```sql
-- (domain, domain)
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b) $$;
-- (domain, jsonb) — cast the jsonb operand to the domain
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b::eql_v2_<T>_ord) $$;
-- (jsonb, domain)
AS $$ SELECT eql_v2.ord_term(a::eql_v2_<T>_ord) < eql_v2.ord_term(b) $$;
```

The extractor itself reads its term from the payload, e.g.
`SELECT eql_v2.ore_block_u64_8_256(a::jsonb)`.

### Blockers: unsupported operators

Every operator a variant does **not** support gets a blocker that always
raises.

```sql
CREATE FUNCTION eql_v2.<T>_<variant>_<op>(a …, b …)
RETURNS boolean
IMMUTABLE PARALLEL SAFE          -- NOTE: not STRICT
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_<T>_<variant>', '<op>'); END; $$
LANGUAGE plpgsql;
```

- `LANGUAGE plpgsql`, `IMMUTABLE PARALLEL SAFE`.
- **Never `STRICT`.** A `STRICT` blocker lets PostgreSQL skip the body
  and return `NULL` on a `NULL` argument, silently bypassing the
  exception. The blocker contract is *always raises* — there is an
  explicit regression test for this (§10).
- Boolean blockers delegate to the shared helper
  `eql_v2.encrypted_domain_unsupported_bool(type_name, operator_name)`
  (`src/encrypted_domain/functions.sql`) for a uniform message:
  `operator <op> is not supported for <type>`.
- Path-operator blockers (`->`, `->>`) return non-boolean types, so they
  cannot use the boolean helper — they `RAISE EXCEPTION` inline with the
  same message text.

The shared helper is itself `plpgsql`, `IMMUTABLE PARALLEL SAFE`, and
**does** carry `SET search_path = pg_catalog, extensions, public` — it
is never on an inline-critical path, so pinning is correct there.

### Allowlist wiring (mandatory)

Every **inlinable** function must be allowlisted, or the build/lint
tooling will break inlining or fail:

- `tasks/pin_search_path.sql` — otherwise the function gets a pinned
  `search_path`, which disables inlining. Add the extractor (matched by
  `pronargs = 1 AND proname = '<extractor>'`) and every wrapper name.
- `tasks/test/splinter.sh` — otherwise the linter flags
  `function_search_path_mutable`. Add one row per inlinable function
  with a short rationale.

> **Caveat — overload coverage.** A name-only allowlist clause covers
> every overload of that name; an existing clause scoped by argument
> type (e.g. an `eq_term` clause matched by `proargtypes[0]`) does
> **not** cover a new overload on a different domain. If you reuse an
> extractor name (`eq_term`, `ord_term`) that another module already
> allowlists, confirm the existing clause actually matches your new
> overload — add a fresh `pronargs`/name clause if it does not.

Blockers and the shared helper are **not** allowlisted — they carry a
pinned `search_path` like ordinary EQL functions.

---

## 6. Reference — Operators

### The operator surface

Every variant declares the **full** 12-operator surface. Supported
operators route to an inlinable wrapper; all others route to a blocker.
Declaring the full surface is what prevents fall-through to native
`jsonb`.

| Operators | Kind | Arg-shapes |
|-----------|------|-----------|
| `=` `<>` `<` `<=` `>` `>=` `~~` `~~*` `@>` `<@` | symmetric boolean (10) | `(domain,domain)`, `(domain,jsonb)`, `(jsonb,domain)` |
| `->` `->>` | path (2) | `(domain,text)`, `(domain,integer)`, `(jsonb,domain)` |

The `(*,jsonb)` / `(jsonb,*)` shapes cover ORM bind patterns where one
operand arrives as raw `jsonb`. That is **12 operators × 3 shapes = 36
`CREATE OPERATOR` statements per variant.**

### Function counts per variant (reference: int4)

| Variant | Extractor | Wrappers | Blockers | Functions | Operators |
|---------|-----------|----------|----------|-----------|-----------|
| storage `eql_v2_<T>`      | 0 | 0  | 36 | 36 | 36 |
| `eql_v2_<T>_eq`           | 1 | 6  | 30 | 37 | 36 |
| `eql_v2_<T>_ord[_ore]`    | 1 | 18 | 18 | 37 | 36 |

(Wrappers/blockers = supported/unsupported operators × 3 shapes; the
storage variant supports nothing.)

### `CREATE OPERATOR` metadata

```sql
CREATE OPERATOR = (
  FUNCTION = eql_v2.<T>_<variant>_eq,
  LEFTARG = eql_v2_<T>_<variant>, RIGHTARG = eql_v2_<T>_<variant>,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
```

- Supported operators carry full metadata: `COMMUTATOR`, `NEGATOR`, and
  selectivity estimators — `eqsel`/`neqsel` for `=`/`<>`,
  `scalarltsel`/`scalarlesel`/`scalargtsel`/`scalargesel` for the range
  operators (with matching `*joinsel`). `COMMUTATOR` lets the planner
  normalise `$1 < col` to `col > $1`; `NEGATOR` drives `NOT (…)`.
- Blockers carry minimal metadata. The wrappers inline to the index-term
  comparison *before* index matching, so this metadata is for
  plan-quality completeness, not index engagement.

### File split

Per `CLAUDE.md`: implementation in `_functions.sql`, operator
declarations in `_operators.sql`. One pair per variant:
`<T>_<variant>_functions.sql` and `<T>_<variant>_operators.sql`.

---

## 7. Reference — Test structure

- **One SQLx suite per variant**:
  `tests/sqlx/tests/encrypted_<T>[_variant]_tests.rs`.
- **Storage variant — synthetic.** No migration fixture is needed; cast
  literals (`$1::jsonb::eql_v2_<T>`), a `TEMP TABLE` for the typed-column
  case, and payload-`CHECK` probes are sufficient.
- **eq / ord variants — fixture-based** (§8). Tests cast
  `payload::eql_v2_<T>_<variant>` per query.
- Each case is an `async fn` under `#[sqlx::test]`. Source-only checks
  (e.g. the twin-sync guard) use a plain `#[test]`.
- **Twin-sync guard.** When two variants are mechanical twins (same
  surface, type-name swap only — e.g. `_ord` / `_ord_ore`), add a
  `#[test]` that reads both `.sql` files, normalises the two type names
  to a common token, and asserts the executable bodies are
  byte-identical. This pins the duplication cheaply without a
  de-duplication refactor.

### Test categories (each variant covers the applicable ones)

| Category | Applies to |
|----------|-----------|
| Supported operators return correct rows, all 3 shapes | eq, ord |
| Range operators match numeric/native semantics | ord |
| `ORDER BY extractor(col)` preserves plaintext order | ord |
| Functional index **engages** (`EXPLAIN` names the index, with `SET LOCAL enable_seqscan = off`) | eq, ord |
| Functional index **correctness** (rows via index = ground truth) | eq, ord |
| Constant-on-left / commuted shape engages the index | eq, ord |
| Index preferred at scale (no `enable_seqscan` override) | eq, ord |
| Unsupported operators raise the variant-specific error, all shapes | all |
| Blockers raise on `NULL` input (guards against `STRICT` regressing in) | all |
| Supported wrappers yield `NULL` on a `NULL` operand | eq, ord |
| Inlinability catalogue assertion (see §10) | eq, ord |
| Operator planner-metadata assertion (`COMMUTATOR`/`NEGATOR` present) | eq, ord |
| Blockers engage on a real typed column, not just cast literals | storage (+ others) |
| Domain `CHECK` rejects malformed / under-populated payloads at the cast | all |
| Twin-sync source check | twinned variants |

---

## 8. Reference — Fixtures

- **Generated, not hand-written.** Fixture generation uses three files
  under `tasks/fixtures/`:
  - `_generate_common.sh` — shared, **sourced** (not run) helper:
    resolves the Postgres/Proxy connection, and exposes
    `restart_proxy_and_wait` and `dump_fixture_table`. Reuse it as-is.
  - `encrypted_<T>_schema.sql` — per-type schema: creates the
    `bench_<T>` source table with an `eql_v2_encrypted` column and
    registers the index terms with `eql_v2.add_search_config(...)` so
    Proxy emits the terms the variants need (e.g. `unique` → HMAC,
    `ore` → ORE-block). Written to be idempotent.
  - `generate_encrypted_<T>.sh` — the per-type generator: applies the
    schema, restarts Proxy, inserts plaintext rows, and dumps the
    encrypted rows into the migration.
- The generator produces the migration
  `tests/sqlx/migrations/0NN_install_encrypted_<T>_fixture.sql`, carrying
  an `AUTO-GENERATED … DO NOT EDIT BY HAND` header.
- Encrypted payloads are produced via **CipherStash Proxy** (real HMAC
  and ORE terms), not synthesised.
- **Table shape:**

  ```sql
  CREATE TABLE encrypted_<T>_plaintext (
      id        BIGINT PRIMARY KEY,
      plaintext <native type> NOT NULL,
      payload   JSONB NOT NULL
  );
  ```

- **One payload, all terms.** Each `payload` carries every term the
  family uses (`c`, `hm`, `ob`) so a single fixture feeds every
  variant's suite — the ordered suites read `ob`, the equality suite
  reads `hm`, from the same rows.
- **Value-set design rules:**
  - Choose pivots so each range operator yields a **distinct
    cardinality** — a swapped operator then fails an assertion instead
    of silently passing.
  - Include negative values and boundary values where the type allows.
  - All values distinct, so a distinctness sweep proves no two
    plaintexts share an index term.
  - int4 uses 14 values; size similarly.

---

## 9. Reference — Build wiring & documentation

### Build

- Every `.sql` file declares its dependencies with `-- REQUIRE:` lines;
  the build resolves order with `tsort`. Required edges for a variant:
  `src/schema.sql`, `src/encrypted_domain/types.sql`, the shared
  `src/encrypted_domain/functions.sql` (for blockers), the variant's own
  `_functions.sql` (from its `_operators.sql`), and **the module that
  defines the extractor's return type** (e.g.
  `src/ore_block_u64_8_256/functions.sql` and `…/operators.sql`, or
  `src/hmac_256/functions.sql`).
- Build with `mise run clean && mise run build` — clean first; a bare
  `mise run build` can report sources up-to-date and leave stale
  `release/*.sql`.
- Confirm the **Supabase** and **Protect** build variants still build.

### Documentation

A new type is user-facing, so per `CLAUDE.md` release discipline:

- A reference page and a walkthrough under `docs/reference/`.
- A `## [Unreleased]` entry in `CHANGELOG.md` (`Added`).
- A numbered upgrade note (`U-NNN`) in the active
  `docs/upgrading/v<x>.md` — variant set, the extractor interface,
  index recipes, and the Supabase seq-scan caveat for ordered columns.
- All SQL functions/types need Doxygen `--!` comments (`@brief`,
  `@param`, `@return`, …) per `CLAUDE.md`.

---

## 10. Reference — Coverage expectations

The bar a new type's test suites must clear:

- **Full operator surface.** Every declared operator × every arg-shape
  is exercised — supported ops asserted for correctness, blocked ops
  asserted to raise the exact `operator <op> is not supported for
  <type>` message.
- **Index engagement *and* correctness.** For every index-served
  operator, assert both that `EXPLAIN` names the functional index (under
  `SET LOCAL enable_seqscan = off`) **and** that the rows returned match
  numeric/native ground truth. Cover the commuted (constant-on-left)
  shape too.
- **NULL handled both ways.** Blockers must raise on `NULL` input
  (catches a `STRICT` regression); supported wrappers must yield `NULL`
  on a `NULL` operand (three-valued logic).
- **Inlinability asserted structurally.** Query `pg_catalog.pg_proc`:
  every wrapper and a `LANGUAGE sql` extractor must have
  `lanname = 'sql'`, `provolatile = 'i'`, and `proconfig IS NULL`. Do
  not assume inlining — assert it.
- **Negative space.** Test the absence of capability: unsupported
  operators raise; and where a term is dropped by design (e.g. ordered
  variants without `hm`), strip that term from the payload and prove
  the variant still routes correctly — so an accidental regression to
  the wrong term fails instead of passing on a fully-populated fixture.
- **Payload validation.** Assert the domain `CHECK` rejects malformed
  payloads — a non-object, and an object missing the envelope (`v`,
  `i`), the ciphertext (`c`), or the variant's capability term — with a
  `violates check constraint` error at the cast.
- **Real columns, not just literals.** At least one test per variant
  runs operators against a genuine `eql_v2_<T>_<variant>`-typed table
  column, the shape a real caller writes.
- **Twin drift.** Twinned variants are pinned byte-identical by a
  source-only test.

---

## 11. Appendix — `jsonb`

`jsonb` uses the same family model but its capabilities differ from a
scalar type, so the variant set and which operators are *supported*
(vs. blocked) change:

| Domain                   | Supported operators            | Index term / extractor |
|--------------------------|--------------------------------|------------------------|
| `eql_v2_jsonb`           | none — storage only            | `c`                    |
| `eql_v2_jsonb_eq`        | `=`, `<>`                      | `hm` via `eq_term`     |
| `eql_v2_jsonb_ste_vec`   | `@>`, `<@`, `->`, `->>`, and path-scoped `=`/ordering | ste_vec terms |

Key divergences from the scalar template — the §3–§10 mechanics
otherwise hold unchanged:

- **The operator surface inverts.** For scalar types `@>`, `<@`, `->`,
  `->>` are always blockers. For the `jsonb` containment/ste_vec variant
  they are *supported* — `@>`/`<@` are real containment queries and
  `->`/`->>` are real path navigation.
- **Path operators return a sub-domain, not a scalar.** `col -> 'sel'`
  yields an encrypted value that is itself searchable; the chained
  recipe is `WHERE col -> 'sel' = $1` and an `ORDER BY` over an
  ordering extractor on the selected entry. The extractors take a
  selector, mirroring the existing ste_vec entry extractors.
- **The index term is ste_vec-shaped**, reusing the `eql_v2_encrypted`
  ste_vec machinery rather than a single scalar ORE/HMAC term.

> **Design intent, not current API.** This appendix describes the
> *target* shape, not shipped code. As of writing, `src/ste_vec/`
> exposes `eql_v2.eq_term(eql_v2.ste_vec_entry)` returning `bytea` and
> `eql_v2.ore_cllw(...)` for ordering — there is **no**
> `ord_term(ste_vec_entry)` overload, and no `eql_v2_jsonb` domain
> family exists yet. The existing `public.eql_v2_encrypted` type
> already covers general encrypted `jsonb`; an `eql_v2_jsonb` domain
> family would be the capability-scoped, fall-through-safe presentation
> of the same underlying scheme. Settle the exact extractor surface and
> the relationship to `eql_v2_encrypted` in the `jsonb` type's design
> note before implementing.
