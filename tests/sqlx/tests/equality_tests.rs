//! Equality operator tests
//!
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
    let row = sqlx::query(sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("executing query for text result: {}", sql))?;

    row.try_get(0)
        .with_context(|| format!("extracting text column for query: {}", sql))
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_finds_matching_record_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = eql_v2_encrypted with HMAC index

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
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-1000)
    // The important part is that id=4 doesn't exist in the fixture data (only 1, 2, 3)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e = '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

// Same-type Blake3 equality lookups via the bare `=` operator are no
// longer supported post-#193: the operator implementation is now an
// inlinable SQL function that compares `eql_v2.hmac_256(a) =
// eql_v2.hmac_256(b)` and requires both operands to carry an `hm`
// index term. The `eql_v2.eq` function still walks `eql_v2.compare`
// for the Blake3 / ORE fallback path — see the
// `eq_function_*_blake3` tests below for that coverage.

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn eq_function_finds_matching_record_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2.eq() function with HMAC index
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

// `eq_function_*_blake3` tests removed alongside the equality_operator_*_blake3
// tests above: they exercised root-level Blake3 equality, which has no
// production analogue. Blake3 only appears inside ste_vec elements.

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb with HMAC index

    // Create encrypted JSON with HMAC, remove 'ob' field for comparison
    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!("SELECT e FROM encrypted WHERE e = '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_hmac(pool: PgPool) -> Result<()> {
    // Test: jsonb = eql_v2_encrypted with HMAC index (reverse direction)

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!("SELECT e FROM encrypted WHERE '{}'::jsonb = e", json_value);

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_encrypted_equals_jsonb_no_match_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted = jsonb with no matching record

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!("SELECT e FROM encrypted WHERE e = '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn equality_operator_jsonb_equals_encrypted_no_match_hmac(pool: PgPool) -> Result<()> {
    // Test: jsonb = eql_v2_encrypted with no matching record

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let json_value = fetch_text_column(&pool, sql_create).await?;

    let sql = format!("SELECT e FROM encrypted WHERE '{}'::jsonb = e", json_value);

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

// Cross-type (jsonb / eql_v2_encrypted) Blake3 equality lookups via
// the bare `=` operator are no longer supported post-#193 for the
// same reason as the same-type Blake3 tests removed above.
