# EQL Test Framework

Rust-based test framework for EQL (Encrypt Query Language) using SQLx.

## Overview

This test crate provides:
- **Granular test execution**: Run individual tests via `cargo test test_name`
- **Self-documenting fixtures**: SQL files with inline documentation
- **No magic literals**: Selector constants in `src/selectors.rs`
- **Fluent assertions**: Chainable query assertions via `QueryAssertion`

## Architecture

- **SQLx `#[sqlx::test]`**: Automatic test isolation (each test gets fresh database)
- **Fixtures**: SQL files in `fixtures/` seed test data
- **Migrations**: SQL files in `migrations/` install EQL extension and test infrastructure
  - `001_install_eql.sql` - Installs EQL extension
  - `002_install_ore_data.sql` - Loads ORE encryption data
  - `003_install_ste_vec_data.sql` - Loads STE vector encryption data
  - `004_install_test_helpers.sql` - Creates test helper functions
- **Assertions**: Builder pattern for common test assertions

## Running Tests

```bash
# All tests
cargo test

# Specific test
cargo test jsonb_array_elements_returns_array_elements

# All JSONB tests
cargo test jsonb_

# All equality tests
cargo test equality_

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
async fn my_test(pool: PgPool) {
    let sql = format!(
        "SELECT * FROM encrypted WHERE e = '{}'",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(3)
        .await;
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
async fn test_name(pool: PgPool) {
    let sql = format!("SELECT ... FROM encrypted WHERE e = '{}'", Selectors::ARRAY_ELEMENTS);
    QueryAssertion::new(&pool, &sql).returns_rows().await;
}
```

**Benefits**:
- **Run individual tests**: `cargo test test_name`
- **No magic literals**: `Selectors::ARRAY_ELEMENTS` is self-documenting
- **Self-documenting**: Test name describes behavior
- **Less verbose**: No DO $$ boilerplate
- **Better errors**: Rust panic messages show exact assertion failure
- **Test isolation**: Each test runs in fresh database (SQLx handles this automatically)

## Test Organization

### Current Test Modules

**`tests/jsonb_tests.rs`** - 11 tests for JSONB functions
- Converted from `src/jsonb/functions_test.sql`
- Tests: `jsonb_array_elements`, `jsonb_array_elements_text`, `jsonb_array_length`, `jsonb_path_query`, `jsonb_path_exists`

**`tests/equality_tests.rs`** - 5 tests for equality operators
- Converted from `src/operators/=_test.sql`
- Tests: HMAC index equality, Blake3 index equality, `eq()` function

### Test Count

- **Total**: 16 tests
- **JSONB**: 11 tests
- **Equality**: 5 tests

## Dependencies

From `Cargo.toml`:
```toml
[dependencies]
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres", "macros"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

## Database Configuration

Tests connect to PostgreSQL database configured by SQLx:
- Connection managed automatically by `#[sqlx::test]` macro
- Each test gets isolated database instance
- Fixtures and migrations run before each test

## Future Work

- **Fixture generator tool** (see `docs/plans/fixture-generator.md`)
- **Convert remaining SQL tests**: Many SQL tests still need conversion
- **Property-based tests**: Add encryption round-trip property tests
- **Coverage expansion**: ORE indexes, bloom filters, other operators
