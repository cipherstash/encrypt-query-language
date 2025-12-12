//! Containment with index tests (@> and <@) for encrypted JSONB
//!
//! Tests that encrypted JSONB containment operations work correctly with
//! GIN indexes using the jsonb_array() function which returns jsonb[] arrays.
//!
//! The jsonb_array approach leverages PostgreSQL's native hash support for jsonb
//! elements, enabling efficient GIN indexed containment queries at scale.
//!
//! Uses the ste_vec_vast table (500 rows) from migration 005_install_ste_vec_vast_data.sql

use anyhow::Result;
use eql_tests::{
    analyze_table, assert_uses_index, assert_uses_seq_scan, create_jsonb_gin_index, explain_query,
    get_ste_vec_encrypted, get_ste_vec_encrypted_pair, get_ste_vec_sv_element,
};
use sqlx::PgPool;

// Constants for ste_vec_vast table testing
const STE_VEC_VAST_TABLE: &str = "ste_vec_vast";
const STE_VEC_VAST_GIN_INDEX: &str = "ste_vec_vast_gin_idx";

// ============================================================================
// GIN Index Helper Functions
// ============================================================================

/// Setup GIN index on ste_vec_vast table for testing
///
/// Creates the GIN index and runs ANALYZE to ensure query planner
/// has accurate statistics.
async fn setup_ste_vec_vast_gin_index(pool: &PgPool) -> Result<()> {
    create_jsonb_gin_index(pool, STE_VEC_VAST_TABLE, STE_VEC_VAST_GIN_INDEX).await?;
    analyze_table(pool, STE_VEC_VAST_TABLE).await?;
    Ok(())
}

// ============================================================================
// Sanity Tests: Value Contains Itself (Exact Match)
// ============================================================================
//
// These tests verify basic functionality - a value trivially contains itself.
// They serve as sanity checks that the GIN index and containment functions work.

#[sqlx::test]
async fn sanity_before_after_index_creation(pool: PgPool) -> Result<()> {
    // Demonstrates GIN index impact: Seq Scan before, Index Scan after
    analyze_table(&pool, STE_VEC_VAST_TABLE).await?;

    let id = 1;
    let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE,
        row.to_string()
    );

    // BEFORE: Without index, should use Seq Scan
    let explain_before = explain_query(&pool, &sql).await?;
    assert_uses_seq_scan(&explain_before);

    // Create the GIN index
    setup_ste_vec_vast_gin_index(&pool).await?;

    // AFTER: With index, should use the GIN index
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn sanity_non_matching_returns_empty(pool: PgPool) -> Result<()> {
    // Non-existent value returns no results
    setup_ste_vec_vast_gin_index(&pool).await?;

    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_array(e) @> ARRAY['{{\"s\":\"nonexistent\",\"v\":1}}'::jsonb]",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent selector");

    Ok(())
}

// ============================================================================
// Helper Function Tests
// ============================================================================

#[sqlx::test]
async fn test_get_ste_vec_encrypted_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_encrypted returns serde_json::Value
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, 1).await?;

    // Should be an object with expected encrypted structure
    assert!(
        encrypted.is_object(),
        "encrypted value should be a JSON object"
    );
    assert!(
        encrypted.get("sv").is_some(),
        "encrypted value should have 'sv' field"
    );

    Ok(())
}

#[sqlx::test]
async fn test_get_ste_vec_sv_element_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_sv_element returns serde_json::Value with expected fields
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, 1, 0).await?;

    // Should be an object with expected fields
    assert!(sv_element.is_object(), "sv element should be a JSON object");
    assert!(
        sv_element.get("s").is_some(),
        "sv element should have 's' (selector) field"
    );

    Ok(())
}

#[sqlx::test]
async fn test_get_ste_vec_encrypted_pair_returns_different_rows(pool: PgPool) -> Result<()> {
    // Test that we can get two different encrypted values for comparison
    let (enc1, enc2) = get_ste_vec_encrypted_pair(&pool, STE_VEC_VAST_TABLE, 1, 2).await?;

    // They should be different values
    assert_ne!(enc1, enc2, "Different rows should have different encrypted values");

    // Both should have sv field
    assert!(enc1.get("sv").is_some(), "enc1 should have sv field");
    assert!(enc2.get("sv").is_some(), "enc2 should have sv field");

    Ok(())
}
