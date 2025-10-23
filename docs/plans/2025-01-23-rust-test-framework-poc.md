# Rust Test Framework POC Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Create a proof-of-concept Rust test framework using SQLx that replaces verbose SQL test files with granular, self-documenting Rust tests and eliminates magic literals through fixture-based testing.

**Architecture:** New `tests/eql_tests` crate using SQLx's `#[sqlx::test]` macro for automatic test isolation. SQL fixtures with inline documentation replace procedural SQL test helpers. Custom assertion builder provides fluent, chainable test assertions. Converts `src/jsonb/functions_test.sql` and `src/operators/=_test.sql` to demonstrate the pattern.

**Tech Stack:**
- SQLx 0.8 with `macros` and `postgres` features
- tokio for async runtime
- Existing EQL PostgreSQL extension
- mise for task management and database orchestration

---

## Plan Amendments (2025-01-23)

This plan has been amended with the following improvements:

### Database Management
- **Task 0 (NEW)**: Setup database using existing mise tasks instead of manual Docker commands
- Uses `mise run postgres:up` to start PostgreSQL
- Uses `mise run eql:install` to install extension
- Leverages mise.toml environment variables for connection details

### Verification Steps
- **Task 1, Step 6 (NEW)**: Verify test helper SQL functions exist before writing tests
- **Task 3, Step 3 (NEW)**: Verify selector constants match actual encrypted data
- Added database connection verification steps

### Migration Improvements
- **Task 5**: Include test_helpers.sql as migration (002_install_test_helpers.sql)
- Added migrations/README.md documenting SQLx migration behavior
- Clarified that each test gets fresh database with migrations auto-applied

### Documentation Enhancements
- Documented SQL helper function signatures (create_encrypted_json variadic form)
- Added notes about selector hash generation and verification
- Clarified .env file usage (SQLx needs it at compile time, mise provides runtime vars)

### mise Integration
- **Task 19 (NEW)**: Optional mise task for running Rust tests (`mise run test:rust`)
- Updated CI documentation to use mise for database management
- Added cargo workspace detection and handling for existing Cargo.toml

### Task Renumbering
- Original Task 19 → Task 20 (CI configuration)

---

## Task 0: Setup Database with mise

**Prerequisites**: Verify mise and Docker are available

**Step 1: Verify mise tasks**

```bash
mise tasks | grep postgres
```

Expected output:
```
postgres:down    Tear down Postgres containers
postgres:psql    Run psql
postgres:reset   Reset database
postgres:up      Run Postgres instances with docker compose
```

**Step 2: Start PostgreSQL using mise**

```bash
mise run postgres:up --extra-args "--detach --wait"
```

This starts PostgreSQL 17 (default) on port 7432 with credentials from mise.toml:
- User: cipherstash
- Password: password
- Database: cipherstash
- Host: localhost
- Port: 7432

**Step 3: Verify database is running**

```bash
mise run postgres:psql -- -c "SELECT version();"
```

Expected: Shows PostgreSQL version

**Step 4: Install EQL and test helpers**

```bash
# Build EQL
mise run build

# Install to database
mise run eql:install

# Install test helpers
psql postgresql://cipherstash:password@localhost:7432/cipherstash -f tests/test_helpers.sql
```

**Step 5: Verify installation**

```bash
psql postgresql://cipherstash:password@localhost:7432/cipherstash -c "
SELECT EXISTS (
    SELECT 1 FROM pg_namespace WHERE nspname = 'eql_v2'
) as eql_installed;
"
```

Expected: `t` (true)

**Note**: This database will remain running for all test tasks. To reset between sessions:
```bash
mise run postgres:reset
# Then re-run install steps
```

---

## Task 1: Create Test Crate Structure

**Files:**
- Create: `tests/eql_tests/Cargo.toml`
- Create: `tests/eql_tests/src/lib.rs`
- Create: `tests/eql_tests/.env`
- Create: `tests/eql_tests/migrations/.gitkeep`
- Create: `tests/eql_tests/fixtures/.gitkeep`

**Step 1: Create test crate directory structure**

```bash
mkdir -p tests/eql_tests/src
mkdir -p tests/eql_tests/migrations
mkdir -p tests/eql_tests/fixtures
```

**Step 2: Write Cargo.toml**

```toml
[package]
name = "eql_tests"
version = "0.1.0"
edition = "2021"

[dependencies]
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres", "macros"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[dev-dependencies]
# None needed - tests live in this crate
```

**Step 3: Create lib.rs with test infrastructure**

```rust
//! EQL test framework infrastructure
//!
//! Provides assertion builders and test helpers for EQL functionality tests.

pub mod assertions;
pub mod selectors;

pub use assertions::QueryAssertion;
pub use selectors::Selectors;
```

**Step 4: Create .env file for database connection**

Use mise environment variables instead of hardcoding:

```bash
# Generate .env from mise configuration
cat > tests/eql_tests/.env << 'EOF'
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
EOF

# Or create explicit .env (mise will provide these vars at runtime)
cat > tests/eql_tests/.env << 'EOF'
DATABASE_URL=postgresql://cipherstash:password@localhost:7432/cipherstash
EOF
```

**Note**: SQLx needs DATABASE_URL at compile time for `sqlx::test` macro. The project uses mise.toml for runtime env vars.

**Step 5: Create .gitkeep files to preserve directories**

```bash
touch tests/eql_tests/migrations/.gitkeep
touch tests/eql_tests/fixtures/.gitkeep
```

**Step 6: Verify test helper functions exist**

```bash
# Ensure PostgreSQL is running
mise run postgres:up --extra-args "--detach --wait"

# Verify connection
psql postgresql://cipherstash:password@localhost:7432/cipherstash -c "SELECT 1"

# Verify test helper functions are available
psql postgresql://cipherstash:password@localhost:7432/cipherstash -c "
SELECT proname FROM pg_proc
WHERE proname IN ('seed_encrypted', 'create_encrypted_json', 'get_array_ste_vec', 'create_table_with_encrypted')
ORDER BY proname;
"
```

Expected output: Should show all 4 function names. If not, install EQL and test helpers:

```bash
mise run build
mise run eql:install
psql postgresql://cipherstash:password@localhost:7432/cipherstash -f tests/test_helpers.sql
```

**Step 7: Commit crate structure**

```bash
git add tests/eql_tests/
git commit -m "feat: create eql_tests crate structure for Rust test framework POC"
```

---

## Task 2: Implement Assertion Builder

**Files:**
- Create: `tests/eql_tests/src/assertions.rs`

**Step 1: Write assertion builder skeleton**

```rust
//! Fluent assertion builder for database queries
//!
//! Provides chainable assertions for common test patterns:
//! - Query returns rows
//! - Query returns specific count
//! - Query returns specific value
//! - Query throws exception

use sqlx::{PgPool, Row};

/// Fluent assertion builder for SQL queries
pub struct QueryAssertion<'a> {
    pool: &'a PgPool,
    sql: String,
}

impl<'a> QueryAssertion<'a> {
    /// Create new query assertion
    ///
    /// # Example
    /// ```
    /// QueryAssertion::new(&pool, "SELECT * FROM encrypted")
    ///     .returns_rows()
    ///     .await;
    /// ```
    pub fn new(pool: &'a PgPool, sql: impl Into<String>) -> Self {
        Self {
            pool,
            sql: sql.into(),
        }
    }
}
```

**Step 2: Add returns_rows assertion**

```rust
impl<'a> QueryAssertion<'a> {
    // ... existing new() method ...

    /// Assert that query returns at least one row
    ///
    /// # Panics
    /// Panics if query returns no rows or fails to execute
    pub async fn returns_rows(self) -> Self {
        let rows = sqlx::query(&self.sql)
            .fetch_all(self.pool)
            .await
            .expect(&format!("Query failed: {}", self.sql));

        assert!(
            !rows.is_empty(),
            "Expected query to return rows but got none: {}",
            self.sql
        );

        self
    }
}
```

**Step 3: Add count assertion**

```rust
impl<'a> QueryAssertion<'a> {
    // ... existing methods ...

    /// Assert that query returns exactly N rows
    ///
    /// # Panics
    /// Panics if query returns different number of rows
    pub async fn count(self, expected: usize) -> Self {
        let rows = sqlx::query(&self.sql)
            .fetch_all(self.pool)
            .await
            .expect(&format!("Query failed: {}", self.sql));

        assert_eq!(
            rows.len(),
            expected,
            "Expected {} rows but got {}: {}",
            expected,
            rows.len(),
            self.sql
        );

        self
    }
}
```

**Step 4: Add returns_value assertion**

```rust
impl<'a> QueryAssertion<'a> {
    // ... existing methods ...

    /// Assert that query returns a specific value in first row, first column
    ///
    /// # Panics
    /// Panics if value doesn't match or query fails
    pub async fn returns_value(self, expected: &str) -> Self {
        let row = sqlx::query(&self.sql)
            .fetch_one(self.pool)
            .await
            .expect(&format!("Query failed: {}", self.sql));

        let value: String = row.try_get(0)
            .expect("Failed to get column 0");

        assert_eq!(
            value,
            expected,
            "Expected '{}' but got '{}': {}",
            expected,
            value,
            self.sql
        );

        self
    }
}
```

**Step 5: Add throws_exception assertion**

```rust
impl<'a> QueryAssertion<'a> {
    // ... existing methods ...

    /// Assert that query throws an exception
    ///
    /// # Panics
    /// Panics if query succeeds instead of failing
    pub async fn throws_exception(self) {
        let result = sqlx::query(&self.sql)
            .fetch_all(self.pool)
            .await;

        assert!(
            result.is_err(),
            "Expected query to throw exception but it succeeded: {}",
            self.sql
        );
    }
}
```

**Step 6: Commit assertion builder**

```bash
git add tests/eql_tests/src/assertions.rs tests/eql_tests/src/lib.rs
git commit -m "feat: add fluent query assertion builder"
```

---

## Task 3: Create Selector Constants and Verification

**IMPORTANT**: Selector hashes are generated by EQL's selector algorithm. These must match the actual selectors produced by `create_encrypted_json()` helper functions.

**Files:**
- Create: `tests/eql_tests/src/selectors.rs`

**Step 1: Document selector mapping**

```rust
//! Selector constants for test fixtures
//!
//! These selectors correspond to encrypted test data and provide
//! self-documenting references instead of magic literals.
//!
//! Test data structure:
//! - Plaintext: {"hello": "world", "n": 10/20/30, "a": [1,2,3,4,5]}
//! - Three records with IDs 1, 2, 3 (n=10, n=20, n=30)
//! - One record with array data

/// Selector constants for test fixtures
pub struct Selectors;

impl Selectors {
    // Root selectors

    /// Selector for root object ($)
    /// Maps to: $
    pub const ROOT: &'static str = "bca213de9ccce676fa849ff9c4807963";

    /// Selector for $.hello path
    /// Maps to: $.hello
    pub const HELLO: &'static str = "a7cea93975ed8c01f861ccb6bd082784";

    /// Selector for $.n path
    /// Maps to: $.n (numeric value)
    pub const N: &'static str = "2517068c0d1f9d4d41d2c666211f785e";

    // Array selectors

    /// Selector for $.a path (array accessor)
    /// Maps to: $.a (returns array elements)
    pub const ARRAY_ELEMENTS: &'static str = "f510853730e1c3dbd31b86963f029dd5";

    /// Selector for array root
    /// Maps to: array itself as single element
    pub const ARRAY_ROOT: &'static str = "33743aed3ae636f6bf05cff11ac4b519";
}
```

**Step 2: Add helper methods for selector construction**

```rust
impl Selectors {
    // ... existing constants ...

    /// Create eql_v2_encrypted selector JSON for use in queries
    ///
    /// # Example
    /// ```
    /// let selector = Selectors::as_encrypted(Selectors::N);
    /// // Returns: {"s": "2517068c0d1f9d4d41d2c666211f785e"}
    /// ```
    pub fn as_encrypted(selector: &str) -> String {
        format!(r#"{{"s": "{}"}}"#, selector)
    }
}
```

**Step 3: Verify selectors match test data**

```bash
# Query actual selectors from test data to verify our constants
psql postgresql://cipherstash:password@localhost:7432/cipherstash -c "
SELECT DISTINCT
    jsonb_path_query(create_encrypted_json(1)::jsonb, '$.sv[*].s') as selector
FROM generate_series(1,3);
"
```

Expected selectors in output:
- `"bca213de9ccce676fa849ff9c4807963"` (ROOT)
- `"a7cea93975ed8c01f861ccb6bd082784"` (HELLO)
- `"2517068c0d1f9d4d41d2c666211f785e"` (N)

These match comments in test_helpers.sql:273-278 and the constants defined above.

**Step 4: Commit selector constants**

```bash
git add tests/eql_tests/src/selectors.rs tests/eql_tests/src/lib.rs
git commit -m "feat: add selector constants to eliminate magic literals"
```

---

## Task 4: Create SQL Fixtures

**Files:**
- Create: `tests/eql_tests/fixtures/encrypted_json.sql`
- Create: `tests/eql_tests/fixtures/array_data.sql`

**Step 1: Create encrypted_json fixture**

```sql
-- Fixture: encrypted_json.sql
--
-- Creates base test data with three encrypted records
-- Plaintext structure: {"hello": "world", "n": N}
-- where N is 10, 20, or 30 for records 1, 2, 3
--
-- Selectors:
-- $ (root)       -> bca213de9ccce676fa849ff9c4807963
-- $.hello        -> a7cea93975ed8c01f861ccb6bd082784
-- $.n            -> 2517068c0d1f9d4d41d2c666211f785e

-- Create table
CREATE TABLE IF NOT EXISTS encrypted (
    id bigint GENERATED ALWAYS AS IDENTITY,
    e eql_v2_encrypted,
    PRIMARY KEY(id)
);

-- Insert three base records using test helper
-- These call the existing SQL helper functions
SELECT seed_encrypted(create_encrypted_json(1));
SELECT seed_encrypted(create_encrypted_json(2));
SELECT seed_encrypted(create_encrypted_json(3));
```

**Step 2: Create array_data fixture**

```sql
-- Fixture: array_data.sql
--
-- Adds encrypted record with array field
-- Plaintext: {"hello": "four", "n": 20, "a": [1, 2, 3, 4, 5]}
--
-- Array selectors:
-- $.a[*] (elements) -> f510853730e1c3dbd31b86963f029dd5
-- $.a (array root)  -> 33743aed3ae636f6bf05cff11ac4b519

-- Insert array data using test helper
SELECT seed_encrypted(get_array_ste_vec()::eql_v2_encrypted);
```

**Step 3: Commit fixtures**

```bash
git add tests/eql_tests/fixtures/
git commit -m "feat: add SQL fixtures for test data seeding"
```

---

## Task 5: Setup EQL Migration and Test Helpers

**Files:**
- Create: `tests/eql_tests/migrations/001_install_eql.sql`
- Create: `tests/eql_tests/migrations/002_install_test_helpers.sql`

**Step 1: Build EQL release file**

```bash
cd /Users/tobyhede/src/encrypt-query-language
mise run build
```

Expected output: Creates `release/cipherstash-encrypt.sql`

**Step 2: Copy EQL installer to migrations**

```bash
cp release/cipherstash-encrypt.sql tests/eql_tests/migrations/001_install_eql.sql
```

**Step 3: Copy test helpers to migrations**

```bash
cp tests/test_helpers.sql tests/eql_tests/migrations/002_install_test_helpers.sql
```

**Step 4: Verify migration files exist**

```bash
ls -lh tests/eql_tests/migrations/
```

Expected:
- `001_install_eql.sql` (~50KB+)
- `002_install_test_helpers.sql` (~20KB+)

**Step 5: Add note about SQLx migration behavior**

Create `tests/eql_tests/migrations/README.md`:

```markdown
# SQLx Migrations

These migrations install EQL and test helpers into the test database.

**Important**: SQLx tracks migration state. When using `#[sqlx::test]`:
- Each test gets a fresh database
- Migrations run automatically before each test
- No need to manually reset database between tests

To regenerate migrations:
```bash
mise run build
cp release/cipherstash-encrypt.sql tests/eql_tests/migrations/001_install_eql.sql
cp tests/test_helpers.sql tests/eql_tests/migrations/002_install_test_helpers.sql
```
```

**Step 6: Commit migrations**

```bash
git add tests/eql_tests/migrations/
git commit -m "feat: add EQL and test helper migrations for tests"
```

---

## Task 6: Write First JSONB Test (jsonb_array_elements)

**Files:**
- Create: `tests/eql_tests/tests/jsonb_tests.rs`

**Step 1: Create test file with module setup**

```rust
//! JSONB function tests
//!
//! Converted from src/jsonb/functions_test.sql
//! Tests EQL JSONB path query functions with encrypted data

use eql_tests::{QueryAssertion, Selectors};
use sqlx::PgPool;
```

**Step 2: Write first test - jsonb_array_elements returns elements**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_returns_array_elements(pool: PgPool) {
    // Test: jsonb_array_elements returns array elements from jsonb_path_query result
    // Original SQL line 19-21 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;
}
```

**Step 3: Run test to verify it works**

```bash
cd tests/eql_tests
cargo test jsonb_array_elements_returns_array_elements -- --nocapture
```

Expected: Test passes

**Step 4: Add second assertion to same test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_returns_array_elements(pool: PgPool) {
    // ... existing assertion ...

    // Also verify count
    QueryAssertion::new(&pool, &sql)
        .count(5)
        .await;
}
```

**Step 5: Run test again**

```bash
cargo test jsonb_array_elements_returns_array_elements -- --nocapture
```

Expected: Test passes with both assertions

**Step 6: Commit first test**

```bash
git add tests/eql_tests/tests/jsonb_tests.rs
git commit -m "feat: add first JSONB test (jsonb_array_elements)"
```

---

## Task 7: Add Exception Test (jsonb_array_elements)

**Files:**
- Modify: `tests/eql_tests/tests/jsonb_tests.rs`

**Step 1: Add test for exception case**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_throws_exception_for_non_array(pool: PgPool) {
    // Test: jsonb_array_elements throws exception if input is not an array
    // Original SQL line 28-30 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql)
        .throws_exception()
        .await;
}
```

**Step 2: Run test**

```bash
cargo test jsonb_array_elements_throws_exception_for_non_array -- --nocapture
```

Expected: Test passes

**Step 3: Commit exception test**

```bash
git add tests/eql_tests/tests/jsonb_tests.rs
git commit -m "test: add jsonb_array_elements exception test"
```

---

## Task 8: Add jsonb_array_elements_text Tests

**Files:**
- Modify: `tests/eql_tests/tests/jsonb_tests.rs`

**Step 1: Add test for jsonb_array_elements_text**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_text_returns_array_elements(pool: PgPool) {
    // Test: jsonb_array_elements_text returns array elements as text
    // Original SQL line 83-90 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(5)
        .await;
}
```

**Step 2: Add exception test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_text_throws_exception_for_non_array(pool: PgPool) {
    // Original SQL line 92-94

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql)
        .throws_exception()
        .await;
}
```

**Step 3: Run tests**

```bash
cargo test jsonb_array_elements_text -- --nocapture
```

Expected: Both tests pass

**Step 4: Commit**

```bash
git add tests/eql_tests/tests/jsonb_tests.rs
git commit -m "test: add jsonb_array_elements_text tests"
```

---

## Task 9: Add jsonb_array_length Tests

**Files:**
- Modify: `tests/eql_tests/tests/jsonb_tests.rs`

**Step 1: Add test for jsonb_array_length**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_length_returns_array_length(pool: PgPool) {
    // Test: jsonb_array_length returns correct array length
    // Original SQL line 114-117 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql)
        .returns_value("5")
        .await;
}
```

**Step 2: Add exception test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_length_throws_exception_for_non_array(pool: PgPool) {
    // Original SQL line 119-121

    let sql = format!(
        "SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql)
        .throws_exception()
        .await;
}
```

**Step 3: Run tests**

```bash
cargo test jsonb_array_length -- --nocapture
```

Expected: Both tests pass

**Step 4: Commit**

```bash
git add tests/eql_tests/tests/jsonb_tests.rs
git commit -m "test: add jsonb_array_length tests"
```

---

## Task 10: Add jsonb_path_query Tests

**Files:**
- Modify: `tests/eql_tests/tests/jsonb_tests.rs`

**Step 1: Add basic jsonb_path_query test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_finds_selector(pool: PgPool) {
    // Test: jsonb_path_query finds records by selector
    // Original SQL line 182-189 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;
}
```

**Step 2: Add count test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_returns_correct_count(pool: PgPool) {
    // Original SQL line 186-189

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .count(3)
        .await;
}
```

**Step 3: Run tests**

```bash
cargo test jsonb_path_query -- --nocapture
```

Expected: Both tests pass

**Step 4: Commit**

```bash
git add tests/eql_tests/tests/jsonb_tests.rs
git commit -m "test: add jsonb_path_query tests"
```

---

## Task 11: Add jsonb_path_exists Tests

**Files:**
- Modify: `tests/eql_tests/tests/jsonb_tests.rs`

**Step 1: Add test for path exists true**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_true_for_existing_path(pool: PgPool) {
    // Test: jsonb_path_exists returns true for existing path
    // Original SQL line 231-234 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .returns_value("true")
        .await;
}
```

**Step 2: Add test for path exists false**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_false_for_nonexistent_path(pool: PgPool) {
    // Original SQL line 236-239

    let sql = "SELECT eql_v2.jsonb_path_exists(e, 'blahvtha') FROM encrypted LIMIT 1";

    QueryAssertion::new(&pool, sql)
        .returns_value("false")
        .await;
}
```

**Step 3: Add count test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_correct_count(pool: PgPool) {
    // Original SQL line 241-244

    let sql = format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') FROM encrypted",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .count(3)
        .await;
}
```

**Step 4: Run tests**

```bash
cargo test jsonb_path_exists -- --nocapture
```

Expected: All three tests pass

**Step 5: Commit**

```bash
git add tests/eql_tests/tests/jsonb_tests.rs
git commit -m "test: add jsonb_path_exists tests"
```

---

## Task 12: Write First Equality Test

**Files:**
- Create: `tests/eql_tests/tests/equality_tests.rs`

**Step 1: Create equality test file with module setup**

```rust
//! Equality operator tests
//!
//! Converted from src/operators/=_test.sql
//! Tests EQL equality operators with encrypted data (HMAC and Blake3 indexes)

use eql_tests::{QueryAssertion, Selectors};
use sqlx::PgPool;
```

**Step 2: Add helper to create encrypted JSON with specific index**

**IMPORTANT**: The SQL function `create_encrypted_json(id integer, VARIADIC indexes text[])` exists in test_helpers.sql (line 337-355). It filters the encrypted JSON to only include specified index fields.

```rust
/// Helper to execute create_encrypted_json SQL function with specific indexes
/// Uses variadic form: create_encrypted_json(id, index1, index2, ...)
async fn create_encrypted_json_with_index(pool: &PgPool, id: i32, index_type: &str) -> String {
    let sql = format!(
        "SELECT create_encrypted_json({}, '{}')::text",
        id, index_type
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .expect("Failed to create encrypted JSON");

    row.try_get(0).expect("Failed to get result")
}
```

**Step 3: Write first equality test (HMAC index)**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_hmac(pool: PgPool) {
    // Test: eql_v2_encrypted = eql_v2_encrypted with HMAC index
    // Original SQL line 10-32 in src/operators/=_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;
}
```

**Step 4: Run test**

```bash
cd tests/eql_tests
cargo test equality_operator_finds_matching_record_hmac -- --nocapture
```

Expected: Test passes

**Step 5: Commit first equality test**

```bash
git add tests/eql_tests/tests/equality_tests.rs
git commit -m "feat: add first equality operator test (HMAC index)"
```

---

## Task 13: Add No Match Equality Test

**Files:**
- Modify: `tests/eql_tests/tests/equality_tests.rs`

**Step 1: Add test for no matching record**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_returns_empty_for_no_match_hmac(pool: PgPool) {
    // Test: equality returns no results for non-existent record
    // Original SQL line 25-29 in src/operators/=_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 91347, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .count(0)
        .await;
}
```

**Step 2: Run test**

```bash
cargo test equality_operator_returns_empty_for_no_match_hmac -- --nocapture
```

Expected: Test passes

**Step 3: Commit**

```bash
git add tests/eql_tests/tests/equality_tests.rs
git commit -m "test: add equality operator no-match test (HMAC)"
```

---

## Task 14: Add Blake3 Equality Tests

**Files:**
- Modify: `tests/eql_tests/tests/equality_tests.rs`

**Step 1: Add Blake3 match test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_blake3(pool: PgPool) {
    // Test: eql_v2_encrypted = eql_v2_encrypted with Blake3 index
    // Original SQL line 105-127 in src/operators/=_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "b3").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;
}
```

**Step 2: Add Blake3 no-match test**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_returns_empty_for_no_match_blake3(pool: PgPool) {
    // Original SQL line 120-124

    let encrypted = create_encrypted_json_with_index(&pool, 91347, "b3").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .count(0)
        .await;
}
```

**Step 3: Run tests**

```bash
cargo test equality_operator.*blake3 -- --nocapture
```

Expected: Both tests pass

**Step 4: Commit**

```bash
git add tests/eql_tests/tests/equality_tests.rs
git commit -m "test: add Blake3 equality operator tests"
```

---

## Task 15: Add eq() Function Tests

**Files:**
- Modify: `tests/eql_tests/tests/equality_tests.rs`

**Step 1: Add eq() function test (HMAC)**

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_finds_matching_record_hmac(pool: PgPool) {
    // Test: eql_v2.eq() function with HMAC index
    // Original SQL line 38-59 in src/operators/=_test.sql

    let mut encrypted = create_encrypted_json_with_index(&pool, 1, "").await;
    // Remove 'ob' field to simulate jsonb-'ob' operation
    let encrypted_json: serde_json::Value = serde_json::from_str(&encrypted).unwrap();
    let mut obj = encrypted_json.as_object().unwrap().clone();
    obj.remove("ob");
    encrypted = serde_json::to_string(&obj).unwrap();

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;
}
```

**Step 2: Run test**

```bash
cargo test eq_function_finds_matching_record_hmac -- --nocapture
```

Expected: Test passes

**Step 3: Commit**

```bash
git add tests/eql_tests/tests/equality_tests.rs
git commit -m "test: add eq() function test (HMAC)"
```

---

## Task 16: Add Documentation and README

**Files:**
- Create: `tests/eql_tests/README.md`

**Step 1: Create README**

```markdown
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
- **Migrations**: `migrations/001_install_eql.sql` installs EQL extension
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

### Selectors

See `src/selectors.rs` for all selector constants:
- `Selectors::ROOT`: $ (root object)
- `Selectors::N`: $.n path
- `Selectors::HELLO`: $.hello path
- `Selectors::ARRAY_ELEMENTS`: $.a[*] (array elements)
- `Selectors::ARRAY_ROOT`: $.a (array root)

## Writing Tests

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
- Run individual tests: `cargo test test_name`
- No magic literals: `Selectors::ARRAY_ELEMENTS`
- Self-documenting: Test name describes behavior
- Less verbose: No DO $$ boilerplate
- Better errors: Rust panic messages show exact assertion failure

## Future Work

- Fixture generator tool (see docs/plans/fixture-generator.md)
- Convert remaining SQL tests
- Add property-based tests for encryption round-trips
```

**Step 2: Commit README**

```bash
git add tests/eql_tests/README.md
git commit -m "docs: add comprehensive README for test framework"
```

---

## Task 17: Run Full Test Suite

**Files:**
- None (verification step)

**Step 1: Run all tests**

```bash
cd tests/eql_tests
cargo test
```

Expected: All tests pass

**Step 2: Verify test count**

```bash
cargo test 2>&1 | grep "test result:"
```

Expected: Should show ~15 tests passing

**Step 3: Test parallel execution**

```bash
cargo test -- --test-threads=4
```

Expected: Tests run in parallel, all pass

**Step 4: Document results**

Create a summary of test conversion:

```
JSONB Tests Converted:
- jsonb_array_elements (2 tests)
- jsonb_array_elements_text (2 tests)
- jsonb_array_length (2 tests)
- jsonb_path_query (2 tests)
- jsonb_path_exists (3 tests)

Equality Tests Converted:
- HMAC equality operator (2 tests)
- Blake3 equality operator (2 tests)
- eq() function (1 test)

Total: 16 tests converted from SQL to Rust
```

---

## Task 18: Update Root Cargo Workspace

**Files:**
- Create or Modify: `Cargo.toml` (root)

**Step 1: Check if root Cargo.toml exists**

```bash
cd /Users/tobyhede/src/encrypt-query-language
ls -la Cargo.toml
```

**Step 2a: If Cargo.toml does NOT exist, create workspace**

```bash
cat > Cargo.toml << 'EOF'
[workspace]
members = [
    "tests/eql_tests",
]

resolver = "2"
EOF
```

**Step 2b: If Cargo.toml EXISTS, add eql_tests to members**

```bash
# Check current contents
cat Cargo.toml
```

If it's a workspace, add `"tests/eql_tests"` to the members array.
If it's a package, convert to workspace:

```toml
[workspace]
members = [
    "tests/eql_tests",
    # ... any existing crates
]

resolver = "2"
```

**Step 3: Verify workspace configuration**

```bash
cargo metadata --format-version 1 | jq '.workspace_members'
```

Expected: Should show `eql_tests` in the list

**Step 4: Test workspace**

```bash
cargo test --workspace
```

Expected: Runs tests from eql_tests crate

**Step 5: Commit workspace update**

```bash
git add Cargo.toml
git commit -m "chore: add eql_tests to Cargo workspace"
```

---

## Task 19: Add mise Task for Rust Tests (Optional)

**Files:**
- Modify: `mise.toml` or create `tasks/rust.toml`

**Step 1: Add Rust test task to mise**

Create `tasks/rust.toml`:

```toml
["test:rust"]
description = "Run Rust test framework"
dir = "{{config_root}}/tests/eql_tests"
run = """
# Ensure database is running
mise run postgres:up --extra-args "--detach --wait"

# Run tests
cargo test {{arg(name="filter",default="")}} {{option(name="extra-args",default="")}}
"""

["test:rust:watch"]
description = "Run Rust tests in watch mode"
dir = "{{config_root}}/tests/eql_tests"
run = """
cargo watch -x test
"""
```

**Step 2: Update mise.toml to include rust tasks**

Edit `mise.toml`:

```toml
[task_config]
includes = ["tasks", "tasks/postgres.toml", "tasks/rust.toml"]
```

**Step 3: Test new mise tasks**

```bash
# Run all Rust tests
mise run test:rust

# Run specific test
mise run test:rust -- jsonb_array_elements

# Run with cargo flags
mise run test:rust --extra-args "-- --nocapture"
```

**Step 4: Commit mise integration**

```bash
git add tasks/rust.toml mise.toml
git commit -m "feat: add mise tasks for Rust test framework"
```

---

## Task 20: Update CI Configuration (Future)

**Files:**
- Note: Identify CI config file location

**Step 1: Find CI configuration**

```bash
find . -name ".github" -o -name ".gitlab-ci.yml" -o -name "ci.yml"
```

**Step 2: Document CI changes needed**

Create note for future CI integration:

```markdown
# CI Integration TODO

Add to CI pipeline:

```yaml
- name: Run Rust tests
  run: |
    # Use mise to manage database
    mise run postgres:up --extra-args "--detach --wait"
    mise run build
    mise run eql:install
    psql postgresql://cipherstash:password@localhost:7432/cipherstash -f tests/test_helpers.sql

    # Run Rust tests
    mise run test:rust
```

Requires:
- mise installed in CI environment
- Docker available for PostgreSQL
- DATABASE_URL set (handled by mise.toml)
```

**Step 3: Commit documentation**

```bash
git add docs/plans/ci-integration-notes.md
git commit -m "docs: add CI integration notes for Rust tests with mise"
```

---

## Summary

### Completed POC Deliverables

1. ✅ New `tests/eql_tests` Rust test crate
2. ✅ SQLx-based test framework with `#[sqlx::test]` macro
3. ✅ Fluent assertion builder (`QueryAssertion`)
4. ✅ Selector constants (eliminate magic literals) with verification
5. ✅ SQL fixtures with documentation
6. ✅ 16 tests converted from SQL to Rust:
   - 11 JSONB function tests
   - 5 equality operator tests
7. ✅ Comprehensive README
8. ✅ Test isolation (each test gets fresh database)
9. ✅ Parallel test execution support
10. ✅ mise integration for database management
11. ✅ Verified test helper SQL functions available

### Key Improvements Demonstrated

**Granularity**: Run individual tests
```bash
cargo test jsonb_array_elements_returns_array_elements
```

**No Magic Literals**: Self-documenting selectors
```rust
Selectors::ARRAY_ELEMENTS  // vs 'f510853730e1c3dbd31b86963f029dd5'
```

**Less Verbose**: Compare 30+ line SQL test to 10-line Rust test

**Better Errors**: Rust panic messages show exact failure point

### Next Steps

1. **Convert remaining tests**: src/jsonb/functions_test.sql has more test cases
2. **Fixture generator**: Tool to create fixtures from CipherStash client (see research)
3. **Property-based tests**: Use proptest for encryption round-trip properties
4. **CI integration**: Add Rust tests to CI pipeline

### Files Created

```
tests/eql_tests/
├── Cargo.toml
├── README.md
├── .env
├── src/
│   ├── lib.rs
│   ├── assertions.rs
│   └── selectors.rs
├── migrations/
│   └── 001_install_eql.sql
├── fixtures/
│   ├── encrypted_json.sql
│   └── array_data.sql
└── tests/
    ├── jsonb_tests.rs
    └── equality_tests.rs
```
