# EQL permissions & grants

## Design decision: EQL never grants permissions automatically

The EQL installer (`release/cipherstash-encrypt.sql`) issues **no `GRANT` or
`REVOKE` statements**. Access to the `eql_v3` and `eql_v3_internal` schemas — and
to the domains, functions, operators, and aggregates within them — is **strictly
opt-in**. This is a deliberate least-privilege stance, not an oversight.

Two consequences follow from standard PostgreSQL behaviour:

- PostgreSQL does **not** grant `USAGE` on a newly-created schema to `PUBLIC`
  (unlike the special-cased `public` schema). So immediately after install, only
  the **installing role (the owner)** and superusers can use `eql_v3` /
  `eql_v3_internal`.
- Functions are created with the usual default `EXECUTE` to `PUBLIC`, but that is
  moot without `USAGE` on the containing schema.

A deployment that exposes EQL to non-owner roles must grant access explicitly.

## Granting access (the opt-in step)

For an application role (for example a Supabase `authenticated` / `anon` role, or
a dedicated app role) that queries encrypted columns:

```sql
-- Required: use the public API schema and its objects.
GRANT USAGE ON SCHEMA eql_v3 TO app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA eql_v3 TO app_role;
-- Optionally keep future functions granted:
ALTER DEFAULT PRIVILEGES IN SCHEMA eql_v3 GRANT EXECUTE ON FUNCTIONS TO app_role;
```

Grant only what the deployment needs; narrow to individual functions where you
can.

### `eql_v3_internal`

`eql_v3_internal` is **not** part of the public API and normally needs no grant.
It holds index-term TYPES, unsupported-operator blockers, aggregate state
functions, opclass comparators, and CHECK validators — implementation detail.

A public `eql_v3` operator or aggregate can dispatch into an internal backing
object (a blocker, or an aggregate state function). If a low-privilege role hits
a "permission denied for schema eql_v3_internal" error while using a supported
operator or aggregate, grant it deliberately:

```sql
GRANT USAGE ON SCHEMA eql_v3_internal TO app_role;
```

Prefer granting the minimum. The **supported** operator surface is designed so
the function-form equivalents callers actually invoke (`eql_v3.eq`,
`eql_v3.jsonb_contains`, …) live in the public `eql_v3` schema — see below.

## Operators vs. function equivalents (operator-free platforms)

Not every platform can invoke custom operators. Supabase/PostgREST, for example,
exposes the database through an auto-generated REST/RPC layer that calls
**functions**, not operators — `WHERE col = $1` is not expressible over that
interface, but `eql_v3.eq(col, $1)` is.

For this reason **every supported EQL operator has a public function equivalent
in `eql_v3`**:

| Operator | Public function equivalent |
| --- | --- |
| `=` | `eql_v3.eq(a, b)` |
| `<>` | `eql_v3.neq(a, b)` |
| `<` `<=` `>` `>=` | `eql_v3.lt` / `lte` / `gt` / `gte(a, b)` |
| `@>` `<@` (text match) | `eql_v3.contains` / `contained_by(a, b)` |
| `@>` `<@` (jsonb documents) | `eql_v3.jsonb_contains` / `jsonb_contained_by(a, b)`, and the typed `eql_v3.ste_vec_contains` |
| `MIN` / `MAX` | `eql_v3.min` / `eql_v3.max` aggregates |

This invariant is enforced by
`tests/sqlx/tests/v3_operator_equivalents_tests.rs`: any supported operator whose
backing wrapper is hidden in `eql_v3_internal` fails CI.
