//! ORDER BY tests for ORE-encrypted columns
//!
//! Converted from src/operators/order_by_test.sql
//! Tests ORDER BY with ORE (Order-Revealing Encryption)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use anyhow::Result;
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::{PgPool, Row};

#[sqlx::test]
async fn order_by_desc_returns_highest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC returns records in descending order
    // Combined with WHERE e < 42 to verify ordering
    // Original SQL lines 17-25 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e DESC",
        ore_term
    );

    // Should return 41 records, highest first
    QueryAssertion::new(&pool, &sql).count(41).await;

    // First record should be id=41
    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(first_id, 41, "ORDER BY DESC should return id=41 first");

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_with_limit(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC LIMIT 1 returns highest value
    // Original SQL lines 22-25 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 41, "Should return id=41 (highest value < 42)");

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_with_limit(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC LIMIT 1 returns lowest value
    // Original SQL lines 27-30 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 1, "Should return id=1 (lowest value < 42)");

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_with_greater_than(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC with WHERE e > 42
    // Original SQL lines 33-36 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC",
        ore_term
    );

    // Should return 57 records (43-99)
    QueryAssertion::new(&pool, &sql).count(57).await;

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_with_greater_than_returns_highest(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC LIMIT 1 with e > 42 returns 99
    // Original SQL lines 38-41 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 99, "Should return id=99 (highest value > 42)");

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_with_greater_than_returns_lowest(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC LIMIT 1 with e > 42 returns 43
    // Original SQL lines 43-46 in src/operators/order_by_test.sql

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 43, "Should return id=43 (lowest value > 42)");

    Ok(())
}
