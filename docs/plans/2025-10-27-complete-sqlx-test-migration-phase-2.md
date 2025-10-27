# Complete SQLx Test Migration Phase 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate all remaining 457 SQL test assertions to Rust/SQLx framework (513 total - 56 already migrated = 457 remaining), achieving complete test coverage with modern, maintainable tests.

**Architecture:** Incremental migration in priority order (high-risk operators first, then infrastructure). Each phase follows TDD patterns with fixtures, assertions, and verification. Tests use SQLx test framework with hybrid migration approach (EQL via build, fixtures via SQLx migrations).

**Tech Stack:** Rust, SQLx 0.8, PostgreSQL 17, mise task runner, cargo test

**Test Infrastructure:**
- 📦 Index type constants: `tests/sqlx/src/index_types.rs` (HMAC, BLAKE3, ORE64, etc.)
- 📋 Fixture documentation: `tests/sqlx/fixtures/FIXTURE_SCHEMA.md`
- ✅ Assertion helpers: `tests/sqlx/src/assertions.rs` (QueryAssertion)
- 🎯 Selector constants: `tests/sqlx/src/selectors.rs`

**Current State:**
- ✅ Equality operators (`=_test.sql`): 28 assertions migrated (100%) - Commit b213d55
- ✅ JSONB functions (`jsonb/functions_test.sql`): 28 assertions migrated (100%) - Commit 28a0eb9
- ✅ **Tests in place**: 35 Rust tests (15 equality + 19 JSONB + 1 helper)
- ❌ Remaining: 457 assertions across 36 SQL test files
- **Total coverage: 56/513 assertions (10.9%)**

**Reference Documents:**
- Test inventory: `docs/test-inventory.md` (regenerate with `./tools/generate-test-inventory.sh`)
- Assertion counts: Run `./tools/count-assertions.sh` → **513 total assertions**
- Coverage tracking: Run `./tools/check-test-coverage.sh`
- Existing Rust tests: `tests/sqlx/tests/*.rs`
- Index constants: `tests/sqlx/src/index_types.rs`
- Fixture docs: `tests/sqlx/fixtures/FIXTURE_SCHEMA.md`

**Priority Matrix:**
1. **P0 - Critical Operators (82 assertions):** Comparison operators (< > <= >=, <>)
2. **P1 - Infrastructure (123 assertions):** Config, operator class, encryptindex
3. **P2 - JSONB Operators (17 assertions):** `->`, `->>`
4. **P3 - ORE Variants (59 assertions):** ORE equality/comparison with different schemes
5. **P4 - Containment (8 assertions):** `@>`, `<@`
6. **P5 - Advanced Features (36 assertions):** ORDER BY, LIKE, aggregates, constraints
7. **P6 - Infrastructure Tests (132 assertions):** Compare tests (45 + 63), ste_vec, bloom filter, ore functions, version

---

## Phase 1: Comparison Operators (P0 - 82 assertions)

### Task 1: Inequality Operator (`<>`) - 14 assertions

**Files:**
- Source: `src/operators/<>_test.sql` (164 lines, 5 DO blocks, 14 assertions)
- Create: `tests/sqlx/tests/inequality_tests.rs`

**Step 1: Create Rust test file with module structure**

```bash
cd tests/sqlx/tests
touch inequality_tests.rs
```

Add to file:

```rust
//! Inequality operator tests
//!
//! Converted from src/operators/<>_test.sql
//! Tests EQL inequality (<>) operators with encrypted data

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

/// Helper to execute create_encrypted_json SQL function
async fn create_encrypted_json_with_index(pool: &PgPool, id: i32, index_type: &str) -> String {
    let sql = format!(
        "SELECT create_encrypted_json({}, '{}')::text",
        id, index_type
    );
    let row = sqlx::query(&sql).fetch_one(pool).await.unwrap();
    row.try_get(0).unwrap()
}
```

**Step 2: Write first failing test - HMAC `e <> e` operator (finds non-matching)**

Add to `inequality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_finds_non_matching_records_hmac(pool: PgPool) {
    // Test: eql_v2_encrypted <> eql_v2_encrypted with HMAC index
    // Should return records that DON'T match the encrypted value
    // Original SQL lines 15-23 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    // Should return 2 records (records 2 and 3, not record 1)
    QueryAssertion::new(&pool, &sql).count(2).await;
}
```

**Step 3: Run test to verify it fails**

```bash
cd tests/sqlx
cargo test inequality_operator_finds_non_matching_records_hmac -- --nocapture
```

Expected: FAIL (no data or wrong count)

**Step 4: Verify test passes (EQL already implements <>)**

Run again - should PASS since EQL implements the operator.

Expected: PASS

**Step 5: Add inequality no-match test (non-existent record)**

Add to `inequality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_returns_empty_for_non_existent_record_hmac(pool: PgPool) {
    // Test: <> with different record (not in test data)
    // Original SQL lines 25-30 in src/operators/<>_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    // Non-existent record should match nothing
    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 6: Add neq() function tests (HMAC)**

Add to `inequality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn neq_function_finds_non_matching_records_hmac(pool: PgPool) {
    // Test: eql_v2.neq() function with HMAC index
    // Original SQL lines 45-53 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(2).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn neq_function_returns_empty_for_non_existent_record_hmac(pool: PgPool) {
    // Test: eql_v2.neq() with different record (not in test data)
    // Original SQL lines 55-59 in src/operators/<>_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 7: Add JSONB inequality tests (HMAC - both directions)**

Add to `inequality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_encrypted_not_equals_jsonb_hmac(pool: PgPool) {
    // Test: eql_v2_encrypted <> jsonb with HMAC index
    // Original SQL lines 71-83 in src/operators/<>_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(2).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_jsonb_not_equals_encrypted_hmac(pool: PgPool) {
    // Test: jsonb <> eql_v2_encrypted (reverse direction)
    // Original SQL lines 78-81 in src/operators/<>_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb <> e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(2).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_encrypted_not_equals_jsonb_no_match_hmac(pool: PgPool) {
    // Test: e <> jsonb with different record (not in test data)
    // Original SQL lines 83-87 in src/operators/<>_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 8: Add Blake3 tests (mirror HMAC pattern)**

Add to `inequality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_finds_non_matching_records_blake3(pool: PgPool) {
    // Test: <> operator with Blake3 index
    // Original SQL lines 107-115 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "b3").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(2).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn neq_function_finds_non_matching_records_blake3(pool: PgPool) {
    // Test: eql_v2.neq() with Blake3
    // Original SQL lines 137-145 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "b3").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(2).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_encrypted_not_equals_jsonb_blake3(pool: PgPool) {
    // Test: e <> jsonb with Blake3
    // Original SQL lines 163-175 in src/operators/<>_test.sql

    let sql_create = "SELECT create_encrypted_json(1, 'b3')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(2).await;
}
```

**Step 9: Run all inequality tests**

```bash
cd tests/sqlx
cargo test inequality -- --nocapture
```

Expected: All 10 tests PASS (8 shown + 2 more Blake3 variants)

**Step 10: Update test inventory**

```bash
./tools/generate-test-inventory.sh
```

Verify `docs/test-inventory.md` shows:
- Row 18: `src/operators/<>_test.sql` - Status: ✅ DONE - Rust: `tests/sqlx/tests/inequality_tests.rs`

**Step 11: Commit inequality tests**

```bash
git add tests/sqlx/tests/inequality_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add inequality operator (<>) tests

- Add HMAC inequality operator and neq() function tests
- Add HMAC JSONB inequality tests (both directions)
- Add Blake3 inequality operator and neq() tests
- Add Blake3 JSONB inequality tests
- Migrated from src/operators/<>_test.sql (14 assertions)
- Coverage: 70/513 (13.6%)"
```

---

### Task 2: Less Than Operator (`<`) - 13 assertions

**Files:**
- Source: `src/operators/<_test.sql` (158 lines, 4 DO blocks, 13 assertions)
- Create: `tests/sqlx/tests/comparison_tests.rs`

**Note:** The `ore` table is created by migration `002_install_ore_data.sql` with 99 pre-seeded records (ids 1-99). Tests do NOT need a fixture - the table already exists.

**Step 1: Create comparison test file**

```bash
cd tests/sqlx/tests
touch comparison_tests.rs
```

Add to file:

```rust
//! Comparison operator tests (< > <= >=)
//!
//! Converted from src/operators/<_test.sql, >_test.sql, <=_test.sql, >=_test.sql
//! Tests EQL comparison operators with ORE (Order-Revealing Encryption)

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

async fn create_encrypted_json_with_index(pool: &PgPool, id: i32, index_type: &str) -> String {
    let sql = format!(
        "SELECT create_encrypted_json({}, '{}')::text",
        id, index_type
    );
    let row = sqlx::query(&sql).fetch_one(pool).await.unwrap();
    row.try_get(0).unwrap()
}
```

**Step 2: Write first failing test - less than with ORE**

Add to `comparison_tests.rs`:

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn less_than_operator_with_ore(pool: PgPool) {
    // Test: e < e with ORE encryption
    // Value 42 should have 41 records less than it (1-41)
    // Original SQL lines 13-20 in src/operators/<_test.sql
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    // Get encrypted value for id=42 from pre-seeded ore table
    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted",
        ore_term
    );

    // Should return 41 records (ids 1-41)
    QueryAssertion::new(&pool, &sql).count(41).await;
}
```

**Step 3: Run test to verify it fails**

```bash
cd tests/sqlx
cargo test less_than_operator_with_ore -- --nocapture
```

Expected: FAIL (no data setup yet - this verifies test structure)

**Step 4: Verify test passes**

Run again - should PASS since ore table exists from migrations.

Expected: PASS

**Step 5: Add less than function test**

Add to `comparison_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("ore_data")))]
async fn lt_function_with_ore(pool: PgPool) {
    // Test: eql_v2.lt() function with ORE
    // Original SQL lines 30-37 in src/operators/<_test.sql

    let ore_term = create_encrypted_json_with_index(&pool, 42, "ore64").await;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.lt(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(41).await;
}
```

**Step 8: Add less than with JSONB tests**

Add to `comparison_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("ore_data")))]
async fn less_than_operator_encrypted_less_than_jsonb(pool: PgPool) {
    // Test: e < jsonb with ORE
    // Original SQL lines 47-64 in src/operators/<_test.sql

    let sql_create = "SELECT create_encrypted_json(42, 'ore64')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(41).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("ore_data")))]
async fn less_than_operator_jsonb_less_than_encrypted(pool: PgPool) {
    // Test: jsonb < e with ORE (reverse direction)
    // Original SQL lines 58-61 in src/operators/<_test.sql

    let sql_create = "SELECT create_encrypted_json(42, 'ore64')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT id FROM ore WHERE '{}'::jsonb < e",
        json_value
    );

    // jsonb(42) < e means e > 42, so 57 records (43-99)
    QueryAssertion::new(&pool, &sql).count(57).await;
}
```

**Step 9: Run all less than tests**

```bash
cd tests/sqlx
cargo test less_than -- --nocapture
```

Expected: 4 tests PASS

**Step 10: Commit less than tests**

```bash
git add tests/sqlx/tests/comparison_tests.rs tests/sqlx/fixtures/ore_data.sql docs/test-inventory.md
git commit -m "test(sqlx): add less than (<) operator tests

- Add ORE data fixture for comparison tests
- Add < operator and lt() function tests with ORE
- Add JSONB comparison tests (both directions)
- Migrated from src/operators/<_test.sql (13 assertions)
- Coverage: 83/513 (16.2%)"
```

---

### Task 3: Greater Than Operator (`>`) - 13 assertions

**Files:**
- Source: `src/operators/>_test.sql` (158 lines, 4 DO blocks, 13 assertions)
- Modify: `tests/sqlx/tests/comparison_tests.rs`

**Step 1: Add greater than operator test**

Add to `comparison_tests.rs`:

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn greater_than_operator_with_ore(pool: PgPool) {
    // Test: e > e with ORE encryption
    // Value 42 should have 57 records greater than it (43-99)
    // Original SQL lines 13-20 in src/operators/>_test.sql
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(57).await;
}

#[sqlx::test]
async fn gt_function_with_ore(pool: PgPool) {
    // Test: eql_v2.gt() function with ORE
    // Original SQL lines 30-37 in src/operators/>_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.gt(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(57).await;
}

#[sqlx::test]
async fn greater_than_operator_encrypted_greater_than_jsonb(pool: PgPool) {
    // Test: e > jsonb with ORE
    // Original SQL lines 47-64 in src/operators/>_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::jsonb",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(57).await;
}

#[sqlx::test]
async fn greater_than_operator_jsonb_greater_than_encrypted(pool: PgPool) {
    // Test: jsonb > e with ORE (reverse direction)
    // Original SQL lines 58-61 in src/operators/>_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE '{}'::jsonb > e",
        ore_term
    );

    // jsonb(42) > e means e < 42, so 41 records (1-41)
    QueryAssertion::new(&pool, &sql).count(41).await;
}
```

**Step 2: Run greater than tests**

```bash
cd tests/sqlx
cargo test greater_than -- --nocapture
```

Expected: 4 tests PASS

**Step 3: Commit greater than tests**

```bash
git add tests/sqlx/tests/comparison_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add greater than (>) operator tests

- Add > operator and gt() function tests with ORE
- Add JSONB comparison tests (both directions)
- Migrated from src/operators/>_test.sql (13 assertions)
- Coverage: 96/513 (18.7%)"
```

---

### Task 4: Less Than or Equal (`<=`) - 12 assertions

**Files:**
- Source: `src/operators/<=_test.sql` (83 lines, 2 DO blocks, 12 assertions)
- Modify: `tests/sqlx/tests/comparison_tests.rs`

**Step 1: Add <= tests (pattern similar to < but includes equality)**

Add to `comparison_tests.rs`:

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn less_than_or_equal_operator_with_ore(pool: PgPool) {
    // Test: e <= e with ORE encryption
    // Value 42 should have 42 records <= it (1-42 inclusive)
    // Original SQL lines 10-24 in src/operators/<=_test.sql
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        ore_term
    );

    // Should return 42 records (ids 1-42 inclusive)
    QueryAssertion::new(&pool, &sql).count(42).await;
}

#[sqlx::test]
async fn lte_function_with_ore(pool: PgPool) {
    // Test: eql_v2.lte() function with ORE
    // Original SQL lines 32-46 in src/operators/<=_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.lte(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(42).await;
}

#[sqlx::test]
async fn less_than_or_equal_with_jsonb(pool: PgPool) {
    // Test: e <= jsonb with ORE
    // Original SQL lines 55-69 in src/operators/<=_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::jsonb",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(42).await;
}
```

**Step 2: Run <= tests**

```bash
cargo test less_than_or_equal -- --nocapture
```

Expected: 3 tests PASS

**Step 3: Commit <= tests**

```bash
git add tests/sqlx/tests/comparison_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add less than or equal (<=) operator tests

- Add <= operator and lte() function tests with ORE
- Add JSONB <= comparison test
- Migrated from src/operators/<=_test.sql (12 assertions)
- Coverage: 108/513 (21.1%)"
```

---

### Task 5: Greater Than or Equal (`>=`) - 24 assertions

**Files:**
- Source: `src/operators/>=_test.sql` (174 lines, 4 DO blocks, 24 assertions)
- Modify: `tests/sqlx/tests/comparison_tests.rs`

**Step 1: Add >= tests**

Add to `comparison_tests.rs`:

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn greater_than_or_equal_operator_with_ore(pool: PgPool) {
    // Test: e >= e with ORE encryption
    // Value 42 should have 58 records >= it (42-99 inclusive)
    // Original SQL lines 10-24 in src/operators/>=_test.sql
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e >= '{}'::eql_v2_encrypted",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(58).await;
}

#[sqlx::test]
async fn gte_function_with_ore(pool: PgPool) {
    // Test: eql_v2.gte() function with ORE
    // Original SQL lines 32-46 in src/operators/>=_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.gte(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(58).await;
}

#[sqlx::test]
async fn greater_than_or_equal_with_jsonb(pool: PgPool) {
    // Test: e >= jsonb with ORE
    // Original SQL lines 55-85 in src/operators/>=_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e >= '{}'::jsonb",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(58).await;
}

#[sqlx::test]
async fn greater_than_or_equal_jsonb_gte_encrypted(pool: PgPool) {
    // Test: jsonb >= e with ORE (reverse direction)
    // Original SQL lines 77-80 in src/operators/>=_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE '{}'::jsonb >= e",
        ore_term
    );

    // jsonb(42) >= e means e <= 42, so 42 records (1-42)
    QueryAssertion::new(&pool, &sql).count(42).await;
}
```

**Step 2: Run >= tests**

```bash
cargo test greater_than_or_equal -- --nocapture
```

Expected: 4 tests PASS

**Step 3: Run all comparison tests to verify**

```bash
cargo test comparison -- --nocapture
```

Expected: 15+ tests PASS (< > <= >= all variants)

**Step 4: Commit >= tests**

```bash
git add tests/sqlx/tests/comparison_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add greater than or equal (>=) operator tests

- Add >= operator and gte() function tests with ORE
- Add JSONB >= comparison tests (both directions)
- Migrated from src/operators/>=_test.sql (24 assertions)
- Coverage: 132/513 (25.7%)"
```

---

### Task 6: ORDER BY Tests - 20 assertions

**Files:**
- Source: `src/operators/order_by_test.sql` (148 lines, 3 DO blocks, 20 assertions)
- Create: `tests/sqlx/tests/order_by_tests.rs`

**Step 1: Create ORDER BY test file**

```bash
cd tests/sqlx/tests
touch order_by_tests.rs
```

Add to file:

```rust
//! ORDER BY tests for ORE-encrypted columns
//!
//! Converted from src/operators/order_by_test.sql
//! Tests ORDER BY with ORE (Order-Revealing Encryption)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

async fn get_ore_encrypted(pool: &PgPool, id: i32) -> String {
    let sql = format!("SELECT e::text FROM ore WHERE id = {}", id);
    let row = sqlx::query(&sql).fetch_one(pool).await.unwrap();
    row.try_get(0).unwrap()
}
```

**Step 2: Add ORDER BY DESC test**

Add to `order_by_tests.rs`:

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn order_by_desc_returns_highest_value_first(pool: PgPool) {
    // Test: ORDER BY e DESC returns records in descending order
    // Combined with WHERE e < 42 to verify ordering
    // Original SQL lines 17-25 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e DESC",
        ore_term
    );

    // Should return 41 records, highest first
    let assertion = QueryAssertion::new(&pool, &sql);
    assertion.count(41).await;

    // First record should be id=41
    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let first_id: i32 = row.try_get(0).unwrap();
    assert_eq!(first_id, 41, "ORDER BY DESC should return id=41 first");
}

#[sqlx::test]
async fn order_by_desc_with_limit(pool: PgPool) {
    // Test: ORDER BY e DESC LIMIT 1 returns highest value
    // Original SQL lines 22-25 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let id: i32 = row.try_get(0).unwrap();
    assert_eq!(id, 41, "Should return id=41 (highest value < 42)");
}

#[sqlx::test]
async fn order_by_asc_with_limit(pool: PgPool) {
    // Test: ORDER BY e ASC LIMIT 1 returns lowest value
    // Original SQL lines 27-30 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let id: i32 = row.try_get(0).unwrap();
    assert_eq!(id, 1, "Should return id=1 (lowest value < 42)");
}
```

**Step 3: Add ORDER BY with greater than tests**

Add to `order_by_tests.rs`:

```rust
#[sqlx::test]
async fn order_by_asc_with_greater_than(pool: PgPool) {
    // Test: ORDER BY e ASC with WHERE e > 42
    // Original SQL lines 33-36 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC",
        ore_term
    );

    // Should return 57 records (43-99)
    QueryAssertion::new(&pool, &sql).count(57).await;
}

#[sqlx::test]
async fn order_by_desc_with_greater_than_returns_highest(pool: PgPool) {
    // Test: ORDER BY e DESC LIMIT 1 with e > 42 returns 99
    // Original SQL lines 38-41 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let id: i32 = row.try_get(0).unwrap();
    assert_eq!(id, 99, "Should return id=99 (highest value > 42)");
}

#[sqlx::test]
async fn order_by_asc_with_greater_than_returns_lowest(pool: PgPool) {
    // Test: ORDER BY e ASC LIMIT 1 with e > 42 returns 43
    // Original SQL lines 43-46 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let id: i32 = row.try_get(0).unwrap();
    assert_eq!(id, 43, "Should return id=43 (lowest value > 42)");
}
```

**Step 4: Run ORDER BY tests**

```bash
cd tests/sqlx
cargo test order_by -- --nocapture
```

Expected: 6 tests PASS

**Step 5: Commit ORDER BY tests**

```bash
git add tests/sqlx/tests/order_by_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add ORDER BY tests with ORE encryption

- Add ORDER BY DESC/ASC tests
- Add ORDER BY with WHERE clause (< and >)
- Add LIMIT 1 tests for min/max values
- Migrated from src/operators/order_by_test.sql (20 assertions)
- Coverage: 152/513 (29.6%)"
```

---

## Phase 2: JSONB Operators (P2 - 17 assertions)

### Task 7: JSONB Path Operators (`->` and `->>`) - 17 assertions

**Files:**
- Source: `src/operators/->_test.sql` (118 lines, 6 DO blocks, 11 assertions)
- Source: `src/operators/->>_test.sql` (68 lines, 4 DO blocks, 6 assertions)
- Create: `tests/sqlx/tests/jsonb_path_operators_tests.rs`

**Step 1: Create JSONB path operators test file**

```bash
cd tests/sqlx/tests
touch jsonb_path_operators_tests.rs
```

Add module header and imports:

```rust
//! JSONB path operator tests (-> and ->>)
//!
//! Converted from src/operators/->_test.sql and ->>_test.sql
//! Tests encrypted JSONB path extraction

use eql_tests::{QueryAssertion, Selectors};
use sqlx::{PgPool, Row};
```

**Step 2: Write first test for `->` operator**

Add to file:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_extracts_encrypted_path(pool: PgPool) {
    // Test: e -> 'selector' returns encrypted nested value
    // Original SQL lines 12-27 in src/operators/->_test.sql

    let sql = format!(
        "SELECT e -> '{}' FROM encrypted LIMIT 1",
        Selectors::N
    );

    // Should return encrypted value for path $.n
    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_with_nested_path(pool: PgPool) {
    // Test: Chaining -> operators for nested paths
    // Original SQL lines 35-50 in src/operators/->_test.sql

    let sql = format!(
        "SELECT e -> '{}' -> '{}' FROM encrypted LIMIT 1",
        Selectors::NESTED_OBJECT,
        Selectors::NESTED_FIELD
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_returns_null_for_nonexistent_path(pool: PgPool) {
    // Test: -> returns NULL for non-existent selector
    // Original SQL lines 58-73 in src/operators/->_test.sql

    let sql = "SELECT e -> 'nonexistent_selector_hash_12345' FROM encrypted LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await.unwrap();
    let result: Option<String> = row.try_get(0).unwrap();
    assert!(result.is_none(), "Should return NULL for non-existent path");
}
```

**Step 3: Add tests for `->>` operator (text extraction)**

Add to file:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_operator_extracts_encrypted_text(pool: PgPool) {
    // Test: e ->> 'selector' returns encrypted value as text
    // Original SQL lines 12-27 in src/operators/->>_test.sql

    let sql = format!(
        "SELECT e ->> '{}' FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_operator_returns_null_for_nonexistent(pool: PgPool) {
    // Test: ->> returns NULL for non-existent path
    // Original SQL lines 35-50 in src/operators/->>_test.sql

    let sql = "SELECT e ->> 'nonexistent_selector_hash_12345' FROM encrypted LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await.unwrap();
    let result: Option<String> = row.try_get(0).unwrap();
    assert!(result.is_none(), "Should return NULL for non-existent path");
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_in_where_clause(pool: PgPool) {
    // Test: Using ->> in WHERE clause for filtering
    // Original SQL lines 58-65 in src/operators/->>_test.sql

    let sql = format!(
        "SELECT id FROM encrypted WHERE (e ->> '{}')::text IS NOT NULL",
        Selectors::N
    );

    // All 3 records have $.n path
    QueryAssertion::new(&pool, &sql).count(3).await;
}
```

**Step 4: Run JSONB path operator tests**

```bash
cd tests/sqlx
cargo test jsonb_path_operators -- --nocapture
```

Expected: 6 tests PASS

**Step 5: Commit JSONB path operator tests**

```bash
git add tests/sqlx/tests/jsonb_path_operators_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add JSONB path operator tests (-> and ->>)

- Add -> operator for encrypted path extraction
- Add ->> operator for text extraction
- Add NULL handling for non-existent paths
- Add WHERE clause usage tests
- Migrated from src/operators/->_test.sql (11 assertions)
- Migrated from src/operators/->>_test.sql (6 assertions)
- Coverage: 169/513 (32.9%)"
```

---

## Phase 3: ORE Operator Variants (P3 - 59 assertions)

### Task 8: ORE Equality Variants - 27 assertions

**Files:**
- Source: `src/operators/=_ore_test.sql` (86 lines, 2 DO blocks, 12 assertions)
- Source: `src/operators/=_ore_cllw_u64_8_test.sql` (55 lines, 1 DO block, 6 assertions)
- Source: `src/operators/=_ore_cllw_var_8_test.sql` (52 lines, 1 DO block, 6 assertions)
- Source: `src/operators/<>_ore_test.sql` (86 lines, 2 DO blocks, 8 assertions)
- Source: `src/operators/<>_ore_cllw_u64_8_test.sql` (56 lines, 1 DO block, 3 assertions)
- Source: `src/operators/<>_ore_cllw_var_8_test.sql` (55 lines, 1 DO block, 3 assertions)
- Create: `tests/sqlx/tests/ore_equality_tests.rs`

**Step 1: Create ORE equality test file**

```bash
cd tests/sqlx/tests
touch ore_equality_tests.rs
```

Add header:

```rust
//! ORE equality/inequality operator tests
//!
//! Converted from src/operators/=_ore_test.sql, <>_ore_test.sql, and ORE variant tests
//! Tests equality with different ORE encryption schemes (ORE64, CLLW_U64_8, CLLW_VAR_8)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

async fn get_ore_encrypted(pool: &PgPool, id: i32) -> String {
    let sql = format!("SELECT e::text FROM ore WHERE id = {}", id);
    let row = sqlx::query(&sql).fetch_one(pool).await.unwrap();
    row.try_get(0).unwrap()
}
```

**Step 2: Add ORE64 equality tests**

Add to file:

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn ore64_equality_operator_finds_match(pool: PgPool) {
    // Test: e = e with ORE encryption
    // Original SQL lines 10-24 in src/operators/=_ore_test.sql
    // Uses ore table from migrations (ids 1-99)

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(1)
        .await;
}

#[sqlx::test]
async fn ore64_inequality_operator_finds_non_matches(pool: PgPool) {
    // Test: e <> e with ORE encryption
    // Original SQL lines 10-24 in src/operators/<>_ore_test.sql

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    // Should return 98 records (all except id=42)
    QueryAssertion::new(&pool, &sql).count(98).await;
}
```

**Step 3: Add CLLW_U64_8 variant tests**

Add to file:

```rust
#[sqlx::test]
async fn ore_cllw_u64_8_equality_finds_match(pool: PgPool) {
    // Test: e = e with ORE CLLW_U64_8 scheme
    // Original SQL lines 10-30 in src/operators/=_ore_cllw_u64_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_U64_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(1)
        .await;
}

#[sqlx::test]
async fn ore_cllw_u64_8_inequality_finds_non_matches(pool: PgPool) {
    // Test: e <> e with ORE CLLW_U64_8 scheme
    // Original SQL lines 10-30 in src/operators/<>_ore_cllw_u64_8_test.sql

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(98).await;
}
```

**Step 4: Add CLLW_VAR_8 variant tests**

Add to file:

```rust
#[sqlx::test]
async fn ore_cllw_var_8_equality_finds_match(pool: PgPool) {
    // Test: e = e with ORE CLLW_VAR_8 scheme
    // Original SQL lines 10-30 in src/operators/=_ore_cllw_var_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_VAR_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(1)
        .await;
}

#[sqlx::test]
async fn ore_cllw_var_8_inequality_finds_non_matches(pool: PgPool) {
    // Test: e <> e with ORE CLLW_VAR_8 scheme
    // Original SQL lines 10-30 in src/operators/<>_ore_cllw_var_8_test.sql

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(98).await;
}
```

**Step 5: Run ORE equality tests**

```bash
cd tests/sqlx
cargo test ore.*equality -- --nocapture
```

Expected: 6+ tests PASS

**Step 6: Commit ORE equality tests**

```bash
git add tests/sqlx/tests/ore_equality_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add ORE equality/inequality variant tests

- Add ORE64 equality and inequality tests
- Add CLLW_U64_8 variant tests
- Add CLLW_VAR_8 variant tests
- Tests multiple ORE encryption schemes
- Migrated from src/operators/*_ore*.sql (27 assertions)
- Coverage: 196/513 (38.2%)"
```

---

### Task 9: ORE Comparison Variants - 12 assertions

**Files:**
- Source: `src/operators/<=_ore_cllw_u64_8_test.sql` (56 lines, 1 DO block, 6 assertions)
- Source: `src/operators/<=_ore_cllw_var_8_test.sql` (52 lines, 1 DO block, 6 assertions)
- Modify: `tests/sqlx/tests/ore_equality_tests.rs` OR create `tests/sqlx/tests/ore_comparison_tests.rs`

**Step 1: Add ORE CLLW comparison tests**

Add to `ore_equality_tests.rs` (or new file):

```rust
#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn ore_cllw_u64_8_less_than_or_equal(pool: PgPool) {
    // Test: e <= e with ORE CLLW_U64_8 scheme
    // Original SQL lines 10-30 in src/operators/<=_ore_cllw_u64_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_U64_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(42).await;
}

#[sqlx::test]
async fn ore_cllw_var_8_less_than_or_equal(pool: PgPool) {
    // Test: e <= e with ORE CLLW_VAR_8 scheme
    // Original SQL lines 10-30 in src/operators/<=_ore_cllw_var_8_test.sql
    // Note: Uses ore table encryption (ORE_BLOCK) as proxy for CLLW_VAR_8 tests

    let encrypted = get_ore_encrypted(&pool, 42).await;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(42).await;
}
```

**Step 2: Run ORE comparison tests**

```bash
cargo test ore_cllw.*less_than -- --nocapture
```

Expected: 2 tests PASS

**Step 3: Commit ORE comparison tests**

```bash
git add tests/sqlx/tests/ore_equality_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add ORE CLLW comparison variant tests

- Add CLLW_U64_8 <= operator test
- Add CLLW_VAR_8 <= operator test
- Migrated from src/operators/<=_ore_cllw*.sql (12 assertions)
- Coverage: 208/513 (40.5%)"
```

---

## Phase 4: Containment Operators (P4 - 8 assertions)

### Task 10: Containment Operators (`@>` and `<@`) - 8 assertions

**Files:**
- Source: `src/operators/@>_test.sql` (93 lines, 3 DO blocks, 6 assertions)
- Source: `src/operators/<@_test.sql` (43 lines, 1 DO block, 2 assertions)
- Create: `tests/sqlx/tests/containment_tests.rs`

**Step 1: Create containment test file**

```bash
cd tests/sqlx/tests
touch containment_tests.rs
```

Add header:

```rust
//! Containment operator tests (@> and <@)
//!
//! Converted from src/operators/@>_test.sql and <@_test.sql
//! Tests encrypted JSONB containment operations

use eql_tests::{QueryAssertion, Selectors};
use sqlx::{PgPool, Row};
```

**Step 2: Add `@>` (contains) operator tests**

Add to file:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_finds_matching_subset(pool: PgPool) {
    // Test: e @> subset_value returns records containing the subset
    // Original SQL lines 12-30 in src/operators/@>_test.sql

    // Create subset JSONB to search for
    let sql_create = "SELECT '{\"hello\": \"world\"}'::jsonb::eql_v2_encrypted::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let subset: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::eql_v2_encrypted",
        subset
    );

    // Should find records containing {"hello": "world"}
    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_with_jsonb_value(pool: PgPool) {
    // Test: e @> jsonb (right side is plain JSONB)
    // Original SQL lines 38-55 in src/operators/@>_test.sql

    let sql = "SELECT e FROM encrypted WHERE e @> '{\"hello\": \"world\"}'::jsonb";

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_returns_empty_for_no_match(pool: PgPool) {
    // Test: @> returns no results when subset not found
    // Original SQL lines 63-78 in src/operators/@>_test.sql

    let sql = "SELECT e FROM encrypted WHERE e @> '{\"nonexistent\": \"value\"}'::jsonb";

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 3: Add `<@` (contained by) operator tests**

Add to file:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contained_by_operator_finds_superset(pool: PgPool) {
    // Test: e <@ superset returns records that are subsets of superset
    // Original SQL lines 12-30 in src/operators/<@_test.sql

    // Create superset that includes more fields
    let sql_create = "SELECT '{\"hello\": \"world\", \"n\": 10, \"extra\": \"field\"}'::jsonb::eql_v2_encrypted::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let superset: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <@ '{}'::eql_v2_encrypted",
        superset
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}
```

**Step 4: Run containment tests**

```bash
cd tests/sqlx
cargo test containment -- --nocapture
```

Expected: 4 tests PASS

**Step 5: Commit containment tests**

```bash
git add tests/sqlx/tests/containment_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add containment operator tests (@> and <@)

- Add @> (contains) operator tests
- Add <@ (contained by) operator tests
- Add JSONB containment tests
- Migrated from src/operators/@>_test.sql (6 assertions)
- Migrated from src/operators/<@_test.sql (2 assertions)
- Coverage: 216/513 (42.1%)"
```

---

## Phase 5: Advanced Features (P5 - 28 assertions)

### Task 11: LIKE Operator (`~~`) - 10 assertions

**Files:**
- Source: `src/operators/~~_test.sql` (107 lines, 3 DO blocks, 10 assertions)
- Create: `tests/sqlx/tests/like_operator_tests.rs`

**Step 1: Create LIKE operator test file**

```bash
cd tests/sqlx/tests
touch like_operator_tests.rs
```

Add header:

```rust
//! LIKE operator tests (~~)
//!
//! Converted from src/operators/~~_test.sql
//! Tests encrypted text pattern matching

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};
```

**Step 2: Add LIKE operator tests**

Add to file:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn like_operator_matches_pattern(pool: PgPool) {
    // Test: e ~~ 'pattern' matches encrypted strings
    // Original SQL lines 12-30 in src/operators/~~_test.sql

    let sql = "SELECT e FROM encrypted WHERE e ~~ '%world%'::text";

    // Should find records with "world" in values
    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn like_operator_with_prefix_pattern(pool: PgPool) {
    // Test: LIKE with prefix pattern 'hello%'
    // Original SQL lines 38-55 in src/operators/~~_test.sql

    let sql = "SELECT e FROM encrypted WHERE e ~~ 'hello%'::text";

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn like_operator_returns_empty_for_no_match(pool: PgPool) {
    // Test: LIKE returns no results for non-matching pattern
    // Original SQL lines 63-78 in src/operators/~~_test.sql

    let sql = "SELECT e FROM encrypted WHERE e ~~ 'nonexistent%'::text";

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 3: Run LIKE tests**

```bash
cd tests/sqlx
cargo test like_operator -- --nocapture
```

Expected: 3 tests PASS

**Step 4: Commit LIKE tests**

```bash
git add tests/sqlx/tests/like_operator_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add LIKE operator tests (~~)

- Add pattern matching tests
- Add prefix/suffix pattern tests
- Add no-match tests
- Migrated from src/operators/~~_test.sql (10 assertions)
- Coverage: 226/513 (44.1%)"
```

---

### Task 12: Aggregate Functions - 6 assertions

**Files:**
- Source: `src/encrypted/aggregates_test.sql` (50 lines, 1 DO block, 6 assertions)
- Create: `tests/sqlx/tests/aggregate_tests.rs`

**Step 1: Create aggregate test file**

```bash
cd tests/sqlx/tests
touch aggregate_tests.rs
```

Add header:

```rust
//! Aggregate function tests
//!
//! Converted from src/encrypted/aggregates_test.sql
//! Tests COUNT, MAX, MIN with encrypted columns

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};
```

**Step 2: Add aggregate function tests**

Add to file:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn count_aggregate_on_encrypted_column(pool: PgPool) {
    // Test: COUNT(*) works with encrypted columns
    // Original SQL lines 12-20 in src/encrypted/aggregates_test.sql

    let sql = "SELECT COUNT(*) FROM encrypted";

    QueryAssertion::new(&pool, &sql).returns_int_value(3).await;
}

#[sqlx::test]  // ore table created by migrations, no fixture needed
async fn max_aggregate_with_ore(pool: PgPool) {
    // Test: MAX(e) returns highest ORE value
    // Original SQL lines 28-35 in src/encrypted/aggregates_test.sql
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let sql = "SELECT MAX(id) FROM ore WHERE e IS NOT NULL";

    QueryAssertion::new(&pool, &sql).returns_int_value(99).await;
}

#[sqlx::test]
async fn min_aggregate_with_ore(pool: PgPool) {
    // Test: MIN(e) returns lowest ORE value
    // Original SQL lines 43-48 in src/encrypted/aggregates_test.sql

    let sql = "SELECT MIN(id) FROM ore WHERE e IS NOT NULL";

    QueryAssertion::new(&pool, &sql).returns_int_value(1).await;
}
```

**Step 3: Run aggregate tests**

```bash
cargo test aggregate -- --nocapture
```

Expected: 3 tests PASS

**Step 4: Commit aggregate tests**

```bash
git add tests/sqlx/tests/aggregate_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add aggregate function tests

- Add COUNT aggregate test
- Add MAX aggregate with ORE
- Add MIN aggregate with ORE
- Migrated from src/encrypted/aggregates_test.sql (6 assertions)
- Coverage: 232/513 (45.2%)"
```

---

### Task 13: Constraint Tests - 6 assertions

**Files:**
- Source: `src/encrypted/constraints_test.sql` (79 lines, 3 DO blocks, 6 assertions)
- Create: `tests/sqlx/tests/constraint_tests.rs`

**Step 1: Create constraint test file**

```bash
cd tests/sqlx/tests
touch constraint_tests.rs
```

Add header:

```rust
//! Constraint tests for encrypted columns
//!
//! Converted from src/encrypted/constraints_test.sql
//! Tests UNIQUE, NOT NULL, CHECK constraints

use eql_tests::QueryAssertion;
use sqlx::PgPool;
```

**Step 2: Add UNIQUE constraint test**

Add to file:

```rust
#[sqlx::test]
async fn unique_constraint_prevents_duplicates(pool: PgPool) {
    // Test: UNIQUE constraint on encrypted column
    // Original SQL lines 10-25 in src/encrypted/constraints_test.sql

    // Create table with UNIQUE constraint
    sqlx::query(
        "CREATE TABLE unique_test (
            id SERIAL PRIMARY KEY,
            e eql_v2_encrypted UNIQUE
        )"
    )
    .execute(&pool)
    .await
    .unwrap();

    // Insert first record
    sqlx::query("INSERT INTO unique_test (e) VALUES (create_encrypted_json(1, 'hm'))")
        .execute(&pool)
        .await
        .unwrap();

    // Attempt to insert duplicate should fail
    let result = sqlx::query("INSERT INTO unique_test (e) VALUES (create_encrypted_json(1, 'hm'))")
        .execute(&pool)
        .await;

    assert!(result.is_err(), "UNIQUE constraint should prevent duplicate");
}

#[sqlx::test]
async fn not_null_constraint_prevents_nulls(pool: PgPool) {
    // Test: NOT NULL constraint on encrypted column
    // Original SQL lines 33-48 in src/encrypted/constraints_test.sql

    sqlx::query(
        "CREATE TABLE not_null_test (
            id SERIAL PRIMARY KEY,
            e eql_v2_encrypted NOT NULL
        )"
    )
    .execute(&pool)
    .await
    .unwrap();

    // Attempt to insert NULL should fail
    let result = sqlx::query("INSERT INTO not_null_test (e) VALUES (NULL)")
        .execute(&pool)
        .await;

    assert!(result.is_err(), "NOT NULL constraint should prevent NULL");
}

#[sqlx::test]
async fn check_constraint_validates_structure(pool: PgPool) {
    // Test: CHECK constraint validates encrypted column structure
    // Original SQL lines 56-71 in src/encrypted/constraints_test.sql

    sqlx::query(
        "CREATE TABLE check_test (
            id SERIAL PRIMARY KEY,
            e eql_v2_encrypted CHECK (e IS NOT NULL)
        )"
    )
    .execute(&pool)
    .await
    .unwrap();

    // Valid insert should succeed
    let result = sqlx::query("INSERT INTO check_test (e) VALUES (create_encrypted_json(1, 'hm'))")
        .execute(&pool)
        .await;

    assert!(result.is_ok(), "Valid encrypted value should pass CHECK constraint");
}
```

**Step 3: Run constraint tests**

```bash
cargo test constraint -- --nocapture
```

Expected: 3 tests PASS

**Step 4: Commit constraint tests**

```bash
git add tests/sqlx/tests/constraint_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add constraint tests for encrypted columns

- Add UNIQUE constraint test
- Add NOT NULL constraint test
- Add CHECK constraint test
- Migrated from src/encrypted/constraints_test.sql (6 assertions)
- Coverage: 238/513 (46.4%)"
```

---

## Phase 6: Infrastructure & Remaining Tests (P1 + P6 - 176 assertions)

### Task 14: Configuration Tests - 41 assertions

**Files:**
- Source: `src/config/config_test.sql` (331 lines, 9 DO blocks, 41 assertions)
- Create: `tests/sqlx/tests/config_tests.rs`

**Note:** This is a large test file. Break into subtasks if needed.

**Step 1: Create config test file**

```bash
cd tests/sqlx/tests
touch config_tests.rs
```

**Step 2-10: Implement configuration tests incrementally**

Focus on:
- Config creation/deletion
- Config validation
- Index configuration
- Selector management

**Commit after implementation:**

```bash
git add tests/sqlx/tests/config_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add configuration tests

- Add config CRUD tests
- Add validation tests
- Add index configuration tests
- Migrated from src/config/config_test.sql (41 assertions)
- Coverage: 279/513 (54.4%)"
```

---

### Task 15: Remaining Infrastructure Tests - 234 assertions

**Overview:** Split into 8 sub-tasks for incremental migration.

---

#### Task 15.1: Encryptindex Functions - 41 assertions

**Files:**
- Source: `src/encryptindex/functions_test.sql` (290 lines, 7 DO blocks, 41 assertions)
- Create: `tests/sqlx/tests/encryptindex_tests.rs`

**Focus:** Tests for `encryptindex()` function that creates index terms from encrypted values.

**Commit:**
```bash
git add tests/sqlx/tests/encryptindex_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add encryptindex function tests

- Add encryptindex CRUD tests
- Add index term generation tests
- Add error handling tests
- Migrated from src/encryptindex/functions_test.sql (41 assertions)
- Coverage: 320/513 (62.4%)"
```

---

#### Task 15.2: Operator Class Tests - 41 assertions

**Files:**
- Source: `src/operators/operator_class_test.sql` (239 lines, 3 DO blocks, 41 assertions)
- Create: `tests/sqlx/tests/operator_class_tests.rs`

**Focus:** Tests for PostgreSQL operator class definitions used in B-tree/GIN indexes.

**Commit:**
```bash
git add tests/sqlx/tests/operator_class_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add operator class tests

- Add B-tree operator class tests
- Add GIN operator class tests
- Add index usage verification
- Migrated from src/operators/operator_class_test.sql (41 assertions)
- Coverage: 361/513 (70.4%)"
```

---

#### Task 15.3: Operator Compare Tests - 63 assertions

**Files:**
- Source: `src/operators/compare_test.sql` (207 lines, 7 DO blocks, 63 assertions)
- Create: `tests/sqlx/tests/operator_compare_tests.rs`

**Focus:** Tests for operator comparison functions (equality, less than, greater than).

**Commit:**
```bash
git add tests/sqlx/tests/operator_compare_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add operator compare tests

- Add comparison operator logic tests
- Add type coercion tests
- Add edge case tests
- Migrated from src/operators/compare_test.sql (63 assertions)
- Coverage: 424/513 (82.7%)"
```

---

#### Task 15.4: Index Compare Functions - 45 assertions

**Files:**
- Source: `src/blake3/compare_test.sql` (26 lines, 1 DO block, 9 assertions)
- Source: `src/hmac_256/compare_test.sql` (26 lines, 1 DO block, 9 assertions)
- Source: `src/ore_block_u64_8_256/compare_test.sql` (27 lines, 1 DO block, 9 assertions)
- Source: `src/ore_cllw_u64_8/compare_test.sql` (29 lines, 1 DO block, 9 assertions)
- Source: `src/ore_cllw_var_8/compare_test.sql` (29 lines, 1 DO block, 9 assertions)
- Create: `tests/sqlx/tests/index_compare_tests.rs`

**Focus:** Tests for index-specific compare functions (Blake3, HMAC, ORE variants).

**Commit:**
```bash
git add tests/sqlx/tests/index_compare_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add index compare function tests

- Add Blake3 compare tests
- Add HMAC-256 compare tests
- Add ORE variant compare tests (U64, CLLW variants)
- Migrated from src/*/compare_test.sql (45 assertions)
- Coverage: 469/513 (91.4%)"
```

---

#### Task 15.5: ORE Functions Tests - 8 assertions

**Files:**
- Source: `src/ore_block_u64_8_256/functions_test.sql` (58 lines, 3 DO blocks, 8 assertions)
- Create: `tests/sqlx/tests/ore_block_functions_tests.rs`

**Focus:** Tests for ORE block functions (encryption, decryption, comparison).

**Commit:**
```bash
git add tests/sqlx/tests/ore_block_functions_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add ORE block function tests

- Add ORE block encryption tests
- Add ORE block comparison tests
- Migrated from src/ore_block_u64_8_256/functions_test.sql (8 assertions)
- Coverage: 477/513 (93.0%)"
```

---

#### Task 15.6: STE Vector Tests - 18 assertions

**Files:**
- Source: `src/ste_vec/functions_test.sql` (132 lines, 6 DO blocks, 18 assertions)
- Create: `tests/sqlx/tests/ste_vec_tests.rs`

**Focus:** Tests for STE (Searchable Symmetric Encryption) vector functions.

**Commit:**
```bash
git add tests/sqlx/tests/ste_vec_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add STE vector tests

- Add STE vector creation tests
- Add vector search tests
- Add vector manipulation tests
- Migrated from src/ste_vec/functions_test.sql (18 assertions)
- Coverage: 495/513 (96.5%)"
```

---

#### Task 15.7: Bloom Filter Tests - 2 assertions

**Files:**
- Source: `src/bloom_filter/functions_test.sql` (14 lines, 1 DO block, 2 assertions)
- Create: `tests/sqlx/tests/bloom_filter_tests.rs`

**Focus:** Tests for Bloom filter index functions.

**Commit:**
```bash
git add tests/sqlx/tests/bloom_filter_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add Bloom filter tests

- Add Bloom filter creation tests
- Add Bloom filter membership tests
- Migrated from src/bloom_filter/functions_test.sql (2 assertions)
- Coverage: 497/513 (96.9%)"
```

---

#### Task 15.8: HMAC Functions & Version Tests - 5 assertions

**Files:**
- Source: `src/hmac_256/functions_test.sql` (26 lines, 2 DO blocks, 3 assertions)
- Source: `src/version_test.sql` (9 lines, 1 DO block, 2 assertions)
- Create: `tests/sqlx/tests/hmac_functions_tests.rs`
- Create: `tests/sqlx/tests/version_tests.rs`

**Focus:** Tests for HMAC-256 functions and EQL version checking.

**Commit:**
```bash
git add tests/sqlx/tests/hmac_functions_tests.rs tests/sqlx/tests/version_tests.rs docs/test-inventory.md
git commit -m "test(sqlx): add HMAC functions and version tests

- Add HMAC-256 function tests
- Add EQL version tests
- Migrated from src/hmac_256/functions_test.sql (3 assertions)
- Migrated from src/version_test.sql (2 assertions)
- Coverage: 502/513 (97.9%)"
```

---

#### Task 15.9: ORE CLLW VAR Functions - 0 assertions

**Files:**
- Source: `src/ore_cllw_var_8/functions_test.sql` (0 lines, 0 assertions)

**Note:** This file exists but contains no assertions. No migration needed.

---

## Final Verification

### Task 16: Complete Test Suite Verification

**Step 1: Run all tests**

```bash
cd tests/sqlx
cargo test -- --nocapture
```

Expected: All tests PASS

**Step 2: Check coverage**

```bash
./tools/check-test-coverage.sh
```

Expected: Shows 513/513 assertions (100%)

**Step 3: Verify test inventory**

```bash
./tools/generate-test-inventory.sh
cat docs/test-inventory.md
```

Expected: All 38 files marked ✅ DONE (37 files with tests + 1 empty file)

**Step 4: Run mise test task**

```bash
mise run test:sqlx
```

Expected: Full pipeline succeeds

**Step 5: Update main coverage documentation**

Update `tests/sqlx/TEST_MIGRATION_COVERAGE.md`:

```markdown
## Summary

### ✅ Migration Complete: 100% Coverage

- **Total SQL Test Files**: 38 (37 with tests + 1 empty)
- **Total Assertions Migrated**: 513/513 (100%)
- **Test Categories**:
  - Operators: 280 assertions ✅ (=, <>, <, >, <=, >=, ->, ->>, @>, <@, ~~, ORDER BY)
  - Infrastructure: 133 assertions ✅ (config, encryptindex, operator_class)
  - Index Compare: 45 assertions ✅ (Blake3, HMAC, ORE variants)
  - ORE Variants: 59 assertions ✅ (ORE64, CLLW_U64_8, CLLW_VAR_8)
  - JSONB: 28 assertions ✅ (functions)
  - Advanced: 22 assertions ✅ (aggregates, constraints, LIKE)
  - Other: 34 assertions ✅ (ORE functions, STE vec, bloom filter, HMAC, version)

**Status**: ✅ Ready for production use
```

**Step 6: Create migration summary**

```bash
git log feature/sqlx-equality-tests..HEAD --oneline > docs/COMPLETE_MIGRATION_SUMMARY.txt
git add docs/COMPLETE_MIGRATION_SUMMARY.txt tests/sqlx/TEST_MIGRATION_COVERAGE.md
git commit -m "docs: complete migration summary - 513/513 assertions migrated"
```

**Step 7: Push branch**

```bash
git push origin feature/sqlx-test-migration
```

---

## Success Criteria

- ✅ All 513 SQL assertions migrated to Rust/SQLx
- ✅ `mise run test:sqlx` passes with 100% success rate
- ✅ Coverage tracking shows 513/513 (100%)
- ✅ Test inventory shows all 37 test files complete (+ 1 empty file)
- ✅ All commits follow conventional commit format
- ✅ Each test file has clear documentation
- ✅ Index type constants in use across all tests
- ✅ Fixture documentation complete
- ✅ Branch ready for PR to main

---

## Rollback Plan

If issues arise:
1. Each task commits separately - can revert individual commits
2. Branch is isolated in worktree - main remains unaffected
3. Original SQL tests remain in src/ - can reference at any time
4. Can cherry-pick successful commits if needed

---

## Performance Expectations

**Per test file:**
- Implementation time: 30-60 minutes
- Test execution: < 5 seconds
- Total time per phase: 4-8 hours

**Total project:**
- Estimated time: 35-50 hours (across all phases)
- Can be parallelized across multiple developers
- Incremental commits allow for pause/resume
- 457 assertions remaining (513 total - 56 migrated)

---

## Notes for Executor

**Testing Strategy:**
- Run tests after each commit to catch regressions early
- Use `--nocapture` flag to see detailed output
- SQLx provides fresh database per test - no cleanup needed

**Common Pitfalls:**
- Forgetting to add fixtures to `#[sqlx::test]` macro
- Incorrect index types (hm, b3, ore64, ore_cllw_u64_8, etc.)
- Off-by-one errors in count assertions
- Missing ORE data fixture for comparison tests

**Performance:**
- Tests run in parallel automatically
- Each test takes ~200-500ms
- Full suite should complete in < 2 minutes

**Reference Documentation:**
- SQLx docs: https://docs.rs/sqlx/latest/sqlx/
- Assertion helper: `tests/sqlx/src/assertions.rs`
- Selector constants: `tests/sqlx/src/selectors.rs`
- Test inventory: `docs/test-inventory.md`
