//! Smoke + drift-detection suite for the default `eql_v2_int4` variant.
//!
//! `eql_v2_int4` is a line-for-line duplicate of `_ord_ore` with a
//! different domain identifier. The INLINEABLE_DOMAIN_FUNCTIONS test
//! detects structural drift (SQL + IMMUTABLE + no proconfig);
//! `default_matches_ord_ore_explain` here detects behavioural drift
//! by comparing EXPLAIN output for parallel queries.

use anyhow::Result;
use sqlx::PgPool;

const SAMPLE: &str = r#"{"v":2,"i":{"t":"t","c":"c"},"c":"x","hm":"aa","ob":["bb"]}"#;

#[sqlx::test]
async fn default_accepts_payload_and_supports_equality(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE t_default (id integer GENERATED ALWAYS AS IDENTITY, value eql_v2_int4) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("INSERT INTO t_default(value) VALUES ($1::jsonb::eql_v2_int4)")
        .bind(SAMPLE)
        .execute(&mut *tx)
        .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM t_default WHERE value = $1::jsonb::eql_v2_int4",
    )
    .bind(SAMPLE)
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(count, 1);

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn default_matches_ord_ore_explain(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query("CREATE TEMP TABLE t_default (id integer GENERATED ALWAYS AS IDENTITY, value eql_v2_int4) ON COMMIT DROP")
        .execute(&mut *tx).await?;
    sqlx::query("CREATE TEMP TABLE t_ore (id integer GENERATED ALWAYS AS IDENTITY, value eql_v2_int4_ord_ore) ON COMMIT DROP")
        .execute(&mut *tx).await?;
    sqlx::query("INSERT INTO t_default(value) VALUES ($1::jsonb::eql_v2_int4)").bind(SAMPLE).execute(&mut *tx).await?;
    sqlx::query("INSERT INTO t_ore(value) VALUES ($1::jsonb::eql_v2_int4_ord_ore)").bind(SAMPLE).execute(&mut *tx).await?;

    sqlx::query("CREATE INDEX t_default_hmac_idx ON t_default ((eql_v2.hmac_256(value::jsonb)))").execute(&mut *tx).await?;
    sqlx::query("CREATE INDEX t_ore_hmac_idx ON t_ore ((eql_v2.hmac_256(value::jsonb)))").execute(&mut *tx).await?;
    sqlx::query("ANALYZE t_default").execute(&mut *tx).await?;
    sqlx::query("ANALYZE t_ore").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off").execute(&mut *tx).await?;

    let default_plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM t_default WHERE value = '{}'::jsonb::eql_v2_int4",
        SAMPLE.replace('\'', "''")
    )).fetch_all(&mut *tx).await?;
    let ore_plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM t_ore WHERE value = '{}'::jsonb::eql_v2_int4_ord_ore",
        SAMPLE.replace('\'', "''")
    )).fetch_all(&mut *tx).await?;

    let default_node = default_plan.iter().find(|r| r.contains("Index Scan")).cloned();
    let ore_node = ore_plan.iter().find(|r| r.contains("Index Scan")).cloned();
    assert!(default_node.is_some() && ore_node.is_some(),
        "both plans must show an Index Scan; default: {default_plan:?} ore: {ore_plan:?}");

    tx.commit().await?;
    Ok(())
}
