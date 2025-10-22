use sqlx::{PgPool, postgres::PgPoolOptions};
use std::path::Path;

/// Create a test database with EQL extension loaded from release build
///
/// This connects to a test PostgreSQL instance and loads the pre-built
/// SQL file, giving us a clean database for testing.
pub async fn setup_test_db() -> anyhow::Result<PgPool> {
    // Connect to postgres to create test DB
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect("postgres://cipherstash:password@localhost:7432/postgres")
        .await?;

    // Create a fresh test database
    let test_db = format!("eql_test_{}", uuid::Uuid::new_v4().simple());
    sqlx::query(&format!("CREATE DATABASE {}", test_db))
        .execute(&pool)
        .await?;

    // Connect to the new database
    let test_pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&format!("postgres://cipherstash:password@localhost:7432/{}", test_db))
        .await?;

    // Load the built EQL extension
    let release_sql = std::fs::read_to_string("../release/cipherstash-encrypt.sql")
        .expect("Release SQL file should exist. Run 'mise run build' first.");

    sqlx::raw_sql(&release_sql)
        .execute(&test_pool)
        .await?;

    Ok(test_pool)
}

/// Drop the test database after tests complete
pub async fn cleanup_test_db(pool: PgPool, db_name: &str) -> anyhow::Result<()> {
    pool.close().await;

    let admin_pool = PgPoolOptions::new()
        .max_connections(1)
        .connect("postgres://cipherstash:password@localhost:7432/postgres")
        .await?;

    sqlx::query(&format!("DROP DATABASE IF EXISTS {} WITH (FORCE)", db_name))
        .execute(&admin_pool)
        .await?;

    Ok(())
}
