# Assertion Count Report

Generated: 2025-10-24

# SQL Test Assertions

| File | ASSERT | PERFORM assert_* | SELECT checks | Total |
|------|--------|------------------|---------------|-------|
| `src/blake3/compare_test.sql` | 9 | 0 | 0 | 9 |
| `src/bloom_filter/functions_test.sql` | 0 | 2 | 0 | 2 |
| `src/config/config_test.sql` | 26 | 4 | 11 | 41 |
| `src/encrypted/aggregates_test.sql` | 4 | 0 | 2 | 6 |
| `src/encrypted/constraints_test.sql` | 0 | 6 | 0 | 6 |
| `src/encryptindex/functions_test.sql` | 21 | 1 | 19 | 41 |
| `src/hmac_256/compare_test.sql` | 9 | 0 | 0 | 9 |
| `src/hmac_256/functions_test.sql` | 1 | 2 | 0 | 3 |
| `src/jsonb/functions_test.sql` | 4 | 24 | 0 | 28 |
| `src/operators/->>_test.sql` | 0 | 6 | 0 | 6 |
| `src/operators/->_test.sql` | 2 | 9 | 0 | 11 |
| `src/operators/<=_ore_cllw_u64_8_test.sql` | 0 | 3 | 3 | 6 |
| `src/operators/<=_ore_cllw_var_8_test.sql` | 0 | 3 | 3 | 6 |
| `src/operators/<=_test.sql` | 0 | 8 | 4 | 12 |
| `src/operators/<>_ore_cllw_u64_8_test.sql` | 0 | 3 | 0 | 3 |
| `src/operators/<>_ore_cllw_var_8_test.sql` | 0 | 3 | 0 | 3 |
| `src/operators/<>_ore_test.sql` | 0 | 8 | 0 | 8 |
| `src/operators/<>_test.sql` | 0 | 12 | 2 | 14 |
| `src/operators/<@_test.sql` | 0 | 2 | 0 | 2 |
| `src/operators/<_test.sql` | 0 | 12 | 1 | 13 |
| `src/operators/=_ore_cllw_u64_8_test.sql` | 0 | 3 | 3 | 6 |
| `src/operators/=_ore_cllw_var_8_test.sql` | 0 | 3 | 3 | 6 |
| `src/operators/=_ore_test.sql` | 0 | 8 | 4 | 12 |
| `src/operators/=_test.sql` | 0 | 16 | 12 | 28 |
| `src/operators/>=_test.sql` | 0 | 14 | 10 | 24 |
| `src/operators/>_test.sql` | 0 | 12 | 1 | 13 |
| `src/operators/@>_test.sql` | 4 | 2 | 0 | 6 |
| `src/operators/compare_test.sql` | 63 | 0 | 0 | 63 |
| `src/operators/operator_class_test.sql` | 16 | 1 | 24 | 41 |
| `src/operators/order_by_test.sql` | 0 | 16 | 4 | 20 |
| `src/operators/~~_test.sql` | 0 | 10 | 0 | 10 |
| `src/ore_block_u64_8_256/compare_test.sql` | 9 | 0 | 0 | 9 |
| `src/ore_block_u64_8_256/functions_test.sql` | 1 | 5 | 2 | 8 |
| `src/ore_cllw_u64_8/compare_test.sql` | 9 | 0 | 0 | 9 |
| `src/ore_cllw_var_8/compare_test.sql` | 9 | 0 | 0 | 9 |
| `src/ore_cllw_var_8/functions_test.sql` | 0 | 0 | 0 | 0 |
| `src/ste_vec/functions_test.sql` | 18 | 0 | 0 | 18 |
| `src/version_test.sql` | 0 | 1 | 1 | 2 |

**Total SQL assertions:** 513 across 38 files

# Rust Test Assertions

| File | assert* | expect* | is_err/is_ok | Total |
|------|---------|---------|--------------|-------|
| `rust-tests/tests/add_column_test.rs` | 0 | 0 | 0 | 0 |
| `rust-tests/tests/test_helpers_test.rs` | 0 | 0 | 0 | 0 |

**Total Rust assertions:** 0 across 2 files
