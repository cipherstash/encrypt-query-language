# `encrypted_text` walkthrough

## Type

```sql
CREATE DOMAIN public.encrypted_text AS jsonb;
```

Domain over `jsonb`, lives in `public` so user table columns survive an `eql_v2` uninstall. No CHECK constraint (avoids cross-schema lifecycle coupling).

## Payload shape

```jsonc
{
  "v":  2,                              // EQL version
  "i":  {"t":"users","c":"email"},      // column ident
  "c":  "<base64 ciphertext>",          // AES-GCM payload
  "hm": "<hex bytes>",                  // HMAC of plaintext  → used by =, <>
  "bf": [12, 34, 56, 78, ...]           // bloom of n-grams   → used by ~~, ~~*
}
```

## Operator surface

| Operator | Function | Inlined body | Index target |
|---|---|---|---|
| `=` | `eql_v2.encrypted_text_eq` | `hmac_256(a::jsonb) = hmac_256(b::jsonb)` | btree on `((hmac_256(col::jsonb)))` |
| `<>` | `eql_v2.encrypted_text_neq` | `hmac_256(a::jsonb) <> hmac_256(b::jsonb)` | (same) |
| `~~` | `eql_v2.encrypted_text_like` | `bloom_filter(a::jsonb) @> bloom_filter(b::jsonb)` | GIN on `((bloom_filter(col::jsonb)))` |
| `~~*` | (same function as `~~`) | (same) | (same) |
| `<` `<=` `>` `>=` `@>` `<@` `->` `->>` | blockers | `RAISE` via `encrypted_domain_unsupported_bool` | n/a |

Three signature shapes per operator: `(domain, domain)`, `(domain, jsonb)`, `(jsonb, domain)`. Cross-type shapes exist so ORM-bound `jsonb` parameters resolve cleanly without falling back to native jsonb operators.

## Inlining chain

```
WHERE email = $1                                  -- (encrypted_text, jsonb)
        │
        ▼  operator → function
encrypted_text_eq(email, $1)                      -- SQL+IMMUTABLE+STRICT+PARALLEL SAFE
        │
        ▼  body inlines
hmac_256(email::jsonb) = hmac_256($1)             -- hmac_256 is plpgsql but IMMUTABLE
        │
        ▼  planner matches expression to indexed expression
USES users_email_hmac_idx
```

For `~~`:

```
WHERE email ~~ $1
        │
        ▼
encrypted_text_like(email, $1)
        │
        ▼
bloom_filter(email::jsonb) @> bloom_filter($1)    -- bloom_filter is IMMUTABLE
        │
        ▼
USES users_email_bloom_idx (GIN)
```

## File layout

```
src/encrypted_domain/
  types.sql       CREATE DOMAIN public.encrypted_text AS jsonb
  functions.sql   encrypted_text_eq / _neq / _like (× 3 shapes each)
                  encrypted_text_lt / _lte / _gt / _gte / _contains /
                    _contained_by / _arrow / _arrow_text  ← blockers
  operators.sql   CREATE OPERATOR =, <>, ~~, ~~*, <, <=, >, >=,
                    @>, <@, ->, ->>  (× 3 shapes)
```

## Inlineability guard rails

- `tasks/pin_search_path.sql` allowlist keeps `encrypted_text_eq`, `_neq`, `_like` unpinned (any `SET search_path` would break inlining).
- `tasks/test/splinter.sh` allowlist matches.
- Catalog test asserts the 3 hot-path functions are `LANGUAGE sql IMMUTABLE` with no `proconfig`.

## Test coverage

- **Synthetic** (`tests/sqlx/tests/encrypted_domain_types_tests.rs`) — hand-built minimal payloads, 13 tests including `EXPLAIN`-asserted index engagement + 3-form prepared-statement test.
- **Real-Proxy fixture** (`tests/sqlx/tests/encrypted_text_fixture_tests.rs`) — 12 tests against `tests/sqlx/migrations/008_install_encrypted_text_fixture.sql` (40 rows, plaintext-paired, generated via `mise run fixture:text:generate`). Substring families (`app/apple/application/apply`, `al/alice/alien/alignment/all/alpha`) drive bloom assertions with literal ground truth. HMAC distinctness sweep proves no plaintext collisions across the 40 rows.

## What `encrypted_text` proves about the architecture

Functional indexes engage on real Proxy output across all three signature shapes for both `=` and `~~`. HMAC and bloom dispatch independently. ORM-bound `jsonb` parameters route to the right operator without per-query rewriting. This is the cleanest of the domains — the `eql_v2_int4` variant family (range ops; see `docs/reference/encrypted-int4-domain.md`) and `encrypted_jsonb` (no top-level `hm`) hit limitations that text doesn't.
