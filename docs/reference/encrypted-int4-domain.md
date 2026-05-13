# `encrypted_int4` walkthrough

## Type

```sql
CREATE DOMAIN public.encrypted_int4 AS jsonb;
```

Same lifecycle pattern as `encrypted_text`: durable `public` domain over `jsonb`, no CHECK.

## Payload shape

Today (real Proxy, ORE blocks — quarantined):

```jsonc
{ "v": 2, "i": {...}, "c": "...", "hm": "...", "ob": [...] }
```

Prototype target (in-flight Proxy OPE-direct):

```jsonc
{ "v": 2, "i": {...}, "c": "...", "hm": "...",
  "opf": "<130 hex chars = 65 bytes; signal at index 8>" }
```

## Operator surface

| Operator | Function | Inlined body | Index target |
|---|---|---|---|
| `=` / `<>` | `eql_v2.encrypted_int4_eq` / `_neq` | `hmac_256(a::jsonb) = hmac_256(b::jsonb)` | btree on `((hmac_256(col::jsonb)))` |
| `<` `<=` `>` `>=` | `eql_v2.encrypted_int4_lt` / `_lte` / `_gt` / `_gte` | `encrypted_int4_ope_key(a) < encrypted_int4_ope_key(b)` (bytea lex compare) | btree on `((eql_v2.encrypted_int4_ope_key(col::jsonb)))` |
| `~~` `~~*` `@>` `<@` `->` `->>` | `_like` / `_ilike` / `_contains` / `_contained_by` / `_arrow` / `_arrow_text` | PL/pgSQL → `RAISE EXCEPTION 'operator X is not supported for encrypted_int4'` | n/a |

Three signature shapes per operator. Same-domain range ops carry `scalarltsel` / `scalargtsel` hints; cross-type omit them.

## OPE-key extractor

Two SQL+IMMUTABLE overloads return `bytea`, both inline to `(eql_v2.ope_cllw_u64_65(a)).bytes`:

```sql
encrypted_int4_ope_key(a encrypted_int4) → bytea
encrypted_int4_ope_key(a jsonb)          → bytea
```

## Inlining chain (range op)

```
col < $1::encrypted_int4
  └─ eql_v2.encrypted_int4_lt(encrypted_int4, encrypted_int4)   [SQL IMMUTABLE]
       └─ eql_v2.encrypted_int4_ope_key(col) < eql_v2.encrypted_int4_ope_key($1)
            └─ (eql_v2.ope_cllw_u64_65(col::jsonb)).bytes < ... [bytea built-in]
                 ⇒ planner matches functional btree on
                   ((eql_v2.encrypted_int4_ope_key(col::jsonb)))
```

## File layout

```
src/encrypted_domain/
  types.sql        # domain declaration
  functions.sql    # ope_key, _eq/_neq, _lt/_lte/_gt/_gte, blockers
  operators.sql    # CREATE OPERATOR × 3 shapes
tasks/
  pin_search_path.sql   # inline-critical allowlist (ope_key + 6 op fns)
  test/splinter.sh      # function_search_path_mutable allowlist (same 7)
```

## Inlineability guard rails

- `pin_search_path.sql` — 7 int4 names allowlisted (`encrypted_int4_ope_key` + 6 operators)
- `tasks/test/splinter.sh` — matching `function_search_path_mutable` allowlist
- `INLINEABLE_DOMAIN_FUNCTIONS` catalog test asserts SQL + IMMUTABLE + no-proconfig

## Test coverage

- **Synthetic, mixed-domain** (`tests/sqlx/tests/encrypted_domain_types_tests.rs`): `encrypted_int4_range_and_equality_use_indexes` (functional-index engagement across all 3 shapes via `EXPLAIN`), `encrypted_int4_unsupported_operators_are_blocked` (6 blockers raise).
- **Synthetic OPE-direct** (`tests/sqlx/tests/encrypted_int4_ope_tests.rs`) — 7 tests using `opf_payload(signal: u8)` modeled on `tests/sqlx/tests/ope_tests.rs:20-27`: hmac index engagement, OPE index engagement for range, range semantics, ORDER BY ordering, cross-type shapes, HMAC distinctness, blocker preservation.
- **Real-Proxy ORE fixture** (`tests/sqlx/tests/encrypted_int4_fixture_tests.rs`, 14 rows in `009_install_encrypted_int4_fixture.sql`) — 7 tests, all `#[ignore]`-d pending Proxy OPE-direct migration.

## What `encrypted_int4` proves about the architecture

Same inlineable-SQL-wrapper + functional-btree recipe extends from equality (`hmac_256`) to ordered range (`bytea` lex compare on an OPE-key extractor); only the extractor body changes, and the cryptographic emission can change underneath without touching the operator surface.
