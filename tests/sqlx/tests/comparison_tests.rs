//! Comparison operator tests (< > <= >=)
//!
//! Converted from src/operators/<_test.sql, >_test.sql, <=_test.sql, >=_test.sql
//! Tests EQL comparison operators with ORE (Order-Revealing Encryption)

use anyhow::{Context, Result};
use eql_tests::{get_ore_encrypted, get_ore_encrypted_as_jsonb, QueryAssertion};
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
    // Original SQL lines 13-20 in src/operators/<_test.sql
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
    // Original SQL lines 30-37 in src/operators/<_test.sql

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
    // Original SQL lines 13-20 in src/operators/>_test.sql
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
    // Original SQL lines 30-37 in src/operators/>_test.sql

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
    // Original SQL lines 10-24 in src/operators/<=_test.sql
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
    // Original SQL lines 32-46 in src/operators/<=_test.sql

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
    // Original SQL lines 55-69 in src/operators/<=_test.sql

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
    // Original SQL lines 10-24 in src/operators/>=_test.sql
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
    // Original SQL lines 32-46 in src/operators/>=_test.sql

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
    // Original SQL lines 55-85 in src/operators/>=_test.sql

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE e >= '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(58).await;

    Ok(())
}

#[sqlx::test]
async fn greater_than_or_equal_jsonb_gte_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb >= e with ORE (reverse direction)
    // Original SQL lines 77-80 in src/operators/>=_test.sql

    let json_value = get_ore_encrypted_as_jsonb(&pool, 42).await?;

    let sql = format!("SELECT id FROM ore WHERE '{}'::jsonb >= e", json_value);

    // jsonb(42) >= e means e <= 42, so 42 records (1-42)
    QueryAssertion::new(&pool, &sql).count(42).await;

    Ok(())
}
