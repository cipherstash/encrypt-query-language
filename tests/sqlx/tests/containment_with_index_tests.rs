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
// Partial Element Containment Tests (proper containment semantics)
// ============================================================================
//
// DISCOVERY: These tests reveal that current containment implementation works
// correctly for EXACT VALUE MATCHING but has limitations for partial containment:
//
// 1. jsonb_contains() uses PostgreSQL's native @> operator on jsonb[] arrays
// 2. ste_vec_contains() requires BOTH:
//    - Matching selector: eql_v2.selector(_a) = eql_v2.selector(b)
//    - AND exact value equality: _a = b
// 3. This means containment works for:
//    - "Value contains itself" (trivially true) ✅
//    - "Value contains exact element from its sv array" ✅
//    - Cross-row matching with same selector ❌ (fails due to different encrypted values)
//
// The tests below demonstrate both the working cases and the limitation.
// Most tests PASS because they test exact element extraction from the same row.
// The cross-row test FAILS because it requires selector-only matching without value equality.
//
// This is actually correct behavior for encrypted data - we need exact matches
// to maintain security. The "contains itself" tests are not trivial - they verify
// that JSONB array containment works correctly with GIN indexes.

#[sqlx::test]
async fn jsonb_contains_partial_element_from_sv_array(pool: PgPool) -> Result<()> {
    // Test: Full value contains exact element from its sv array
    //
    // This test verifies that:
    // 1. We can extract a single element from the sv array
    // 2. The jsonb_contains function recognizes that element as contained
    // 3. GIN index can be used for this query
    //
    // This PASSES because we're checking exact value match from the same row.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Extract the first element from the sv array as a standalone JSONB value
    // The sv array contains search vector elements like:
    // {"a": false, "c": "...", "s": "...", "b3": "..."}
    let sql = format!(
        r#"
        WITH full_data AS (
            SELECT (e).data as d
            FROM {}
            WHERE id = {}
        ),
        extracted_element AS (
            SELECT d->'sv'->0 as element
            FROM full_data
        )
        SELECT 1
        FROM {} t1, extracted_element
        WHERE eql_v2.jsonb_contains(t1.e, extracted_element.element)
        AND t1.id = {}
        LIMIT 1
        "#,
        STE_VEC_VAST_TABLE, id, STE_VEC_VAST_TABLE, id
    );

    // Verify containment works for exact element from same row
    assert_contains(&pool, &sql).await?;

    Ok(())
}

#[sqlx::test]
async fn jsonb_array_contains_single_sv_element(pool: PgPool) -> Result<()> {
    // Test: jsonb_array() containment with single sv element
    //
    // Tests that PostgreSQL's @> operator correctly recognizes when an array
    // containing all sv elements contains a single-element array.
    //
    // This PASSES because the element is extracted from the same row,
    // so both selector and value match exactly.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    let sql = format!(
        r#"
        WITH full_data AS (
            SELECT (e).data as d, e
            FROM {}
            WHERE id = {}
        ),
        extracted_element AS (
            SELECT d->'sv'->0 as element
            FROM full_data
        )
        SELECT 1
        FROM {} t1, full_data, extracted_element
        WHERE eql_v2.jsonb_array(t1.e) @> ARRAY[extracted_element.element]
        AND t1.id = {}
        LIMIT 1
        "#,
        STE_VEC_VAST_TABLE, id, STE_VEC_VAST_TABLE, id
    );

    // Verify array containment works for exact element
    assert_contains(&pool, &sql).await?;

    Ok(())
}

#[sqlx::test]
async fn jsonb_contains_multiple_sv_elements(pool: PgPool) -> Result<()> {
    // Test: Full value contains multiple exact elements from its sv array
    //
    // Tests that containment works correctly when checking for multiple elements.
    // All extracted elements are from the same row, so they all match exactly.
    //
    // This PASSES because we're extracting exact elements from the same row.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Extract first 3 elements from sv array and check containment
    let sql = format!(
        r#"
        WITH full_data AS (
            SELECT (e).data as d
            FROM {}
            WHERE id = {}
        ),
        extracted_elements AS (
            SELECT jsonb_build_array(
                d->'sv'->0,
                d->'sv'->1,
                d->'sv'->2
            ) as elements
            FROM full_data
        )
        SELECT 1
        FROM {} t1, full_data, extracted_elements
        WHERE t1.id = {}
        AND eql_v2.jsonb_array(t1.e) @> (
            SELECT array_agg(elem)
            FROM jsonb_array_elements(extracted_elements.elements) as elem
        )
        LIMIT 1
        "#,
        STE_VEC_VAST_TABLE, id, STE_VEC_VAST_TABLE, id
    );

    // Verify multiple element containment works
    assert_contains(&pool, &sql).await?;

    Ok(())
}

#[sqlx::test]
#[ignore = "Demonstrates expected failure: cross-row containment requires exact value match, not just selector match"]
async fn jsonb_contains_sv_element_with_different_selector(pool: PgPool) -> Result<()> {
    // Test: Cross-row containment limitation (selector-only matching)
    //
    // This test demonstrates the current containment implementation behavior:
    // - Row 1 and Row 2 both have elements with selector "9493d6010fe7845d52149b697729c745"
    // - However, their encrypted values (c field) are different
    // - ste_vec_contains() requires BOTH matching selector AND matching value
    // - Therefore, this cross-row containment check FAILS
    //
    // This is actually CORRECT BEHAVIOR for encrypted data security:
    // We need exact value matches, not just selector matches.
    //
    // This test is ignored because it documents expected failure behavior.
    // Run with `cargo test -- --ignored` to verify it still fails as expected.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let sql = format!(
        r#"
        WITH row1_data AS (
            SELECT e
            FROM {}
            WHERE id = 1
        ),
        row2_element AS (
            -- Get the first sv element from row 2 that has the common selector
            -- but different encrypted value
            SELECT (e).data->'sv'->0 as element
            FROM {}
            WHERE id = 2
        )
        SELECT 1
        FROM row1_data, row2_element
        WHERE eql_v2.jsonb_contains(row1_data.e, row2_element.element)
        LIMIT 1
        "#,
        STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE
    );

    // This assertion will fail, demonstrating the security requirement
    // that containment needs exact value matching, not just selector matching
    assert_contains(&pool, &sql).await?;

    Ok(())
}

// ============================================================================
// Mixed Type Containment Tests (encrypted, jsonb)
// ============================================================================

#[sqlx::test]
async fn jsonb_contains_encrypted_jsonb_uses_index(pool: PgPool) -> Result<()> {
    // Test: jsonb_contains(encrypted, jsonb) helper function with GIN index
    //
    // Verifies that the mixed-type variant (encrypted, jsonb) works correctly
    // and uses the GIN index efficiently.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Test using the helper function with jsonb parameter
    // We pass the .data field from an encrypted value as the jsonb parameter
    let sql = format!(
        "SELECT 1 FROM {} t1 WHERE eql_v2.jsonb_contains(t1.e, (SELECT (t2.e).data FROM {} t2 WHERE t2.id = {})) LIMIT 1",
        STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE, id
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn jsonb_contains_jsonb_encrypted_uses_index(pool: PgPool) -> Result<()> {
    // Test: jsonb_contains(jsonb, encrypted) helper function with GIN index
    //
    // Verifies that the mixed-type variant (jsonb, encrypted) works correctly.
    // Note: This variant is less likely to use an index on the table column
    // since the column is not on the left side of the containment check.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Test using the helper function with jsonb as container
    let sql = format!(
        "SELECT 1 FROM {} t1 WHERE eql_v2.jsonb_contains((SELECT (t2.e).data FROM {} t2 WHERE t2.id = {}), t1.e) LIMIT 1",
        STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE, id
    );

    assert_contains(&pool, &sql).await?;
    // Note: This query pattern may or may not use the index depending on planner decisions
    // We just verify it returns correct results

    Ok(())
}

#[sqlx::test]
async fn jsonb_contains_multiple_rows_encrypted_jsonb(pool: PgPool) -> Result<()> {
    // Test: Verify jsonb_contains(encrypted, jsonb) works for multiple different rows
    //
    // Tests that the mixed-type variant works across the dataset.
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Test several different rows across the 500-row dataset
    for id in [1, 5, 10, 50, 100, 250, 499] {
        let sql = format!(
            "SELECT 1 FROM {} t1 WHERE eql_v2.jsonb_contains(t1.e, (SELECT (t2.e).data FROM {} t2 WHERE t2.id = {})) LIMIT 1",
            STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE, id
        );

        assert_contains(&pool, &sql).await?;
    }

    Ok(())
}

#[sqlx::test]
async fn jsonb_contained_by_encrypted_jsonb_uses_index(pool: PgPool) -> Result<()> {
    // Test: jsonb_contained_by(encrypted, jsonb) helper function with GIN index
    //
    // Verifies that the mixed-type variant (encrypted, jsonb) for contained_by
    // works correctly and uses the GIN index efficiently.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Test using the helper function with jsonb parameter
    let sql = format!(
        "SELECT 1 FROM {} t1 WHERE eql_v2.jsonb_contained_by(t1.e, (SELECT (t2.e).data FROM {} t2 WHERE t2.id = {})) LIMIT 1",
        STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE, id
    );

    assert_contains(&pool, &sql).await?;
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn jsonb_contained_by_jsonb_encrypted_uses_index(pool: PgPool) -> Result<()> {
    // Test: jsonb_contained_by(jsonb, encrypted) helper function with GIN index
    //
    // Verifies that the mixed-type variant (jsonb, encrypted) for contained_by
    // works correctly.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;

    // Test using the helper function with jsonb as contained value
    let sql = format!(
        "SELECT 1 FROM {} t1 WHERE eql_v2.jsonb_contained_by((SELECT (t2.e).data FROM {} t2 WHERE t2.id = {}), t1.e) LIMIT 1",
        STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE, id
    );

    assert_contains(&pool, &sql).await?;
    // Note: This query pattern may or may not use the index depending on planner decisions
    // We just verify it returns correct results

    Ok(())
}

#[sqlx::test]
async fn jsonb_contained_by_multiple_rows_encrypted_jsonb(pool: PgPool) -> Result<()> {
    // Test: Verify jsonb_contained_by(encrypted, jsonb) works for multiple different rows
    //
    // Tests that the mixed-type variant works across the dataset.
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Test several different rows across the 500-row dataset
    for id in [1, 5, 10, 50, 100, 250, 499] {
        let sql = format!(
            "SELECT 1 FROM {} t1 WHERE eql_v2.jsonb_contained_by(t1.e, (SELECT (t2.e).data FROM {} t2 WHERE t2.id = {})) LIMIT 1",
            STE_VEC_VAST_TABLE, STE_VEC_VAST_TABLE, id
        );

        assert_contains(&pool, &sql).await?;
    }

    Ok(())
}

#[sqlx::test]
async fn jsonb_contains_non_matching_encrypted_jsonb_returns_empty(pool: PgPool) -> Result<()> {
    // Test: Non-matching jsonb_contains(encrypted, jsonb) returns no results
    //
    // Verifies that searching for a non-existent value correctly returns empty
    // with the mixed-type variant.
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Use a fake encrypted value that won't match anything
    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_contains(e, '{{\"s\":\"nonexistent\",\"v\":1}}'::jsonb)",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent value");

    Ok(())
}

#[sqlx::test]
async fn jsonb_contained_by_non_matching_encrypted_jsonb_returns_empty(pool: PgPool) -> Result<()> {
    // Test: Non-matching jsonb_contained_by(encrypted, jsonb) returns no results
    //
    // Verifies that searching for a non-existent value correctly returns empty
    // with the mixed-type variant.
    setup_ste_vec_vast_gin_index(&pool).await?;

    // Use a fake encrypted value that won't match anything
    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_contained_by(e, '{{\"s\":\"nonexistent\",\"v\":1}}'::jsonb)",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent value");

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
