# High-Level Encrypted Domain Types Prototype Design

## Context

EQL currently exposes one public encrypted column type, `public.eql_v2_encrypted`,
implemented as a composite type with a single `jsonb` payload field. Query behavior
is selected dynamically from the encrypted payload terms that are present (`hm`,
`bf`, `ob`, `opf`, `opv`, `sv`, etc.).

The new goal is to add high-level SQL column types such as `encrypted_text`,
`encrypted_jsonb`, and `encrypted_int4`. These types should make application DDL
clearer and give each plaintext shape a static, predictable SQL operator surface.
They should not rely on the broad dynamic dispatch behavior of
`eql_v2_encrypted`.

The prototype is intentionally limited to:

- `public.encrypted_text`
- `public.encrypted_jsonb`
- `public.encrypted_int4`

Configuration inference, automatic registration, broad type coverage, and
production migration behavior are out of scope for the prototype. The prototype
exists to prove whether `jsonb` domain types can provide a clean client-facing
DDL surface while still producing indexable query plans without operator
classes.

## History And Spike Findings

A previous branch tried changing `eql_v2_encrypted` itself from a composite type
to a `jsonb` domain. That PR closed unmerged with failing CI, and there is no
clear written rationale for the failure. Separately, EQL has kept
`public.eql_v2_encrypted` and `public.eql_v2_configuration` outside the
`eql_v2` schema so EQL upgrades can drop and recreate `eql_v2` without
cascading into customer columns.

A transient SQL spike compared three shapes:

- domain over raw `jsonb`
- domain over `public.eql_v2_encrypted`
- independent composite type with `(data jsonb)`

The spike showed that domains over `public.eql_v2_encrypted` are ergonomic and
can use existing helpers, but inherit base EQL operators when exact domain
operators are absent. Independent composites avoid inherited behavior, but need
more casts and exact helper/operator wrappers.

The approved design is simpler: define the high-level types as domains over
raw `jsonb`, then define exact operators for supported and unsupported
operations. This removes the extra `eql_v2_encrypted` layer from the new public
types.

## Type Model

Create public domain types over `jsonb`:

```sql
CREATE DOMAIN public.encrypted_text AS jsonb;
CREATE DOMAIN public.encrypted_jsonb AS jsonb;
CREATE DOMAIN public.encrypted_int4 AS jsonb;
```

The payload remains the existing EQL encrypted JSONB payload. The specific
types do not depend on `public.eql_v2_encrypted` for storage or operator
dispatch.

Because PostgreSQL domains can fall back to base-type behavior, every public
operation in the supported SQL surface must have an exact domain operator:

- supported operations delegate to fixed index-term helpers;
- unsupported operations raise a type-specific error.

This prevents accidental fallback to native `jsonb` semantics for common SQL
operators.

## Prototype Acceptance Criteria

The prototype must prove these properties:

- exact domain operators resolve for supported operations;
- exact blocker operators prevent common unsupported operations from falling
  through to native `jsonb` behavior;
- supported hot-path operator functions are inlineable SQL functions with no
  `SET search_path` clause;
- bare operator predicates use functional indexes and do not require custom
  btree or hash operator classes;
- where existing helper signatures are awkward, temporary typed helper wrappers
  are small, `LANGUAGE sql`, immutable, strict, parallel-safe, and inlineable
  when used in indexed predicates.

## Operator Surface

### `encrypted_text`

Supported:

- `=` and `<>`, using the `hm` term through `eql_v2.hmac_256(value::jsonb)`
- `~~` and `~~*`, using the `bf` term through `eql_v2.bloom_filter(value::jsonb)`

Unsupported blockers:

- `<`, `<=`, `>`, `>=`
- `@>`, `<@`
- `->`, `->>`

### `encrypted_int4`

Supported:

- `=` and `<>`, using the `hm` term through `eql_v2.hmac_256(value::jsonb)`
- `<`, `<=`, `>`, `>=`, using OPE terms by default through an inlineable
  expression over `value::jsonb`

Unsupported blockers:

- `~~`, `~~*`
- `@>`, `<@`
- `->`, `->>`

### `encrypted_jsonb`

Supported:

- `=` and `<>`, using the `hm` term through `eql_v2.hmac_256(value::jsonb)`
- `@>` and `<@`, using `sv` through inlineable typed STE vector helpers or
  wrappers
- `->` and `->>`, using stubbed or adapted encrypted JSON path helpers for the
  domain type

Unsupported blockers:

- `<`, `<=`, `>`, `>=`
- `~~`, `~~*`

## Out Of Scope

Do not add configuration inference in this prototype. The prototype should not
change `eql_v2.add_column`, `eql_v2.add_search_config`, or the configuration
validation functions.

Do not add automatic registration or event triggers in this prototype.

Do not add full support for additional encrypted scalar types in this prototype.
The three selected types are enough to test text, scalar range, and JSONB
operator behavior.

## Error Handling

Unsupported exact operators should raise clear errors:

```text
operator < is not supported for encrypted_text
operator ~~ is not supported for encrypted_int4
operator -> is not supported for encrypted_int4
```

Missing required encrypted index terms should fail through the fixed helper path
with the existing helper errors, such as missing `hm`, `bf`, `opf`, or `sv`.

Supported hot-path functions should not raise custom errors for missing terms if
an existing helper already provides a precise missing-term error.

## Testing

Add focused SQLx coverage for the first three domain types:

- Domain creation and assignment from valid encrypted JSONB payloads.
- Supported operators for each type.
- Unsupported operators raise the exact type-specific error instead of falling
  through to native `jsonb` behavior.
- Functional indexes engage for supported terms:
  - `encrypted_text`: `eql_v2.hmac_256(col::jsonb)`,
    `eql_v2.bloom_filter(col::jsonb)`
  - `encrypted_int4`: `eql_v2.hmac_256(col::jsonb)`, and an OPE order
    expression over `col::jsonb`
  - `encrypted_jsonb`: `eql_v2.hmac_256(col::jsonb)`, and a typed STE vector
    array helper or overload that accepts `encrypted_jsonb`
- `EXPLAIN` plans show index scans for bare operator predicates such as
  `col = rhs`, `col ~~ rhs`, `col < rhs`, and `col @> rhs`.
- The same predicates do not require btree/hash operator classes.
- Prepared statements with domain-typed parameters still resolve to exact
  domain operators.

## Implementation Boundary

Write the first three type surfaces manually. Do not introduce a generator in
the prototype. Manual SQL keeps the spike easy to audit and
lets tests prove the domain-over-`jsonb` approach before expanding to
`encrypted_int2`, `encrypted_int8`, numeric, floating-point, boolean, date, and
timestamp types.

Supported operator functions and helper wrappers that appear in indexed
predicates must be SQL-language functions intended for planner inlining.
Unsupported blocker functions can use PL/pgSQL because they are not performance
paths.
