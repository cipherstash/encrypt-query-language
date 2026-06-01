//! Aggregate function tests
//!
//! Covers native `COUNT` / `GROUP BY` on `eql_v2_encrypted` and the
//! `eql_v2.min(eql_v2_encrypted)` / `eql_v2.max(eql_v2_encrypted)` aggregates
//! on the composite type. Per-domain aggregates
//! (`eql_v2.min(eql_v2_<T>_ord)` etc.) are additionally covered by the
//! encrypted-domain test matrix (`tests/sqlx/src/matrix.rs`, instantiated per
//! scalar type from `tests/sqlx/tests/encrypted_domain/scalars/<T>.rs`).

use anyhow::Result;
use sqlx::PgPool;

#[sqlx::test]
async fn count_aggregate_on_encrypted_column(pool: PgPool) -> Result<()> {
    // COUNT on an `eql_v2_encrypted` column is PostgreSQL-native — no
    // aggregate declaration is required. Pin that it still counts non-NULL
    // encrypted rows on the legacy composite type.
    let count: i64 = sqlx::query_scalar("SELECT COUNT(e) FROM ore")
        .fetch_one(&pool)
        .await?;

    assert_eq!(count, 1000, "should count all non-NULL encrypted values");

    Ok(())
}

#[sqlx::test]
async fn max_aggregate_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: eql_v2.max() returns highest encrypted value
    // The ore table has id and e columns where e is the encrypted version of id
    // So eql_v2.max(e) should return the encrypted value corresponding to id=1000

    // Get the expected max value (encrypted value where id = 1000)
    let expected: String = sqlx::query_scalar("SELECT e::text FROM ore WHERE id = 1000")
        .fetch_one(&pool)
        .await?;

    // Get the actual max from eql_v2.max()
    let actual: String = sqlx::query_scalar("SELECT eql_v2.max(e)::text FROM ore")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        actual, expected,
        "eql_v2.max(e) should return the encrypted value where id = 1000 (maximum)"
    );

    Ok(())
}

#[sqlx::test]
async fn min_aggregate_on_encrypted_column(pool: PgPool) -> Result<()> {
    // Test: eql_v2.min() returns lowest encrypted value
    // The ore table has id and e columns where e is the encrypted version of id
    // So eql_v2.min(e) should return the encrypted value corresponding to id=1

    // Get the expected min value (encrypted value where id = 1)
    let expected: String = sqlx::query_scalar("SELECT e::text FROM ore WHERE id = 1")
        .fetch_one(&pool)
        .await?;

    // Get the actual min from eql_v2.min()
    let actual: String = sqlx::query_scalar("SELECT eql_v2.min(e)::text FROM ore")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        actual, expected,
        "eql_v2.min(e) should return the encrypted value where id = 1 (minimum)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_with_encrypted_column(pool: PgPool) -> Result<()> {
    // GROUP BY on `eql_v2_encrypted` works natively against the fixture's
    // distinct payloads. Pin that grouping by an encrypted column returns
    // the expected number of groups.
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

// ========== eql_v2.min() and eql_v2.max() Tests ==========

#[sqlx::test(fixtures(path = "../fixtures", scripts("aggregate_minmax_data")))]
async fn eql_v2_min_with_null_values(pool: PgPool) -> Result<()> {
    // Test: eql_v2.min() on NULL encrypted values returns NULL
    // Source SQL: ASSERT ((SELECT eql_v2.min(enc_int) FROM agg_test where enc_int IS NULL) IS NULL);

    let result: Option<String> =
        sqlx::query_scalar("SELECT eql_v2.min(enc_int)::text FROM agg_test WHERE enc_int IS NULL")
            .fetch_one(&pool)
            .await?;

    assert!(
        result.is_none(),
        "eql_v2.min() should return NULL when querying only NULL values"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("aggregate_minmax_data")))]
async fn eql_v2_min_finds_minimum_encrypted_value(pool: PgPool) -> Result<()> {
    // Test: eql_v2.min() finds the minimum encrypted value (plain_int = 1)
    // Source SQL: ASSERT ((SELECT enc_int FROM agg_test WHERE plain_int = 1) = (SELECT eql_v2.min(enc_int) FROM agg_test));

    // Get the expected minimum value (plain_int = 1)
    let expected: String =
        sqlx::query_scalar("SELECT enc_int::text FROM agg_test WHERE plain_int = 1")
            .fetch_one(&pool)
            .await?;

    // Get the actual minimum from eql_v2.min()
    let actual: String = sqlx::query_scalar("SELECT eql_v2.min(enc_int)::text FROM agg_test")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        actual, expected,
        "eql_v2.min() should return the encrypted value where plain_int = 1 (minimum)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("aggregate_minmax_data")))]
async fn eql_v2_max_with_null_values(pool: PgPool) -> Result<()> {
    // Test: eql_v2.max() on NULL encrypted values returns NULL
    // Source SQL: ASSERT ((SELECT eql_v2.max(enc_int) FROM agg_test where enc_int IS NULL) IS NULL);

    let result: Option<String> =
        sqlx::query_scalar("SELECT eql_v2.max(enc_int)::text FROM agg_test WHERE enc_int IS NULL")
            .fetch_one(&pool)
            .await?;

    assert!(
        result.is_none(),
        "eql_v2.max() should return NULL when querying only NULL values"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("aggregate_minmax_data")))]
async fn eql_v2_max_finds_maximum_encrypted_value(pool: PgPool) -> Result<()> {
    // Test: eql_v2.max() finds the maximum encrypted value (plain_int = 5)
    // Source SQL: ASSERT ((SELECT enc_int FROM agg_test WHERE plain_int = 5) = (SELECT eql_v2.max(enc_int) FROM agg_test));

    // Get the expected maximum value (plain_int = 5)
    let expected: String =
        sqlx::query_scalar("SELECT enc_int::text FROM agg_test WHERE plain_int = 5")
            .fetch_one(&pool)
            .await?;

    // Get the actual maximum from eql_v2.max()
    let actual: String = sqlx::query_scalar("SELECT eql_v2.max(enc_int)::text FROM agg_test")
        .fetch_one(&pool)
        .await?;

    assert_eq!(
        actual, expected,
        "eql_v2.max() should return the encrypted value where plain_int = 5 (maximum)"
    );

    Ok(())
}
