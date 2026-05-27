//! Aggregate behaviour against the legacy `eql_v2_encrypted` composite type.
//!
//! Only the aggregate forms that survive — native `COUNT` and `GROUP BY` —
//! are exercised here. `eql_v2.min(eql_v2_encrypted)` /
//! `eql_v2.max(eql_v2_encrypted)` were removed in favour of per-domain
//! aggregates (`eql_v2.min(eql_v2_<T>_ord)` etc.); their coverage moved to
//! the encrypted-domain test matrix (`tests/sqlx/src/matrix.rs`,
//! instantiated per scalar type from
//! `tests/sqlx/tests/encrypted_domain/scalars/<T>.rs`).

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
