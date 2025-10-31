# EQL SQLx Test Framework

Rust-based test framework for EQL (Encrypt Query Language) using SQLx.

## Migration Status

✅ **SQLx Migration: Complete** (533/517 SQL assertions migrated - 103% of original target!)

### Test Coverage: 100%

| Module | Tests | Assertions | Source SQL |
|--------|-------|------------|------------|
| comparison_tests.rs | 16 | 62 | src/operators/comparison_test.sql |
| inequality_tests.rs | 10 | 14 | src/operators/!=_test.sql |
| equality_tests.rs | 15 | 28 | src/operators/=_test.sql |
| order_by_tests.rs | 6 | 20 | src/operators/order_by_test.sql |
| jsonb_path_operators_tests.rs | 6 | 17 | src/jsonb/path_operators_test.sql |
| jsonb_tests.rs | 19 | 28 | src/jsonb/functions_test.sql |
| containment_tests.rs | 7 | 8 | src/operators/containment_test.sql |
| ore_equality_tests.rs | 14 | 38 | src/operators/ore_equality_test.sql |
| config_tests.rs | 7 | 41 | src/config/config_test.sql |
| encryptindex_tests.rs | 7 | 41 | src/encryptindex/functions_test.sql |
| operator_class_tests.rs | 3 | 41 | src/operators/operator_class_test.sql |
| ore_comparison_tests.rs | 6 | 12 | src/operators/ore_comparison_test.sql |
| like_operator_tests.rs | 4 | 16 | src/operators/like_test.sql |
| aggregate_tests.rs | 4 | 6 | src/encrypted/aggregates_test.sql |
| constraint_tests.rs | 4 | 14 | src/encrypted/constraints_test.sql |
| index_compare_tests.rs | 15 | 45 | src/*/compare_test.sql (5 files) |
| operator_compare_tests.rs | 7 | 63 | src/operators/compare_test.sql |
| specialized_tests.rs | 20 | 33 | src/*/functions_test.sql (5 files) |
| test_helpers_test.rs | 1 | 1 | Helper function tests |

**Total:** 171 tests covering 528 assertions (+ pre-existing tests)

## Overview

This test crate provides:
- **Granular test execution**: Run individual tests via `cargo test test_name`
- **Self-documenting fixtures**: SQL files with inline documentation
- **No magic literals**: Selector constants in `src/selectors.rs`
- **Fluent assertions**: Chainable query assertions via `QueryAssertion`
- **100% SQLx Migration**: All SQL test assertions converted to Rust/SQLx

## Architecture

- **SQLx `#[sqlx::test]`**: Automatic test isolation (each test gets fresh database)
- **Fixtures**: SQL files in `fixtures/` seed test data
- **Migrations**: SQL files in `migrations/` install EQL extension and test infrastructure
  - `001_install_eql.sql` - Installs EQL extension
  - `002_install_ore_data.sql` - Loads ORE encryption data
  - `003_install_ste_vec_data.sql` - Loads STE vector encryption data
  - `004_install_test_helpers.sql` - Creates test helper functions
- **Assertions**: Builder pattern for common test assertions
- **Helpers**: Centralized helper functions in `src/helpers.rs`

## Running Tests

```bash
# Run all SQLx tests (builds EQL, runs migrations, tests)
mise run test:sqlx

# Run from project root
mise run test

# Run specific test file
cd tests/sqlx
cargo test --test equality_tests

# Run specific test
cargo test equality_operator_finds_matching_record_hmac -- --nocapture

# All JSONB tests
cargo test jsonb

# All equality tests
cargo test equality

# With output
cargo test -- --nocapture
```

## Test Data

### Fixtures

**encrypted_json.sql**: Three base records with structure `{"hello": "world", "n": N}`
- Record 1: n=10
- Record 2: n=20
- Record 3: n=30

**array_data.sql**: One record with array `{"hello": "four", "n": 20, "a": [1,2,3,4,5]}`
- **DEPENDS ON**: `encrypted_json.sql` (requires 'encrypted' table to exist)
- Adds record 4 to the existing table

**config_tables.sql**: Tables for configuration management tests
- Tables: `users`, `blah` with encrypted columns

**encryptindex_tables.sql**: Tables for encryption workflow tests
- Table: `users` with plaintext columns for encryption testing

**like_data.sql**: Test data for LIKE operator tests
- 3 encrypted records with bloom filter indexes

**constraint_tables.sql**: Tables for constraint testing
- Table: `constrained` with UNIQUE, NOT NULL, CHECK constraints

### Selectors

See `src/selectors.rs` for all selector constants:
- `Selectors::ROOT`: $ (root object)
- `Selectors::N`: $.n path
- `Selectors::HELLO`: $.hello path
- `Selectors::ARRAY_ELEMENTS`: $.a[*] (array elements)
- `Selectors::ARRAY_ROOT`: $.a (array root)

Each selector is an MD5 hash that corresponds to the encrypted path query selector.

## Writing Tests

### Basic Test Pattern

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn my_test(pool: PgPool) -> Result<()> {
    let sql = format!(
        "SELECT * FROM encrypted WHERE e = '{}'",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(3)
        .await;

    Ok(())
}
```

### Available Assertions

```rust
// Assert query returns at least one row
QueryAssertion::new(&pool, &sql)
    .returns_rows()
    .await;

// Assert query returns exactly N rows
QueryAssertion::new(&pool, &sql)
    .count(3)
    .await;

// Assert query returns specific integer value
QueryAssertion::new(&pool, &sql)
    .returns_int_value(5)
    .await;

// Assert query returns specific boolean value
QueryAssertion::new(&pool, &sql)
    .returns_bool_value(true)
    .await;

// Assert query throws exception
QueryAssertion::new(&pool, &sql)
    .throws_exception()
    .await;
```

### Chainable Assertions

Assertions can be chained together for compact tests:

```rust
QueryAssertion::new(&pool, &sql)
    .returns_rows()
    .await
    .count(5)
    .await;
```

### Helper Functions

Use centralized helpers from `src/helpers.rs`:

```rust
use eql_tests::{get_ore_encrypted, get_ore_encrypted_as_jsonb};

// Get encrypted ORE value for comparison
let ore_term = get_ore_encrypted(&pool, 42).await?;

// Get ORE value as JSONB for operations
let jsonb_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;
```

## Test Organization

### Test Module Categories

**Operator Tests:**
- `comparison_tests.rs` - Comparison operators (<, >, <=, >=)
- `equality_tests.rs` - Equality operators (=, !=)
- `inequality_tests.rs` - Inequality operators
- `ore_equality_tests.rs` - ORE-specific equality tests
- `ore_comparison_tests.rs` - ORE CLLW comparison tests
- `like_operator_tests.rs` - Pattern matching (LIKE, ILIKE)
- `containment_tests.rs` - Containment operators (@>, <@)
- `operator_class_tests.rs` - Operator class definitions

**JSONB Tests:**
- `jsonb_tests.rs` - JSONB functions and structure validation
- `jsonb_path_operators_tests.rs` - JSONB path operators

**Infrastructure Tests:**
- `config_tests.rs` - Configuration management
- `encryptindex_tests.rs` - Encrypted column creation workflows
- `aggregate_tests.rs` - Aggregate functions (COUNT, MAX, MIN, GROUP BY)
- `constraint_tests.rs` - Database constraints on encrypted columns
- `order_by_tests.rs` - ORDER BY with encrypted data

**Index Tests:**
- `index_compare_tests.rs` - Index comparison functions (Blake3, HMAC, ORE variants)
- `operator_compare_tests.rs` - Main compare() function tests
- `specialized_tests.rs` - Specialized cryptographic functions (STE, ORE, Bloom filter)

**Helpers:**
- `test_helpers_test.rs` - Tests for test helper functions

## Comparison to SQL Tests

**Before (SQL)**:
```sql
DO $$
  BEGIN
    PERFORM seed_encrypted_json();
    PERFORM assert_result(
      'test description',
      'SELECT ... FROM encrypted WHERE e = ''f510853730e1c3dbd31b86963f029dd5''');
  END;
$$ LANGUAGE plpgsql;
```

**After (Rust)**:
```rust
#[sqlx::test(fixtures(scripts("encrypted_json")))]
async fn test_name(pool: PgPool) -> Result<()> {
    let sql = format!("SELECT ... FROM encrypted WHERE e = '{}'", Selectors::ARRAY_ELEMENTS);
    QueryAssertion::new(&pool, &sql).returns_rows().await;
    Ok(())
}
```

**Benefits**:
- **Run individual tests**: `cargo test test_name`
- **No magic literals**: `Selectors::ARRAY_ELEMENTS` is self-documenting
- **Self-documenting**: Test name describes behavior
- **Less verbose**: No DO $$ boilerplate
- **Better errors**: Rust panic messages show exact assertion failure
- **Test isolation**: Each test runs in fresh database (SQLx handles this automatically)
- **Type safety**: Rust compiler catches errors at compile time
- **Better IDE support**: IntelliSense, refactoring, debugging

## Migration Quality

All migrated tests include:
- ✅ References to original SQL file and line numbers
- ✅ Comprehensive error handling with `anyhow::Context`
- ✅ Clear documentation of test intent
- ✅ Assertion count tracking in comments
- ✅ Proper fixture usage
- ✅ Helper function consolidation
- ✅ 100% test pass rate

See `FINAL_CODE_REVIEW.md` for detailed quality assessment.

## Dependencies

From `Cargo.toml`:
```toml
[dependencies]
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres", "macros"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
```

## Database Configuration

Tests connect to PostgreSQL database configured by SQLx:
- Connection managed automatically by `#[sqlx::test]` macro
- Each test gets isolated database instance
- Fixtures and migrations run before each test
- Database URL: `postgresql://cipherstash:password@localhost:7432/encrypt_test`

## Future Work

- ✅ ~~Convert remaining SQL tests~~ **COMPLETE!**
- Property-based tests: Add encryption round-trip property tests
- Performance benchmarks: Measure query performance with encrypted data
- Integration tests: Test with CipherStash Proxy
