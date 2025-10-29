//! JSONB path operator tests (-> and ->>)
//!
//! Converted from src/operators/->_test.sql and ->>_test.sql
//! Tests encrypted JSONB path extraction

use anyhow::Result;
use eql_tests::{QueryAssertion, Selectors};
use sqlx::{PgPool, Row};

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn arrow_operator_extracts_encrypted_path(pool: PgPool) -> Result<()> {
    // Test: e -> 'selector' returns encrypted nested value
    // Original SQL lines 12-27 in src/operators/->_test.sql

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
    // Original SQL lines 58-73 in src/operators/->_test.sql

    let sql = "SELECT e -> 'nonexistent_selector_hash_12345'::text FROM encrypted LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let result: Option<String> = row.try_get(0)?;
    assert!(result.is_none(), "Should return NULL for non-existent path");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_operator_extracts_encrypted_text(pool: PgPool) -> Result<()> {
    // Test: e ->> 'selector' returns encrypted value as text
    // Original SQL lines 12-27 in src/operators/->>_test.sql

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
    // Original SQL lines 35-50 in src/operators/->>_test.sql

    let sql = "SELECT e ->> 'nonexistent_selector_hash_12345'::text FROM encrypted LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let result: Option<String> = row.try_get(0)?;
    assert!(result.is_none(), "Should return NULL for non-existent path");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn double_arrow_in_where_clause(pool: PgPool) -> Result<()> {
    // Test: Using ->> in WHERE clause for filtering
    // Original SQL lines 58-65 in src/operators/->>_test.sql

    let sql = format!(
        "SELECT id FROM encrypted WHERE (e ->> '{}'::text)::text IS NOT NULL",
        Selectors::N
    );

    // All 3 records have $.n path
    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}
