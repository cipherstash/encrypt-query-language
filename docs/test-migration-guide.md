# SQL to SQLx Test Migration Guide

This guide explains how to port SQL tests to Rust/SQLx while ensuring complete coverage.

## Overview

We have three tools to track coverage during migration:

1. **Test Inventory** - Which tests have been ported
2. **Assertion Counts** - How many test assertions ported
3. **Function Call Tracking** - Which SQL functions are tested

## Workflow

### Before Starting Migration

1. **Generate baseline coverage:**

   ```bash
   # Enable function tracking
   psql postgres://cipherstash:password@localhost:7432/postgres -c "ALTER SYSTEM SET track_functions = 'all';"
   psql postgres://cipherstash:password@localhost:7432/postgres -c "SELECT pg_reload_conf();"

   # Reset stats and run SQL tests
   psql postgres://cipherstash:password@localhost:7432/postgres -c "SELECT pg_stat_reset();"
   mise run test

   # Capture baseline
   TEST_TYPE=sql ./tools/track-function-calls.sh sql-function-calls.json
   ./tools/count-assertions.sh
   ./tools/generate-test-inventory.sh
   ```

2. **Review baseline metrics:**
   - 38 SQL test files
   - ~3,917 lines of tests
   - ~513 assertions
   - Function call coverage saved in `sql-function-calls.json`

### During Migration

For each SQL test file you port:

1. **Pick a test from inventory** (`docs/test-inventory.md`)

2. **Read the SQL test**, understand what it tests

3. **Write equivalent Rust test** in `rust-tests/tests/`

4. **Run the Rust test:**
   ```bash
   cd rust-tests
   cargo test <test_name> -- --nocapture
   ```

5. **Verify function coverage:**
   ```bash
   psql postgres://cipherstash:password@localhost:7432/postgres -c "SELECT pg_stat_reset();"
   cd rust-tests && cargo test
   TEST_TYPE=rust ./tools/track-function-calls.sh rust-function-calls.json
   ./tools/compare-function-calls.sh sql-function-calls.json rust-function-calls.json
   ```

6. **Update test inventory:**
   ```bash
   ./tools/generate-test-inventory.sh
   ```

   Manually edit `docs/test-inventory.md` to mark test as ✅ Ported.

7. **Check assertion coverage:**
   ```bash
   ./tools/compare-assertions.sh
   ```

8. **Commit** when test passes and coverage verified:
   ```bash
   git add rust-tests/tests/<test_file>.rs docs/test-inventory.md
   git commit -m "test: port <feature> tests from SQL to SQLx"
   ```

### After Migration Complete

1. **Verify 100% coverage:**
   ```bash
   ./tools/check-test-coverage.sh
   ```

2. **Ensure all checks pass:**
   - ✅ All 38 tests marked as ported
   - ✅ Rust assertion count ≥ SQL assertion count
   - ✅ Rust function calls cover same functions as SQL

3. **Delete SQL tests** (only after verification):
   ```bash
   # DO NOT DO THIS UNTIL MIGRATION COMPLETE
   git rm src/**/*_test.sql
   ```

## Coverage Metrics Explained

### Test Inventory

Shows 1:1 mapping of SQL test files to Rust test files:

- **Status ❌ TODO** - Not yet ported
- **Status ✅ Ported** - Rust equivalent exists and passes

### Assertion Counts

Tracks test thoroughness:

- **SQL:** ASSERT statements, PERFORM assert_*, SELECT checks
- **Rust:** assert!(), assert_eq!(), .expect()

Goal: Rust count ≥ SQL count

### Function Call Tracking

Ensures same code paths exercised:

- Uses PostgreSQL `pg_stat_user_functions`
- Compares which `eql_v2.*` functions called in SQL vs Rust tests
- Identifies gaps: functions only in SQL tests = missing coverage

## Troubleshooting

**Q: Rust test passes but function coverage shows missing functions?**

A: Your test might not be exercising the same code paths. Review the SQL test to see which functions it calls.

**Q: Assertion count much lower in Rust?**

A: You may be using fewer, but more comprehensive assertions. That's OK if function coverage matches. Document in test inventory notes.

**Q: pg_stat_user_functions not tracking?**

A: Verify `track_functions = 'all'` in postgresql.conf and PostgreSQL reloaded.

## Tips

- **Port tests in related groups** (e.g., all operator tests together)
- **Keep both test suites running** until migration complete
- **Update inventory frequently** to track progress
- **Compare function coverage often** to catch gaps early

## See Also

- `tools/check-test-coverage.sh` - Run all coverage checks
- `docs/test-inventory.md` - Current migration status
- `docs/assertion-counts.md` - Detailed assertion breakdown
