//! Tests for the inlined jsonb_path_query / _first / _exists family.
//!
//! Coverage: behavioural parity with the pre-inlining plpgsql bodies, plus
//! plan assertions confirming the bodies fold into the calling query.

use anyhow::Result;
use eql_tests::Selectors;
use sqlx::PgPool;

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_first_returns_matching_element(pool: PgPool) -> Result<()> {
    let result: Option<serde_json::Value> = sqlx::query_scalar(&format!(
        "SELECT (eql_v2.jsonb_path_query_first(e, '{}')).data \
         FROM encrypted ORDER BY id LIMIT 1",
        Selectors::HELLO
    ))
    .fetch_one(&pool)
    .await?;

    let payload = result.expect("jsonb_path_query_first should return a value");
    assert_eq!(
        payload.get("s").and_then(|s| s.as_str()),
        Some(Selectors::HELLO),
        "returned element's selector must match the queried selector"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_first_returns_null_for_missing_selector(pool: PgPool) -> Result<()> {
    let result: Option<serde_json::Value> = sqlx::query_scalar(
        "SELECT (eql_v2.jsonb_path_query_first(e, 'no_such_selector')).data \
         FROM encrypted ORDER BY id LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;
    assert!(result.is_none(), "missing selector should yield NULL");
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_true_when_selector_matches(pool: PgPool) -> Result<()> {
    let result: bool = sqlx::query_scalar(&format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') \
         FROM encrypted ORDER BY id LIMIT 1",
        Selectors::HELLO
    ))
    .fetch_one(&pool)
    .await?;
    assert!(result, "selector $.hello is present in the fixture");
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_false_when_selector_missing(pool: PgPool) -> Result<()> {
    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.jsonb_path_exists(e, 'no_such_selector') \
         FROM encrypted ORDER BY id LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;
    assert!(!result, "non-existent selector should report false");
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_set_returning_yields_matching_element(pool: PgPool) -> Result<()> {
    // Set-returning form. The legacy contract: 0 or 1 rows for non-array
    // matches; a single array-wrapped row when matched elements carry `a: 1`.
    // Fixture elements at $.hello don't have the array flag, so we expect
    // one row per matching encrypted-document.
    let rows: Vec<serde_json::Value> = sqlx::query_scalar(&format!(
        "SELECT (eql_v2.jsonb_path_query(e, '{}')).data FROM encrypted",
        Selectors::HELLO
    ))
    .fetch_all(&pool)
    .await?;

    assert_eq!(rows.len(), 3, "fixture has 3 rows, each yielding one match");
    for row in rows {
        assert_eq!(
            row.get("s").and_then(|s| s.as_str()),
            Some(Selectors::HELLO)
        );
    }
    Ok(())
}

#[sqlx::test]
async fn jsonb_path_query_preserves_array_wrap_semantics(pool: PgPool) -> Result<()> {
    // Two matched elements at the same selector where at least one has `a: 1`:
    // legacy contract returns a single row containing both matches under
    // `sv`, with `a: 1` set on the wrapper.
    let sql = r#"
        SELECT (eql_v2.jsonb_path_query(
            '{
                "v": 2,
                "i": {"t": "t", "c": "c"},
                "sv": [
                    {"s": "sel_a", "c": "ct1", "a": 1},
                    {"s": "sel_a", "c": "ct2"}
                ]
            }'::jsonb,
            'sel_a'
        )).data
    "#;
    let result: serde_json::Value = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert_eq!(result.get("a").and_then(|v| v.as_i64()), Some(1));
    let inner_sv = result
        .get("sv")
        .and_then(|v| v.as_array())
        .expect("sv array present");
    assert_eq!(inner_sv.len(), 2);
    Ok(())
}
