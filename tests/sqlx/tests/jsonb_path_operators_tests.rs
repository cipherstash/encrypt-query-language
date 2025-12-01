//! JSONB path operator tests (-> and ->>)
//!
//! Tests encrypted JSONB path extraction

use anyhow::Result;
use eql_tests::{QueryAssertion, Selectors};
use serde_json;
use sqlx::{PgPool, Row};

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_extracts_encrypted_path(pool: PgPool) -> Result<()> {
    // Test: e -> 'selector' returns encrypted nested value

    let sql = format!(
        "SELECT e -> '{}'::text FROM encrypted LIMIT 1",
        Selectors::N
    );

    // Should return encrypted value for path $.n
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
#[ignore = "Test data doesn't have nested objects - placeholders used for selectors"]
async fn arrow_operator_with_nested_path(pool: PgPool) -> Result<()> {
    // Test: Chaining -> operators for nested paths
    // NOTE: This test doesn't match the original SQL test which tested eql_v2_encrypted selectors
    // Current test data (ste_vec.sql) doesn't have nested object structure

    let sql = format!(
        "SELECT e -> '{}'::text -> '{}'::text FROM encrypted LIMIT 1",
        Selectors::NESTED_OBJECT,
        Selectors::NESTED_FIELD
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_returns_null_for_nonexistent_path(pool: PgPool) -> Result<()> {
    // Test: -> returns NULL for non-existent selector

    let sql = "SELECT e -> 'nonexistent_selector_hash_12345'::text FROM encrypted LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let result: Option<String> = row.try_get(0)?;
    assert!(result.is_none(), "Should return NULL for non-existent path");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_operator_extracts_encrypted_text(pool: PgPool) -> Result<()> {
    // Test: e ->> 'selector' returns encrypted value as text

    let sql = format!(
        "SELECT e ->> '{}'::text FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_operator_returns_null_for_nonexistent(pool: PgPool) -> Result<()> {
    // Test: ->> returns NULL for non-existent path

    let sql = "SELECT e ->> 'nonexistent_selector_hash_12345'::text FROM encrypted LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let result: Option<String> = row.try_get(0)?;
    assert!(result.is_none(), "Should return NULL for non-existent path");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_in_where_clause(pool: PgPool) -> Result<()> {
    // Test: Using ->> in WHERE clause for filtering

    let sql = format!(
        "SELECT id FROM encrypted WHERE (e ->> '{}'::text)::text IS NOT NULL",
        Selectors::N
    );

    // All 3 records have $.n path
    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_returns_metadata_fields(pool: PgPool) -> Result<()> {
    // Test: e -> 'selector' returns JSONB with 'i' (index) and 'v' (version) metadata fields.
    // This verifies that the arrow operator returns the full encrypted metadata structure,
    // not just the value. The metadata includes the index term ('i') and version ('v').
    // SQL equivalent: src/operators/->_test.sql lines 106-118
    //
    // NOTE: This test uses raw SQLx instead of QueryAssertion because we need to verify
    // specific JSONB field presence. QueryAssertion is designed for row count and basic
    // value assertions, but doesn't support introspecting JSONB object structure.

    let sql = format!(
        "SELECT (e -> '{}'::text)::jsonb FROM encrypted LIMIT 1",
        Selectors::N
    );

    let result: serde_json::Value = sqlx::query_scalar(&sql).fetch_one(&pool).await?;

    assert!(
        result.is_object(),
        "-> operator should return JSONB object"
    );
    let obj = result
        .as_object()
        .expect("Result should be a JSONB object after is_object() check");
    assert!(
        obj.contains_key("i"),
        "Result should contain 'i' (index metadata) field"
    );
    assert!(
        obj.contains_key("v"),
        "Result should contain 'v' (version) field"
    );

    Ok(())
}
