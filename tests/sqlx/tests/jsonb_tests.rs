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

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    // Also verify count
    QueryAssertion::new(&pool, &sql).count(5).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_throws_exception_for_non_array(pool: PgPool) {
    // Test: jsonb_array_elements throws exception if input is not an array
    // Original SQL line 28-30 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
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

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_length_returns_array_length(pool: PgPool) {
    // Test: jsonb_array_length returns correct array length
    // Original SQL line 114-117 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql).returns_int_value(5).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_length_throws_exception_for_non_array(pool: PgPool) {
    // Test: jsonb_array_length throws exception if input is not an array
    // Original SQL line 119-121 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_finds_selector(pool: PgPool) {
    // Test: jsonb_path_query finds records by selector
    // Original SQL line 182-189 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_returns_correct_count(pool: PgPool) {
    // Test: jsonb_path_query returns correct count
    // Original SQL line 186-189 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).count(3).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_true_for_existing_path(pool: PgPool) {
    // Test: jsonb_path_exists returns true for existing path
    // Original SQL line 231-234 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql)
        .returns_bool_value(true)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_false_for_nonexistent_path(pool: PgPool) {
    // Test: jsonb_path_exists returns false for nonexistent path
    // Original SQL line 236-239 in src/jsonb/functions_test.sql

    let sql = "SELECT eql_v2.jsonb_path_exists(e, 'blahvtha') FROM encrypted LIMIT 1";

    QueryAssertion::new(&pool, sql)
        .returns_bool_value(false)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_correct_count(pool: PgPool) {
    // Test: jsonb_path_exists returns correct count
    // Original SQL line 241-244 in src/jsonb/functions_test.sql

    let sql = format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') FROM encrypted",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).count(3).await;
}
