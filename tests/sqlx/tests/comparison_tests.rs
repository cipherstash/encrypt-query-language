//! Comparison operator tests (< > <= >=)
//!
//! Tests EQL comparison operators with ORE (Order-Revealing Encryption)

use anyhow::{Context, Result};
use eql_tests::{
    get_ore_encrypted, get_ore_encrypted_as_jsonb, get_ste_vec_selector_term, QueryAssertion,
    Selectors,
};
use sqlx::{PgPool, Row};

/// Helper to execute create_encrypted_json SQL function
#[allow(dead_code)]
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

// ============================================================================
// Task 2: Less Than (<) Operator Tests
// ============================================================================

#[sqlx::test]
async fn less_than_operator_with_ore(pool: PgPool) -> Result<()> {
    // Test: e < e with ORE encryption
    // Value 42 should have 41 records less than it (1-41)
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    // Get encrypted value for id=42 from pre-seeded ore table
    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted",
        ore_term
    );

    // Should return 41 records (ids 1-41)
    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn lt_function_with_ore(pool: PgPool) -> Result<()> {
    // Test: eql_v2.lt() function with ORE

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.lt(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn less_than_operator_encrypted_less_than_jsonb(pool: PgPool) -> Result<()> {
    // Test: e < jsonb with ORE
    // Tests jsonb variant of < operator (casts jsonb to eql_v2_encrypted)
    // Get encrypted value for id=42, remove 'ob' field to create comparable JSONB

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE e < '{}'::jsonb", json_value);

    // Records with id < 42 should match (ids 1-41)
    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn less_than_operator_jsonb_less_than_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb < e with ORE (reverse direction)
    // Tests jsonb variant of < operator with operands reversed

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE '{}'::jsonb < e", json_value);

    // jsonb(42) < e means e > 42, so 57 records (43-99)
    QueryAssertion::new(&pool, &sql).count(57).await;

    Ok(())
}

// ============================================================================
// Task 3: Greater Than (>) Operator Tests
// ============================================================================

#[sqlx::test]
async fn greater_than_operator_with_ore(pool: PgPool) -> Result<()> {
    // Test: e > e with ORE encryption
    // Value 42 should have 57 records greater than it (43-99)
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(57).await;

    Ok(())
}

#[sqlx::test]
async fn gt_function_with_ore(pool: PgPool) -> Result<()> {
    // Test: eql_v2.gt() function with ORE

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.gt(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(57).await;

    Ok(())
}

#[sqlx::test]
async fn greater_than_operator_encrypted_greater_than_jsonb(pool: PgPool) -> Result<()> {
    // Test: e > jsonb with ORE
    // Tests jsonb variant of > operator (casts jsonb to eql_v2_encrypted)

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE e > '{}'::jsonb", json_value);

    // Records with id > 42 should match (ids 43-99 = 57 records)
    QueryAssertion::new(&pool, &sql).count(57).await;

    Ok(())
}

#[sqlx::test]
async fn greater_than_operator_jsonb_greater_than_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb > e with ORE (reverse direction)
    // Tests jsonb variant of > operator with operands reversed

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE '{}'::jsonb > e", json_value);

    // jsonb(42) > e means e < 42, so 41 records (1-41)
    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

// ============================================================================
// Task 4: Less Than or Equal (<=) Operator Tests
// ============================================================================

#[sqlx::test]
async fn less_than_or_equal_operator_with_ore(pool: PgPool) -> Result<()> {
    // Test: e <= e with ORE encryption
    // Value 42 should have 42 records <= it (1-42 inclusive)
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e <= '{}'::eql_v2_encrypted",
        ore_term
    );

    // Should return 42 records (ids 1-42 inclusive)
    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn lte_function_with_ore(pool: PgPool) -> Result<()> {
    // Test: eql_v2.lte() function with ORE

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.lte(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn less_than_or_equal_with_jsonb(pool: PgPool) -> Result<()> {
    // Test: e <= jsonb with ORE

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE e <= '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

#[sqlx::test]
async fn less_than_or_equal_jsonb_lte_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb <= e with ORE (reverse direction)
    // Complements e <= jsonb test for symmetry with other operators

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE '{}'::jsonb <= e", json_value);

    // jsonb(42) <= e means e >= 42, so 58 records (42-99)
    QueryAssertion::new(&pool, &sql).count(58).await;

    Ok(())
}

// ============================================================================
// Task 5: Greater Than or Equal (>=) Operator Tests
// ============================================================================

#[sqlx::test]
async fn greater_than_or_equal_operator_with_ore(pool: PgPool) -> Result<()> {
    // Test: e >= e with ORE encryption
    // Value 42 should have 58 records >= it (42-99 inclusive)
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e >= '{}'::eql_v2_encrypted",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(58).await;

    Ok(())
}

#[sqlx::test]
async fn gte_function_with_ore(pool: PgPool) -> Result<()> {
    // Test: eql_v2.gte() function with ORE

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE eql_v2.gte(e, '{}'::eql_v2_encrypted)",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(58).await;

    Ok(())
}

#[sqlx::test]
async fn greater_than_or_equal_with_jsonb(pool: PgPool) -> Result<()> {
    // Test: e >= jsonb with ORE

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE e >= '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(58).await;

    Ok(())
}

#[sqlx::test]
async fn greater_than_or_equal_jsonb_gte_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb >= e with ORE (reverse direction)

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE '{}'::jsonb >= e", json_value);

    // jsonb(42) >= e means e <= 42, so 42 records (1-42)
    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}

// ============================================================================
// Selector-based Comparison Tests
// ============================================================================
// Tests for extracting subterms with e->'selector' and comparing them
// Covers ore_cllw_u64_8 and ore_cllw_var_8 index types with fallback behavior

#[sqlx::test]
async fn selector_less_than_with_ore_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' < term with ore_cllw_u64_8 index
    //
    // Uses test data created by seed_encrypted_json() helper which creates:
    // - Three records with n=10, n=20, n=30
    // - ore_cllw_u64_8 index on $.n selector

    // Create table and seed with test data
    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=30 test data
    let term = get_ste_vec_selector_term(&pool, 30, Selectors::N).await?;

    // Query: e->'$.n' < term(30)
    // Should return 2 records (n=10 and n=20)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text < '{}'::eql_v2_encrypted",
        Selectors::N,
        term
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test]
async fn selector_less_than_with_ore_cllw_u64_8_fallback(pool: PgPool) -> Result<()> {
    // Test: e->'selector' < term fallback when index missing
    //
    // Tests that comparison falls back to JSONB literal comparison
    // when the requested index type is not present on the selector

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=30 test data
    let term = get_ste_vec_selector_term(&pool, 30, Selectors::N).await?;

    // Query with $.hello selector (which has ore_cllw_var_8, not ore_cllw_u64_8)
    // Falls back to JSONB literal comparison - should still return results
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text < '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test]
async fn selector_less_than_with_ore_cllw_var_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' < term with ore_cllw_var_8 index
    //
    // STE vec test data has ore_cllw_var_8 on $.hello selector (a7cea93975ed8c01f861ccb6bd082784)
    // Extract $.hello from ste_vec id=3 and compare

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.hello selector term from n=30 test data (corresponds to "three")
    let term = get_ste_vec_selector_term(&pool, 30, Selectors::HELLO).await?;

    // Query: e->'$.hello' < term(from ste_vec 3)
    // Should return 1 record (ste_vec id=1, since "world 1" < "world 3")
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text < '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_with_ore_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' > term with ore_cllw_u64_8 index
    //
    // Extract $.n from ste_vec id=2 (n=20 value) and find records > 20

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=20 test data
    let term = get_ste_vec_selector_term(&pool, 20, Selectors::N).await?;

    // Query: e->'$.n' > term(20)
    // Should return 1 record (n=30)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text > '{}'::eql_v2_encrypted",
        Selectors::N,
        term
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_with_ore_cllw_u64_8_fallback(pool: PgPool) -> Result<()> {
    // Test: e->'selector' > term fallback when index missing

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=20 test data
    let term = get_ste_vec_selector_term(&pool, 20, Selectors::N).await?;

    // Query with $.hello selector (falls back to JSONB comparison)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text > '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_with_ore_cllw_var_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' > term with ore_cllw_var_8 index

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.hello selector term from n=30 test data (corresponds to "three")
    let term = get_ste_vec_selector_term(&pool, 30, Selectors::HELLO).await?;

    // Query: e->'$.hello' > term
    // Should return 1 record
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text > '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_with_ore_cllw_var_8_fallback(pool: PgPool) -> Result<()> {
    // Test: e->'selector' > term fallback to JSONB comparison
    //
    // Tests fallback when selector doesn't have ore_cllw_var_8

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.hello selector term from n=30 test data
    let term = get_ste_vec_selector_term(&pool, 30, Selectors::HELLO).await?;

    // Query with $.n selector (which has ore_cllw_u64_8, not ore_cllw_var_8)
    // Falls back to JSONB literal comparison - should not return results
    // because the extracted term is a string selector and $.n expects numeric
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text > '{}'::eql_v2_encrypted",
        Selectors::N,
        term
    );

    // The fallback query succeeds but returns no results due to type mismatch
    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test]
async fn selector_less_than_or_equal_with_ore_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' <= term with ore_cllw_u64_8 index
    //
    // Extract $.n from ste_vec id=2 (n=20) and find records <= 20

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=20 test data
    let term = get_ste_vec_selector_term(&pool, 20, Selectors::N).await?;

    // Query: e->'$.n' <= term(20)
    // Should return 2 records (n=10 and n=20)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text <= '{}'::eql_v2_encrypted",
        Selectors::N,
        term
    );

    QueryAssertion::new(&pool, &sql).count(2).await;

    Ok(())
}

#[sqlx::test]
async fn selector_less_than_or_equal_with_ore_cllw_u64_8_fallback(pool: PgPool) -> Result<()> {
    // Test: e->'selector' <= term fallback when index missing

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=20 test data
    let term = get_ste_vec_selector_term(&pool, 20, Selectors::N).await?;

    // Query with $.hello selector (falls back to JSONB comparison)
    // The extracted term is numeric but $.hello selector expects string
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text <= '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    // SQL test behavior: fallback succeeds but returns no results due to type mismatch
    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_or_equal_with_ore_cllw_u64_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' >= term with ore_cllw_u64_8 index
    //
    // Extract $.n from ste_vec id=1 (n=10) and find records >= 10

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=10 test data
    let term = get_ste_vec_selector_term(&pool, 10, Selectors::N).await?;

    // Query: e->'$.n' >= term(10)
    // Should return 3 records (n=10, n=20, n=30)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text >= '{}'::eql_v2_encrypted",
        Selectors::N,
        term
    );

    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_or_equal_with_ore_cllw_u64_8_fallback(pool: PgPool) -> Result<()> {
    // Test: e->'selector' >= term fallback when index missing

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.n selector term from n=10 test data
    let term = get_ste_vec_selector_term(&pool, 10, Selectors::N).await?;

    // Query with $.hello selector (falls back to JSONB comparison)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text >= '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_or_equal_with_ore_cllw_var_8(pool: PgPool) -> Result<()> {
    // Test: e->'selector' >= term with ore_cllw_var_8 index

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.hello selector term from n=10 test data (corresponds to "one")
    let term = get_ste_vec_selector_term(&pool, 10, Selectors::HELLO).await?;

    // Query: e->'$.hello' >= term
    // Should return 3 records (all have "world X" >= "world 1")
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text >= '{}'::eql_v2_encrypted",
        Selectors::HELLO,
        term
    );

    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test]
async fn selector_greater_than_or_equal_with_ore_cllw_var_8_fallback(pool: PgPool) -> Result<()> {
    // Test: e->'selector' >= term fallback to JSONB comparison

    sqlx::query("SELECT create_table_with_encrypted()")
        .execute(&pool)
        .await?;

    sqlx::query("SELECT seed_encrypted_json()")
        .execute(&pool)
        .await?;

    // Extract $.hello selector term from n=10 test data
    let term = get_ste_vec_selector_term(&pool, 10, Selectors::HELLO).await?;

    // Query with $.n selector (falls back to JSONB comparison)
    let sql = format!(
        "SELECT e FROM encrypted WHERE e->'{}'::text >= '{}'::eql_v2_encrypted",
        Selectors::N,
        term
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}
