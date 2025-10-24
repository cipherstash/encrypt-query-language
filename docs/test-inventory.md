# Test Inventory - SQL to SQLx Migration

Generated: 2025-10-24

| # | SQL Test File | Test Cases | Lines | Status | Rust Test File | Notes |
|---|---------------|------------|-------|--------|----------------|-------|
| 1 | `src/blake3/compare_test.sql` | 1 | 26 | ❌ TODO | `*TBD*` | |
| 2 | `src/bloom_filter/functions_test.sql` | 1 | 14 | ❌ TODO | `*TBD*` | |
| 3 | `src/config/config_test.sql` | 9 | 331 | ❌ TODO | `*TBD*` | |
| 4 | `src/encrypted/aggregates_test.sql` | 1 | 50 | ❌ TODO | `*TBD*` | |
| 5 | `src/encrypted/constraints_test.sql` | 3 | 79 | ❌ TODO | `*TBD*` | |
| 6 | `src/encryptindex/functions_test.sql` | 7 | 290 | ❌ TODO | `*TBD*` | |
| 7 | `src/hmac_256/compare_test.sql` | 1 | 26 | ❌ TODO | `*TBD*` | |
| 8 | `src/hmac_256/functions_test.sql` | 2 | 26 | ❌ TODO | `*TBD*` | |
| 9 | `src/jsonb/functions_test.sql` | 12 | 338 | ❌ TODO | `*TBD*` | |
| 10 | `src/operators/->>_test.sql` | 4 | 68 | ❌ TODO | `*TBD*` | |
| 11 | `src/operators/->_test.sql` | 6 | 118 | ❌ TODO | `*TBD*` | |
| 12 | `src/operators/<=_ore_cllw_u64_8_test.sql` | 1 | 56 | ❌ TODO | `*TBD*` | |
| 13 | `src/operators/<=_ore_cllw_var_8_test.sql` | 1 | 52 | ❌ TODO | `*TBD*` | |
| 14 | `src/operators/<=_test.sql` | 2 | 83 | ❌ TODO | `*TBD*` | |
| 15 | `src/operators/<>_ore_cllw_u64_8_test.sql` | 1 | 56 | ❌ TODO | `*TBD*` | |
| 16 | `src/operators/<>_ore_cllw_var_8_test.sql` | 1 | 55 | ❌ TODO | `*TBD*` | |
| 17 | `src/operators/<>_ore_test.sql` | 2 | 86 | ❌ TODO | `*TBD*` | |
| 18 | `src/operators/<>_test.sql` | 5 | 164 | ❌ TODO | `*TBD*` | |
| 19 | `src/operators/<@_test.sql` | 1 | 43 | ❌ TODO | `*TBD*` | |
| 20 | `src/operators/<_test.sql` | 4 | 158 | ❌ TODO | `*TBD*` | |
| 21 | `src/operators/=_ore_cllw_u64_8_test.sql` | 1 | 55 | ❌ TODO | `*TBD*` | |
| 22 | `src/operators/=_ore_cllw_var_8_test.sql` | 1 | 52 | ❌ TODO | `*TBD*` | |
| 23 | `src/operators/=_ore_test.sql` | 2 | 86 | ❌ TODO | `*TBD*` | |
| 24 | `src/operators/=_test.sql` | 6 | 195 | ❌ TODO | `*TBD*` | |
| 25 | `src/operators/>=_test.sql` | 4 | 174 | ❌ TODO | `*TBD*` | |
| 26 | `src/operators/>_test.sql` | 4 | 158 | ❌ TODO | `*TBD*` | |
| 27 | `src/operators/@>_test.sql` | 3 | 93 | ❌ TODO | `*TBD*` | |
| 28 | `src/operators/compare_test.sql` | 7 | 207 | ❌ TODO | `*TBD*` | |
| 29 | `src/operators/operator_class_test.sql` | 3 | 239 | ❌ TODO | `*TBD*` | |
| 30 | `src/operators/order_by_test.sql` | 3 | 148 | ❌ TODO | `*TBD*` | |
| 31 | `src/operators/~~_test.sql` | 3 | 107 | ❌ TODO | `*TBD*` | |
| 32 | `src/ore_block_u64_8_256/compare_test.sql` | 1 | 27 | ❌ TODO | `*TBD*` | |
| 33 | `src/ore_block_u64_8_256/functions_test.sql` | 3 | 58 | ❌ TODO | `*TBD*` | |
| 34 | `src/ore_cllw_u64_8/compare_test.sql` | 1 | 29 | ❌ TODO | `*TBD*` | |
| 35 | `src/ore_cllw_var_8/compare_test.sql` | 1 | 29 | ❌ TODO | `*TBD*` | |
| 36 | `src/ore_cllw_var_8/functions_test.sql` | 0 | 0 | ❌ TODO | `*TBD*` | |
| 37 | `src/ste_vec/functions_test.sql` | 6 | 132 | ❌ TODO | `*TBD*` | |
| 38 | `src/version_test.sql` | 1 | 9 | ❌ TODO | `*TBD*` | |

## Summary

- **Total SQL Test Files:** 38
- **Total Test Cases:** 115
- **Total Lines:** 3917

## Usage

Update this inventory as you port tests:
1. Mark status ✅ when Rust test passes
2. Add Rust test file path
3. Add notes for any deviations

Regenerate: `./tools/generate-test-inventory.sh`
