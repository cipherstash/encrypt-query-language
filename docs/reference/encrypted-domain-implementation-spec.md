# Encrypted Domain Type Implementation Spec

This is the scalar encrypted-domain generator contract used by `int4`.
It applies to scalar domains whose searchable payloads are represented by
the fixed term catalog in `tasks/codegen/terms.py`.

`text` and `jsonb` are outside this scalar materializer.

## 1. Model

Each generated public domain is a concrete `jsonb` domain named
`public.eql_v2_<domain>`. The manifest is intentionally small:

```toml
[domain]
int4 = []
int4_eq = ["hm"]
int4_ord_ore = ["ore"]
int4_ord = ["ore"]
```

The TOML filename supplies the type token. The `[domain]` table maps each
generated domain name to the fixed terms it carries. The generator
emits files in the manifest's declared order, so order keys in the TOML
in the order you want them to appear in generated output. Term capabilities
come only from `tasks/codegen/terms.py`:

| Term | JSON key | Extractor | Return type | Supported operators |
|---|---|---|---|---|
| `hm` | `hm` | `eq_term` | `eql_v2.hmac_256` | `=` / `<>` |
| `ore` | `ob` | `ord_term` | `eql_v2.ore_block_u64_8_256` | `=` / `<>` / `<` / `<=` / `>` / `>=` |

For current `int4`, domains carrying `ore` use JSON key `ob`, extractor
`ord_term`, and the ORE block supports equality plus ordering. A type
that needs a non-ORE equality term on an ordered domain needs a new
catalog term design, not a manifest flag.

The manifest above declares two ordered domains, `int4_ord` and
`int4_ord_ore`, carrying the same term. They are intentional twins: the
generator emits byte-identical SQL (modulo type name) so callers can pick
a name that documents intent without committing to a term family in a
future migration.

## 2. Checklist

- [ ] Author `tasks/codegen/types/<T>.toml`. The filename supplies `<T>`.
      The `[domain]` table maps generated domain names to fixed terms:

      ```toml
      [domain]
      int4 = []
      int4_eq = ["hm"]
      int4_ord_ore = ["ore"]
      int4_ord = ["ore"]
      ```

      Terms determine operator support: `hm` provides `=` / `<>`; `ore`
      provides `=` / `<>` / `<` / `<=` / `>` / `>=`.
- [ ] Add or update catalog terms in `tasks/codegen/terms.py` with tests.
- [ ] Run `mise run codegen:domain <T>` to materialise generated SQL
      while iterating, or just `mise run build` — every build
      regenerates from the manifest first.
- [ ] Generated `*_types.sql` / `*_functions.sql` / `*_operators.sql` /
      `*_aggregates.sql` are gitignored and never committed. The TOML
      manifest plus `tasks/codegen/terms.py` are the source of truth.
      Change the manifest or catalog and rebuild; do not hand-edit
      generated SQL.
- [ ] Put optional hand-written SQL in
      `src/encrypted_domain/<T>/<T>_extensions.sql` with explicit
      `-- REQUIRE:` edges. This file IS committed.
- [ ] Run `mise run test:codegen`, the relevant SQLx suites, and the
      PostgreSQL matrix before merging.

## 3. Domain Generation

The generator emits `src/encrypted_domain/<T>/<T>_types.sql` (gitignored;
materialised on every `mise run build` and on `mise run codegen:domain
<T>`) with one idempotent `DO $$ ... $$` block. Domain `CHECK`
constraints always require:

- fixed envelope keys `v` and `i`;
- ciphertext key `c`;
- catalog JSON keys for the listed terms.

For example, a domain with `["ore"]` requires `v`, `i`, `c`, and `ob`.
The baseline validation checks object presence only. A malformed term can
still fail later inside its extractor unless a future catalog design adds
stronger validation.

Every generated domain is a concrete domain over `jsonb`. Do not define
one generated domain over another generated domain; PostgreSQL resolves
operators against the underlying base type in ways that bypass the fixed
operator surface.

## 4. Extractors And Wrappers

Extractor names and return types come from `tasks/codegen/terms.py`, not
from TOML. Generated extractors and supported comparison wrappers are
inline-friendly SQL functions:

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
| `=` `<>` `<` `<=` `>` `>=` `@>` `<@` | `(domain, domain)`, `(domain, jsonb)`, `(jsonb, domain)` |
| `->` `->>` | `(domain, text)`, `(domain, integer)`, `(jsonb, domain)` |
| `?` | `(domain, text)` |
| `?|` `?&` | `(domain, text[])` |
| `@?` `@@` | `(domain, jsonpath)` |
| `#>` `#>>` `#-` | `(domain, text[])` |
| `-` | `(domain, text)`, `(domain, integer)`, `(domain, text[])` |
| `||` | `(domain, domain)`, `(domain, jsonb)`, `(jsonb, domain)` |

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
for untyped string literals in forms such as `payload::eql_v2_int4 ? 'c'`.
Use typed parameters or explicit casts (`'c'::text`) to route those forms
to the generated blocker. The generated surface blocks the typed native
operator shapes exposed by the catalog.

### Aggregates

Each ordered (ord-capable) domain additionally gets a generated
`<domain>_aggregates.sql` file declaring `MIN` / `MAX`:

- two state functions, `eql_v2.min_sfunc` and `eql_v2.max_sfunc`, and
- two aggregates, `eql_v2.min(<domain>)` and `eql_v2.max(<domain>)`.

Comparison routes through the domain's `<` / `>` operator (the ORE block
term — no decryption). The state functions are `LANGUAGE plpgsql
IMMUTABLE STRICT` **with** a pinned `SET search_path`. This is the one
place the "no pinned `search_path`" rule of §4 does not apply: aggregate
transition functions are never index expressions, so pinning is correct.
`STRICT` makes PostgreSQL seed the running state with the first non-NULL
value and skip NULLs, so an all-NULL group returns NULL. Storage-only and
equality-only domains have no comparator and emit no aggregate file.

## 6. Extension Files

Optional hand-written SQL beyond the fixed scalar surface belongs in:

```text
src/encrypted_domain/<T>/<T>_extensions.sql
```

The generator must not create this file, list it in TOML, add an
auto-generated header, or clean it during regeneration. The file must
declare its own `-- REQUIRE:` edges, usually to `<T>_types.sql` and
whichever generated function or operator file it extends. Unlike the
generated siblings, `<T>_extensions.sql` IS committed.

## 7. Indexing

Do not create operator classes on generated public domains. Index through
the extractor:

```sql
CREATE INDEX ... ON table_name USING btree (eql_v2.ord_term(col));
CREATE INDEX ... ON table_name USING hash (eql_v2.eq_term(col));
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
  (verified by `tasks/codegen/test_against_reference.py` against the
  hand-reviewed baseline in `tests/codegen/reference/<T>/`).

For ordered `int4`, keep the assertion that distinct plaintext values
produce distinct ORE blocks. Do not add assertions for term behavior that
the catalog does not promise.

## 9. Fixtures

Fixture generation should use real encrypted payloads produced through
CipherStash Proxy. A single payload table may carry every term needed by
the generated domains for that type. For `int4`, the payloads carry `c`,
`hm`, and `ob`; the equality domain reads `hm`, and ordered domains read
`ob`.

Choose values so range operators produce distinguishable result counts,
include useful boundaries, and cover omitted-term negative cases.

## 10. Build And Verification

- `mise run codegen:domain <T>` (optional; refreshes one type while
  iterating on its manifest before a full build)
- `mise run test:codegen`
- `mise run clean && mise run build` (regenerates every type's SQL
  from its manifest first, then builds the release artefacts)
- relevant SQLx suites
- `mise run test` across supported PostgreSQL versions
- `mise run --output prefix test:splinter --postgres 17` after a
  PostgreSQL 17 install has built EQL

The CI codegen job should remain a prerequisite of the PostgreSQL test
matrix so generated SQL drift is caught before database tests run.
