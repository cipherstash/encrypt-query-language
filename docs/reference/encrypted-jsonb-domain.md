# `encrypted_jsonb` walkthrough

## Type

```sql
CREATE DOMAIN public.encrypted_jsonb AS jsonb;
```

Same lifecycle pattern as `encrypted_text` / `encrypted_int4`. No CHECK constraint.

## Payload shape

Real Proxy output (`unique` + `ste_vec` configs):

```json
{
  "v": 2,
  "i": {"t": "bench_jsonb", "c": "encrypted_jsonb"},
  "c": "<doc ciphertext>",
  "sv": [
    {"s": "<blake3 selector>", "b3": "<blake3 plaintext>", "c": "<leaf ct>",
     "ocv": "...", "ocf": "...", "a": false}
  ]
}
```

No top-level `hm` — equality threads through `eql_v2.encrypted_jsonb_path_value` to derive an HMAC-able token.

## Operator surface

| Operator | Function | Inlined body | Index target |
|---|---|---|---|
| `=` / `<>` | `encrypted_jsonb_eq` / `_neq` | `hmac_256(a) = hmac_256(path_value(b))` | btree on `((eql_v2.hmac_256(value::jsonb)))` |
| `@>` / `<@` | `encrypted_jsonb_contains` / `_contained_by` | `encrypted_jsonb_array(a) @> encrypted_jsonb_array(b)` | GIN on `((eql_v2.encrypted_jsonb_array(value)))` |
| `->` (text) | `encrypted_jsonb_arrow` | `path_value(eql_v2."->"(to_encrypted(a), sel))` | none (access op) |
| `->` (int) | `encrypted_jsonb_arrow_int` | same, integer selector | none |
| `->>` (text) | `encrypted_jsonb_arrow_text` | `(eql_v2."->"(to_encrypted(a), sel))::jsonb::text` | none |
| `->>` (int) | `encrypted_jsonb_arrow_text_int` | same, integer selector | none |
| `<` `<=` `>` `>=` `~~` `~~*` | `_lt/_lte/_gt/_gte/_like/_ilike` | `RAISE EXCEPTION` | n/a |

Signature shapes:

- `=`, `<>`, `@>`, `<@` — three overloads each.
- `->`, `->>` — encrypted-document-on-LHS only (`(encrypted_jsonb, text|integer)`). No reverse shape.
- Blockers — full three-shape coverage so unsupported ops never fall through to native `jsonb`.

`@>` / `<@` is exact across re-encryptions: `eql_v2.jsonb_array` (in `src/ste_vec/functions.sql`) drops the random per-row `c` ciphertext from each `sv` element and keeps deterministic fields (`s`, `b3`, `hm`, `ocv`, `ocf`, `opf`, `opv`).

## Inlining chain (representative: `@>`)

```
WHERE value @> $1::encrypted_jsonb
  → eql_v2.encrypted_jsonb_contains(value, $1)
    → eql_v2.encrypted_jsonb_array(value) @> eql_v2.encrypted_jsonb_array($1)
      → eql_v2.jsonb_array(value::jsonb) @> ...
        ⇒ matches GIN expression on
          ((eql_v2.encrypted_jsonb_array(value)))
```

## File layout

- `src/encrypted_domain/types.sql` — domain declaration
- `src/encrypted_domain/functions.sql` — `path_value` helper, supported wrappers, blockers, path operators
- `src/encrypted_domain/operators.sql` — `CREATE OPERATOR` declarations
- `tasks/fixtures/encrypted_jsonb_schema.sql` — `bench_jsonb` table, `add_search_config(unique)` + `add_search_config(ste_vec)`
- `tasks/fixtures/encrypted_jsonb_documents.json` — 8 curated docs
- `tests/sqlx/migrations/010_install_encrypted_jsonb_fixture.sql` — generated, 8 rows

## Inlineability guard rails

`pin_search_path.sql` allowlists `encrypted_jsonb_eq`, `_neq`, `_contains`, `_contained_by`, `_arrow`, `_arrow_int`, `_arrow_text`, `_arrow_text_int`, `_array` as inline-critical. `tasks/test/splinter.sh` allowlists the same names in `function_search_path_mutable`. Catalog test (`INLINEABLE_DOMAIN_FUNCTIONS`) asserts live `pg_proc.proconfig` is null for each.

## Test coverage

**Synthetic** (`tests/sqlx/tests/encrypted_domain_types_tests.rs`, hand-built payloads carrying a top-level `hm`):

- `encrypted_jsonb_equality_and_inequality_use_hmac_index` — `=`/`<>` across all three shapes; asserts `typed_jsonb_hmac_idx` engages.
- `encrypted_jsonb_containment_uses_gin_index` — `@>`/`<@` across all three shapes; asserts `typed_jsonb_array_idx` (GIN) engages.
- `encrypted_jsonb_path_operators_resolve` — `->` text/int, `->>` text/int; verifies `->>` returns parseable JSON.
- `encrypted_jsonb_path_results_support_equality_and_inequality` — `(doc -> sel) = leaf` composes via the path-local `hm` token.
- `encrypted_jsonb_unsupported_operators_are_blocked` — 6 blockers × 3 shapes raise.

**Real-Proxy fixture** (`tests/sqlx/tests/encrypted_jsonb_fixture_tests.rs`, 8 docs):

- `encrypted_jsonb_contains_finds_supersets` — doc 7 (alice+email) ⊂ doc 1; `@> doc7` matches `{1, 2, 7}`, excludes doc 6 (alice-only).
- `encrypted_jsonb_contains_cross_type_shape` — `(domain, jsonb)` matches `(domain, domain)`.
- `encrypted_jsonb_contained_by_returns_subsets` — `<@`.
- `encrypted_jsonb_containment_distinguishes_value_differences` — docs 1 vs 2 (same name+email, different score) distinguishable.
- `encrypted_jsonb_array_gin_engages_for_contains` — GIN engagement against real Proxy data.

`=`/`<>` and `->`/`->>` are NOT covered by the fixture suite. Proxy's jsonb `cast_as` does not emit a top-level `hm` — equality on real data would need a different per-document identifier (likely the first `sv` element's `b3`). Path operators require the BLAKE3-hashed selector, only obtainable by encrypting the selector text through Proxy.

## What `encrypted_jsonb` proves about the architecture

Widest operator surface of the three domains: equality + containment + path access + four blockers, three cross-type shapes apiece for the bool operators. Containment is the load-bearing case — `encrypted_jsonb_array` is the deterministic normalizer that strips per-encryption randomness, so `@>` / `<@` give ground-truth subset semantics across independently-encrypted documents, and the same single-arg extractor backs the GIN functional index. Path operators thread through the existing `eql_v2_encrypted` machinery (`to_encrypted` cast + `eql_v2."->"`), with a path-local `hm` synthesized by `encrypted_jsonb_path_value` so `(doc -> sel) = leaf` keeps inlining all the way down. The synthetic-vs-fixture split exposes a real gap: the prototype's equality story (top-level `hm`) does not match Proxy's actual jsonb output, and is currently only exercised against hand-built payloads.
