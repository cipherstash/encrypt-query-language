//! Specialized function tests
//!
//! - src/ste_vec/functions_test.sql (18 assertions)
//! - src/ore_block_u64_8_256/functions_test.sql (8 assertions)
//! - src/hmac_256/functions_test.sql (3 assertions)
//! - src/bloom_filter/functions_test.sql (2 assertions)
//! - src/version_test.sql (2 assertions)

use anyhow::Result;
use eql_tests::QueryAssertion;
use sqlx::PgPool;

// ============================================================================
// STE Vec tests (18 assertions)
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn ste_vec_returns_array_with_three_elements(pool: PgPool) -> Result<()> {
    // Test: ste_vec() returns array with 3 elements for encrypted data

    // ste_vec() returns eql_v2_encrypted[] - use array_length to verify
    let result: Option<i32> = sqlx::query_scalar(
        "SELECT array_length(eql_v2.ste_vec(e), 1) FROM encrypted LIMIT 1"
    )
    .fetch_one(&pool)
    .await?;

    assert_eq!(result, Some(3), "ste_vec should return array with 3 elements");

    Ok(())
}

#[sqlx::test]
async fn ste_vec_returns_array_for_ste_vec_element(pool: PgPool) -> Result<()> {
    // Test: ste_vec() returns array with 3 elements for ste_vec element itself

    let result: Option<i32> = sqlx::query_scalar(
        "SELECT array_length(eql_v2.ste_vec(get_numeric_ste_vec_10()::eql_v2_encrypted), 1)"
    )
    .fetch_one(&pool)
    .await?;

    assert_eq!(result, Some(3), "ste_vec should return array with 3 elements for ste_vec element");

    Ok(())
}

#[sqlx::test]
async fn is_ste_vec_array_returns_true_for_valid_array(pool: PgPool) -> Result<()> {
    // Test: is_ste_vec_array() returns true for valid ste_vec array

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.is_ste_vec_array('{\"a\": 1}'::jsonb::eql_v2_encrypted)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result, "is_ste_vec_array should return true for valid array");

    Ok(())
}

#[sqlx::test]
async fn is_ste_vec_array_returns_false_for_invalid_array(pool: PgPool) -> Result<()> {
    // Test: is_ste_vec_array() returns false for invalid arrays

    let result1: bool = sqlx::query_scalar(
        "SELECT eql_v2.is_ste_vec_array('{\"a\": 0}'::jsonb::eql_v2_encrypted)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result1, "is_ste_vec_array should return false for a=0");

    let result2: bool = sqlx::query_scalar(
        "SELECT eql_v2.is_ste_vec_array('{}'::jsonb::eql_v2_encrypted)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result2, "is_ste_vec_array should return false for empty object");

    Ok(())
}

#[sqlx::test]
async fn to_ste_vec_value_extracts_ste_vec_fields(pool: PgPool) -> Result<()> {
    // Test: to_ste_vec_value() extracts fields from ste_vec structure

    // to_ste_vec_value() returns eql_v2_encrypted - cast to jsonb for parsing
    let result: serde_json::Value = sqlx::query_scalar(
        "SELECT eql_v2.to_ste_vec_value('{\"i\": \"i\", \"v\": 2, \"sv\": [{\"ocf\": \"ocf\"}]}'::jsonb)::jsonb"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result.is_object(), "to_ste_vec_value should return object");
    let obj = result.as_object().unwrap();
    assert!(obj.contains_key("i"), "should contain 'i' key");
    assert!(obj.contains_key("v"), "should contain 'v' key");
    assert!(obj.contains_key("ocf"), "should contain 'ocf' key");

    Ok(())
}

#[sqlx::test]
async fn to_ste_vec_value_returns_original_for_non_ste_vec(pool: PgPool) -> Result<()> {
    // Test: to_ste_vec_value() returns original if not ste_vec value

    let result: serde_json::Value = sqlx::query_scalar(
        "SELECT eql_v2.to_ste_vec_value('{\"i\": \"i\", \"v\": 2, \"b3\": \"b3\"}'::jsonb)::jsonb"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result.is_object(), "to_ste_vec_value should return object");
    let obj = result.as_object().unwrap();
    assert!(obj.contains_key("i"), "should contain 'i' key");
    assert!(obj.contains_key("v"), "should contain 'v' key");
    assert!(obj.contains_key("b3"), "should contain 'b3' key");

    Ok(())
}

#[sqlx::test]
async fn is_ste_vec_value_returns_true_for_valid_value(pool: PgPool) -> Result<()> {
    // Test: is_ste_vec_value() returns true for valid ste_vec value

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.is_ste_vec_value('{\"sv\": [1]}'::jsonb::eql_v2_encrypted)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result, "is_ste_vec_value should return true for valid value");

    Ok(())
}

#[sqlx::test]
async fn is_ste_vec_value_returns_false_for_invalid_values(pool: PgPool) -> Result<()> {
    // Test: is_ste_vec_value() returns false for invalid values

    let result1: bool = sqlx::query_scalar(
        "SELECT eql_v2.is_ste_vec_value('{\"sv\": []}'::jsonb::eql_v2_encrypted)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result1, "is_ste_vec_value should return false for empty array");

    let result2: bool = sqlx::query_scalar(
        "SELECT eql_v2.is_ste_vec_value('{}'::jsonb::eql_v2_encrypted)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result2, "is_ste_vec_value should return false for empty object");

    Ok(())
}

#[sqlx::test]
async fn ste_vec_contains_self(pool: PgPool) -> Result<()> {
    // Test: ste_vec_contains() returns true when value contains itself

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.ste_vec_contains(
            get_numeric_ste_vec_10()::eql_v2_encrypted,
            get_numeric_ste_vec_10()::eql_v2_encrypted
        )"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result, "ste_vec_contains should return true for self-containment");

    Ok(())
}

#[sqlx::test]
async fn ste_vec_contains_term(pool: PgPool) -> Result<()> {
    // Test: ste_vec_contains() returns true when value contains extracted term

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.ste_vec_contains(
            get_numeric_ste_vec_10()::eql_v2_encrypted,
            (get_numeric_ste_vec_10()::eql_v2_encrypted) -> '2517068c0d1f9d4d41d2c666211f785e'::text
        )"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result, "ste_vec_contains should return true when array contains term");

    Ok(())
}

#[sqlx::test]
async fn ste_vec_term_does_not_contain_array(pool: PgPool) -> Result<()> {
    // Test: ste_vec_contains() returns false when term doesn't contain array

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.ste_vec_contains(
            (get_numeric_ste_vec_10()::eql_v2_encrypted) -> '2517068c0d1f9d4d41d2c666211f785e'::text,
            get_numeric_ste_vec_10()::eql_v2_encrypted
        )"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result, "ste_vec_contains should return false when term doesn't contain array");

    Ok(())
}

// ============================================================================
// ORE block functions tests (8 assertions)
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn ore_block_extracts_ore_term(pool: PgPool) -> Result<()> {
    // Test: ore_block_u64_8_256() extracts ore index term from encrypted data

    // ore_block_u64_8_256() returns custom type - cast to text for verification
    let result: String = sqlx::query_scalar(
        "SELECT eql_v2.ore_block_u64_8_256('{\"ob\": []}'::jsonb)::text"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result.is_empty(), "ore_block_u64_8_256 should return non-empty result");

    Ok(())
}

#[sqlx::test]
async fn ore_block_throws_exception_for_missing_term(pool: PgPool) -> Result<()> {
    // Test: ore_block_u64_8_256() throws exception when ore term is missing

    QueryAssertion::new(&pool, "SELECT eql_v2.ore_block_u64_8_256('{}'::jsonb)")
        .throws_exception()
        .await;

    Ok(())
}

#[sqlx::test]
async fn has_ore_block_returns_true_for_ore_data(pool: PgPool) -> Result<()> {
    // Test: has_ore_block_u64_8_256() returns true for data with ore term

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.has_ore_block_u64_8_256(e) FROM ore WHERE id = 42 LIMIT 1"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result, "has_ore_block_u64_8_256 should return true for ore data");

    Ok(())
}

// ============================================================================
// HMAC functions tests (3 assertions)
// ============================================================================

#[sqlx::test]
async fn hmac_extracts_hmac_term(pool: PgPool) -> Result<()> {
    // Test: hmac_256() extracts hmac index term from encrypted data

    let result: String = sqlx::query_scalar(
        "SELECT eql_v2.hmac_256('{\"hm\": \"u\"}'::jsonb)"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result.is_empty(), "hmac_256 should return non-empty string");
    assert_eq!(result, "u", "hmac_256 should extract 'hm' field value");

    Ok(())
}

#[sqlx::test]
async fn hmac_throws_exception_for_missing_term(pool: PgPool) -> Result<()> {
    // Test: hmac_256() throws exception when hmac term is missing

    QueryAssertion::new(&pool, "SELECT eql_v2.hmac_256('{}'::jsonb)")
        .throws_exception()
        .await;

    Ok(())
}

#[sqlx::test]
async fn has_hmac_returns_true_for_hmac_data(pool: PgPool) -> Result<()> {
    // Test: has_hmac_256() returns true for data with hmac term

    let result: bool = sqlx::query_scalar(
        "SELECT eql_v2.has_hmac_256(create_encrypted_json(1, 'hm'))"
    )
    .fetch_one(&pool)
    .await?;

    assert!(result, "has_hmac_256 should return true for hmac data");

    Ok(())
}

// ============================================================================
// Bloom filter tests (2 assertions)
// ============================================================================

#[sqlx::test]
async fn bloom_filter_extracts_bloom_term(pool: PgPool) -> Result<()> {
    // Test: bloom_filter() extracts bloom filter term from encrypted data

    // bloom_filter() returns smallint[] - cast to text for verification
    let result: String = sqlx::query_scalar(
        "SELECT eql_v2.bloom_filter('{\"bf\": []}'::jsonb)::text"
    )
    .fetch_one(&pool)
    .await?;

    assert!(!result.is_empty(), "bloom_filter should return non-empty result");

    Ok(())
}

#[sqlx::test]
async fn bloom_filter_throws_exception_for_missing_term(pool: PgPool) -> Result<()> {
    // Test: bloom_filter() throws exception when bloom filter term is missing

    QueryAssertion::new(&pool, "SELECT eql_v2.bloom_filter('{}'::jsonb)")
        .throws_exception()
        .await;

    Ok(())
}

// ============================================================================
// Version tests (2 assertions)
// ============================================================================

#[sqlx::test]
async fn eql_version_returns_dev_in_test_environment(pool: PgPool) -> Result<()> {
    // Test: version() returns 'DEV' in test environment

    let version: String = sqlx::query_scalar("SELECT eql_v2.version()")
        .fetch_one(&pool)
        .await?;

    assert_eq!(version, "DEV", "version should return 'DEV' in test environment");

    Ok(())
}
