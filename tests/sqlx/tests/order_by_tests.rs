//! ORDER BY tests for ORE-encrypted columns
//!
//! Tests ORDER BY with ORE (Order-Revealing Encryption)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use anyhow::Result;
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::{PgPool, Row};

#[sqlx::test]
async fn order_by_desc_returns_highest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC returns records in descending order
    // Combined with WHERE e < 42 to verify ordering

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e DESC",
        ore_term
    );

    // Should return 41 records, highest first
    QueryAssertion::new(&pool, &sql).count(41).await;

    // First record should be id=41
    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(first_id, 41, "ORDER BY DESC should return id=41 first");

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_with_limit(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC LIMIT 1 returns highest value

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 41, "Should return id=41 (highest value < 42)");

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_with_limit(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC LIMIT 1 returns lowest value

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY e ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 1, "Should return id=1 (lowest value < 42)");

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_with_greater_than(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC with WHERE e > 42

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC",
        ore_term
    );

    // Should return 57 records (43-99)
    QueryAssertion::new(&pool, &sql).count(57).await;

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_with_greater_than_returns_highest(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC LIMIT 1 with e > 42 returns 99

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 99, "Should return id=99 (highest value > 42)");

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_with_greater_than_returns_lowest(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC LIMIT 1 with e > 42 returns 43

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 43, "Should return id=43 (lowest value > 42)");

    Ok(())
}

// NULL ordering tests

#[sqlx::test]
async fn order_by_asc_nulls_first_returns_null_record_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC NULLS FIRST returns NULL values first
    // Setup: Create table with NULLs and encrypted values
    //   - ID=1: NULL
    //   - ID=2: 42
    //   - ID=3: 3
    //   - ID=4: NULL
    // Expected: ORDER BY e ASC NULLS FIRST returns id=1 first

    // Create test table
    sqlx::query("CREATE TABLE encrypted(id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, e eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert id=42 from ore table
    let ore_42 = get_ore_encrypted(&pool, 42).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_42
    ))
    .execute(&pool)
    .await?;

    // Insert id=3 from ore table
    let ore_3 = get_ore_encrypted(&pool, 3).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_3
    ))
    .execute(&pool)
    .await?;

    // Insert another NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Test: NULLS FIRST should return a NULL row first
    // Use tie-breaker (id) to ensure deterministic ordering among NULL rows
    let sql = "SELECT id FROM encrypted ORDER BY e ASC NULLS FIRST, id";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 1,
        "ORDER BY e ASC NULLS FIRST, id should return NULL value with lowest id (id=1) first"
    );

    Ok(())
}

#[sqlx::test]
async fn order_by_asc_nulls_last_returns_smallest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC NULLS LAST returns smallest non-NULL value first
    // Setup: Same as previous test
    // Expected: ORDER BY e ASC NULLS LAST returns id=3 (value=3) first

    // Create test table
    sqlx::query("CREATE TABLE encrypted(id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, e eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert id=42 from ore table
    let ore_42 = get_ore_encrypted(&pool, 42).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_42
    ))
    .execute(&pool)
    .await?;

    // Insert id=3 from ore table
    let ore_3 = get_ore_encrypted(&pool, 3).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_3
    ))
    .execute(&pool)
    .await?;

    // Insert another NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Test: NULLS LAST should return id=3 (smallest value)
    let sql = "SELECT id FROM encrypted ORDER BY e ASC NULLS LAST";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 3,
        "ORDER BY e ASC NULLS LAST should return smallest non-NULL value (id=3) first"
    );

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_nulls_first_returns_null_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC NULLS FIRST returns NULL values first
    // Expected: ORDER BY e DESC NULLS FIRST returns id=1 first

    // Create test table
    sqlx::query("CREATE TABLE encrypted(id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, e eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert id=42 from ore table
    let ore_42 = get_ore_encrypted(&pool, 42).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_42
    ))
    .execute(&pool)
    .await?;

    // Insert id=3 from ore table
    let ore_3 = get_ore_encrypted(&pool, 3).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_3
    ))
    .execute(&pool)
    .await?;

    // Insert another NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Test: DESC NULLS FIRST should return a NULL row first
    // Use tie-breaker (id) to ensure deterministic ordering among NULL rows
    let sql = "SELECT id FROM encrypted ORDER BY e DESC NULLS FIRST, id";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 1,
        "ORDER BY e DESC NULLS FIRST, id should return NULL value with lowest id (id=1) first"
    );

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_nulls_last_returns_largest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC NULLS LAST returns largest non-NULL value first
    // Expected: ORDER BY e DESC NULLS LAST returns id=2 (value=42) first

    // Create test table
    sqlx::query("CREATE TABLE encrypted(id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, e eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Insert id=42 from ore table
    let ore_42 = get_ore_encrypted(&pool, 42).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_42
    ))
    .execute(&pool)
    .await?;

    // Insert id=3 from ore table
    let ore_3 = get_ore_encrypted(&pool, 3).await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted(e) VALUES ('{}'::eql_v2_encrypted)",
        ore_3
    ))
    .execute(&pool)
    .await?;

    // Insert another NULL
    sqlx::query("INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted)")
        .execute(&pool)
        .await?;

    // Test: DESC NULLS LAST should return id=2 (largest value)
    let sql = "SELECT id FROM encrypted ORDER BY e DESC NULLS LAST";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 2,
        "ORDER BY e DESC NULLS LAST should return largest non-NULL value (id=2) first"
    );

    Ok(())
}

// eql_v2.order_by() helper function tests

#[sqlx::test]
async fn order_by_helper_function_desc_returns_correct_count(pool: PgPool) -> Result<()> {
    // Test: ORDER BY eql_v2.order_by(e) DESC with WHERE e < 42
    // Expected: Returns 41 records

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY eql_v2.order_by(e) DESC",
        ore_term
    );

    QueryAssertion::new(&pool, &sql).count(41).await;

    Ok(())
}

#[sqlx::test]
async fn order_by_helper_function_desc_returns_highest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY eql_v2.order_by(e) DESC LIMIT 1 returns id=41

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY eql_v2.order_by(e) DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(
        id, 41,
        "ORDER BY eql_v2.order_by(e) DESC should return id=41 (highest value < 42) first"
    );

    Ok(())
}

#[sqlx::test]
async fn order_by_helper_function_asc_returns_lowest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY eql_v2.order_by(e) ASC LIMIT 1 returns id=1

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e < '{}'::eql_v2_encrypted ORDER BY eql_v2.order_by(e) ASC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(
        id, 1,
        "ORDER BY eql_v2.order_by(e) ASC should return id=1 (lowest value < 42) first"
    );

    Ok(())
}
