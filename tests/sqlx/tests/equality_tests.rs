//! Equality operator tests
//!
//! Converted from src/operators/=_test.sql
//! Tests EQL equality operators with encrypted data (HMAC and Blake3 indexes)

use anyhow::{Context, Result};
use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

/// Helper to execute create_encrypted_json SQL function with specific indexes
/// Uses variadic form: create_encrypted_json(id, index1, index2, ...)
async fn create_encrypted_json_with_index(
    pool: &PgPool,
    id: i32,
    index_type: &str,
) -> Result<String> {
    let sql = format!(
        "SELECT create_encrypted_json({}, '{}')::text",
        id, index_type
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching create_encrypted_json({}, '{}')", id, index_type))?;

    let result: Option<String> = row.try_get(0).with_context(|| {
        format!(
            "extracting text column for id={}, index_type='{}'",
            id, index_type
        )
    })?;

    result.with_context(|| {
        format!(
            "create_encrypted_json returned NULL for id={}, index_type='{}'",
            id, index_type
        )
    })
}

async fn fetch_text_column(pool: &PgPool, sql: &str) -> Result<String> {
    let row = sqlx::query(sql).fetch_one(pool).await.with_context(|| {
        format!("executing query for text result: {}", sql)
    })?;

    row.try_get(0).with_context(|| format!("extracting text column for query: {}", sql))
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = eql_v2_encrypted with HMAC index
    // Original SQL line 10-32 in src/operators/=_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_returns_empty_for_no_match_hmac(pool: PgPool) -> Result<()> {
    // Test: equality returns no results for non-existent record
    // Original SQL line 25-29 in src/operators/=_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)
    // The important part is that id=4 doesn't exist in the fixture data (only 1, 2, 3)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_blake3(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = eql_v2_encrypted with Blake3 index
    // Original SQL line 105-127 in src/operators/=_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "b3").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_returns_empty_for_no_match_blake3(pool: PgPool) -> Result<()> {
    // Test: equality returns no results for non-existent record with Blake3
    // Original SQL line 120-124 in src/operators/=_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists
    // The important part is that id=4 doesn't exist in the fixture data (only 1, 2, 3)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "b3").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_finds_matching_record_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2.eq() function with HMAC index
    // Original SQL line 38-59 in src/operators/=_test.sql
    // Uses create_encrypted_json(id)::jsonb-'ob' to get encrypted data without ORE field

    // Call SQL function to create encrypted JSON and remove 'ob' field
    // Cast to eql_v2_encrypted first, then to text to get tuple format
    let sql_create = "SELECT ((create_encrypted_json(1)::jsonb - 'ob')::eql_v2_encrypted)::text";
    let encrypted = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_finds_matching_record_blake3(pool: PgPool) -> Result<()> {
    // Test: eql_v2.eq() function with Blake3 index
    // Original SQL line 135-156 in src/operators/=_test.sql

    // Call SQL function to create encrypted JSON with Blake3 and remove 'ob' field
    let sql_create = "SELECT ((create_encrypted_json(1, 'b3')::jsonb - 'ob')::eql_v2_encrypted)::text";
    let encrypted = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_returns_empty_for_no_match_blake3(pool: PgPool) -> Result<()> {
    // Test: eql_v2.eq() returns no results for non-existent record with Blake3
    // Original SQL line 148-153 in src/operators/=_test.sql

    let sql_create = "SELECT ((create_encrypted_json(4, 'b3')::jsonb - 'ob')::eql_v2_encrypted)::text";
    let encrypted = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb with HMAC index
    // Original SQL line 65-94 in src/operators/=_test.sql

    // Create encrypted JSON with HMAC, remove 'ob' field for comparison
    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_hmac(pool: PgPool) -> Result<()> {
    // Test: jsonb = eql_v2_encrypted with HMAC index (reverse direction)
    // Original SQL line 78-81 in src/operators/=_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_no_match_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb with no matching record
    // Original SQL line 83-87 in src/operators/=_test.sql

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_no_match_hmac(pool: PgPool) -> Result<()> {
    // Test: jsonb = eql_v2_encrypted with no matching record
    // Original SQL line 89-91 in src/operators/=_test.sql

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_blake3(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb with Blake3 index
    // Original SQL line 164-193 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(1, 'b3')::jsonb::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_blake3(pool: PgPool) -> Result<()> {
    // Test: jsonb = eql_v2_encrypted with Blake3 index (reverse direction)
    // Original SQL line 177-180 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(1, 'b3')::jsonb::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_no_match_blake3(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb with no matching record (Blake3)
    // Original SQL line 184-187 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(4, 'b3')::jsonb::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_no_match_blake3(pool: PgPool) -> Result<()> {
    // Test: jsonb = eql_v2_encrypted with no matching record (Blake3)
    // Original SQL line 188-191 in src/operators/=_test.sql

    let sql_create = "SELECT create_encrypted_json(4, 'b3')::jsonb::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb = e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}
