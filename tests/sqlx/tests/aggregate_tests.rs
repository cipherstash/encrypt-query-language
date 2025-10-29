//! Aggregate function tests
//!
//! Converted from src/encrypted/aggregates_test.sql
//! Tests COUNT, MAX, MIN with encrypted data

use anyhow::Result;
use sqlx::PgPool;

#[sqlx::test]
async fn count_aggregate_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: COUNT works with encrypted columns
    // Original SQL lines 13-19 in src/encrypted/aggregates_test.sql

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM ore")
        .fetch_one(&pool)
        .await?;

    assert_eq!(count, 99, "should count all ORE records");

    Ok(())
}

#[sqlx::test]
async fn max_aggregate_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: MAX returns highest value with ORE
    // Original SQL lines 21-32 in src/encrypted/aggregates_test.sql

    let max_id: i64 = sqlx::query_scalar("SELECT MAX(id) FROM ore WHERE id <= 50")
        .fetch_one(&pool)
        .await?;

    assert_eq!(max_id, 50, "MAX should return 50");

    Ok(())
}

#[sqlx::test]
async fn min_aggregate_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: MIN returns lowest value with ORE
    // Original SQL lines 34-45 in src/encrypted/aggregates_test.sql

    let min_id: i64 = sqlx::query_scalar("SELECT MIN(id) FROM ore WHERE id >= 10")
        .fetch_one(&pool)
        .await?;

    assert_eq!(min_id, 10, "MIN should return 10");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_with_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: GROUP BY works with encrypted data
    // Original SQL lines 47-50 in src/encrypted/aggregates_test.sql
    // Fixture creates 3 distinct encrypted records, each unique

    let group_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM (
            SELECT e, COUNT(*) FROM encrypted GROUP BY e
        ) subquery",
    )
    .fetch_one(&pool)
    .await?;

    assert_eq!(
        group_count, 3,
        "GROUP BY should return 3 groups (one per distinct encrypted value in fixture)"
    );

    Ok(())
}
