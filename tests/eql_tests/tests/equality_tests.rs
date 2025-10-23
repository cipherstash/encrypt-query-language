//! Equality operator tests
//!
//! Converted from src/operators/=_test.sql
//! Tests EQL equality operators with encrypted data (HMAC and Blake3 indexes)

use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

/// Helper to execute create_encrypted_json SQL function with specific indexes
/// Uses variadic form: create_encrypted_json(id, index1, index2, ...)
async fn create_encrypted_json_with_index(pool: &PgPool, id: i32, index_type: &str) -> String {
    let sql = format!(
        "SELECT create_encrypted_json({}, '{}')::text",
        id, index_type
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .unwrap_or_else(|e| panic!(
            "Failed to create encrypted JSON with id={}, index_type='{}': {}",
            id, index_type, e
        ));

    let result: Option<String> = row.try_get(0).unwrap_or_else(|e| panic!(
        "Failed to get result from create_encrypted_json(id={}, index_type='{}'): {}",
        id, index_type, e
    ));

    result.expect(&format!(
        "create_encrypted_json returned NULL for id={}, index_type='{}'",
        id, index_type
    ))
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_hmac(pool: PgPool) {
    // Test: eql_v2_encrypted = eql_v2_encrypted with HMAC index
    // Original SQL line 10-32 in src/operators/=_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .returns_rows()
        .await;
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_returns_empty_for_no_match_hmac(pool: PgPool) {
    // Test: equality returns no results for non-existent record
    // Original SQL line 25-29 in src/operators/=_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)
    // The important part is that id=4 doesn't exist in the fixture data (only 1, 2, 3)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql)
        .count(0)
        .await;
}
