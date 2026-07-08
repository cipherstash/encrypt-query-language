# Native-Spelling Type Aliases

EQL generates a set of Postgres-native spelling **aliases** for its encrypted scalar domains, so a schema can use whichever native name it already reaches for — `public.int4` instead of `public.integer`, `public.float8` instead of `public.double`. Each alias is a full, standalone encrypted type; it is not a view, a cast, or a thin wrapper.

## The alias set

| Canonical | Alias    |
|-----------|----------|
| `smallint`| `int2`   |
| `integer` | `int4`   |
| `bigint`  | `int8`   |
| `real`    | `float4` |
| `double`  | `float8` |
| `numeric` | `decimal`|

Every alias carries the same domain variants as its canonical family — `public.<name>`, `public.<name>_eq`, `public.<name>_ord`, `public.<name>_ord_ore`, `public.<name>_ord_ope` — with byte-identical CHECK constraints and the same extractors (`eq_term` / `ord_term`), comparison wrappers, and `min`/`max` aggregates. Because an alias shares the canonical payload envelope exactly, a value encrypted for `public.integer` is a valid `public.int4` value and vice versa: conversion between the two is a plain value coercion, not a re-encryption.

## Always schema-qualify the domain name

> **Important:** every bare-family name in this set — `int2`, `int4`, `int8`, `float4`, `float8`, `decimal`, *and* their canonical spellings `smallint`, `integer`, `bigint`, `real`, `double precision`, `numeric` — is **also a built-in PostgreSQL type name**, resolved from `pg_catalog`, which always shadows the `public` schema. So an **unqualified** name in DDL binds the plaintext built-in type, **not** the encrypted domain:
>
> ```sql
> CREATE TABLE t (x int4);          -- ❌ plaintext built-in integer — NOT encrypted
> CREATE TABLE t (x public.int4);   -- ✅ the encrypted-domain alias
> ```
>
> This is not specific to the aliases — the canonical `public.integer` storage domain behaves identically (bare `integer` is a built-in too). Always write the **schema-qualified** name (`public.int4`, `public.integer_eq`, …) so the column is typed as the encrypted domain. The alias's value is a *familiar spelling* in that qualified form, not a new bare-name binding.

## Both-directions interop

An alias and its canonical twin interoperate in **both** directions. Comparing a `public.int4_eq` value to a `public.integer_eq` value (in either operand order) resolves the generated **cross-name operator**, which routes the comparison through the encrypted index term (HMAC for equality, ORE for ordering) — exactly as a same-name comparison would.

```sql
-- both of these engage the encrypted equality operator, never native jsonb:
SELECT a = b FROM t;                 -- a public.int4_eq, b public.integer_eq
SELECT eql_v3.eq(a, b) FROM t;       -- function form (Supabase/PostgREST)
```

This matters because the two domains share the same `jsonb` base type. Without the generated cross-name operator, a mixed comparison would silently fall through to PostgreSQL's native `jsonb` `=`, which compares the raw ciphertext (`c`) and would report two independent encryptions of the same plaintext as **not equal**. The cross-name operators exist precisely to shadow that native fallback with the correct encrypted comparison.

## Value conversion uses a plain cast

To move a value between an alias and its canonical twin, use an ordinary cast to the target domain:

```sql
SELECT $1::jsonb::public.int4_eq;    -- the same envelope, typed as the alias
```

There is **no** `CREATE CAST` between them — a cast on a PostgreSQL domain is impossible, and none is needed: both domains resolve to `jsonb`, so value coercion is free.

## Only an alias and its canonical twin interoperate

Cross-name operators are generated **only** between the names within one family group (an alias and its canonical name). Comparing two *unrelated* encrypted types — e.g. `public.integer_eq` against `public.text_eq` — has no defined operator and must not be relied upon: there is no cross-type comparison surface, and any incidental behaviour is not part of the contract.

## Adding an alias

Aliases are generated from the catalog. To add one, see the "Adding an alias" section of [Adding a scalar encrypted-domain type](./adding-a-scalar-encrypted-domain-type.md).
