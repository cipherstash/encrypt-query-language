# Rust-based SQL Development Tooling - Proof of Concept (v2)

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Create a Rust-based development framework for EQL that provides testing, documentation generation, and multi-database support, using the Config module as a proof of concept.

**Architecture:** Modular trait system with core traits (Schema, Config, etc.) and independent feature traits (Ore32Bit, Ore64Bit, etc.). Each database implements only supported features. SQL files remain the source of truth (one function per file), referenced via Rust. Build tool extracts SQL in dependency order using type-safe dependency graph.

**Tech Stack:** Rust (workspace with multiple crates), PostgreSQL driver (tokio-postgres), rustdoc for documentation generation, thiserror for structured errors.

**Working Directory:** All commands run from `.worktrees/rust-sql-tooling` unless otherwise specified.

---

## Success Criteria

- [ ] Rust workspace compiles successfully
- [ ] Core trait system defined (Component, Config, Dependencies traits)
- [ ] Structured error handling with thiserror from the start
- [ ] PostgreSQL implementation of Config module **fully functional** (add_column works end-to-end)
- [ ] Test harness provides transaction isolation
- [ ] Build tool uses automatic dependency resolution via Component::Dependencies
- [ ] Build tool generates valid `cipherstash-encrypt-postgres.sql` from Config module
- [ ] Rustdoc generates customer-facing API documentation (HTML with SQL examples)
- [ ] All Config functions migrated: types, add_column, and their dependencies
- [ ] Integration tests pass: add_column creates working configuration

---

## Task 1: Initialize Rust Workspace

**Working directory:** Start from main repo root, then move to worktree

**Files:**
- Create: `Cargo.toml` (workspace root)
- Create: `eql-core/Cargo.toml`
- Create: `eql-postgres/Cargo.toml`
- Create: `eql-test/Cargo.toml`
- Create: `eql-build/Cargo.toml`

**Step 1: Navigate to worktree**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
# All subsequent commands run from this directory
```

**Step 2: Create workspace Cargo.toml**

Create the root workspace configuration:

```toml
[workspace]
members = [
    "eql-core",
    "eql-postgres",
    "eql-test",
    "eql-build",
]

resolver = "2"

[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.35", features = ["full"] }
tokio-postgres = "0.7"
anyhow = "1.0"
thiserror = "1.0"
```

**Step 3: Create eql-core crate (trait definitions)**

```toml
[package]
name = "eql-core"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tokio-postgres = { workspace = true }
```

**Step 4: Create eql-postgres crate (PostgreSQL implementation)**

```toml
[package]
name = "eql-postgres"
version = "0.1.0"
edition = "2021"

[dependencies]
eql-core = { path = "../eql-core" }
serde = { workspace = true }
serde_json = { workspace = true }

[dev-dependencies]
eql-test = { path = "../eql-test" }
tokio = { workspace = true }
```

**Step 5: Create eql-test crate (test harness)**

```toml
[package]
name = "eql-test"
version = "0.1.0"
edition = "2021"

[dependencies]
eql-core = { path = "../eql-core" }
tokio = { workspace = true }
tokio-postgres = { workspace = true }
serde_json = { workspace = true }
```

**Step 6: Create eql-build crate (build tool)**

```toml
[package]
name = "eql-build"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "eql-build"
path = "src/main.rs"

[dependencies]
eql-core = { path = "../eql-core" }
eql-postgres = { path = "../eql-postgres" }
anyhow = { workspace = true }
```

**Step 7: Create directory structure**

```bash
mkdir -p eql-core/src
mkdir -p eql-postgres/src
mkdir -p eql-test/src
mkdir -p eql-build/src
```

**Step 8: Create minimal lib.rs files**

```bash
echo "// EQL Core" > eql-core/src/lib.rs
echo "// EQL PostgreSQL" > eql-postgres/src/lib.rs
echo "// EQL Test Harness" > eql-test/src/lib.rs
echo "// EQL Build Tool" > eql-build/src/main.rs
echo "fn main() {}" >> eql-build/src/main.rs
```

**Step 9: Verify workspace compiles**

```bash
cargo build
```

Expected: Builds successfully (warnings about empty crates are fine)

**Step 10: Commit**

```bash
git add Cargo.toml eql-*/Cargo.toml eql-*/src/
git commit -m "feat: initialize Rust workspace for EQL tooling

Create workspace with four crates:
- eql-core: Trait definitions for EQL API
- eql-postgres: PostgreSQL implementation
- eql-test: Test harness with transaction isolation
- eql-build: Build tool for SQL extraction

This is a proof of concept for Rust-based SQL development tooling
to improve testing, documentation, and multi-database support."
```

---

## Task 2: Define Error Handling with thiserror

**Files:**
- Create: `eql-core/src/error.rs`
- Modify: `eql-core/src/lib.rs`

**Why first:** Errors need to be designed upfront so subsequent tasks use them from the start (TDD principle).

**Step 1: Write test for error hierarchy**

Create `eql-core/src/lib.rs`:

```rust
//! EQL Core - Trait definitions for multi-database SQL extension API

pub mod error;

pub use error::{ComponentError, DatabaseError, EqlError};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_types_display() {
        let err = ComponentError::SqlFileNotFound {
            path: "test.sql".to_string(),
        };
        assert!(err.to_string().contains("SQL file not found"));
        assert!(err.to_string().contains("test.sql"));
    }

    #[test]
    fn test_database_error_context() {
        let err = DatabaseError::MissingJsonbKey {
            key: "tables".to_string(),
            actual: serde_json::json!({"wrong": "value"}),
        };
        let err_string = err.to_string();
        assert!(err_string.contains("tables"));
        assert!(err_string.contains("wrong"));
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cargo test --package eql-core
```

Expected: FAIL with "module `error` not found"

**Step 3: Implement error hierarchy**

Create `eql-core/src/error.rs`:

```rust
//! Error types for EQL operations

use thiserror::Error;

/// Top-level error type for all EQL operations
#[derive(Error, Debug)]
pub enum EqlError {
    #[error("Component error: {0}")]
    Component(#[from] ComponentError),

    #[error("Database error: {0}")]
    Database(#[from] DatabaseError),
}

/// Errors related to SQL components and dependencies
#[derive(Error, Debug)]
pub enum ComponentError {
    #[error("SQL file not found: {path}")]
    SqlFileNotFound { path: String },

    #[error("Dependency cycle detected: {cycle}")]
    DependencyCycle { cycle: String },

    #[error("IO error reading SQL file {path}: {source}")]
    IoError {
        path: String,
        #[source]
        source: std::io::Error,
    },

    #[error("Missing dependency: {component} requires {missing}")]
    MissingDependency {
        component: String,
        missing: String,
    },
}

/// Errors related to database operations
#[derive(Error, Debug)]
pub enum DatabaseError {
    #[error("Connection failed: {0}")]
    Connection(#[source] tokio_postgres::Error),

    #[error("Transaction failed: {0}")]
    Transaction(String),

    #[error("Query failed: {query}: {source}")]
    Query {
        query: String,
        #[source]
        source: tokio_postgres::Error,
    },

    #[error("Expected JSONB value to have key '{key}', got: {actual}")]
    MissingJsonbKey {
        key: String,
        actual: serde_json::Value,
    },
}
```

**Step 4: Run tests to verify they pass**

```bash
cargo test --package eql-core
```

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add eql-core/
git commit -m "feat(eql-core): add structured error handling with thiserror

Add error hierarchy:
- EqlError: Top-level error type
- ComponentError: SQL file and dependency errors
- DatabaseError: Database operation errors

Benefits:
- Clear error messages with context (e.g., which query failed)
- Type-safe error handling throughout the codebase
- Better debugging experience for tests and build tools

Errors defined first (before other code) to enable TDD."
```

---

## Task 3: Define Core Trait System

**Files:**
- Modify: `eql-core/src/lib.rs`
- Create: `eql-core/src/component.rs`
- Create: `eql-core/src/config.rs`

**Step 1: Write test for Component trait**

Update `eql-core/src/lib.rs`:

```rust
//! EQL Core - Trait definitions for multi-database SQL extension API

pub mod component;
pub mod config;
pub mod error;

pub use component::{Component, Dependencies};
pub use config::Config;
pub use error::{ComponentError, DatabaseError, EqlError};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_component_trait_compiles() {
        // This test verifies the trait definition compiles
        // Actual implementations will be in eql-postgres
        struct TestComponent;

        impl Component for TestComponent {
            type Dependencies = ();

            fn sql_file() -> &'static str {
                "test.sql"
            }
        }

        assert_eq!(TestComponent::sql_file(), "test.sql");
    }

    // ... existing error tests ...
}
```

**Step 2: Run test to verify it fails**

```bash
cargo test --package eql-core
```

Expected: FAIL with "module `component` not found"

**Step 3: Implement Component trait**

Create `eql-core/src/component.rs`:

```rust
//! Component trait for SQL file dependencies

use std::marker::PhantomData;

/// Marker trait for dependency specifications
pub trait Dependencies {
    /// Collect all dependency SQL files in dependency order (dependencies first)
    fn collect_sql_files(files: &mut Vec<&'static str>);
}

/// Unit type represents no dependencies
impl Dependencies for () {
    fn collect_sql_files(_files: &mut Vec<&'static str>) {
        // No dependencies
    }
}

/// Single dependency
impl<T: Component> Dependencies for T {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        // First collect transitive dependencies
        T::Dependencies::collect_sql_files(files);
        // Then add this dependency
        if !files.contains(&T::sql_file()) {
            files.push(T::sql_file());
        }
    }
}

/// Two dependencies
impl<A: Component, B: Component> Dependencies for (A, B) {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        A::Dependencies::collect_sql_files(files);
        if !files.contains(&A::sql_file()) {
            files.push(A::sql_file());
        }
        B::Dependencies::collect_sql_files(files);
        if !files.contains(&B::sql_file()) {
            files.push(B::sql_file());
        }
    }
}

/// Three dependencies
impl<A: Component, B: Component, C: Component> Dependencies for (A, B, C) {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        A::Dependencies::collect_sql_files(files);
        if !files.contains(&A::sql_file()) {
            files.push(A::sql_file());
        }
        B::Dependencies::collect_sql_files(files);
        if !files.contains(&B::sql_file()) {
            files.push(B::sql_file());
        }
        C::Dependencies::collect_sql_files(files);
        if !files.contains(&C::sql_file()) {
            files.push(C::sql_file());
        }
    }
}

/// Four dependencies
impl<A: Component, B: Component, C: Component, D: Component> Dependencies for (A, B, C, D) {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        A::Dependencies::collect_sql_files(files);
        if !files.contains(&A::sql_file()) {
            files.push(A::sql_file());
        }
        B::Dependencies::collect_sql_files(files);
        if !files.contains(&B::sql_file()) {
            files.push(B::sql_file());
        }
        C::Dependencies::collect_sql_files(files);
        if !files.contains(&C::sql_file()) {
            files.push(C::sql_file());
        }
        D::Dependencies::collect_sql_files(files);
        if !files.contains(&D::sql_file()) {
            files.push(D::sql_file());
        }
    }
}

/// A component represents a single SQL file with its dependencies
pub trait Component {
    /// Type specifying what this component depends on
    type Dependencies: Dependencies;

    /// Path to the SQL file containing this component's implementation
    fn sql_file() -> &'static str;

    /// Collect this component and all its dependencies in load order
    fn collect_dependencies() -> Vec<&'static str> {
        let mut files = Vec::new();
        // First collect all transitive dependencies
        Self::Dependencies::collect_sql_files(&mut files);
        // Then add self
        if !files.contains(&Self::sql_file()) {
            files.push(Self::sql_file());
        }
        files
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct A;
    impl Component for A {
        type Dependencies = ();
        fn sql_file() -> &'static str { "a.sql" }
    }

    struct B;
    impl Component for B {
        type Dependencies = A;
        fn sql_file() -> &'static str { "b.sql" }
    }

    struct C;
    impl Component for C {
        type Dependencies = (A, B);
        fn sql_file() -> &'static str { "c.sql" }
    }

    #[test]
    fn test_no_dependencies() {
        let deps = A::collect_dependencies();
        assert_eq!(deps, vec!["a.sql"]);
    }

    #[test]
    fn test_single_dependency() {
        let deps = B::collect_dependencies();
        assert_eq!(deps, vec!["a.sql", "b.sql"]);
    }

    #[test]
    fn test_multiple_dependencies() {
        let deps = C::collect_dependencies();
        assert_eq!(deps, vec!["a.sql", "b.sql", "c.sql"]);
    }

    #[test]
    fn test_deduplication() {
        // C depends on both A and B, but A should only appear once
        let deps = C::collect_dependencies();
        let a_count = deps.iter().filter(|&&f| f == "a.sql").count();
        assert_eq!(a_count, 1, "a.sql should only appear once");
    }
}
```

**Step 4: Implement Config trait**

Create `eql-core/src/config.rs`:

```rust
//! Configuration management trait

use crate::Component;

/// Configuration management functions for encrypted columns
pub trait Config {
    /// Add a column for encryption/decryption.
    ///
    /// Initializes a column to work with CipherStash encryption. The column
    /// must be of type `eql_v2_encrypted`.
    ///
    /// # Parameters
    ///
    /// - `table_name` - Name of the table containing the column
    /// - `column_name` - Name of the column to configure
    /// - `cast_as` - PostgreSQL type for decrypted data (default: 'text')
    /// - `migrating` - Whether this is part of a migration (default: false)
    ///
    /// # Returns
    ///
    /// JSONB containing the updated configuration.
    ///
    /// # Examples
    ///
    /// ```sql
    /// -- Configure a text column for encryption
    /// SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
    ///
    /// -- Configure a JSONB column
    /// SELECT eql_v2.add_column('users', 'encrypted_data', 'jsonb');
    /// ```
    fn add_column() -> &'static dyn Component;

    /// Remove column configuration completely.
    ///
    /// # Examples
    ///
    /// ```sql
    /// SELECT eql_v2.remove_column('users', 'encrypted_email');
    /// ```
    fn remove_column() -> &'static dyn Component;

    /// Add a searchable index to an encrypted column.
    ///
    /// # Supported index types
    ///
    /// - `unique` - Exact equality (uses hmac_256 or blake3)
    /// - `match` - Full-text search (uses bloom_filter)
    /// - `ore` - Range queries and ordering (uses ore_block_u64_8_256)
    /// - `ste_vec` - JSONB containment queries (uses structured encryption)
    ///
    /// # Examples
    ///
    /// ```sql
    /// SELECT eql_v2.add_search_config('users', 'encrypted_email', 'unique', 'text');
    /// SELECT eql_v2.add_search_config('docs', 'encrypted_content', 'match', 'text');
    /// ```
    fn add_search_config() -> &'static dyn Component;
}
```

**Step 5: Run tests to verify they pass**

```bash
cargo test --package eql-core
```

Expected: PASS (6 tests: 2 error tests + 1 component test + 4 dependency tests)

**Step 6: Commit**

```bash
git add eql-core/
git commit -m "feat(eql-core): define Component and Config traits

Add core trait system for EQL API:
- Component trait: Represents SQL file with type-safe dependencies
- Dependencies trait: Automatic dependency collection via type system
- Config trait: Configuration management API with rustdoc examples

Key innovation: Component::collect_dependencies() walks the type graph
at compile time to resolve SQL load order automatically.

The Config trait includes documentation that will be auto-generated
into customer-facing docs, preventing documentation drift."
```

---

## Task 4: Create Test Harness with Transaction Isolation

**Files:**
- Create: `eql-test/src/lib.rs`

**Step 1: Write test for TestDb**

Create `eql-test/src/lib.rs`:

```rust
//! Test harness providing transaction isolation for SQL tests

use eql_core::error::DatabaseError;
use tokio_postgres::{Client, NoTls, Row};

pub struct TestDb {
    client: Client,
    in_transaction: bool,
}

impl TestDb {
    /// Create new test database with transaction isolation
    pub async fn new() -> Result<Self, DatabaseError> {
        let (client, connection) = tokio_postgres::connect(
            &Self::connection_string(),
            NoTls,
        )
        .await
        .map_err(DatabaseError::Connection)?;

        // Spawn connection handler
        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("Connection error: {}", e);
            }
        });

        // Begin transaction for isolation
        client.execute("BEGIN", &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: "BEGIN".to_string(),
                source: e,
            })?;

        Ok(Self {
            client,
            in_transaction: true,
        })
    }

    fn connection_string() -> String {
        std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "host=localhost port=7432 user=cipherstash password=password dbname=postgres".to_string())
    }

    /// Execute SQL (for setup/implementation loading)
    pub async fn execute(&self, sql: &str) -> Result<u64, DatabaseError> {
        self.client.execute(sql, &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: sql.to_string(),
                source: e,
            })
    }

    /// Query with single result
    pub async fn query_one(&self, sql: &str) -> Result<Row, DatabaseError> {
        self.client.query_one(sql, &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: sql.to_string(),
                source: e,
            })
    }

    /// Assert JSONB result has key
    pub fn assert_jsonb_has_key(&self, result: &Row, column_index: usize, key: &str) -> Result<(), DatabaseError> {
        let json: serde_json::Value = result.get(column_index);
        if json.get(key).is_none() {
            return Err(DatabaseError::MissingJsonbKey {
                key: key.to_string(),
                actual: json,
            });
        }
        Ok(())
    }
}

impl Drop for TestDb {
    fn drop(&mut self) {
        if self.in_transaction {
            // Auto-rollback on drop
            // Note: Can't use async in Drop, but connection will rollback anyway
            // when client drops
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_testdb_transaction_isolation() {
        let db = TestDb::new().await.expect("Failed to create TestDb");

        // Create a temporary table
        db.execute("CREATE TEMPORARY TABLE test_table (id int, value text)")
            .await
            .expect("Failed to create table");

        // Insert data
        db.execute("INSERT INTO test_table VALUES (1, 'test')")
            .await
            .expect("Failed to insert");

        // Query data
        let row = db.query_one("SELECT value FROM test_table WHERE id = 1")
            .await
            .expect("Failed to query");

        let value: String = row.get(0);
        assert_eq!(value, "test");

        // Transaction will rollback on drop - table won't exist in next test
    }

    #[tokio::test]
    async fn test_database_error_includes_query() {
        let db = TestDb::new().await.expect("Failed to create TestDb");

        let result = db.execute("INVALID SQL SYNTAX").await;
        assert!(result.is_err());

        let err = result.unwrap_err();
        let err_string = err.to_string();
        assert!(err_string.contains("Query failed"));
        assert!(err_string.contains("INVALID SQL SYNTAX"));
    }
}
```

**Step 2: Run test to verify it compiles**

```bash
cargo test --package eql-test
```

Expected: May fail if PostgreSQL container not running, but should compile

**Step 3: Start PostgreSQL container for testing**

From main repo root:

```bash
cd /Users/tobyhede/src/encrypt-query-language
mise run postgres:up postgres-17 --extra-args "--detach --wait"
```

Expected: PostgreSQL container starts successfully on port 7432

**Step 4: Run test to verify it passes**

```bash
cd .worktrees/rust-sql-tooling
cargo test --package eql-test
```

Expected: PASS (2 tests) - transaction isolation working, error messages include query context

**Step 5: Commit**

```bash
git add eql-test/
git commit -m "feat(eql-test): add test harness with transaction isolation

Create TestDb struct providing:
- Automatic transaction BEGIN on creation
- Auto-rollback on drop (clean slate for next test)
- Helper methods: execute(), query_one()
- Assertion helpers: assert_jsonb_has_key()
- Structured DatabaseError with query context

This solves current testing pain points:
- No more manual database resets between tests
- Clear error messages (shows which query failed)
- Foundation for parallel test execution (future)"
```

---

## Task 5: Migrate Config SQL Dependencies

**Files:**
- Create: `eql-postgres/src/sql/config/types.sql`
- Create: `eql-postgres/src/sql/config/functions_private.sql`
- Create: `eql-postgres/src/sql/encrypted/check_encrypted.sql`
- Create: `eql-postgres/src/sql/encrypted/add_encrypted_constraint.sql`
- Create: `eql-postgres/src/sql/config/migrate_activate.sql`
- Create: `eql-postgres/src/sql/config/add_column.sql`

**Why this order:** We need all dependencies before we can test add_column working end-to-end.

**Step 1: Create directory structure**

```bash
mkdir -p eql-postgres/src/sql/config
mkdir -p eql-postgres/src/sql/encrypted
```

**Step 2: Copy config types**

Copy from main repo (go up two levels from worktree):

```bash
cp ../../src/config/types.sql eql-postgres/src/sql/config/types.sql
```

**Step 3: Copy config private functions**

```bash
cp ../../src/config/functions_private.sql eql-postgres/src/sql/config/functions_private.sql
```

**Step 4: Create minimal check_encrypted stub**

Create `eql-postgres/src/sql/encrypted/check_encrypted.sql`:

```sql
-- Stub for check_encrypted function (minimal implementation for POC)
-- Full implementation would validate encrypted data structure

CREATE FUNCTION eql_v2.check_encrypted(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
  -- For POC: Just check that it's a JSONB object
  RETURN jsonb_typeof(val) = 'object';
END;
$$ LANGUAGE plpgsql;
```

**Step 5: Extract add_encrypted_constraint function**

Create `eql-postgres/src/sql/encrypted/add_encrypted_constraint.sql`:

```sql
-- Add constraint to verify encrypted column structure
--
-- Depends on: check_encrypted function

CREATE FUNCTION eql_v2.add_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
BEGIN
  EXECUTE format(
    'ALTER TABLE %I ADD CONSTRAINT eql_v2_encrypted_check_%I CHECK (eql_v2.check_encrypted(%I))',
    table_name,
    column_name,
    column_name
  );
END;
$$ LANGUAGE plpgsql;
```

**Step 6: Extract migrate_config and activate_config**

Create `eql-postgres/src/sql/config/migrate_activate.sql`:

```sql
-- Configuration migration and activation functions
--
-- Depends on: config/types.sql (for eql_v2_configuration table)

-- Stub for ready_for_encryption (POC only)
CREATE FUNCTION eql_v2.ready_for_encryption()
  RETURNS boolean
AS $$
BEGIN
  -- POC: Always return true
  -- Real implementation would validate all configured columns exist
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Marks the currently pending configuration as encrypting
CREATE FUNCTION eql_v2.migrate_config()
  RETURNS boolean
AS $$
BEGIN
    IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'encrypting') THEN
      RAISE EXCEPTION 'An encryption is already in progress';
    END IF;

    IF NOT EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'pending') THEN
      RAISE EXCEPTION 'No pending configuration exists to encrypt';
    END IF;

    IF NOT eql_v2.ready_for_encryption() THEN
      RAISE EXCEPTION 'Some pending columns do not have an encrypted target';
    END IF;

    UPDATE public.eql_v2_configuration SET state = 'encrypting' WHERE state = 'pending';
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Activates the currently encrypting configuration
CREATE FUNCTION eql_v2.activate_config()
  RETURNS boolean
AS $$
BEGIN
    IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'encrypting') THEN
      UPDATE public.eql_v2_configuration SET state = 'inactive' WHERE state = 'active';
      UPDATE public.eql_v2_configuration SET state = 'active' WHERE state = 'encrypting';
      RETURN true;
    ELSE
      RAISE EXCEPTION 'No encrypting configuration exists to activate';
    END IF;
END;
$$ LANGUAGE plpgsql;
```

**Step 7: Extract add_column function**

Create `eql-postgres/src/sql/config/add_column.sql`:

```sql
-- Add a column for encryption/decryption
--
-- This function initializes a column to work with CipherStash encryption.
-- The column must be of type eql_v2_encrypted.
--
-- Depends on: config/types.sql, config/functions_private.sql,
--             config/migrate_activate.sql, encrypted/add_encrypted_constraint.sql

CREATE FUNCTION eql_v2.add_column(table_name text, column_name text, cast_as text DEFAULT 'text', migrating boolean DEFAULT false)
  RETURNS jsonb
AS $$
  DECLARE
    _config jsonb;
  BEGIN
    -- set the active config
    SELECT data INTO _config FROM public.eql_v2_configuration WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- set default config
    SELECT eql_v2.config_default(_config) INTO _config;

    -- if index exists
    IF _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'Config exists for column: % %', table_name, column_name;
    END IF;

    SELECT eql_v2.config_add_table(table_name, _config) INTO _config;

    SELECT eql_v2.config_add_column(table_name, column_name, _config) INTO _config;

    SELECT eql_v2.config_add_cast(table_name, column_name, cast_as, _config) INTO _config;

    --  create a new pending record if we don't have one
    INSERT INTO public.eql_v2_configuration (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO UPDATE
      SET data = _config;

    IF NOT migrating THEN
      PERFORM eql_v2.migrate_config();
      PERFORM eql_v2.activate_config();
    END IF;

    PERFORM eql_v2.add_encrypted_constraint(table_name, column_name);

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;
```

**Step 8: Verify SQL files exist**

```bash
ls -la eql-postgres/src/sql/config/
ls -la eql-postgres/src/sql/encrypted/
```

Expected: All 6 SQL files exist

**Step 9: Commit SQL files**

```bash
git add eql-postgres/src/sql/
git commit -m "feat(eql-postgres): migrate Config module SQL files

Add SQL implementations:
- config/types.sql: Configuration table and enum type
- config/functions_private.sql: Helper functions (config_default, etc.)
- config/migrate_activate.sql: Migration and activation functions
- config/add_column.sql: Main add_column function
- encrypted/check_encrypted.sql: Stub for encrypted data validation
- encrypted/add_encrypted_constraint.sql: Constraint helper

All dependencies for add_column now present. Next task will wire
these up via Rust Component trait with automatic dependency resolution."
```

---

## Task 6: Implement PostgreSQL Config Components

**Files:**
- Create: `eql-postgres/src/lib.rs`
- Create: `eql-postgres/src/config.rs`

**Step 1: Design component hierarchy**

We need components for each SQL file, with proper dependencies:
- `ConfigTypes` (no dependencies)
- `ConfigPrivateFunctions` (depends on ConfigTypes)
- `CheckEncrypted` (no dependencies)
- `AddEncryptedConstraint` (depends on CheckEncrypted)
- `MigrateActivate` (depends on ConfigTypes)
- `AddColumn` (depends on ConfigTypes, ConfigPrivateFunctions, AddEncryptedConstraint, MigrateActivate)

**Step 2: Write test for component dependencies**

Create `eql-postgres/src/lib.rs`:

```rust
//! PostgreSQL implementation of EQL

pub mod config;

pub use config::PostgresEQL;

#[cfg(test)]
mod tests {
    use super::*;
    use eql_core::{Component, Config};

    #[test]
    fn test_component_sql_files_exist() {
        let add_column = PostgresEQL::add_column();
        let path = add_column.sql_file();
        assert!(
            std::path::Path::new(path).exists(),
            "add_column SQL file should exist at {}",
            path
        );
    }

    #[test]
    fn test_add_column_dependencies_collected() {
        use config::AddColumn;

        let deps = AddColumn::collect_dependencies();

        // Should include all dependencies in order
        assert!(deps.len() > 1, "AddColumn should have dependencies");

        // Dependencies should come before AddColumn itself
        let add_column_path = AddColumn::sql_file();
        let add_column_pos = deps.iter().position(|&f| f == add_column_path);
        assert!(add_column_pos.is_some(), "Should include AddColumn itself");

        // Verify no duplicates
        let mut seen = std::collections::HashSet::new();
        for file in &deps {
            assert!(seen.insert(file), "Dependency {} appears twice", file);
        }
    }
}
```

**Step 3: Run test to verify it fails**

```bash
cargo test --package eql-postgres
```

Expected: FAIL - module `config` not found

**Step 4: Implement component definitions**

Create `eql-postgres/src/config.rs`:

```rust
//! PostgreSQL implementation of Config trait

use eql_core::{Component, Config, Dependencies};

// Base component: Configuration types
pub struct ConfigTypes;

impl Component for ConfigTypes {
    type Dependencies = ();

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/types.sql"
        )
    }
}

impl Dependencies for ConfigTypes {}

// Private helper functions
pub struct ConfigPrivateFunctions;

impl Component for ConfigPrivateFunctions {
    type Dependencies = ConfigTypes;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/functions_private.sql"
        )
    }
}

impl Dependencies for ConfigPrivateFunctions {}

// Encrypted data validation stub
pub struct CheckEncrypted;

impl Component for CheckEncrypted {
    type Dependencies = ();

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/encrypted/check_encrypted.sql"
        )
    }
}

impl Dependencies for CheckEncrypted {}

// Add encrypted constraint helper
pub struct AddEncryptedConstraint;

impl Component for AddEncryptedConstraint {
    type Dependencies = CheckEncrypted;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/encrypted/add_encrypted_constraint.sql"
        )
    }
}

impl Dependencies for AddEncryptedConstraint {}

// Migration and activation functions
pub struct MigrateActivate;

impl Component for MigrateActivate {
    type Dependencies = ConfigTypes;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/migrate_activate.sql"
        )
    }
}

impl Dependencies for MigrateActivate {}

// Main add_column function
pub struct AddColumn;

impl Component for AddColumn {
    type Dependencies = (
        ConfigTypes,
        ConfigPrivateFunctions,
        MigrateActivate,
        AddEncryptedConstraint,
    );

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/add_column.sql"
        )
    }
}

// PostgreSQL implementation of Config trait
pub struct PostgresEQL;

impl Config for PostgresEQL {
    fn add_column() -> &'static dyn Component {
        &AddColumn
    }

    fn remove_column() -> &'static dyn Component {
        todo!("Not implemented in POC")
    }

    fn add_search_config() -> &'static dyn Component {
        todo!("Not implemented in POC")
    }
}
```

**Step 5: Run tests to verify they pass**

```bash
cargo test --package eql-postgres
```

Expected: PASS (2 tests) - SQL files exist, dependencies collected correctly

**Step 6: Verify dependency order manually**

Add a debug test:

```rust
#[test]
fn test_print_dependency_order() {
    use config::AddColumn;

    let deps = AddColumn::collect_dependencies();
    println!("Dependency order for AddColumn:");
    for (i, file) in deps.iter().enumerate() {
        println!("  {}. {}", i + 1, file);
    }

    // Expected order:
    // 1. types.sql (no deps)
    // 2. functions_private.sql (depends on types)
    // 3. check_encrypted.sql (no deps)
    // 4. add_encrypted_constraint.sql (depends on check_encrypted)
    // 5. migrate_activate.sql (depends on types)
    // 6. add_column.sql (depends on all above)
}
```

```bash
cargo test --package eql-postgres test_print_dependency_order -- --nocapture
```

Expected: Prints dependency order, verify it makes sense

**Step 7: Commit**

```bash
git add eql-postgres/
git commit -m "feat(eql-postgres): implement Config components with dependencies

Add PostgreSQL component implementations:
- ConfigTypes: Configuration table/enum (no dependencies)
- ConfigPrivateFunctions: Helper functions (depends on ConfigTypes)
- CheckEncrypted: Validation stub (no dependencies)
- AddEncryptedConstraint: Constraint helper (depends on CheckEncrypted)
- MigrateActivate: Migration functions (depends on ConfigTypes)
- AddColumn: Main function (depends on all above)

Key achievement: Component::collect_dependencies() automatically
resolves load order via type-level dependency graph.

Tests verify:
- SQL files exist at expected paths
- Dependencies collected without duplicates
- Dependency order respects constraints"
```

---

## Task 7: Write Integration Test for add_column

**Files:**
- Create: `eql-postgres/tests/config_test.rs`

**Step 1: Write failing test**

Create `eql-postgres/tests/config_test.rs`:

```rust
use eql_postgres::config::{AddColumn, PostgresEQL};
use eql_core::{Component, Config};
use eql_test::TestDb;

#[tokio::test]
async fn test_add_column_creates_config() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Load schema (from main project - need eql_v2 schema + encrypted type)
    let schema_sql = include_str!("../../../src/schema.sql");
    db.execute(schema_sql).await.expect("Failed to create schema");

    // Create minimal encrypted type stub for POC
    db.execute(
        "CREATE TYPE eql_v2_encrypted AS (data jsonb);"
    ).await.expect("Failed to create encrypted type");

    // Load all dependencies in order
    let deps = AddColumn::collect_dependencies();
    for sql_file in deps {
        let sql = std::fs::read_to_string(sql_file)
            .unwrap_or_else(|e| panic!("Failed to read {}: {}", sql_file, e));
        db.execute(&sql)
            .await
            .unwrap_or_else(|e| panic!("Failed to load {}: {}", sql_file, e));
    }

    // Setup: Create test table with encrypted column
    db.execute(
        "CREATE TABLE users (
            id int,
            email eql_v2_encrypted
        )"
    ).await.expect("Failed to create table");

    // Execute: Call add_column
    let result = db.query_one(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    )
    .await
    .expect("Failed to call add_column");

    // Assert: Result has expected structure
    db.assert_jsonb_has_key(&result, 0, "tables")
        .expect("Expected 'tables' key in config");

    db.assert_jsonb_has_key(&result, 0, "v")
        .expect("Expected 'v' (version) key in config");

    // Assert: Configuration was stored
    let config_row = db.query_one(
        "SELECT data FROM public.eql_v2_configuration WHERE state = 'active'"
    )
    .await
    .expect("Should have active config");

    db.assert_jsonb_has_key(&config_row, 0, "tables")
        .expect("Stored config should have 'tables' key");

    // Assert: Constraint was added
    let constraint_exists = db.query_one(
        "SELECT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conname = 'eql_v2_encrypted_check_email'
        )"
    ).await.expect("Failed to check constraint");

    let exists: bool = constraint_exists.get(0);
    assert!(exists, "Encrypted constraint should exist");
}

#[tokio::test]
async fn test_add_column_rejects_duplicate() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Load schema and dependencies (same as above)
    let schema_sql = include_str!("../../../src/schema.sql");
    db.execute(schema_sql).await.expect("Failed to create schema");

    db.execute("CREATE TYPE eql_v2_encrypted AS (data jsonb);")
        .await.expect("Failed to create encrypted type");

    let deps = AddColumn::collect_dependencies();
    for sql_file in deps {
        let sql = std::fs::read_to_string(sql_file).unwrap();
        db.execute(&sql).await.unwrap();
    }

    db.execute("CREATE TABLE users (id int, email eql_v2_encrypted)")
        .await.expect("Failed to create table");

    // First call succeeds
    db.query_one("SELECT eql_v2.add_column('users', 'email', 'text')")
        .await
        .expect("First add_column should succeed");

    // Second call should fail
    let result = db.query_one("SELECT eql_v2.add_column('users', 'email', 'text')").await;
    assert!(result.is_err(), "Duplicate add_column should fail");

    let err = result.unwrap_err();
    let err_string = err.to_string();
    assert!(
        err_string.contains("Config exists for column"),
        "Error should mention column already exists: {}",
        err_string
    );
}
```

**Step 2: Run test to verify it fails**

```bash
cargo test --package eql-postgres --test config_test
```

Expected: Likely fails on schema loading or missing encrypted type

**Step 3: Check if schema.sql creates eql_v2 schema**

From main repo:

```bash
head -20 ../../src/schema.sql
```

If it doesn't create the schema, update the test to add:

```rust
db.execute("CREATE SCHEMA IF NOT EXISTS eql_v2;")
    .await.expect("Failed to create schema");
```

**Step 4: Run test until it passes**

Debug any SQL errors by examining the DatabaseError output.

```bash
cargo test --package eql-postgres --test config_test -- --nocapture
```

Expected: PASS (2 tests) - add_column works end-to-end, rejects duplicates

**Step 5: Commit**

```bash
git add eql-postgres/tests/
git commit -m "test(eql-postgres): add integration tests for add_column

Add comprehensive integration tests:
1. test_add_column_creates_config: Verifies complete workflow
   - Loads all dependencies via Component::collect_dependencies()
   - Calls add_column function
   - Validates JSONB config structure
   - Confirms config stored in database
   - Checks encrypted constraint was added

2. test_add_column_rejects_duplicate: Verifies error handling
   - Ensures duplicate column config raises exception
   - Validates error message includes helpful context

Key achievement: add_column function works end-to-end in POC.
All dependencies loaded automatically via type-safe dependency graph."
```

---

## Task 8: Create Build Tool with Dependency Resolution

**Files:**
- Create: `eql-build/src/main.rs`
- Create: `eql-build/src/builder.rs`

**Step 1: Write test for build tool**

Create `eql-build/src/main.rs`:

```rust
//! Build tool for extracting SQL files in dependency order

use anyhow::{Context, Result};
use std::fs;

mod builder;

use builder::Builder;

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: eql-build <database>");
        eprintln!("  database: postgres");
        std::process::exit(1);
    }

    let database = &args[1];

    match database.as_str() {
        "postgres" => build_postgres()?,
        _ => anyhow::bail!("Unknown database: {}", database),
    }

    Ok(())
}

fn build_postgres() -> Result<()> {
    use eql_postgres::config::AddColumn;
    use eql_core::Component;

    println!("Building PostgreSQL installer...");

    let mut builder = Builder::new("CipherStash EQL for PostgreSQL");

    // Use automatic dependency resolution
    let deps = AddColumn::collect_dependencies();
    println!("Resolved {} dependencies", deps.len());

    for (i, sql_file) in deps.iter().enumerate() {
        println!("  {}. {}", i + 1, sql_file.split('/').last().unwrap_or(sql_file));
        builder.add_sql_file(sql_file)?;
    }

    // Write output
    fs::create_dir_all("release")?;
    let output = builder.build();
    fs::write("release/cipherstash-encrypt-postgres-poc.sql", output)?;

    println!("✓ Generated release/cipherstash-encrypt-postgres-poc.sql");

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_build_creates_output_file() {
        // Clean up any previous output
        let _ = std::fs::remove_file("release/cipherstash-encrypt-postgres-poc.sql");

        // Run build
        build_postgres().expect("Build should succeed");

        // Verify output exists
        assert!(
            std::path::Path::new("release/cipherstash-encrypt-postgres-poc.sql").exists(),
            "Build should create output file"
        );

        // Verify it contains expected SQL
        let content = std::fs::read_to_string("release/cipherstash-encrypt-postgres-poc.sql")
            .expect("Should be able to read output");

        assert!(content.contains("eql_v2_configuration_state"), "Should contain config types");
        assert!(content.contains("CREATE FUNCTION eql_v2.add_column"), "Should contain add_column function");
        assert!(content.contains("CREATE FUNCTION eql_v2.config_default"), "Should contain helper functions");
    }

    #[test]
    fn test_build_dependency_order() {
        build_postgres().expect("Build should succeed");

        let content = std::fs::read_to_string("release/cipherstash-encrypt-postgres-poc.sql")
            .expect("Should be able to read output");

        // types.sql should come before functions_private.sql
        let types_pos = content.find("eql_v2_configuration_state")
            .expect("Should contain types");
        let private_pos = content.find("CREATE FUNCTION eql_v2.config_default")
            .expect("Should contain private functions");

        assert!(
            types_pos < private_pos,
            "Types should be defined before functions that use them"
        );

        // check_encrypted should come before add_encrypted_constraint
        let check_pos = content.find("CREATE FUNCTION eql_v2.check_encrypted")
            .expect("Should contain check_encrypted");
        let constraint_pos = content.find("CREATE FUNCTION eql_v2.add_encrypted_constraint")
            .expect("Should contain add_encrypted_constraint");

        assert!(
            check_pos < constraint_pos,
            "check_encrypted should be defined before add_encrypted_constraint"
        );
    }
}
```

**Step 2: Implement Builder**

Create `eql-build/src/builder.rs`:

```rust
//! SQL file builder with dependency management

use anyhow::{Context, Result};
use std::fs;

pub struct Builder {
    header: String,
    files: Vec<String>,
}

impl Builder {
    pub fn new(title: &str) -> Self {
        Self {
            header: format!("-- {}\n-- Generated by eql-build\n\n", title),
            files: Vec::new(),
        }
    }

    pub fn add_sql_file(&mut self, path: &str) -> Result<()> {
        let sql = fs::read_to_string(path)
            .with_context(|| format!("Failed to read SQL file: {}", path))?;

        // Remove REQUIRE comments (they're metadata for old build system)
        let cleaned = sql
            .lines()
            .filter(|line| !line.trim_start().starts_with("-- REQUIRE:"))
            .collect::<Vec<_>>()
            .join("\n");

        self.files.push(cleaned);
        Ok(())
    }

    pub fn build(self) -> String {
        let mut output = self.header;

        for (i, file) in self.files.iter().enumerate() {
            if i > 0 {
                output.push_str("\n\n");
            }
            output.push_str(file);
        }

        output
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_builder_basic() {
        let mut builder = Builder::new("Test");
        assert!(builder.build().contains("Test"));
        assert!(builder.build().contains("Generated by eql-build"));
    }
}
```

**Step 3: Run test to verify it fails**

```bash
cargo test --package eql-build
```

Expected: FAIL - release directory doesn't exist yet

**Step 4: Run build to create output**

```bash
cargo run --bin eql-build postgres
```

Expected: Creates `release/cipherstash-encrypt-postgres-poc.sql` with dependency-ordered SQL

**Step 5: Run tests to verify they pass**

```bash
cargo test --package eql-build
```

Expected: PASS (3 tests) - output created, dependencies in correct order

**Step 6: Verify generated SQL is valid**

From main repo:

```bash
cd /Users/tobyhede/src/encrypt-query-language
psql -h localhost -p 7432 -U cipherstash -d postgres -f .worktrees/rust-sql-tooling/release/cipherstash-encrypt-postgres-poc.sql
```

Expected: SQL executes successfully (may need to manually add schema first)

**Step 7: Commit**

```bash
cd .worktrees/rust-sql-tooling
git add eql-build/ release/
git commit -m "feat(eql-build): implement build tool with dependency resolution

Create build tool that:
- Uses Component::collect_dependencies() for automatic ordering
- Reads SQL files in dependency order
- Generates release/cipherstash-encrypt-postgres-poc.sql
- Removes REQUIRE comments (metadata from old system)

Key achievement: Build tool uses type-level dependency graph
to automatically resolve SQL load order. No manual topological
sort or configuration files needed.

Tests verify:
- Output file created
- Contains all expected SQL
- Dependencies in correct order (types before functions using them)"
```

---

## Task 9: Generate Customer-Facing Documentation

**Files:**
- Create: `.cargo/config.toml` (optional, for rustdoc settings)

**Step 1: Generate rustdoc HTML**

```bash
cargo doc --no-deps --open
```

Expected: Opens browser with generated documentation

**Step 2: Verify Config trait documentation**

In browser, navigate to:
- `eql_core` → `config` → `Config` trait

Verify:
- ✅ SQL examples are visible (not Rust code examples)
- ✅ Function descriptions are customer-friendly
- ✅ No implementation details leaked
- ✅ Examples show actual usage patterns

**Step 3: Add custom CSS (optional)**

Create `.cargo/config.toml`:

```toml
[doc]
# Additional rustdoc flags
rustdocflags = ["--html-in-header", "docs/doc-header.html"]
```

This is optional - only if you want custom styling.

**Step 4: Take screenshots for verification**

```bash
# Generate docs
cargo doc --no-deps

# Docs are in target/doc/eql_core/trait.Config.html
open target/doc/eql_core/trait.Config.html
```

Screenshot the Config trait documentation to confirm it looks good.

**Step 5: Commit (if config added)**

```bash
git add .cargo/config.toml  # Only if created
git commit -m "docs: configure rustdoc for customer-facing documentation

Rustdoc generates HTML documentation directly from trait definitions.
Config trait includes SQL examples (not Rust usage) to show customers
how to use the database functions.

Key benefit: Documentation lives in code, preventing drift.
No separate markdown files to maintain.

View docs: cargo doc --no-deps --open"
```

---

## Verification Checklist

Run these commands to verify POC is complete:

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling

# 1. All tests pass
cargo test --all

# 2. Build tool generates SQL
cargo run --bin eql-build postgres

# 3. Generated SQL is valid
wc -l release/cipherstash-encrypt-postgres-poc.sql  # Should be 100+ lines

# 4. Verify SQL loads successfully
cd /Users/tobyhede/src/encrypt-query-language
psql -h localhost -p 7432 -U cipherstash -d postgres <<EOF
DROP SCHEMA IF EXISTS eql_v2 CASCADE;
CREATE SCHEMA eql_v2;
DROP TYPE IF EXISTS eql_v2_encrypted CASCADE;
CREATE TYPE eql_v2_encrypted AS (data jsonb);
\i .worktrees/rust-sql-tooling/release/cipherstash-encrypt-postgres-poc.sql
-- Test add_column works
CREATE TABLE test_users (id int, email eql_v2_encrypted);
SELECT eql_v2.add_column('test_users', 'email', 'text');
SELECT * FROM eql_v2.config();
EOF

# 5. Rustdoc generates customer-facing documentation
cd .worktrees/rust-sql-tooling
cargo doc --no-deps --open
# Verify in browser: Config trait docs show SQL examples
```

**Expected results:**
- [ ] All tests pass (10+ tests across crates)
- [ ] SQL installer generated (100+ lines)
- [ ] Generated SQL loads without errors
- [ ] add_column function works end-to-end
- [ ] Configuration stored in database
- [ ] Rustdoc HTML generated with Config trait documentation
- [ ] Config trait docs include SQL examples (not Rust usage)
- [ ] No Rust compilation errors

---

## Success Criteria Review

After completing all tasks, verify:

- [x] Rust workspace compiles successfully
- [x] Core trait system defined (Component, Config, Dependencies traits)
- [x] Structured error handling with thiserror from the start
- [x] PostgreSQL implementation of Config module **fully functional** (add_column works)
- [x] Test harness provides transaction isolation
- [x] Build tool uses automatic dependency resolution via Component::Dependencies
- [x] Build tool generates valid `cipherstash-encrypt-postgres-poc.sql`
- [x] Rustdoc generates customer-facing API documentation
- [x] All Config functions migrated: types, add_column, and dependencies
- [x] Integration tests pass: add_column creates working configuration

---

## Future Work (Out of Scope for POC)

The following are explicitly deferred to focus POC on proving the concept:

1. **Complete Config module** - Only add_column implemented, need remove_column, add_search_config
2. **Full encrypted module** - Only stubbed check_encrypted, need full implementation
3. **Parallel test execution** - TestDb supports isolation, need test runner enhancements
4. **Multiple database support** - PostgreSQL only for POC, MySQL/SQLite deferred
5. **Feature trait system** - Ore32Bit, Ore64Bit, etc. not yet implemented
6. **Integration with existing build** - POC is standalone, needs integration with mise tasks
7. **Cycle detection in dependency graph** - Current impl assumes no cycles (valid for DAG)
8. **Remove REQUIRE comments from source** - Currently removed in build output only

---

## Notes for Implementation

**Testing approach:**
- Use TDD at task level (write test → verify fail → implement → verify pass)
- Transaction isolation ensures tests don't interfere
- Integration tests verify SQL loads correctly and functions work end-to-end

**Dependency management:**
- Component::Dependencies is **functional** - automatically resolves load order
- Type-level graph walking at compile time
- No runtime overhead, no configuration files
- Deduplication handled automatically

**Documentation:**
- Rustdoc comments in traits are written for customers (SQL examples, not Rust usage)
- `cargo doc` generates HTML documentation directly from trait definitions
- Key insight: Single source of truth prevents drift

**Error handling:**
- Structured error types using thiserror from the start
- DatabaseError provides query context for better debugging
- ComponentError handles SQL file and dependency issues
- Clear error messages throughout (no cryptic PostgreSQL block-level assertions)

**Migration strategy:**
- Config module proves the concept
- Future modules can follow same pattern
- SQL files remain source of truth, just referenced differently
- Incremental adoption possible (can coexist with current system)
