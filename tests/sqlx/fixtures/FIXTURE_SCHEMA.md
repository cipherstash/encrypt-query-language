# SQLx Test Fixtures Schema Documentation

This document defines the structure and dependencies of test fixtures used in the SQLx test suite.

## Fixture Dependencies

```
EQL Extension (via migrations)
  ├── encrypted_json.sql
  ├── array_data.sql
  └── ore_data.sql
```

All fixtures depend on the EQL extension being installed via SQLx migrations.

---

## encrypted_json.sql

**Purpose:** Creates `encrypted` table with HMAC-indexed encrypted values for equality/JSONB tests.

**Schema:**
```sql
CREATE TABLE encrypted (
  id INTEGER PRIMARY KEY,
  e eql_v2_encrypted
);
```

**Data:**
- 3 records (ids 1, 2, 3)
- Each record has encrypted JSONB with HMAC index
- Values include nested objects for JSONB path tests

**Used By:**
- equality_tests.rs
- jsonb_tests.rs
- inequality_tests.rs
- jsonb_path_operators_tests.rs
- containment_tests.rs
- like_operator_tests.rs
- aggregate_tests.rs

**Create Function:**
- Uses `create_encrypted_json(id, 'hm')` for HMAC-indexed values
- Creates consistent test data across test runs

---

## array_data.sql

**Purpose:** Creates test data with arrays for JSONB array function tests.

**Dependencies:**
- Requires `encrypted_json.sql` (extends encrypted table or creates new table)

**Data:**
- Records with JSONB arrays
- Used for testing `jsonb_array_elements()` and array path queries

**Used By:**
- jsonb_tests.rs (array-specific tests)

---

## ore table (from migrations - NOT a fixture)

**Source:** `tests/sqlx/migrations/002_install_ore_data.sql`

**Purpose:** Provides ORE-encrypted values 1-99 for comparison/ORDER BY tests.

**Schema:**
```sql
CREATE TABLE ore (
  id bigint PRIMARY KEY,
  e eql_v2_encrypted
);
```

**Data:**
- 99 records (ids 1-99)
- Each record has ONLY `ob` key (ORE block), NOT ore64 index
- Pre-seeded by migration, available to all tests automatically
- No fixture needed - table exists from migrations

**Used By:**
- comparison_tests.rs (< > <= >=)
- order_by_tests.rs
- ore_equality_tests.rs (ORE variants)
- aggregate_tests.rs (MAX/MIN)

**Helper Functions:**
- `get_ore_encrypted(pool, id)` - Selects encrypted value from ore table
- `create_encrypted_json(id)` - Looks up ore table at `id * 10` (valid ids: 1-9 → ore lookups: 10-90)

**Key Property:**
- Sequential numeric values enable deterministic comparison tests
- e.g., `WHERE e < get_ore_encrypted(42)` should return 41 records

**IMPORTANT:**
- ❌ DO NOT create `ore_data.sql` fixture - table already exists from migrations
- ❌ DO NOT use `scripts("ore_data")` in test attributes
- ✅ Use `#[sqlx::test]` without fixtures for ORE tests

---

## Validation Tests

Each fixture should have a validation test to ensure correct structure:

### encrypted_json Validation
```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn fixture_encrypted_json_has_three_records(pool: PgPool) {
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM encrypted")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(count, 3, "encrypted_json fixture should create 3 records");
}
```

### ore_data Validation
```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("ore_data")))]
async fn fixture_ore_data_has_99_records(pool: PgPool) {
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM ore")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(count, 99, "ore_data fixture should create 99 records");
}
```

---

## Fixture Naming Conventions

- Use snake_case for fixture file names
- Name should describe the data, not the test using it
- Examples: `encrypted_json.sql`, `ore_data.sql`, `array_data.sql`

## Adding New Fixtures

1. Create fixture file in `tests/sqlx/fixtures/`
2. Add header comment explaining purpose and dependencies
3. Document schema in this file
4. Add validation test
5. Update dependency graph above

## Troubleshooting

**Fixture fails to load:**
- Check EQL extension is installed (migrations run first)
- Verify `create_encrypted_json()` function exists
- Check for SQL syntax errors in fixture file

**Inconsistent test results:**
- Fixtures are loaded per-test (isolated)
- Check fixture dependencies are correct
- Verify no cross-fixture table name conflicts
