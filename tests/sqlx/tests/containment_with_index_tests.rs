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
    get_ste_vec_encrypted, get_ste_vec_sv_element,
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

/// Assert that a containment query returns at least one row
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `sql` - SQL query with `{}` placeholder for the encrypted value
/// * `value` - Encrypted value to substitute into the query
///
/// # Example
/// ```ignore
/// let sql = "SELECT 1 FROM t WHERE eql_v2.ste_vec(e) @> eql_v2.ste_vec('{}'::eql_v2_encrypted) LIMIT 1";
/// assert_contains(&pool, sql, &row_b).await?;
/// ```
async fn assert_contains(pool: &PgPool, sql: &str) -> Result<()> {
    let result: Option<(i32,)> = sqlx::query_as(&sql).fetch_optional(pool).await?;
    assert!(
        result.is_some(),
        "containment check failed - no rows returned: {}",
        sql
    );
    Ok(())
}

// ============================================================================
// Sanity Tests: Value Contains Itself (Exact Match)
// ============================================================================
//
// These tests verify basic functionality - a value trivially contains itself.
// They serve as sanity checks that the GIN index and containment functions work.

#[sqlx::test]
async fn sanity_value_contains_itself_uses_index(pool: PgPool) -> Result<()> {
    // Sanity check: A value contains itself (trivially true)
    // Verifies GIN index is used for containment queries
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, row.to_string()
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn sanity_before_after_index_creation(pool: PgPool) -> Result<()> {
    // Demonstrates GIN index impact: Seq Scan before, Index Scan after
    analyze_table(&pool, STE_VEC_VAST_TABLE).await?;

    let id = 1;
    let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, row.to_string()
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
// Partial Containment Tests: Array Contains Single Element
// ============================================================================
//
// These tests verify true containment semantics:
// - An encrypted value's sv array should CONTAIN a single element from that array
// - jsonb_array(encrypted) returns the sv array: [elem1, elem2, ...]
// - jsonb_array(single_element) returns: [element] (since no sv field)
// - PostgreSQL @> should find element in array
//
// IMPORTANT: These tests are expected to FAIL initially.
// They expose a bug where partial containment doesn't work.

#[sqlx::test]
async fn partial_contains_single_sv_element_literal(pool: PgPool) -> Result<()> {
    // Test: Encrypted column contains a single element from its sv array
    // Uses literal string substitution (no subqueries)
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Get the first sv element (index 0) as serde_json::Value
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    // Query: Does the encrypted column contain this single element?
    // jsonb_array(e) returns [elem0, elem1, ...]
    // jsonb_array(sv_element::jsonb) returns [sv_element] (no sv field)
    // Should find match since sv_element IS IN the sv array
    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) AND id = {} LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element.to_string(), id
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn partial_contains_sv_element_finds_row(pool: PgPool) -> Result<()> {
    // Test: Search table for rows containing a specific sv element
    // Should find exactly the row it came from
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 42; // Pick a row in the middle

    // Get sv element from row 42
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    // Search for rows containing this element (should find row 42)
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element.to_string()
    );

    let result: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(result.0, id as i64, "Should find the row the element came from");
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn partial_contains_different_sv_elements(pool: PgPool) -> Result<()> {
    // Test: Each sv element index should be containable
    // The sv array has ~6 elements per row
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Test containment for sv elements at indices 0, 1, 2
    for sv_index in [0, 1, 2] {
        let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, sv_index).await?;

        let sql = format!(
            "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) AND id = {} LIMIT 1",
            STE_VEC_VAST_TABLE, sv_element.to_string(), id
        );

        assert_contains(&pool, &sql).await?;
    }

    Ok(())
}

#[sqlx::test]
async fn partial_contains_multiple_rows_with_index(pool: PgPool) -> Result<()> {
    // Test: Partial containment works across multiple rows with GIN index
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Test several rows across the dataset (IDs are 1-500)
    for id in [1, 10, 50, 100, 250, 500] {
        let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

        let sql = format!(
            "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) LIMIT 1",
            STE_VEC_VAST_TABLE, sv_element.to_string()
        );

        assert_contains(&pool, &sql).await?;
        assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;
    }

    Ok(())
}

#[sqlx::test]
async fn partial_contains_count_matches(pool: PgPool) -> Result<()> {
    // Test: Count of partial containment matches
    // Each sv element should appear in exactly ONE row
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb)",
        STE_VEC_VAST_TABLE, sv_element.to_string()
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    // Should find exactly 1 match (the row it came from)
    assert_eq!(count.0, 1, "Expected exactly 1 match for unique sv element");

    Ok(())
}

// ============================================================================
// Parameterized Query Tests
// ============================================================================
//
// Tests that verify containment works with prepared statements using .bind()
// These complement the literal string tests above.

#[sqlx::test]
async fn partial_contains_parameterized_query(pool: PgPool) -> Result<()> {
    // Test: Partial containment using parameterized query with .bind()
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Helper returns serde_json::Value directly - no extra parsing needed
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    // Use parameterized query with $1 placeholder
    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2 LIMIT 1",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i32,)> = sqlx::query_as(&sql)
        .bind(&sv_element)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(result.is_some(), "Parameterized containment query should find match");

    Ok(())
}

#[sqlx::test]
async fn partial_contains_parameterized_multiple_rows(pool: PgPool) -> Result<()> {
    // Test: Parameterized containment across multiple rows
    setup_ste_vec_vast_gin_index(&pool).await?;

    for id in [1, 50, 100, 250] {
        // Helper returns serde_json::Value directly
        let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

        let sql = format!(
            "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) LIMIT 1",
            STE_VEC_VAST_TABLE
        );

        let result: (i64,) = sqlx::query_as(&sql)
            .bind(&sv_element)
            .fetch_one(&pool)
            .await?;

        assert_eq!(result.0, id as i64, "Should find the row the element came from");
    }

    Ok(())
}

#[sqlx::test]
async fn contained_by_parameterized_query(pool: PgPool) -> Result<()> {
    // Test: contained_by using parameterized query
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Helper returns serde_json::Value directly
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contained_by($1::jsonb, e) AND id = $2 LIMIT 1",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i32,)> = sqlx::query_as(&sql)
        .bind(&sv_element)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(result.is_some(), "Parameterized contained_by query should find match");

    Ok(())
}

// ============================================================================
// Mixed Type Partial Containment Tests (encrypted, jsonb)
// ============================================================================
//
// Tests for the new function overloads:
// - jsonb_contains(encrypted, jsonb)
// - jsonb_contains(jsonb, encrypted)
// - jsonb_contained_by(encrypted, jsonb)
// - jsonb_contained_by(jsonb, encrypted)

#[sqlx::test]
async fn mixed_contains_encrypted_jsonb_with_sv_element(pool: PgPool) -> Result<()> {
    // Test: jsonb_contains(encrypted, jsonb) with single sv element
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    // Use .to_string() for SQL literal interpolation
    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) AND id = {} LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element.to_string(), id
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn mixed_contained_by_jsonb_encrypted_with_sv_element(pool: PgPool) -> Result<()> {
    // Test: jsonb_contained_by(jsonb, encrypted) - element is contained in encrypted
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    // contained_by: is jsonb contained in encrypted?
    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_contained_by('{}'::jsonb, e) AND id = {} LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element.to_string(), id
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn mixed_contains_non_matching_returns_empty(pool: PgPool) -> Result<()> {
    // Test: Non-matching jsonb returns no results
    setup_ste_vec_vast_gin_index(&pool).await?;

    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_contains(e, '{{\"s\":\"nonexistent\"}}'::jsonb)",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent value");

    Ok(())
}

#[sqlx::test]
async fn mixed_contains_multiple_rows(pool: PgPool) -> Result<()> {
    // Test: Mixed type containment across multiple rows
    setup_ste_vec_vast_gin_index(&pool).await?;

    for id in [1, 10, 50, 100, 250] {
        let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

        let sql = format!(
            "SELECT 1 FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) LIMIT 1",
            STE_VEC_VAST_TABLE, sv_element.to_string()
        );

        assert_contains(&pool, &sql).await?;
        assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;
    }

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
    assert!(encrypted.is_object(), "encrypted value should be a JSON object");
    assert!(encrypted.get("sv").is_some(), "encrypted value should have 'sv' field");

    Ok(())
}

#[sqlx::test]
async fn test_get_ste_vec_sv_element_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_sv_element returns serde_json::Value with expected fields
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, 1, 0).await?;

    // Should be an object with expected fields
    assert!(sv_element.is_object(), "sv element should be a JSON object");
    assert!(sv_element.get("s").is_some(), "sv element should have 's' (selector) field");

    Ok(())
}
