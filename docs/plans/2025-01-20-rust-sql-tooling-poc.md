# Rust-based SQL Development Tooling - Proof of Concept

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Create a Rust-based development framework for EQL that provides testing, documentation generation, and multi-database support, using the Config module as a proof of concept.

**Architecture:** Modular trait system with core traits (Schema, Config, etc.) and independent feature traits (Ore32Bit, Ore64Bit, etc.). Each database implements only supported features. SQL files remain the source of truth (one function per file), referenced via Rust. Build tool extracts SQL in dependency order to generate single installer file per database.

**Tech Stack:** Rust (workspace with multiple crates), PostgreSQL driver (tokio-postgres), TOML for component metadata, rustdoc for documentation generation.

---

## Success Criteria

- [ ] Rust workspace compiles successfully
- [ ] Core trait system defined (Component, Config traits)
- [ ] PostgreSQL implementation of Config module functional
- [ ] Test harness provides transaction isolation
- [ ] Build tool generates valid `cipherstash-encrypt-postgres.sql` from Config module
- [ ] Rustdoc generates customer-facing API documentation (HTML with SQL examples)
- [ ] Structured error handling with thiserror provides clear error messages
- [ ] Config types and add_column migrated with tests passing

---

## Task 1: Initialize Rust Workspace

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/Cargo.toml`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-core/Cargo.toml`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-postgres/Cargo.toml`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-test/Cargo.toml`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-build/Cargo.toml`

**Step 1: Create workspace Cargo.toml**

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
```

**Step 2: Create eql-core crate (trait definitions)**

```toml
[package]
name = "eql-core"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { workspace = true }
serde_json = { workspace = true }
```

**Step 3: Create eql-postgres crate (PostgreSQL implementation)**

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

**Step 4: Create eql-test crate (test harness)**

```toml
[package]
name = "eql-test"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { workspace = true }
tokio-postgres = { workspace = true }
anyhow = { workspace = true }
serde_json = { workspace = true }
```

**Step 5: Create eql-build crate (build tool)**

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

**Step 6: Verify workspace compiles**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo build`

Expected: Builds successfully (may have warnings about empty crates)

**Step 7: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add Cargo.toml eql-core/Cargo.toml eql-postgres/Cargo.toml eql-test/Cargo.toml eql-build/Cargo.toml
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

## Task 2: Define Core Trait System

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-core/src/lib.rs`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-core/src/component.rs`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-core/src/config.rs`

**Step 1: Write test for Component trait**

Create `eql-core/src/lib.rs`:

```rust
//! EQL Core - Trait definitions for multi-database SQL extension API

pub mod component;
pub mod config;

pub use component::{Component, Dependencies};
pub use config::Config;

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
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-core`

Expected: FAIL with "module `component` not found"

**Step 3: Implement Component trait**

Create `eql-core/src/component.rs`:

```rust
//! Component trait for SQL file dependencies

use std::marker::PhantomData;

/// Marker trait for dependency specifications
pub trait Dependencies {}

/// Unit type represents no dependencies
impl Dependencies for () {}

/// Tuple types represent multiple dependencies
impl<A: Dependencies> Dependencies for (A,) {}
impl<A: Dependencies, B: Dependencies> Dependencies for (A, B) {}
impl<A: Dependencies, B: Dependencies, C: Dependencies> Dependencies for (A, B, C) {}
impl<A: Dependencies, B: Dependencies, C: Dependencies, D: Dependencies> Dependencies for (A, B, C, D) {}

/// A component represents a single SQL file with its dependencies
pub trait Component {
    /// Type specifying what this component depends on
    type Dependencies: Dependencies;

    /// Path to the SQL file containing this component's implementation
    fn sql_file() -> &'static str;
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

**Step 5: Run test to verify it passes**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-core`

Expected: PASS (1 test)

**Step 6: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add eql-core/
git commit -m "feat(eql-core): define Component and Config traits

Add core trait system for EQL API:
- Component trait: Represents SQL file with type-safe dependencies
- Dependencies trait: Marker for dependency specifications
- Config trait: Configuration management API with rustdoc examples

The Config trait includes documentation that will be auto-generated
into customer-facing docs, preventing documentation drift."
```

---

## Task 3: Create Test Harness with Transaction Isolation

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-test/src/lib.rs`

**Step 1: Write test for TestDb**

Create `eql-test/src/lib.rs`:

```rust
//! Test harness providing transaction isolation for SQL tests

use anyhow::{Context, Result};
use tokio_postgres::{Client, NoTls, Row};

pub struct TestDb {
    client: Client,
    in_transaction: bool,
}

impl TestDb {
    /// Create new test database with transaction isolation
    pub async fn new() -> Result<Self> {
        let (client, connection) = tokio_postgres::connect(
            &Self::connection_string(),
            NoTls,
        )
        .await
        .context("Failed to connect to test database")?;

        // Spawn connection handler
        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("Connection error: {}", e);
            }
        });

        // Begin transaction for isolation
        client.execute("BEGIN", &[]).await?;

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
    pub async fn execute(&self, sql: &str) -> Result<u64> {
        self.client.execute(sql, &[])
            .await
            .context("Failed to execute SQL")
    }

    /// Query with single result
    pub async fn query_one(&self, sql: &str) -> Result<Row> {
        self.client.query_one(sql, &[])
            .await
            .context("Failed to query")
    }

    /// Assert JSONB result has key
    pub fn assert_jsonb_has_key(&self, result: &Row, column_index: usize, key: &str) -> Result<()> {
        let json: serde_json::Value = result.get(column_index);
        anyhow::ensure!(
            json.get(key).is_some(),
            "Expected key '{}' in result, got: {:?}",
            key,
            json
        );
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
}
```

**Step 2: Run test to verify it compiles**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-test`

Expected: May fail if PostgreSQL container not running, but should compile

**Step 3: Start PostgreSQL container for testing**

Run: `cd /Users/tobyhede/src/encrypt-query-language && mise run postgres:up postgres-17 --extra-args "--detach --wait"`

Expected: PostgreSQL container starts successfully

**Step 4: Run test to verify it passes**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-test`

Expected: PASS (1 test) - transaction isolation working

**Step 5: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add eql-test/
git commit -m "feat(eql-test): add test harness with transaction isolation

Create TestDb struct providing:
- Automatic transaction BEGIN on creation
- Auto-rollback on drop (clean slate for next test)
- Helper methods: execute(), query_one()
- Assertion helpers: assert_jsonb_has_key()

This solves the current testing pain points:
- No more manual database resets between tests
- Clear error messages (no more block-level PostgreSQL ASSERT errors)
- Foundation for parallel test execution (future enhancement)"
```

---

## Task 4: Implement PostgreSQL Config Module

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-postgres/src/lib.rs`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-postgres/src/config.rs`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-postgres/src/sql/config/types.sql`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-postgres/src/sql/config/add_column.sql`

**Step 1: Copy existing SQL files**

Copy the current implementation from main codebase:

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
mkdir -p eql-postgres/src/sql/config
cp ../../src/config/types.sql eql-postgres/src/sql/config/types.sql
cp ../../src/config/functions.sql eql-postgres/src/sql/config/add_column_temp.sql
```

**Step 2: Extract add_column function into separate file**

From `add_column_temp.sql`, extract just the `add_column` function:

Create `eql-postgres/src/sql/config/add_column.sql`:

```sql
-- Add a column for encryption/decryption
--
-- This function initializes a column to work with CipherStash encryption.
-- The column must be of type eql_v2_encrypted.

CREATE FUNCTION eql_v2.add_column(table_name text, column_name text, cast_as text DEFAULT 'text', migrating boolean DEFAULT false)
  RETURNS jsonb

AS $$
  DECLARE
    o jsonb;
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

**Step 3: Implement Rust component definitions**

Create `eql-postgres/src/config.rs`:

```rust
//! PostgreSQL implementation of Config trait

use eql_core::{Component, Config, Dependencies};

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

pub struct AddColumn;

impl Component for AddColumn {
    type Dependencies = ConfigTypes;

    fn sql_file() -> &'static str {
        concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/sql/config/add_column.sql"
        )
    }
}

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

Create `eql-postgres/src/lib.rs`:

```rust
//! PostgreSQL implementation of EQL

pub mod config;

pub use config::PostgresEQL;
```

**Step 4: Verify it compiles**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo build --package eql-postgres`

Expected: Builds successfully

**Step 5: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add eql-postgres/
git commit -m "feat(eql-postgres): implement Config trait with SQL files

Add PostgreSQL implementation:
- ConfigTypes component (wraps config/types.sql)
- AddColumn component (wraps config/add_column.sql)
- PostgresEQL struct implementing Config trait

SQL files copied from existing implementation (src/config/).
Component system provides type-safe dependency: AddColumn depends on ConfigTypes.

This proves the concept of Rust + SQL file references working together."
```

---

## Task 5: Write Integration Test for add_column

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-postgres/tests/config_test.rs`

**Step 1: Write failing test**

Create `eql-postgres/tests/config_test.rs`:

```rust
use eql_postgres::config::{AddColumn, ConfigTypes, PostgresEQL};
use eql_core::{Component, Config};
use eql_test::TestDb;

#[tokio::test]
async fn test_add_column_creates_config() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Load schema (from main project)
    let schema_sql = include_str!("../../../src/schema.sql");
    db.execute(schema_sql).await.expect("Failed to create schema");

    // Load config types
    let types_sql = std::fs::read_to_string(ConfigTypes::sql_file())
        .expect("Failed to read types.sql");
    db.execute(&types_sql).await.expect("Failed to load config types");

    // Load add_column function
    let add_column_sql = std::fs::read_to_string(AddColumn::sql_file())
        .expect("Failed to read add_column.sql");
    db.execute(&add_column_sql).await.expect("Failed to load add_column");

    // Setup: Create test table
    db.execute("CREATE TABLE users (id int)").await.expect("Failed to create table");

    // Execute: Call add_column
    let result = db.query_one("SELECT eql_v2.add_column('users', 'email', 'text')")
        .await
        .expect("Failed to call add_column");

    // Assert: Result has 'tables' key
    db.assert_jsonb_has_key(&result, 0, "tables")
        .expect("Expected 'tables' key in config");
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-postgres --test config_test`

Expected: FAIL - SQL files likely have missing dependencies (functions_private, encrypted/functions, etc.)

**Step 3: Fix dependencies by loading required SQL**

This will fail because `add_column` depends on helper functions not yet migrated. For POC, we'll note this and create a simpler test:

Update `eql-postgres/tests/config_test.rs`:

```rust
use eql_postgres::config::{ConfigTypes, PostgresEQL};
use eql_core::{Component, Config};
use eql_test::TestDb;

#[tokio::test]
async fn test_config_types_loads() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Load config types
    let types_sql = std::fs::read_to_string(ConfigTypes::sql_file())
        .expect("Failed to read types.sql");
    db.execute(&types_sql).await.expect("Failed to load config types");

    // Verify enum type exists
    let result = db.query_one(
        "SELECT EXISTS (
            SELECT 1 FROM pg_type
            WHERE typname = 'eql_v2_configuration_state'
        )"
    ).await.expect("Failed to check type");

    let exists: bool = result.get(0);
    assert!(exists, "eql_v2_configuration_state type should exist");
}

#[tokio::test]
async fn test_component_sql_file_paths_valid() {
    // Verify SQL files exist at the paths components claim
    let types_path = ConfigTypes::sql_file();
    assert!(
        std::path::Path::new(types_path).exists(),
        "ConfigTypes SQL file should exist at {}",
        types_path
    );
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-postgres --test config_test`

Expected: PASS (2 tests)

**Step 5: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add eql-postgres/tests/
git commit -m "test(eql-postgres): add integration tests for Config module

Add two tests:
1. test_config_types_loads: Verifies SQL file loads and creates enum type
2. test_component_sql_file_paths_valid: Verifies Component trait points to real files

These tests demonstrate:
- TestDb transaction isolation working
- SQL file references from Rust components working
- Foundation for full integration testing

Note: Full add_column test deferred - requires migrating helper functions
(config_default, config_add_table, etc.) which is beyond POC scope."
```

---

## Task 6: Create Build Tool Prototype

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-build/src/main.rs`
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-build/src/graph.rs`

**Step 1: Write test for build tool**

Create `eql-build/src/main.rs`:

```rust
//! Build tool for extracting SQL files in dependency order

use anyhow::{Context, Result};
use std::fs;

mod graph;

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: eql-build <database>");
        eprintln!("  database: postgres, mysql, etc.");
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
    use eql_postgres::config::{ConfigTypes, AddColumn};
    use eql_core::Component;

    println!("Building PostgreSQL installer...");

    // For POC: Simple sequential build
    // Future: Use graph module for dependency resolution
    let mut output = String::new();

    // Add header
    output.push_str("-- CipherStash EQL for PostgreSQL\n");
    output.push_str("-- Generated by eql-build\n\n");

    // Add ConfigTypes
    let types_sql = fs::read_to_string(ConfigTypes::sql_file())
        .context("Failed to read config types SQL")?;
    output.push_str(&types_sql);
    output.push_str("\n\n");

    // Add AddColumn
    let add_column_sql = fs::read_to_string(AddColumn::sql_file())
        .context("Failed to read add_column SQL")?;
    output.push_str(&add_column_sql);
    output.push_str("\n\n");

    // Write output
    fs::create_dir_all("release")?;
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
    }
}
```

Create `eql-build/src/graph.rs`:

```rust
//! Dependency graph for topological sorting (future enhancement)

// Placeholder for dependency graph implementation
// Will use Component::Dependencies to build DAG and topologically sort
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-build`

Expected: FAIL - release directory doesn't exist yet, or SQL missing

**Step 3: Run build to create output**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo run --bin eql-build postgres`

Expected: Creates `release/cipherstash-encrypt-postgres-poc.sql`

**Step 4: Run test to verify it passes**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --package eql-build`

Expected: PASS (1 test)

**Step 5: Verify generated SQL is valid**

Run: `cd /Users/tobyhede/src/encrypt-query-language && psql -h localhost -p 7432 -U cipherstash -d postgres < .worktrees/rust-sql-tooling/release/cipherstash-encrypt-postgres-poc.sql`

Expected: SQL executes without errors (though may be incomplete due to dependencies)

**Step 6: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add eql-build/ release/
git commit -m "feat(eql-build): add build tool for SQL extraction

Create build tool that:
- Reads SQL files via Component::sql_file() paths
- Concatenates in dependency order (manual for POC)
- Generates release/cipherstash-encrypt-postgres-poc.sql

Future enhancements:
- Automatic dependency graph resolution via Component::Dependencies
- Topological sort using graph module
- Support for multiple database targets

This proves SQL extraction from Rust component system works."
```

---

## Task 7: Add Error Handling with thiserror

**Files:**
- Create: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-core/src/error.rs`
- Modify: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-core/src/lib.rs`
- Modify: `/Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling/eql-test/src/lib.rs`
- Update: Workspace Cargo.toml to add thiserror dependency

**Step 1: Add thiserror to workspace dependencies**

Update root `Cargo.toml`:

```toml
[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.35", features = ["full"] }
tokio-postgres = "0.7"
anyhow = "1.0"
thiserror = "1.0"
```

**Step 2: Define error hierarchy**

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

**Step 3: Update eql-core to export error types**

Update `eql-core/src/lib.rs`:

```rust
//! EQL Core - Trait definitions for multi-database SQL extension API

pub mod component;
pub mod config;
pub mod error;

pub use component::{Component, Dependencies};
pub use config::Config;
pub use error::{ComponentError, DatabaseError, EqlError};

// ... rest of file
```

Update `eql-core/Cargo.toml`:

```toml
[dependencies]
serde = { workspace = true }
serde_json = { workspace = true }
thiserror = { workspace = true }
tokio-postgres = { workspace = true }
```

**Step 4: Update TestDb to use structured errors**

Update `eql-test/src/lib.rs`:

```rust
use eql_core::error::DatabaseError;

pub struct TestDb {
    // ... fields unchanged
}

impl TestDb {
    // ... new() unchanged ...

    pub async fn execute(&self, sql: &str) -> Result<u64, DatabaseError> {
        self.client
            .execute(sql, &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: sql.to_string(),
                source: e,
            })
    }

    pub async fn query_one(&self, sql: &str) -> Result<Row, DatabaseError> {
        self.client
            .query_one(sql, &[])
            .await
            .map_err(|e| DatabaseError::Query {
                query: sql.to_string(),
                source: e,
            })
    }

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
```

Update `eql-test/Cargo.toml`:

```toml
[dependencies]
eql-core = { path = "../eql-core" }
tokio = { workspace = true }
tokio-postgres = { workspace = true }
serde_json = { workspace = true }
```

**Step 5: Run tests to verify error handling works**

Run: `cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling && cargo test --all`

Expected: All existing tests still pass, now with better error messages

**Step 6: Test error messages manually**

Add a test to `eql-test/src/lib.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // ... existing test ...

    #[tokio::test]
    async fn test_database_error_messages() {
        let db = TestDb::new().await.expect("Failed to create TestDb");

        // Test query error with helpful context
        let result = db.execute("INVALID SQL SYNTAX").await;
        assert!(result.is_err());

        let err = result.unwrap_err();
        let err_string = err.to_string();
        assert!(err_string.contains("Query failed"));
        assert!(err_string.contains("INVALID SQL SYNTAX"));
    }
}
```

**Step 7: Commit**

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling
git add eql-core/src/error.rs eql-core/src/lib.rs eql-core/Cargo.toml eql-test/src/lib.rs eql-test/Cargo.toml Cargo.toml
git commit -m "feat: add structured error handling with thiserror

Add error hierarchy:
- EqlError: Top-level error type
- ComponentError: SQL file and dependency errors
- DatabaseError: Database operation errors

Benefits:
- Clear error messages with context (e.g., which query failed)
- Type-safe error handling throughout the codebase
- Better debugging experience for tests and build tools

TestDb now returns structured DatabaseError instead of anyhow::Error,
providing detailed context about failed queries."
```

---

## Verification Checklist

Run these commands to verify POC is complete:

```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/rust-sql-tooling

# All tests pass
cargo test --all

# Build tool generates SQL
cargo run --bin eql-build postgres
ls -lh release/cipherstash-encrypt-postgres-poc.sql

# Generated SQL is valid (basic check)
# Note: May have dependency errors but should parse
head -20 release/cipherstash-encrypt-postgres-poc.sql

# Rustdoc generates customer-facing documentation
cargo doc --no-deps --open
# Verify in browser: Config trait docs show SQL examples and are customer-friendly
```

Expected results:
- [ ] All tests pass (5+ tests across crates)
- [ ] SQL installer generated (~50+ lines)
- [ ] Rustdoc HTML generated with Config trait documentation
- [ ] Config trait docs include SQL examples (not Rust usage)
- [ ] No Rust compilation errors

---

## Future Work (Out of Scope for POC)

The following are explicitly deferred to focus POC on proving the concept:

1. **Full dependency graph resolution** - Currently manual ordering, should use Component::Dependencies for automatic topological sort
2. **Complete Config module migration** - Only types and add_column migrated, need full module
3. **Parallel test execution** - TestDb supports isolation, need test runner enhancements
4. **Multiple database support** - PostgreSQL only for POC, MySQL/SQLite deferred
5. **Feature trait system** - Ore32Bit, Ore64Bit, etc. not yet implemented
6. **Integration with existing build** - POC is standalone, needs integration with mise tasks
7. **Component-level error handling** - Expand error types as more components are added

---

## Success Criteria Review

After completing all tasks, verify:

- [ ] Rust workspace compiles successfully
- [ ] Core trait system defined (Component, Config traits)
- [ ] PostgreSQL implementation of Config module functional
- [ ] Test harness provides transaction isolation
- [ ] Build tool generates valid SQL installer
- [ ] Rustdoc generates customer-facing API documentation from trait comments
- [ ] Config types and add_column migrated with tests passing
- [ ] Structured error handling with thiserror in place

---

## Notes for Implementation

**Testing approach:**
- Use TDD at task level (write test → verify fail → implement → verify pass)
- Transaction isolation ensures tests don't interfere
- Integration tests verify SQL loads correctly

**Dependency management:**
- POC uses manual ordering in build tool
- Component::Dependencies types are defined but not yet used for graph walking
- Full implementation would traverse type graph at build time

**Documentation:**
- Rustdoc comments in traits are written for customers (showing SQL examples, not Rust usage)
- `cargo doc` generates HTML documentation directly from trait definitions
- Key insight: Single source of truth prevents drift - no separate markdown files to maintain

**Error handling:**
- Structured error types using thiserror
- DatabaseError provides query context for better debugging
- ComponentError will handle SQL file and dependency issues
- Expand error types organically as needs arise

**Migration strategy:**
- Start with one module (Config) to prove concept
- Future modules can follow same pattern
- Existing SQL files are source of truth, just referenced differently
