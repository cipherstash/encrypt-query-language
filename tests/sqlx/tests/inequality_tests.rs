//! Inequality operator tests
//!
//! Converted from src/operators/<>_test.sql
//! Tests EQL inequality (<>) operators with encrypted data

use anyhow::{Context, Result};
use eql_tests::QueryAssertion;
use sqlx::{PgPool, Row};

/// Helper to execute create_encrypted_json SQL function
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

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_finds_non_matching_records_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted <> eql_v2_encrypted with HMAC index
    // Should return records that DON'T match the encrypted value
    // Original SQL lines 15-23 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    // Should return 2 records (records 2 and 3, not record 1)
    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_returns_empty_for_non_existent_record_hmac(pool: PgPool) -> Result<()> {
    // Test: <> with different record (not in test data)
    // Original SQL lines 25-30 in src/operators/<>_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    // Non-existent record: all 3 existing records are NOT equal to id=4
    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn neq_function_finds_non_matching_records_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2.neq() function with HMAC index
    // Original SQL lines 45-53 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn neq_function_returns_empty_for_non_existent_record_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2.neq() with different record (not in test data)
    // Original SQL lines 55-59 in src/operators/<>_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)

    let encrypted = create_encrypted_json_with_index(&pool, 4, "hm").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    // Non-existent record: all 3 existing records are NOT equal to id=4
    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_encrypted_not_equals_jsonb_hmac(pool: PgPool) -> Result<()> {
    // Test: eql_v2_encrypted <> jsonb with HMAC index
    // Original SQL lines 71-83 in src/operators/<>_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create)
        .fetch_one(&pool)
        .await
        .context("fetching json value")?;
    let json_value: String = row.try_get(0).context("extracting json text")?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_jsonb_not_equals_encrypted_hmac(pool: PgPool) -> Result<()> {
    // Test: jsonb <> eql_v2_encrypted (reverse direction)
    // Original SQL lines 78-81 in src/operators/<>_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create)
        .fetch_one(&pool)
        .await
        .context("fetching json value")?;
    let json_value: String = row.try_get(0).context("extracting json text")?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::jsonb <> e",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_encrypted_not_equals_jsonb_no_match_hmac(pool: PgPool) -> Result<()> {
    // Test: e <> jsonb with different record (not in test data)
    // Original SQL lines 83-87 in src/operators/<>_test.sql
    // Note: Using id=4 instead of 91347 to ensure ore data exists (start=40 is within ore range 1-99)

    let sql_create = "SELECT (create_encrypted_json(4)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create)
        .fetch_one(&pool)
        .await
        .context("fetching json value")?;
    let json_value: String = row.try_get(0).context("extracting json text")?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::jsonb",
        json_value
    );

    // Non-existent record: all 3 existing records are NOT equal to id=4
    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_finds_non_matching_records_blake3(pool: PgPool) -> Result<()> {
    // Test: <> operator with Blake3 index
    // Original SQL lines 107-115 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "b3").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn neq_function_finds_non_matching_records_blake3(pool: PgPool) -> Result<()> {
    // Test: eql_v2.neq() with Blake3
    // Original SQL lines 137-145 in src/operators/<>_test.sql

    let encrypted = create_encrypted_json_with_index(&pool, 1, "b3").await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn inequality_operator_encrypted_not_equals_jsonb_blake3(pool: PgPool) -> Result<()> {
    // Test: e <> jsonb with Blake3
    // Original SQL lines 163-175 in src/operators/<>_test.sql

    let sql_create = "SELECT (create_encrypted_json(1)::jsonb - 'ob')::text";
    let row = sqlx::query(sql_create)
        .fetch_one(&pool)
        .await
        .context("fetching json value")?;
    let json_value: String = row.try_get(0).context("extracting json text")?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e <> '{}'::jsonb",
        json_value
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}
