# Complete SQLx Test Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate all remaining SQL tests to Rust/SQLx framework achieving 100% like-for-like coverage, then identify and implement coverage improvements.

**Architecture:** Port SQL test assertions to Rust using SQLx test framework with hybrid migration approach (EQL installed via build, fixtures via SQLx migrations). Tests use `QueryAssertion` helper for consistent verification patterns. Each test is isolated with fresh database per test via `#[sqlx::test]` macro.

**Tech Stack:** Rust, SQLx 0.8, PostgreSQL 17, mise task runner, cargo test

**Current State:**
- Equality tests: 5/16 assertions migrated (31%)
- JSONB tests: 11/24 assertions migrated (46%)
- Total: 16/40 assertions migrated (40%)
- Missing: 24 critical test assertions

**Reference Documents:**
- Test coverage analysis: `tests/sqlx/TEST_MIGRATION_COVERAGE.md`
- Original SQL tests: `src/operators/=_test.sql`, `src/jsonb/functions_test.sql`
- Existing Rust tests: `tests/sqlx/tests/equality_tests.rs`, `tests/sqlx/tests/jsonb_tests.rs`

---

## Phase 1: Complete Equality Tests (11 Missing Assertions)

### Task 1: Blake3 eq() Function Tests

**Files:**
- Modify: `tests/sqlx/tests/equality_tests.rs`

**Step 1: Write failing test for Blake3 eq() matching record**

Add after line 121 in `equality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_finds_matching_record_blake3(pool: PgPool) {
    // Test: eql_v2.eq() function with Blake3 index
    // Original SQL line 135-156 in src/operators/=_test.sql

    // Call SQL function to create encrypted JSON with Blake3 and remove 'ob' field
    let sql_create = "SELECT ((create_encrypted_json(1, 'b3')::jsonb - 'ob')::eql_v2_encrypted)::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let encrypted: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}
```

**Step 2: Run test to verify it fails**

```bash
cd tests/sqlx
cargo test eq_function_finds_matching_record_blake3 -- --nocapture
```

Expected: FAIL (function doesn't exist yet in test file)

**Step 3: Verify test passes**

The test should actually pass since we're testing existing EQL functionality.

Expected: PASS

**Step 4: Write failing test for Blake3 eq() no-match**

Add to `equality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_returns_empty_for_no_match_blake3(pool: PgPool) {
    // Test: eql_v2.eq() returns no results for non-existent record with Blake3
    // Original SQL line 148-153 in src/operators/=_test.sql

    let sql_create = "SELECT ((create_encrypted_json(4, 'b3')::jsonb - 'ob')::eql_v2_encrypted)::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let encrypted: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 5: Run test to verify it passes**

```bash
cd tests/sqlx
cargo test eq_function_returns_empty_for_no_match_blake3 -- --nocapture
```

Expected: PASS

**Step 6: Commit Blake3 eq() tests**

```bash
git add tests/sqlx/tests/equality_tests.rs
git commit -m "test(sqlx): add Blake3 eq() function tests

- Add eq_function_finds_matching_record_blake3
- Add eq_function_returns_empty_for_no_match_blake3
- Covers SQL blocks 5 (lines 135-156) in =_test.sql
- Brings Blake3 coverage to parity with HMAC"
```

---

### Task 2: HMAC JSONB Equality Tests (e = jsonb, jsonb = e)

**Files:**
- Modify: `tests/sqlx/tests/equality_tests.rs`

**Step 1: Write failing test for HMAC e = jsonb (matching)**

Add to `equality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_hmac(pool: PgPool) {
    // Test: eql_v2_encrypted = jsonb with HMAC index
    // Original SQL line 65-94 in src/operators/=_test.sql

    // Create encrypted JSON with HMAC, remove 'ob' field for comparison
    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}
```

**Step 2: Run test to verify behavior**

```bash
cd tests/sqlx
cargo test equality_operator_encrypted_equals_jsonb_hmac -- --nocapture
```

Expected: PASS

**Step 3: Write test for JSONB = encrypted (reverse direction)**

Add to `equality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_hmac(pool: PgPool) {
    // Test: jsonb = eql_v2_encrypted with HMAC index (reverse direction)
    // Original SQL line 78-81 in src/operators/=_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}
```

**Step 4: Run test to verify it passes**

```bash
cd tests/sqlx
cargo test equality_operator_jsonb_equals_encrypted_hmac -- --nocapture
```

Expected: PASS

**Step 5: Write no-match tests for both directions**

Add to `equality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_no_match_hmac(pool: PgPool) {
    // Test: eql_v2_encrypted = jsonb with no matching record
    // Original SQL line 83-87 in src/operators/=_test.sql

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_no_match_hmac(pool: PgPool) {
    // Test: jsonb = eql_v2_encrypted with no matching record
    // Original SQL line 89-91 in src/operators/=_test.sql

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 6: Run all HMAC JSONB tests**

```bash
cd tests/sqlx
cargo test jsonb.*hmac -- --nocapture
```

Expected: All 4 tests PASS

**Step 7: Commit HMAC JSONB equality tests**

```bash
git add tests/sqlx/tests/equality_tests.rs
git commit -m "test(sqlx): add HMAC JSONB equality operator tests

- Add encrypted = jsonb direction
- Add jsonb = encrypted direction (reverse)
- Add no-match tests for both directions
- Covers SQL block 3 (lines 65-94) in =_test.sql"
```

---

### Task 3: Blake3 JSONB Equality Tests

**Files:**
- Modify: `tests/sqlx/tests/equality_tests.rs`

**Step 1: Write tests for Blake3 e = jsonb (both directions + no-match)**

Add to `equality_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_blake3(pool: PgPool) {
    // Test: eql_v2_encrypted = jsonb with Blake3 index
    // Original SQL line 164-193 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(1, 'b3')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_blake3(pool: PgPool) {
    // Test: jsonb = eql_v2_encrypted with Blake3 index (reverse direction)
    // Original SQL line 177-180 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(1, 'b3')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_no_match_blake3(pool: PgPool) {
    // Test: eql_v2_encrypted = jsonb with no matching record (Blake3)
    // Original SQL line 184-187 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(4, 'b3')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_no_match_blake3(pool: PgPool) {
    // Test: jsonb = eql_v2_encrypted with no matching record (Blake3)
    // Original SQL line 188-191 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(4, 'b3')::text";
    let row = sqlx::query(sql_create).fetch_one(&pool).await.unwrap();
    let json_value: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;
}
```

**Step 2: Run all Blake3 JSONB tests**

```bash
cd tests/sqlx
cargo test jsonb.*blake3 -- --nocapture
```

Expected: All 4 tests PASS

**Step 3: Commit Blake3 JSONB equality tests**

```bash
git add tests/sqlx/tests/equality_tests.rs
git commit -m "test(sqlx): add Blake3 JSONB equality operator tests

- Add encrypted = jsonb direction
- Add jsonb = encrypted direction (reverse)
- Add no-match tests for both directions
- Covers SQL block 6 (lines 164-193) in =_test.sql
- Completes equality test migration (16/16 assertions)"
```

**Step 4: Verify complete equality coverage**

```bash
cd tests/sqlx
cargo test equality -- --nocapture
```

Expected: 13 equality tests PASS (5 original + 2 Blake3 eq + 4 HMAC jsonb + 4 Blake3 jsonb = 15 total, adjust count)

**Step 5: Update coverage tracking**

Modify `tests/sqlx/TEST_MIGRATION_COVERAGE.md`:
- Update "Equality Tests" coverage to 100% (16/16)
- Mark all missing equality tests as ✅ Complete

---

## Phase 2: Complete JSONB Tests (13 Missing Assertions)

### Task 4: JSONB Structure Validation Tests

**Files:**
- Modify: `tests/sqlx/tests/jsonb_tests.rs`

**Step 1: Write test for jsonb_path_query structure validation**

Add after line 158 in `jsonb_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_returns_valid_structure(pool: PgPool) {
    // Test: jsonb_path_query returns JSONB with correct structure ('i' and 'v' keys)
    // Original SQL line 195-207 in src/jsonb/functions_test.sql
    // Important: Validates decrypt-ability of returned data

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}')::jsonb FROM encrypted LIMIT 1",
        Selectors::N
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let result: serde_json::Value = row.try_get(0).unwrap();

    // Verify structure has 'i' (iv) and 'v' (value) keys required for decryption
    assert!(
        result.get("i").is_some(),
        "Result must contain 'i' key for initialization vector"
    );
    assert!(
        result.get("v").is_some(),
        "Result must contain 'v' key for encrypted value"
    );
}
```

**Step 2: Add serde_json dependency if needed**

Check `tests/sqlx/Cargo.toml` - if `serde_json` is not present, add:

```toml
[dependencies]
serde_json = "1.0"
```

**Step 3: Run test to verify it passes**

```bash
cd tests/sqlx
cargo test jsonb_path_query_returns_valid_structure -- --nocapture
```

Expected: PASS (structure validation succeeds)

**Step 4: Write test for jsonb_array_elements structure validation**

Add to `jsonb_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_returns_valid_structure(pool: PgPool) {
    // Test: jsonb_array_elements returns elements with correct structure
    // Original SQL line 211-223 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}'))::jsonb FROM encrypted LIMIT 1",
        Selectors::ARRAY_ELEMENTS
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let result: serde_json::Value = row.try_get(0).unwrap();

    // Verify array elements maintain encryption structure
    assert!(
        result.get("i").is_some(),
        "Array element must contain 'i' key for initialization vector"
    );
    assert!(
        result.get("v").is_some(),
        "Array element must contain 'v' key for encrypted value"
    );
}
```

**Step 5: Run structure validation tests**

```bash
cd tests/sqlx
cargo test valid_structure -- --nocapture
```

Expected: Both tests PASS

**Step 6: Commit structure validation tests**

```bash
git add tests/sqlx/tests/jsonb_tests.rs tests/sqlx/Cargo.toml
git commit -m "test(sqlx): add JSONB structure validation tests

- Add jsonb_path_query structure validation (i/v keys)
- Add jsonb_array_elements structure validation
- Critical for ensuring decrypt-ability of returned data
- Covers SQL blocks 7-8 (lines 195-223) in functions_test.sql"
```

---

### Task 5: jsonb_path_query_first Tests

**Files:**
- Modify: `tests/sqlx/tests/jsonb_tests.rs`

**Step 1: Write test for jsonb_path_query_first with array**

Add to `jsonb_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_query_first_with_array_selector(pool: PgPool) {
    // Test: jsonb_path_query_first returns first element from array path
    // Original SQL line 135-160 in src/jsonb/functions_test.sql

    let sql = "SELECT eql_v2.jsonb_path_query_first(e, '33743aed3ae636f6bf05cff11ac4b519') as e FROM encrypted";

    // Should return 4 total rows (3 from encrypted_json + 1 from array_data)
    QueryAssertion::new(&pool, sql).count(4).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_query_first_filters_non_null(pool: PgPool) {
    // Test: jsonb_path_query_first can filter by non-null values
    // Original SQL line 331-333 in src/jsonb/functions_test.sql

    let sql = "SELECT eql_v2.jsonb_path_query_first(e, '33743aed3ae636f6bf05cff11ac4b519') as e FROM encrypted WHERE eql_v2.jsonb_path_query_first(e, '33743aed3ae636f6bf05cff11ac4b519') IS NOT NULL";

    // Should return only 1 row (the one with array data)
    QueryAssertion::new(&pool, sql).count(1).await;
}
```

**Step 2: Run jsonb_path_query_first tests**

```bash
cd tests/sqlx
cargo test jsonb_path_query_first -- --nocapture
```

Expected: Both tests PASS

**Step 3: Commit jsonb_path_query_first tests**

```bash
git add tests/sqlx/tests/jsonb_tests.rs
git commit -m "test(sqlx): add jsonb_path_query_first tests

- Add test for array selector behavior
- Add test for non-null filtering
- Covers SQL blocks 5 & 12 (lines 135-160, 311-336)"
```

---

### Task 6: Array-Specific JSONB Tests

**Files:**
- Modify: `tests/sqlx/tests/jsonb_tests.rs`

**Step 1: Write test for jsonb_path_query with array selector**

Add to `jsonb_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_query_with_array_selector_returns_single_result(pool: PgPool) {
    // Test: jsonb_path_query wraps arrays as single result
    // Original SQL line 254-274 in src/jsonb/functions_test.sql

    let sql = "SELECT eql_v2.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5') FROM encrypted";

    // Array should be wrapped and returned as single element
    QueryAssertion::new(&pool, sql).count(1).await;
}
```

**Step 2: Write test for jsonb_path_exists with array selector**

Add to `jsonb_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_exists_with_array_selector(pool: PgPool) {
    // Test: jsonb_path_exists works with array selectors
    // Original SQL line 282-303 in src/jsonb/functions_test.sql

    let sql = "SELECT eql_v2.jsonb_path_exists(e, 'f510853730e1c3dbd31b86963f029dd5') FROM encrypted";

    // Should return 4 rows (3 encrypted_json + 1 array_data)
    QueryAssertion::new(&pool, sql).count(4).await;
}
```

**Step 3: Run array-specific tests**

```bash
cd tests/sqlx
cargo test array_selector -- --nocapture
```

Expected: Both tests PASS

**Step 4: Commit array-specific tests**

```bash
git add tests/sqlx/tests/jsonb_tests.rs
git commit -m "test(sqlx): add array-specific JSONB path tests

- Add jsonb_path_query with array selector
- Add jsonb_path_exists with array selector
- Covers SQL blocks 10-11 (lines 254-303)"
```

---

### Task 7: Encrypted Selector Tests

**Files:**
- Modify: `tests/sqlx/tests/jsonb_tests.rs`

**Step 1: Write test for jsonb_array_elements with encrypted selector**

Add to `jsonb_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_with_encrypted_selector(pool: PgPool) {
    // Test: jsonb_array_elements_text accepts eql_v2_encrypted selector
    // Original SQL line 39-66 in src/jsonb/functions_test.sql
    // Tests alternative API pattern using encrypted selector

    // Create encrypted selector for array elements path
    let selector_sql = "SELECT '\"s\": \"f510853730e1c3dbd31b86963f029dd5\"'::jsonb::eql_v2_encrypted::text";
    let row = sqlx::query(selector_sql).fetch_one(&pool).await.unwrap();
    let encrypted_selector: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}'::eql_v2_encrypted)) as e FROM encrypted",
        encrypted_selector
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(5)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_with_encrypted_selector_throws_for_non_array(pool: PgPool) {
    // Test: encrypted selector also validates array type
    // Original SQL line 61-63 in src/jsonb/functions_test.sql

    let selector_sql = "SELECT '{\"s\": \"33743aed3ae636f6bf05cff11ac4b519\"}'::jsonb::eql_v2_encrypted::text";
    let row = sqlx::query(selector_sql).fetch_one(&pool).await.unwrap();
    let encrypted_selector: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}'::eql_v2_encrypted)) as e FROM encrypted LIMIT 1",
        encrypted_selector
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}
```

**Step 2: Run encrypted selector tests**

```bash
cd tests/sqlx
cargo test encrypted_selector -- --nocapture
```

Expected: Both tests PASS

**Step 3: Commit encrypted selector tests**

```bash
git add tests/sqlx/tests/jsonb_tests.rs
git commit -m "test(sqlx): add encrypted selector JSONB tests

- Add jsonb_array_elements with encrypted selector
- Add exception test for non-array with encrypted selector
- Tests alternative API pattern for encrypted selectors
- Covers SQL block 2 (lines 39-66)
- Completes JSONB test migration (24/24 assertions)"
```

**Step 4: Verify complete JSONB coverage**

```bash
cd tests/sqlx
cargo test jsonb -- --nocapture
```

Expected: 18 JSONB tests PASS (11 original + 2 structure + 2 query_first + 2 array + 2 encrypted = 19 total)

**Step 5: Update coverage tracking**

Modify `tests/sqlx/TEST_MIGRATION_COVERAGE.md`:
- Update "JSONB Tests" coverage to 100% (24/24)
- Mark all missing JSONB tests as ✅ Complete
- Update overall coverage to 100% (40/40)

---

## Phase 3: Coverage Improvements & Test Infrastructure

### Task 8: Add Assertion Count Tracking

**Files:**
- Create: `tests/sqlx/tools/count_assertions.sh`

**Step 1: Create assertion counting script**

```bash
#!/usr/bin/env bash
# Count assertions in SQL vs Rust tests for verification

set -euo pipefail

echo "=== Test Assertion Counts ==="
echo ""
echo "SQL Tests:"
echo "  Equality (=_test.sql):  $(grep -c 'PERFORM assert' src/operators/=_test.sql)"
echo "  JSONB (functions_test.sql): $(grep -c 'PERFORM assert' src/jsonb/functions_test.sql)"
echo ""
echo "Rust Tests:"
echo "  Equality: $(grep -c '^#\[sqlx::test\]' tests/sqlx/tests/equality_tests.rs)"
echo "  JSONB: $(grep -c '^#\[sqlx::test\]' tests/sqlx/tests/jsonb_tests.rs)"
echo ""
echo "Coverage:"
sql_total=$(($(grep -c 'PERFORM assert' src/operators/=_test.sql) + $(grep -c 'PERFORM assert' src/jsonb/functions_test.sql)))
rust_total=$(($(grep -c '^#\[sqlx::test\]' tests/sqlx/tests/equality_tests.rs) + $(grep -c '^#\[sqlx::test\]' tests/sqlx/tests/jsonb_tests.rs)))
coverage=$(awk "BEGIN {printf \"%.1f\", ($rust_total/$sql_total)*100}")
echo "  Total: ${rust_total}/${sql_total} assertions ($coverage%)"
```

**Step 2: Make script executable**

```bash
chmod +x tests/sqlx/tools/count_assertions.sh
```

**Step 3: Run script to verify**

```bash
./tests/sqlx/tools/count_assertions.sh
```

Expected output showing 100% coverage

**Step 4: Commit assertion tracking**

```bash
git add tests/sqlx/tools/count_assertions.sh
git commit -m "feat(testing): add assertion count tracking script

Provides quick verification of SQL → Rust test migration progress"
```

---

### Task 9: Identify Coverage Improvement Opportunities

**Files:**
- Create: `tests/sqlx/COVERAGE_IMPROVEMENTS.md`

**Step 1: Document coverage improvement opportunities**

```markdown
# Test Coverage Improvement Opportunities

> **Status:** Like-for-like migration complete (100%). This document identifies areas for enhanced coverage.

## Current Coverage (Like-for-Like)

✅ **Equality Operators**: 16/16 assertions (100%)
- HMAC equality (operator + function + JSONB)
- Blake3 equality (operator + function + JSONB)

✅ **JSONB Functions**: 24/24 assertions (100%)
- Array functions (elements, elements_text, length)
- Path queries (query, query_first, exists)
- Structure validation
- Encrypted selectors

## Improvement Opportunities

### 1. Parameterized Testing (Reduce Code Duplication)

**Current State:** Separate tests for HMAC vs Blake3 with duplicated logic

**Improvement:** Use test parameterization

```rust
#[rstest]
#[case("hm", "HMAC")]
#[case("b3", "Blake3")]
fn equality_operator_finds_matching_record(
    #[case] index_type: &str,
    #[case] index_name: &str,
) {
    // Single test covers both index types
}
```

**Benefits:**
- Reduces code duplication
- Easier to add new index types
- Consistent test patterns

**Dependencies:** Add `rstest = "0.18"` to Cargo.toml

---

### 2. Property-Based Testing for Loops

**Current State:** SQL tests loop 1..3, Rust tests single iteration

**SQL Pattern:**
```sql
for i in 1..3 loop
  e := create_encrypted_json(i, 'hm');
  PERFORM assert_result(...);
end loop;
```

**Improvement:** Use proptest for multiple iterations

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn equality_works_for_multiple_records(id in 1..=10i32) {
        // Test holds for any id in range
    }
}
```

**Benefits:**
- Tests edge cases automatically
- Discovers unexpected failures
- More thorough than fixed iterations

**Dependencies:** Add `proptest = "1.0"` to Cargo.toml

---

### 3. Additional Operator Coverage

**Missing from SQL tests:**
- `<>` (not equals) operator
- `<`, `>`, `<=`, `>=` (comparison operators with ORE)
- `@>`, `<@` (containment operators)
- `~~` (LIKE operator)

**Recommendation:** Add comprehensive operator test suite

**Files to reference:**
- `src/operators/<>.sql`
- `src/operators/<.sql`, `src/operators/>.sql`
- `src/operators/@>.sql`, `src/operators/<@.sql`
- `src/operators/~~.sql`

---

### 4. Error Handling & Edge Cases

**Current Coverage:** Basic exception tests (non-array to array functions)

**Additional Tests:**
- NULL handling
- Empty arrays
- Invalid selector formats
- Type mismatches
- Concurrent updates

---

### 5. Performance & Load Testing

**Not covered in SQL or Rust tests:**

- Query performance with large datasets
- Index effectiveness validation
- Concurrent query behavior
- Memory usage patterns

**Recommendation:** Separate benchmark suite using criterion.rs

---

## Priority Ranking

1. **High:** Additional operator coverage (inequality, comparisons, containment)
2. **Medium:** Parameterized tests (reduce duplication)
3. **Medium:** Error handling edge cases
4. **Low:** Property-based testing (nice-to-have)
5. **Low:** Performance benchmarks (separate concern)

---

## Next Steps

1. Complete like-for-like migration ✅
2. Review this document with team
3. Prioritize improvements based on risk/value
4. Create separate tasks for each improvement
5. Implement incrementally
```

**Step 2: Commit coverage improvements doc**

```bash
git add tests/sqlx/COVERAGE_IMPROVEMENTS.md
git commit -m "docs(testing): identify test coverage improvements

Documents opportunities beyond like-for-like migration:
- Parameterized testing
- Property-based testing
- Additional operators
- Error handling
- Performance testing"
```

---

### Task 10: Update Main Documentation

**Files:**
- Modify: `tests/sqlx/README.md`

**Step 1: Add migration completion notice**

Add section to README after line 10:

```markdown
## Migration Status

✅ **Like-for-Like Migration: Complete** (40/40 SQL assertions ported)

- Equality operators: 16/16 (HMAC + Blake3, operators + functions + JSONB)
- JSONB functions: 24/24 (arrays, paths, structure validation, encrypted selectors)

See `TEST_MIGRATION_COVERAGE.md` for detailed mapping.
See `COVERAGE_IMPROVEMENTS.md` for enhancement opportunities.
```

**Step 2: Update running tests section**

Update the "Running Tests" section:

```markdown
## Running Tests

```bash
# Run all SQLx tests (builds EQL, runs migrations, tests)
mise run test:sqlx

# Run specific test file
cd tests/sqlx
cargo test --test equality_tests

# Run specific test
cargo test equality_operator_finds_matching_record_hmac -- --nocapture

# Run with coverage tracking
./tools/count_assertions.sh
```

**Step 3: Commit README updates**

```bash
git add tests/sqlx/README.md
git commit -m "docs(sqlx): update README with migration completion

- Mark like-for-like migration as complete
- Add assertion count tracking instructions
- Reference coverage documentation"
```

---

### Task 11: Final Verification & Branch Preparation

**Files:**
- Modify: `tests/sqlx/TEST_MIGRATION_COVERAGE.md`

**Step 1: Run complete test suite**

```bash
cd tests/sqlx
cargo test -- --nocapture
```

Expected: All tests PASS

**Step 2: Verify assertion counts**

```bash
./tools/count_assertions.sh
```

Expected: Shows 100% coverage

**Step 3: Run mise test task**

```bash
mise run test:sqlx
```

Expected: Full pipeline succeeds (build → migrations → tests)

**Step 4: Update TEST_MIGRATION_COVERAGE.md with final status**

Replace the "Summary" section:

```markdown
## Summary

### ✅ Migration Complete: 100% Like-for-Like Coverage

- **Equality Tests**: 16/16 assertions migrated (100%)
- **JSONB Tests**: 24/24 assertions migrated (100%)
- **Total**: 40/40 assertions migrated (100%)

### Test Breakdown

**Equality Tests (16 total):**
- HMAC `e = e` operator: 2 tests (match + no-match)
- HMAC `eq()` function: 2 tests (match + no-match)
- HMAC JSONB operators: 4 tests (e=jsonb, jsonb=e, both directions + no-match)
- Blake3 `e = e` operator: 2 tests (match + no-match)
- Blake3 `eq()` function: 2 tests (match + no-match)
- Blake3 JSONB operators: 4 tests (e=jsonb, jsonb=e, both directions + no-match)

**JSONB Tests (24 total):**
- `jsonb_array_elements`: 3 tests (result, count, exception) + 2 encrypted selector tests
- `jsonb_array_elements_text`: 3 tests (result, count, exception)
- `jsonb_array_length`: 2 tests (value, exception)
- `jsonb_path_query`: 4 tests (basic, count, array selector, structure validation)
- `jsonb_path_query_first`: 2 tests (array selector, non-null filter)
- `jsonb_path_exists`: 5 tests (true, false, count, array selector, structure)
- Structure validation: 2 tests (ensuring decrypt-ability)

### What's Next

See `COVERAGE_IMPROVEMENTS.md` for opportunities to enhance coverage beyond like-for-like migration.

---

**Last verified**: [Current Date]
**Verified by**: Complete test run + assertion count validation
**Status**: ✅ Ready for PR review
```

**Step 5: Commit final verification**

```bash
git add tests/sqlx/TEST_MIGRATION_COVERAGE.md
git commit -m "docs(testing): mark migration as 100% complete

All 40 SQL assertions successfully ported to SQLx framework"
```

**Step 6: Create summary of branch changes**

```bash
git log feature/rust-test-framework-poc..HEAD --oneline > MIGRATION_SUMMARY.txt
git add MIGRATION_SUMMARY.txt
git commit -m "docs: add migration commit summary"
```

**Step 7: Push branch**

```bash
git push origin feature/sqlx-test-migration
```

Expected: Branch pushed successfully

---

## Phase 4: Optional Improvements (Post-Migration)

### Task 12: Add Parameterized Testing (Optional)

**Dependencies:**
- Add `rstest = "0.21"` to `tests/sqlx/Cargo.toml`

**Files:**
- Modify: `tests/sqlx/tests/equality_tests.rs`

**Step 1: Add rstest dependency**

```toml
[dev-dependencies]
rstest = "0.21"
```

**Step 2: Refactor HMAC/Blake3 tests with parameterization**

Example refactor of duplicate tests:

```rust
use rstest::rstest;

#[rstest]
#[case("hm", "HMAC")]
#[case("b3", "Blake3")]
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_parameterized(
    pool: PgPool,
    #[case] index_type: &str,
    #[case] index_name: &str,
) {
    let encrypted = create_encrypted_json_with_index(&pool, 1, index_type).await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}
```

**Step 3: Run parameterized tests**

```bash
cargo test parameterized -- --nocapture
```

**Step 4: Gradually refactor other duplicate tests**

**Step 5: Commit parameterization**

```bash
git add tests/sqlx/Cargo.toml tests/sqlx/tests/equality_tests.rs
git commit -m "refactor(testing): add parameterized tests for index types

Reduces duplication between HMAC and Blake3 test patterns"
```

---

## Success Criteria

- ✅ All 40 SQL assertions migrated to Rust/SQLx
- ✅ `mise run test:sqlx` passes with 100% success rate
- ✅ Coverage documentation updated to reflect 100% completion
- ✅ Assertion count tracking script confirms parity
- ✅ All commits follow conventional commit format
- ✅ Branch ready for PR to main

---

## Rollback Plan

If issues arise during migration:

1. Each task commits separately - can revert individual commits
2. Branch is isolated in worktree - main remains unaffected
3. Original SQL tests remain in src/ - can reference at any time
4. Can cherry-pick successful commits if needed

---

## Notes for Executor

**Testing Strategy:**
- Run tests after each commit to catch regressions early
- Use `--nocapture` flag to see detailed output
- SQLx provides fresh database per test - no cleanup needed

**Common Pitfalls:**
- Forgetting to add fixtures to `#[sqlx::test]` macro
- Incorrect selector hashes (copy from SQL source)
- Type mismatches between SQL and Rust (use ::text casts)

**Performance:**
- Tests run in parallel automatically
- Each test takes ~200-500ms
- Full suite should complete in <30 seconds

**Reference Documentation:**
- SQLx docs: https://docs.rs/sqlx/latest/sqlx/
- Assertion helper: `tests/sqlx/src/assertions.rs`
- Selector constants: `tests/sqlx/src/selectors.rs`
