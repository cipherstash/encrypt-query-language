# `eql_v2_int4` variant family walkthrough

The `eql_v2_int4` domain family is a Tailwind-style set of five
jsonb-backed PostgreSQL domains. Each variant's name declares the
operators it supports, and therefore the index terms its column
payloads must carry.

## Variant comparison

| Domain                       | Operators supported            | Payload terms required | Index-engagement |
|------------------------------|--------------------------------|------------------------|------------------|
| `public.eql_v2_int4_ct`      | none (all blockers)            | `c` only               | n/a              |
| `public.eql_v2_int4_eq`      | `=`, `<>`                      | `hm`                   | functional btree on `((eql_v2.hmac_256(col::jsonb)))` for `=`; `<>` seq-scan |
| `public.eql_v2_int4_ord_ore` | `=`, `<>`, `<`, `<=`, `>`, `>=` | `hm`, `ob`             | btree (equality); range seq-scan |
| `public.eql_v2_int4_ord_ope` | `=`, `<>`, `<`, `<=`, `>`, `>=` | `hm`, `opf`            | functional btree on `((eql_v2.eql_v2_int4_ord_ope_ope_key(col::jsonb)))` |
| `public.eql_v2_int4`         | same as `_ord_ore`             | `hm`, `ob`             | same as `_ord_ore` |

## Per-variant detail

### `eql_v2_int4_ct` — storage only

Payload terms: `c`. Use when you need an encrypted column but no
operator surface. Every operator (`=`, `<>`, `<`, `<=`, `>`, `>=`,
`~~`, `~~*`, `@>`, `<@`, `->`, `->>`) raises
`operator X is not supported for eql_v2_int4_ct`.

### `eql_v2_int4_eq` — HMAC equality

Payload terms: `hm`. Operators: `=`, `<>`.

Recommended index:

```sql
CREATE INDEX users_age_hmac_idx ON users
USING btree ((eql_v2.hmac_256(age::jsonb)));
```

`=` engages the index; `<>` is seq-scan (btree supports only equality).

### `eql_v2_int4_ord_ore` and the default `eql_v2_int4` — HMAC + ORE-block

Payload terms: `hm`, `ob`. Operators: `=`, `<>`, `<`, `<=`, `>`, `>=`.

Recommended index for equality:

```sql
CREATE INDEX orders_amount_hmac_idx ON orders
USING btree ((eql_v2.hmac_256(amount::jsonb)));
```

Range queries are seq-scan: `compare_ore_block_u64_8_256` is PL/pgSQL
and does not inline. If range performance matters, use
`eql_v2_int4_ord_ope` instead.

ORDER BY caveat: `ORDER BY col` on a jsonb-backed domain follows
native jsonb comparison, not ORE order. Sort by the extractor
expression:

```sql
ORDER BY eql_v2.ore_block_u64_8_256(col::jsonb)
```

### `eql_v2_int4_ord_ope` — HMAC + OPE-direct

Payload terms: `hm`, `opf`. Operators: `=`, `<>`, `<`, `<=`, `>`, `>=`.

Recommended indexes:

```sql
CREATE INDEX prices_hmac_idx ON prices
USING btree ((eql_v2.hmac_256(price::jsonb)));

CREATE INDEX prices_ope_idx ON prices
USING btree ((eql_v2.eql_v2_int4_ord_ope_ope_key(price::jsonb)));
```

Both `=` and range operators engage their respective functional
btrees.

ORDER BY caveat: sort by the OPE-key extractor:

```sql
ORDER BY eql_v2.eql_v2_int4_ord_ope_ope_key(col::jsonb)
```

## Inlining chain

For `_ord_ope` range queries, the planner sees a clean three-layer
inline chain through to a built-in `bytea` compare:

```
col < $1::eql_v2_int4_ord_ope
  └─ eql_v2.eql_v2_int4_ord_ope_lt(eql_v2_int4_ord_ope, eql_v2_int4_ord_ope) [SQL IMMUTABLE]
       └─ eql_v2.eql_v2_int4_ord_ope_ope_key(col) < eql_v2.eql_v2_int4_ord_ope_ope_key($1)
            └─ (eql_v2.ope_cllw_u64_65(col::jsonb)).bytes < ... [bytea built-in]
                 ⇒ planner matches functional btree on
                   ((eql_v2.eql_v2_int4_ord_ope_ope_key(col::jsonb)))
```

For `_ord_ore`, the equivalent chain terminates in a PL/pgSQL
function (`compare_ore_block_u64_8_256`) that the planner cannot
inline; range predicates fall back to seq-scan.

## File layout

```
src/encrypted_domain/
  types.sql                    # five domain declarations (CT/EQ/ORD_ORE/ORD_OPE/default)
  functions.sql                # shared blocker helper; text + jsonb wrappers
  operators.sql                # CREATE OPERATOR for text + jsonb
  int4/
    int4_ct.sql                # all-blocker variant
    int4_eq.sql                # HMAC equality + blockers
    int4_ord_ore.sql           # HMAC = + ORE-block range + blockers
    int4_ord_ope.sql           # HMAC = + OPE-direct range + extractor + blockers
    int4_default.sql           # mirror of _ord_ore under the eql_v2_int4 name
tasks/
  pin_search_path.sql          # inline-critical allowlist (21 wrapper names)
  test/splinter.sh             # function_search_path_mutable mirror
```

## Inlineability guard rails

- `pin_search_path.sql` allowlists ~21 inline-critical wrapper names
  (equality + range wrappers for all four operator-bearing variants,
  plus the `_ord_ope` extractor). Blockers are intentionally absent —
  they must stay PL/pgSQL.
- `tasks/test/splinter.sh` mirrors the allowlist for the splinter
  lint pass.
- `INLINEABLE_DOMAIN_FUNCTIONS` catalog test asserts each allowlisted
  wrapper is `LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE` and has no
  pinned `proconfig`.

## Test coverage

Per-variant Rust/SQLx test files under `tests/sqlx/tests/`:

- `encrypted_int4_ct_tests.rs` — every operator raises on the
  storage-only variant.
- `encrypted_int4_eq_tests.rs` — HMAC functional btree engages for `=`;
  `<>` returns correct rows but is seq-scan; cross-type shapes work;
  all other operators raise.
- `encrypted_int4_ord_ore_tests.rs` — real-Proxy ORE-block fixture
  (`009_install_encrypted_int4_fixture.sql`, 14 rows). Asserts
  equality engages the hmac btree, range returns numerically-correct
  rows, and ORDER BY via `ore_block_u64_8_256` preserves numeric order.
- `encrypted_int4_ord_ope_tests.rs` — synthetic `opf` payloads. Both
  the hmac and OPE-key functional btrees engage; range operators
  pass numeric semantics; blockers raise.
- `encrypted_int4_default_tests.rs` — smoke test plus
  EXPLAIN-equivalence assertion against `_ord_ore` to detect
  behavioural drift between the duplicated wrappers.
