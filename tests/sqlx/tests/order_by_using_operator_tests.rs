//! ORDER BY ... USING operator tests for ORE-encrypted columns
//!
//! Tests that `ORDER BY col USING <operator>` syntax fails without btree operator families.
//! PostgreSQL requires USING operators to be registered as strategy 1 (<) or strategy 5 (>)
//! members of a btree operator family. Dropping the operator family removes those pg_amop
//! entries, making the operators invalid for ordering even though they still exist.
//!
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use anyhow::Result;
use eql_tests::get_ore_encrypted;
use sqlx::PgPool;

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_using_less_than_fails_without_opclass(pool: PgPool) -> Result<()> {
    // ORDER BY e USING < requires < to be registered in a btree operator family

    let result = sqlx::query("SELECT id FROM ore ORDER BY e USING <")
        .fetch_all(&pool)
        .await;

    assert!(
        result.is_err(),
        "ORDER BY e USING < should fail without btree operator family"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_using_greater_than_fails_without_opclass(pool: PgPool) -> Result<()> {
    // ORDER BY e USING > requires > to be registered in a btree operator family

    let result = sqlx::query("SELECT id FROM ore ORDER BY e USING >")
        .fetch_all(&pool)
        .await;

    assert!(
        result.is_err(),
        "ORDER BY e USING > should fail without btree operator family"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_using_less_than_with_limit_fails_without_opclass(pool: PgPool) -> Result<()> {
    // ORDER BY e USING < LIMIT 1 also requires btree operator family registration

    let result = sqlx::query("SELECT id FROM ore ORDER BY e USING < LIMIT 1")
        .fetch_one(&pool)
        .await;

    assert!(
        result.is_err(),
        "ORDER BY e USING < LIMIT 1 should fail without btree operator family"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_using_greater_than_with_limit_fails_without_opclass(pool: PgPool) -> Result<()> {
    // ORDER BY e USING > LIMIT 1 also requires btree operator family registration

    let result = sqlx::query("SELECT id FROM ore ORDER BY e USING > LIMIT 1")
        .fetch_one(&pool)
        .await;

    assert!(
        result.is_err(),
        "ORDER BY e USING > LIMIT 1 should fail without btree operator family"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_using_less_than_with_where_clause_fails_without_opclass(
    pool: PgPool,
) -> Result<()> {
    // WHERE + ORDER BY e USING < also fails without btree operator family

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore WHERE e > '{}'::eql_v2_encrypted ORDER BY e USING <",
        ore_term
    );

    let result = sqlx::query(&sql).fetch_all(&pool).await;

    assert!(
        result.is_err(),
        "ORDER BY e USING < with WHERE clause should fail without btree operator family"
    );

    Ok(())
}
