//! JSONB function tests
//!
//! Converted from src/jsonb/functions_test.sql
//! Tests EQL JSONB path query functions with encrypted data

use eql_tests::{QueryAssertion, Selectors};
use sqlx::PgPool;

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_returns_array_elements(pool: PgPool) {
    // Test: jsonb_array_elements returns array elements from jsonb_path_query result
    // Original SQL line 19-21 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;

    // Also verify count
    QueryAssertion::new(&pool, &sql)
        .count(5)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_throws_exception_for_non_array(pool: PgPool) {
    // Test: jsonb_array_elements throws exception if input is not an array
    // Original SQL line 28-30 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql)
        .throws_exception()
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_text_returns_array_elements(pool: PgPool) {
    // Test: jsonb_array_elements_text returns array elements as text
    // Original SQL line 83-90 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(5)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_text_throws_exception_for_non_array(pool: PgPool) {
    // Test: jsonb_array_elements_text throws exception if input is not an array
    // Original SQL line 92-94 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql)
        .throws_exception()
        .await;
}
