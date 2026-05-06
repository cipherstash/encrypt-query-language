//! JSONB function tests
//!
//! Tests EQL JSONB path query functions with encrypted data

use eql_tests::{QueryAssertion, Selectors};
use sqlx::{PgPool, Row};

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_returns_array_elements(pool: PgPool) {
    // Test: jsonb_array_elements returns array elements from jsonb_path_query result

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

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_text_returns_array_elements(pool: PgPool) {
    // Test: jsonb_array_elements_text returns array elements as text

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

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_length_returns_array_length(pool: PgPool) {
    // Test: jsonb_array_length returns correct array length

    let sql = format!(
        "SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ELEMENTS
    );

    QueryAssertion::new(&pool, &sql).returns_int_value(5).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_length_throws_exception_for_non_array(pool: PgPool) {
    // Test: jsonb_array_length throws exception if input is not an array

    let sql = format!(
        "SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, '{}')) as e FROM encrypted LIMIT 1",
        Selectors::ARRAY_ROOT
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_finds_selector(pool: PgPool) {
    // Test: jsonb_path_query finds records by selector

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_returns_correct_count(pool: PgPool) {
    // Test: jsonb_path_query returns correct count

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).count(3).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_true_for_existing_path(pool: PgPool) {
    // Test: jsonb_path_exists returns true for existing path

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

    let sql = "SELECT eql_v2.jsonb_path_exists(e, 'blahvtha') FROM encrypted LIMIT 1";

    QueryAssertion::new(&pool, sql)
        .returns_bool_value(false)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_exists_returns_correct_count(pool: PgPool) {
    // Test: jsonb_path_exists returns correct count

    let sql = format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') FROM encrypted",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).count(3).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn jsonb_path_query_returns_valid_structure(pool: PgPool) {
    // Test: jsonb_path_query returns JSONB with correct structure ('i' and 'v' keys)
    // Important: Validates decrypt-ability of returned data

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}')::jsonb FROM encrypted LIMIT 1",
        Selectors::N
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let result: serde_json::Value = row.try_get(0).unwrap();

    // Verify structure has 'i' (iv) and 'v' (value) keys required for decryption
    assert!(
        result.get("i").is_some(),
        "Result must contain 'i' key for initialization vector"
    );
    assert!(
        result.get("v").is_some(),
        "Result must contain 'v' key for encrypted value"
    );
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_returns_valid_structure(pool: PgPool) {
    // Test: jsonb_array_elements returns elements with correct structure

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, '{}'))::jsonb FROM encrypted LIMIT 1",
        Selectors::ARRAY_ELEMENTS
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await.unwrap();
    let result: serde_json::Value = row.try_get(0).unwrap();

    // Verify array elements maintain encryption structure
    assert!(
        result.get("i").is_some(),
        "Array element must contain 'i' key for initialization vector"
    );
    assert!(
        result.get("v").is_some(),
        "Array element must contain 'v' key for encrypted value"
    );
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_query_first_with_array_selector(pool: PgPool) {
    // Test: jsonb_path_query_first returns first element from array path

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query_first(e, '{}') as e FROM encrypted",
        Selectors::ARRAY_ROOT
    );

    // Should return 4 total rows (3 from encrypted_json + 1 from array_data)
    QueryAssertion::new(&pool, sql).count(4).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_query_first_filters_non_null(pool: PgPool) {
    // Test: jsonb_path_query_first can filter by non-null values

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query_first(e, '{}') as e FROM encrypted WHERE eql_v2.jsonb_path_query_first(e, '{}') IS NOT NULL",
        Selectors::ARRAY_ROOT,
        Selectors::ARRAY_ROOT
    );

    // Should return only 1 row (the one with array data)
    QueryAssertion::new(&pool, sql).count(1).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_query_with_array_selector_returns_single_result(pool: PgPool) {
    // Test: jsonb_path_query wraps arrays as single result

    let sql = format!(
        "SELECT eql_v2.jsonb_path_query(e, '{}') FROM encrypted",
        Selectors::ARRAY_ELEMENTS
    );

    // Array should be wrapped and returned as single element
    QueryAssertion::new(&pool, sql).count(1).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_path_exists_with_array_selector(pool: PgPool) {
    // Test: jsonb_path_exists works with array selectors

    let sql = format!(
        "SELECT eql_v2.jsonb_path_exists(e, '{}') FROM encrypted",
        Selectors::ARRAY_ELEMENTS
    );

    // Should return 4 rows (3 encrypted_json + 1 array_data)
    QueryAssertion::new(&pool, sql).count(4).await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_with_encrypted_selector(pool: PgPool) {
    // Test: jsonb_array_elements_text accepts eql_v2_encrypted selector
    // Tests alternative API pattern using encrypted selector

    // Create encrypted selector for array elements path
    let selector_sql = format!(
        "SELECT '{}'::jsonb::eql_v2_encrypted::text",
        Selectors::as_encrypted(Selectors::ARRAY_ELEMENTS)
    );
    let row = sqlx::query(&selector_sql).fetch_one(&pool).await.unwrap();
    let encrypted_selector: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}'::eql_v2_encrypted)) as e FROM encrypted",
        encrypted_selector
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await
        .count(5)
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json", "array_data")))]
async fn jsonb_array_elements_with_encrypted_selector_throws_for_non_array(pool: PgPool) {
    // Test: encrypted selector also validates array type

    let selector_sql = format!(
        "SELECT '{}'::jsonb::eql_v2_encrypted::text",
        Selectors::as_encrypted(Selectors::ARRAY_ROOT)
    );
    let row = sqlx::query(&selector_sql).fetch_one(&pool).await.unwrap();
    let encrypted_selector: String = row.try_get(0).unwrap();

    let sql = format!(
        "SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, '{}'::eql_v2_encrypted)) as e FROM encrypted LIMIT 1",
        encrypted_selector
    );

    QueryAssertion::new(&pool, &sql).throws_exception().await;
}
