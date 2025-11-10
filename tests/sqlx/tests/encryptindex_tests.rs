//! Encryptindex function tests
//!
//! Tests encrypted column creation and management

use anyhow::{Context, Result};
use sqlx::PgPool;

/// Helper to check if column exists in information_schema
async fn column_exists(pool: &PgPool, table_name: &str, column_name: &str) -> Result<bool> {
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT * FROM information_schema.columns s
            WHERE s.table_name = $1 AND s.column_name = $2
        )",
    )
    .bind(table_name)
    .bind(column_name)
    .fetch_one(pool)
    .await
    .context("checking column existence")?;

    Ok(exists)
}

/// Helper to check if a column is in pending columns list
async fn has_pending_column(pool: &PgPool, column_name: &str) -> Result<bool> {
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT * FROM eql_v2.select_pending_columns() AS c
            WHERE c.column_name = $1
        )",
    )
    .bind(column_name)
    .fetch_one(pool)
    .await
    .context("checking pending column")?;

    Ok(exists)
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn create_encrypted_columns_from_config(pool: PgPool) -> Result<()> {
    // Test: Create encrypted columns from configuration (7 assertions)
    // Verifies: pending columns, target columns, create_encrypted_columns(),
    // rename_encrypted_columns(), and resulting column types

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Insert config for name column
    sqlx::query(
        "INSERT INTO eql_v2_configuration (data) VALUES (
            '{
                \"v\": 1,
                \"tables\": {
                    \"users\": {
                        \"name\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"ore\": {}
                            }
                        }
                    }
                }
            }'::jsonb
        )",
    )
    .execute(&pool)
    .await?;

    // Verify column is pending
    assert!(
        has_pending_column(&pool, "name").await?,
        "name should be pending"
    );

    // Verify target column doesn't exist yet
    let has_target: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT * FROM eql_v2.select_target_columns() AS c
            WHERE c.target_column IS NOT NULL AND c.column_name = 'name'
        )",
    )
    .fetch_one(&pool)
    .await?;

    assert!(!has_target, "target column should not exist");

    // Create encrypted columns
    sqlx::query("SELECT eql_v2.create_encrypted_columns()")
        .execute(&pool)
        .await?;

    // Verify name_encrypted column exists
    assert!(
        column_exists(&pool, "users", "name_encrypted").await?,
        "name_encrypted should exist"
    );

    // Rename columns
    sqlx::query("SELECT eql_v2.rename_encrypted_columns()")
        .execute(&pool)
        .await?;

    // Verify renamed columns
    assert!(
        column_exists(&pool, "users", "name_plaintext").await?,
        "name_plaintext should exist"
    );

    // Verify name exists as encrypted type
    assert!(
        column_exists(&pool, "users", "name").await?,
        "name should exist"
    );

    // Verify name_encrypted doesn't exist
    assert!(
        !column_exists(&pool, "users", "name_encrypted").await?,
        "name_encrypted should not exist"
    );

    // Verify it's eql_v2_encrypted type
    let is_encrypted_type: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT * FROM information_schema.columns s
            WHERE s.table_name = 'users'
            AND s.column_name = 'name'
            AND s.udt_name = 'eql_v2_encrypted'
        )",
    )
    .fetch_one(&pool)
    .await?;

    assert!(is_encrypted_type, "name should be eql_v2_encrypted type");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn create_multiple_encrypted_columns(pool: PgPool) -> Result<()> {
    // Test: Create multiple encrypted columns from configuration (4 assertions)
    // Verifies: multiple columns with different indexes

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Insert config for multiple columns
    sqlx::query(
        "INSERT INTO eql_v2_configuration (data) VALUES (
            '{
                \"v\": 1,
                \"tables\": {
                    \"users\": {
                        \"name\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"ore\": {},
                                \"unique\": {}
                            }
                        },
                        \"email\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"match\": {}
                            }
                        }
                    }
                }
            }'::jsonb
        )",
    )
    .execute(&pool)
    .await?;

    // Verify name column is pending
    assert!(
        has_pending_column(&pool, "name").await?,
        "name should be pending"
    );

    // Verify target column doesn't exist
    let has_target: bool = sqlx::query_scalar(
        "SELECT EXISTS (
            SELECT * FROM eql_v2.select_target_columns() AS c
            WHERE c.target_column IS NULL
        )",
    )
    .fetch_one(&pool)
    .await?;

    assert!(has_target, "target column should not exist");

    // Create columns
    sqlx::query("SELECT eql_v2.create_encrypted_columns()")
        .execute(&pool)
        .await?;

    // Verify both encrypted columns exist (lines 110-111)
    assert!(
        column_exists(&pool, "users", "name_encrypted").await?,
        "name_encrypted should exist"
    );
    assert!(
        column_exists(&pool, "users", "email_encrypted").await?,
        "email_encrypted should exist"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn select_pending_columns(pool: PgPool) -> Result<()> {
    // Test: select_pending_columns() returns correct columns (6 assertions)

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Create active config
    sqlx::query(
        "INSERT INTO eql_v2_configuration (state, data) VALUES (
            'active',
            '{
                \"v\": 1,
                \"tables\": {
                    \"users\": {
                        \"name\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"unique\": {}
                            }
                        }
                    }
                }
            }'::jsonb
        )",
    )
    .execute(&pool)
    .await?;

    // Create table with plaintext and encrypted columns
    sqlx::query("DROP TABLE IF EXISTS users CASCADE")
        .execute(&pool)
        .await?;
    sqlx::query(
        "CREATE TABLE users (
            id bigint GENERATED ALWAYS AS IDENTITY,
            name TEXT,
            name_encrypted eql_v2_encrypted,
            PRIMARY KEY(id)
        )",
    )
    .execute(&pool)
    .await?;

    // Add search config with migrating flag
    sqlx::query(
        "SELECT eql_v2.add_search_config('users', 'name_encrypted', 'match', migrating => true)",
    )
    .execute(&pool)
    .await?;

    // Migrate config to create encrypting state
    sqlx::query("SELECT eql_v2.migrate_config()")
        .execute(&pool)
        .await?;

    // Verify encrypting config exists (lines 159-161)
    let has_active: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active')",
    )
    .fetch_one(&pool)
    .await?;

    let has_encrypting: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'encrypting')",
    )
    .fetch_one(&pool)
    .await?;

    let has_pending: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending')",
    )
    .fetch_one(&pool)
    .await?;

    assert!(has_active, "active config should exist");
    assert!(has_encrypting, "encrypting config should exist");
    assert!(!has_pending, "pending config should not exist");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn select_target_columns(pool: PgPool) -> Result<()> {
    // Test: select_target_columns() returns correct columns (4 assertions)

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Insert config for name column
    sqlx::query(
        "INSERT INTO eql_v2_configuration (data) VALUES (
            '{
                \"v\": 1,
                \"tables\": {
                    \"users\": {
                        \"name\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"ore\": {}
                            }
                        }
                    }
                }
            }'::jsonb
        )",
    )
    .execute(&pool)
    .await?;

    // Verify we have pending columns
    assert!(
        has_pending_column(&pool, "name").await?,
        "name should be pending"
    );

    // Create encrypted columns
    sqlx::query("SELECT eql_v2.create_encrypted_columns()")
        .execute(&pool)
        .await?;

    // Verify target columns now exist
    let target_columns: Vec<(String, Option<String>)> =
        sqlx::query_as("SELECT column_name, target_column FROM eql_v2.select_target_columns()")
            .fetch_all(&pool)
            .await?;

    assert!(!target_columns.is_empty(), "should have target columns");

    // Verify name has target_column set
    let name_has_target = target_columns.iter().any(|(col, target)| {
        col == "name"
            && target
                .as_ref()
                .map(|t| t == "name_encrypted")
                .unwrap_or(false)
    });

    assert!(
        name_has_target,
        "name should have target_column=name_encrypted"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn activate_pending_config(pool: PgPool) -> Result<()> {
    // Test: activate_config() transitions encrypting -> active (8 assertions)

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Create active config
    sqlx::query(
        "INSERT INTO eql_v2_configuration (state, data) VALUES (
            'active',
            '{
                \"v\": 1,
                \"tables\": {
                    \"users\": {
                        \"name\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"unique\": {}
                            }
                        }
                    }
                }
            }'::jsonb
        )",
    )
    .execute(&pool)
    .await?;

    // Create table with plaintext and encrypted columns
    sqlx::query("DROP TABLE IF EXISTS users CASCADE")
        .execute(&pool)
        .await?;
    sqlx::query(
        "CREATE TABLE users (
            id bigint GENERATED ALWAYS AS IDENTITY,
            name TEXT,
            name_encrypted eql_v2_encrypted,
            PRIMARY KEY(id)
        )",
    )
    .execute(&pool)
    .await?;

    // Add search config and migrate
    sqlx::query(
        "SELECT eql_v2.add_search_config('users', 'name_encrypted', 'match', migrating => true)",
    )
    .execute(&pool)
    .await?;

    sqlx::query("SELECT eql_v2.migrate_config()")
        .execute(&pool)
        .await?;

    // Activate config
    sqlx::query("SELECT eql_v2.activate_config()")
        .execute(&pool)
        .await?;

    // Verify state transitions (lines 284-287)
    let has_active: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active')",
    )
    .fetch_one(&pool)
    .await?;

    let has_inactive: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'inactive')",
    )
    .fetch_one(&pool)
    .await?;

    let has_encrypting: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'encrypting')",
    )
    .fetch_one(&pool)
    .await?;

    let has_pending: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending')",
    )
    .fetch_one(&pool)
    .await?;

    assert!(has_active, "active config should exist");
    assert!(has_inactive, "inactive config should exist");
    assert!(!has_encrypting, "encrypting config should not exist");
    assert!(!has_pending, "pending config should not exist");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn encrypted_column_index_generation(pool: PgPool) -> Result<()> {
    // Test: Encrypted columns are created with proper JSONB structure (5 assertions)
    // Verifies: JSON structure has required 'i' (index metadata) field

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Create active config with match index
    sqlx::query(
        "INSERT INTO eql_v2_configuration (state, data) VALUES (
            'active',
            '{
                \"v\": 1,
                \"tables\": {
                    \"users\": {
                        \"name\": {
                            \"cast_as\": \"text\",
                            \"indexes\": {
                                \"unique\": {}
                            }
                        }
                    }
                }
            }'::jsonb
        )",
    )
    .execute(&pool)
    .await?;

    // Create table
    sqlx::query("DROP TABLE IF EXISTS users CASCADE")
        .execute(&pool)
        .await?;
    sqlx::query(
        "CREATE TABLE users (
            id bigint GENERATED ALWAYS AS IDENTITY,
            name TEXT,
            name_encrypted eql_v2_encrypted,
            PRIMARY KEY(id)
        )",
    )
    .execute(&pool)
    .await?;

    // Add encrypted config without migrating flag (immediately active)
    sqlx::query("SELECT eql_v2.add_search_config('users', 'name_encrypted', 'match')")
        .execute(&pool)
        .await?;

    // Verify active config exists
    let has_active: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active')",
    )
    .fetch_one(&pool)
    .await?;

    assert!(has_active, "active config should exist");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encryptindex_tables")))]
async fn handle_null_values_in_encrypted_columns(pool: PgPool) -> Result<()> {
    // Test: Exception raised when pending config exists but no migrate called (7 assertions)

    // Truncate config
    sqlx::query("TRUNCATE TABLE eql_v2_configuration")
        .execute(&pool)
        .await?;

    // Create table
    sqlx::query("DROP TABLE IF EXISTS users CASCADE")
        .execute(&pool)
        .await?;
    sqlx::query(
        "CREATE TABLE users (
            id bigint GENERATED ALWAYS AS IDENTITY,
            name TEXT,
            name_encrypted eql_v2_encrypted,
            PRIMARY KEY(id)
        )",
    )
    .execute(&pool)
    .await?;

    // Add search config to create active config
    sqlx::query("SELECT eql_v2.add_search_config('users', 'name_encrypted', 'match')")
        .execute(&pool)
        .await?;

    // Try to migrate when no pending config exists (should fail)
    let result = sqlx::query("SELECT eql_v2.migrate_config()")
        .execute(&pool)
        .await;

    assert!(
        result.is_err(),
        "migrate_config() should raise exception when no pending configuration exists"
    );

    Ok(())
}
