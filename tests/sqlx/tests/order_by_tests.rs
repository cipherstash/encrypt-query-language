//! ORDER BY tests for ORE-encrypted columns
//!
//! Tests ORDER BY with ORE (Order-Revealing Encryption)
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-1000)

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

    // Should return 958 records (43-1000)
    QueryAssertion::new(&pool, &sql).count(958).await;

    Ok(())
}

#[sqlx::test]
async fn order_by_desc_with_greater_than_returns_highest(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC LIMIT 1 with e > 42 returns 1000

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e DESC LIMIT 1",
        ore_term
    );

    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(id, 1000, "Should return id=1000 (highest value > 42)");

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

#[sqlx::test(fixtures(path = "../fixtures", scripts("order_by_null_data")))]
async fn order_by_asc_nulls_first_returns_null_record_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC NULLS FIRST returns NULL values first
    // Fixture data: id=1 NULL, id=2 ore(42), id=3 ore(3), id=4 NULL

    let sql = "SELECT id FROM encrypted ORDER BY e ASC NULLS FIRST, id";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 1,
        "ORDER BY e ASC NULLS FIRST, id should return NULL value with lowest id (id=1) first"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("order_by_null_data")))]
async fn order_by_asc_nulls_last_returns_smallest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e ASC NULLS LAST returns smallest non-NULL value first
    // Fixture data: id=1 NULL, id=2 ore(42), id=3 ore(3), id=4 NULL

    let sql = "SELECT id FROM encrypted ORDER BY e ASC NULLS LAST";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 3,
        "ORDER BY e ASC NULLS LAST should return smallest non-NULL value (id=3) first"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("order_by_null_data")))]
async fn order_by_desc_nulls_first_returns_null_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC NULLS FIRST returns NULL values first
    // Fixture data: id=1 NULL, id=2 ore(42), id=3 ore(3), id=4 NULL

    let sql = "SELECT id FROM encrypted ORDER BY e DESC NULLS FIRST, id";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 1,
        "ORDER BY e DESC NULLS FIRST, id should return NULL value with lowest id (id=1) first"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("order_by_null_data")))]
async fn order_by_desc_nulls_last_returns_largest_value_first(pool: PgPool) -> Result<()> {
    // Test: ORDER BY e DESC NULLS LAST returns largest non-NULL value first
    // Fixture data: id=1 NULL, id=2 ore(42), id=3 ore(3), id=4 NULL

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

#[sqlx::test]
async fn order_by_helper_function_without_where_clause(pool: PgPool) -> Result<()> {
    // Test: ORDER BY eql_v2.order_by(e) DESC without any WHERE clause
    // Verifies ORE ordering works without relying on comparison operators
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-1000)

    let sql = "SELECT id FROM ore ORDER BY eql_v2.order_by(e) DESC";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    // Should return all 1000 records
    assert_eq!(rows.len(), 1000, "Should return all 1000 records");

    // Verify descending order: every record should have id = 1000 - index
    for (i, row) in rows.iter().enumerate() {
        let id: i64 = row.try_get(0)?;
        let expected = (1000 - i) as i64;
        assert_eq!(
            id, expected,
            "Row {} should be id={}, got id={}",
            i, expected, id
        );
    }

    Ok(())
}

#[sqlx::test]
async fn order_by_helper_function_without_where_clause_asc(pool: PgPool) -> Result<()> {
    // Test: ORDER BY eql_v2.order_by(e) ASC without any WHERE clause
    // Verifies ORE ordering works in ascending direction
    // Uses ore table from migrations/002_install_ore_data.sql (ids 1-1000)

    let sql = "SELECT id FROM ore ORDER BY eql_v2.order_by(e) ASC";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    // Should return all 1000 records
    assert_eq!(rows.len(), 1000, "Should return all 1000 records");

    // Verify ascending order: every record should have id = index + 1
    for (i, row) in rows.iter().enumerate() {
        let id: i64 = row.try_get(0)?;
        let expected = (i + 1) as i64;
        assert_eq!(
            id, expected,
            "Row {} should be id={}, got id={}",
            i, expected, id
        );
    }

    Ok(())
}
