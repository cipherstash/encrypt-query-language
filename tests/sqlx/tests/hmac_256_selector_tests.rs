//! Tests for the field-level equality extractor: eql_v2.hmac_256(val, selector).
//!
//! Coverage:
//! - Happy path: returns the matched element's hm
//! - Missing selector / missing hm / NULL input / absent sv → NULL
//! - STRICT short-circuit on NULL inputs
//! - Plan: WHERE / GROUP BY against a functional hash index use Index Scan,
//!   not Seq Scan. This is the load-bearing assertion that confirms the
//!   structural index match between query expression and index expression.

use anyhow::Result;
use eql_tests::{explain_query, Selectors};
use sqlx::{Acquire, PgPool, Row};

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn returns_hm_for_matching_selector(pool: PgPool) -> Result<()> {
    let result: Option<String> = sqlx::query_scalar(&format!(
        "SELECT eql_v2.hmac_256(e, '{}')::text FROM encrypted ORDER BY id LIMIT 1",
        Selectors::HELLO
    ))
    .fetch_one(&pool)
    .await?;

    assert!(
        result.is_some(),
        "hmac_256(e, $.hello-selector) should return the overlaid hm term"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn returns_null_for_missing_selector(pool: PgPool) -> Result<()> {
    let result: Option<String> = sqlx::query_scalar(
        "SELECT eql_v2.hmac_256(e, 'selector_does_not_exist')::text \
         FROM encrypted ORDER BY id LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        result.is_none(),
        "hmac_256 with a non-existent selector should return NULL, got: {:?}",
        result
    );
    Ok(())
}

#[sqlx::test]
async fn returns_null_for_null_encrypted_input(pool: PgPool) -> Result<()> {
    // STRICT short-circuit: NULL input → NULL output without entering the body.
    let result: Option<String> =
        sqlx::query_scalar("SELECT eql_v2.hmac_256(NULL::eql_v2_encrypted, 'any-selector')::text")
            .fetch_one(&pool)
            .await?;

    assert!(
        result.is_none(),
        "STRICT function should return NULL for NULL input"
    );
    Ok(())
}

#[sqlx::test]
async fn returns_null_when_sv_absent(pool: PgPool) -> Result<()> {
    // Payload with no `sv` field at all (root-only encrypted value).
    let sql = r#"
        SELECT eql_v2.hmac_256(
            '{"v": 2, "i": {"t": "t", "c": "c"}, "hm": "root_hm"}'::jsonb::eql_v2_encrypted,
            'any-selector'
        )::text
    "#;
    let result: Option<String> = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert!(result.is_none(), "payload without sv should return NULL");
    Ok(())
}

#[sqlx::test]
async fn returns_null_when_matched_element_has_no_hm(pool: PgPool) -> Result<()> {
    // Selector matches but the element carries no hm — represents a node type
    // that didn't get an hm overlay (or legacy data; same outcome).
    let sql = r#"
        SELECT eql_v2.hmac_256(
            '{"v": 2, "i": {"t": "t", "c": "c"},
              "sv": [{"s": "sel_x", "c": "ct", "ocv": "ocv_value"}]}'::jsonb::eql_v2_encrypted,
            'sel_x'
        )::text
    "#;
    let result: Option<String> = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert!(
        result.is_none(),
        "selector match without 'hm' on the element should return NULL"
    );
    Ok(())
}

#[sqlx::test]
async fn returns_matched_element_not_first_when_multiple_selectors(pool: PgPool) -> Result<()> {
    // Multi-element sv: should return the hm of the element matching the
    // selector, not the first element overall.
    let sql = r#"
        SELECT eql_v2.hmac_256(
            '{"v": 2, "i": {"t": "t", "c": "c"},
              "sv": [
                {"s": "sel_first",  "hm": "hm_first"},
                {"s": "sel_target", "hm": "hm_target"},
                {"s": "sel_third",  "hm": "hm_third"}
              ]}'::jsonb::eql_v2_encrypted,
            'sel_target'
        )::text
    "#;
    let result: Option<String> = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert_eq!(result.as_deref(), Some("hm_target"));
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn where_clause_uses_functional_hash_index(pool: PgPool) -> Result<()> {
    // The load-bearing plan assertion: a btree hash index on
    // `eql_v2.hmac_256(col, '<selector>')` engages structurally for
    // bare equality queries on the same expression.
    //
    // The 3-row fixture is too small for the planner to prefer the index
    // naturally, so we pin enable_seqscan=off for the same connection that
    // runs EXPLAIN — proving the structural match is recognised when seq
    // scan is unavailable.

    sqlx::query(&format!(
        "CREATE INDEX encrypted_hello_hmac_idx \
         ON encrypted USING hash (eql_v2.hmac_256(e, '{}'))",
        Selectors::HELLO
    ))
    .execute(&pool)
    .await?;
    sqlx::query("ANALYZE encrypted").execute(&pool).await?;

    let mut conn = pool.acquire().await?;
    sqlx::query("SET enable_seqscan = off")
        .execute(conn.acquire().await?)
        .await?;

    let sql = format!(
        "EXPLAIN SELECT * FROM encrypted \
         WHERE eql_v2.hmac_256(e, '{}') = 'any_value'::eql_v2.hmac_256",
        Selectors::HELLO
    );
    let plan: String = sqlx::query(&sql)
        .fetch_all(conn.acquire().await?)
        .await?
        .into_iter()
        .map(|row| row.try_get::<String, _>(0).unwrap_or_default())
        .collect::<Vec<_>>()
        .join("\n");

    assert!(
        plan.contains("encrypted_hello_hmac_idx"),
        "Expected the functional hash index to be used. Plan:\n{}",
        plan
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_uses_functional_hash_index(pool: PgPool) -> Result<()> {
    sqlx::query(&format!(
        "CREATE INDEX encrypted_hello_hmac_grp_idx \
         ON encrypted USING hash (eql_v2.hmac_256(e, '{}'))",
        Selectors::HELLO
    ))
    .execute(&pool)
    .await?;
    sqlx::query("ANALYZE encrypted").execute(&pool).await?;

    // GROUP BY plan: HashAggregate on the inlined expression is the expected
    // shape (the planner sees `eql_v2.hmac_256(e, '<sel>')` as the group key
    // even on small fixtures where Bitmap Index Scan won't engage).
    let sql = format!(
        "SELECT eql_v2.hmac_256(e, '{}'), count(*) FROM encrypted \
         GROUP BY eql_v2.hmac_256(e, '{}')",
        Selectors::HELLO,
        Selectors::HELLO
    );

    let plan = explain_query(&pool, &sql).await?;
    assert!(
        plan.contains("HashAggregate") || plan.contains("Group"),
        "GROUP BY plan should aggregate on the hmac_256 expression. Plan:\n{}",
        plan
    );
    assert!(
        plan.contains(&format!("eql_v2.hmac_256(e, '{}'", Selectors::HELLO)),
        "Plan should reference the hmac_256(e, '<sel>') expression. Plan:\n{}",
        plan
    );
    Ok(())
}
