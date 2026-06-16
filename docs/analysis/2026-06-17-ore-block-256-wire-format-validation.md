# ORE block-256 wire format — N-from-length validation

- **Date:** 2026-06-17
- **Context:** Validates the `eql_v3` N-block comparator (`eql_v3.compare_ore_block_256_term`) against a PR review claim that ore-rs always emits 8 blocks and chunks wide values into an array.
- **Verdict:** Claim does **not** hold for the pinned deps (`ore-rs 0.8.3`, `cipherstash-client 0.35.0`). Deriving block count `N` from term length is correct for what the crypto emits today.

## Claim under review

> "The current version of ore.rs is always 8-blocks output. To handle longer values, 8-block chunks are created in an array. ... the upcoming changes to ore.rs will support a variable length encoding."

## Wire format (per term)

```
[ N PRP bytes ][ N×16B left blocks ][ 16B hash key ][ N×32B right blocks ]
octet_length = 17·N + 16 + 32·N = 49·N + 16   =>   N = (octet_length − 16) / 49
```

Linear in `N` and invertible for `N ≥ 1`, so length recovers the exact `N` the encryptor used.

## Evidence

**1. ore-rs 0.8.3 — native variable width, not 8-block** ([decimal.rs](https://docs.rs/crate/ore-rs/0.8.3/source/src/decimal.rs), [chrono.rs](https://docs.rs/crate/ore-rs/0.8.3/source/src/chrono.rs))

```rust
//! ... feeding the 14-byte plaintext through the existing fixed-N ORE machinery (`N = 14`).  // L7
const ENCODED_LEN: usize = <Decimal as ToOrderableBytes>::ENCODED_LEN;                         // L16
type FullOutput = CipherText<T, ENCODED_LEN>;                                                  // L20
```

**2. cipherstash-client 0.35.0 — single full-width term, only `text` uses an array** ([ore_indexer/mod.rs](https://docs.rs/crate/cipherstash-client/0.35.0/source/src/encryption/ore_indexer/mod.rs))

```rust
// Decimal (14 bytes) and Timestamp (12 bytes) exceed the 8-byte block;
// ... encrypted at their native ore-rs widths.                                   // L136–139
Plaintext::Decimal(Some(x))   => Ok(IndexTerm::OreFull(x.encrypt(&cipher)?.to_bytes())),  // L140
Plaintext::Timestamp(Some(x)) => Ok(IndexTerm::OreFull(x.encrypt(&cipher)?.to_bytes())),  // L141
```

> doc comment: *"Strings will return an `IndexTerm::OreArray`. All other types will return a `IndexTerm::OreFull`."*

Integers go through `pad_orderable_to_8` (→ N=8); Decimal/Timestamp do **not**. `OreFull` = one term, not chunked.

**3. Real ZeroKMS fixtures — measured, end-to-end** (`tests/sqlx/fixtures/eql_v2_*.sql`)

| type | `ob` array | term bytes | derived N |
|------|-----------:|-----------:|----------:|
| int4 | 1 term | 408 | 8 (`49·8+16`) |
| timestamptz | 1 term | 604 | 12 (`49·12+16`) |
| numeric | 1 term | 702 | 14 (`49·14+16`) |

A numeric value is **one 702-byte term**, not an array of 408-byte chunks. Pinned by `numeric_term_is_14_blocks` / timestamptz-width tests in `tests/sqlx/tests/ore_block_comparator_tests.rs`.

## Correctness of the derivation

- Equal-length guard (`bit_length(a) != bit_length(b)` → raise) ⇒ `a`/`b` share `N`; deriving from `a` alone is sound and blocks cross-type comparison.
- Well-formedness guard is **both** clauses — `octet_length <= 16 OR (octet_length − 16) % 49 != 0`. Modulo alone admits a 16-byte term (`N=0`) that would silently return `0` (equal); `<= 16` is load-bearing.
- N=8 reduces to the old constants (`right_offset = 17·8 = 136`, left base `1+8 = 9`) ⇒ no-op for existing int types.
- Ordering verified against the plaintext oracle (`Decimal`/`DateTime` `Ord`) over **all pairs** + antisymmetry — `assert_orders_like_oracle`, `ore_block_comparator_tests.rs`.

## Forward-looking caveat

- The reviewer's "upcoming variable-length ore-rs" appears to already be present in 0.8.3 (native N=14/12). If a *further* format change is planned, it is a fixture-regeneration / breaking change that equally affects the existing `eql_v2` 8-block comparator — it does not make the current derivation incorrect.
- Action: confirm any tracked ore-rs format change before treating this as blocking; scope against the specific change, not an indefinite hold.

## References

- Design: `docs/plans/2026-06-11-ore-block-comparator-n-blocks-design.md`
- Comparator: `src/v3/sem/ore_block_256/functions.sql`
- Tests: `tests/sqlx/tests/ore_block_comparator_tests.rs`
- ore-rs 0.8.3: https://crates.io/crates/ore-rs/0.8.3 (no `repository` field; docs.rs source is authoritative)
- cipherstash-client 0.35.0: https://crates.io/crates/cipherstash-client/0.35.0 · repo declared: https://github.com/cipherstash/cipherstash-suite
