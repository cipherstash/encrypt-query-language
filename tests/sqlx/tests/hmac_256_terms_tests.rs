//! Tests for eql_v2.hmac_256_terms(val) — the GIN-indexable (s, hm) aggregate.
//!
//! Coverage:
//! - Returns jsonb array of {s, hm} pairs across sv elements with hm
//! - Filters out elements lacking hm
//! - Empty array when sv absent
//! - STRICT short-circuit on NULL input
//! - Plan: GIN containment query engages the index

use anyhow::Result;
use eql_tests::Selectors;
use sqlx::{Acquire, PgPool, Row};

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn returns_array_of_s_hm_pairs(pool: PgPool) -> Result<()> {
    let result: serde_json::Value =
        sqlx::query_scalar("SELECT eql_v2.hmac_256_terms(e) FROM encrypted ORDER BY id LIMIT 1")
            .fetch_one(&pool)
            .await?;

    let arr = result
        .as_array()
        .expect("hmac_256_terms should return a jsonb array");
    assert!(
        !arr.is_empty(),
        "fixture row should have sv elements with hm"
    );
    for elem in arr {
        assert!(
            elem.get("s").is_some(),
            "each element has 's' key: {}",
            elem
        );
        assert!(
            elem.get("hm").is_some(),
            "each element has 'hm' key: {}",
            elem
        );
    }
    Ok(())
}

#[sqlx::test]
async fn excludes_elements_without_hm(pool: PgPool) -> Result<()> {
    // Build a value where one sv element has hm and one doesn't.
    let sql = r#"
        SELECT eql_v2.hmac_256_terms(
            '{"v":2,"i":{"t":"t","c":"c"},
              "sv":[
                {"s":"sel_with_hm",    "c":"c1", "hm":"hash_a"},
                {"s":"sel_without_hm", "c":"c2", "oc":"ocv_only"}
              ]}'::jsonb::eql_v2_encrypted
        )
    "#;
    let result: serde_json::Value = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    let arr = result.as_array().expect("array result");
    assert_eq!(
        arr.len(),
        1,
        "only the element with hm should appear: {:?}",
        arr
    );
    assert_eq!(
        arr[0].get("s").and_then(|v| v.as_str()),
        Some("sel_with_hm")
    );
    assert_eq!(arr[0].get("hm").and_then(|v| v.as_str()), Some("hash_a"));
    Ok(())
}

#[sqlx::test]
async fn empty_array_when_sv_absent(pool: PgPool) -> Result<()> {
    let result: serde_json::Value = sqlx::query_scalar(
        "SELECT eql_v2.hmac_256_terms(
            '{\"v\":2,\"i\":{\"t\":\"t\",\"c\":\"c\"},\"hm\":\"root_hm\"}'::jsonb::eql_v2_encrypted
        )",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        result,
        serde_json::Value::Array(vec![]),
        "no sv → empty jsonb array, not NULL"
    );
    Ok(())
}

#[sqlx::test]
async fn null_input_returns_null(pool: PgPool) -> Result<()> {
    let result: Option<serde_json::Value> =
        sqlx::query_scalar("SELECT eql_v2.hmac_256_terms(NULL::eql_v2_encrypted)")
            .fetch_one(&pool)
            .await?;
    assert!(result.is_none(), "STRICT: NULL input → NULL output");
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn gin_containment_uses_index(pool: PgPool) -> Result<()> {
    // The load-bearing plan assertion: a GIN index on hmac_256_terms(col)
    // engages structurally for `@>` containment queries against the same
    // expression. Pin enable_seqscan=off because the 3-row fixture is too
    // small for the planner to prefer the index naturally.

    sqlx::query(
        "CREATE INDEX encrypted_hmac_terms_idx \
         ON encrypted USING gin (eql_v2.hmac_256_terms(e))",
    )
    .execute(&pool)
    .await?;
    sqlx::query("ANALYZE encrypted").execute(&pool).await?;

    // Discover an actual (s, hm) pair to query against — for the first row's
    // $.hello sv element. This avoids relying on knowing the exact hash value.
    let probe: serde_json::Value = sqlx::query_scalar(&format!(
        "SELECT jsonb_build_array(
             jsonb_build_object(
                 's', '{}',
                 'hm', eql_v2.hmac_256(e, '{}')::text
             )
         )
         FROM encrypted ORDER BY id LIMIT 1",
        Selectors::HELLO,
        Selectors::HELLO
    ))
    .fetch_one(&pool)
    .await?;
    let probe_json = serde_json::to_string(&probe)?;

    let mut conn = pool.acquire().await?;
    sqlx::query("SET enable_seqscan = off")
        .execute(conn.acquire().await?)
        .await?;

    let explain_sql = format!(
        "EXPLAIN SELECT * FROM encrypted \
         WHERE eql_v2.hmac_256_terms(e) @> '{}'::jsonb",
        probe_json
    );
    let plan: String = sqlx::query(&explain_sql)
        .fetch_all(conn.acquire().await?)
        .await?
        .into_iter()
        .map(|row| row.try_get::<String, _>(0).unwrap_or_default())
        .collect::<Vec<_>>()
        .join("\n");

    assert!(
        plan.contains("encrypted_hmac_terms_idx"),
        "Expected the GIN index to be used. Plan:\n{}",
        plan
    );
    Ok(())
}
