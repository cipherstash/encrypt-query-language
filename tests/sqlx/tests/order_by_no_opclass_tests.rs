//! ORDER BY tests without operator classes (Supabase mode)
//!
//! Simulates the Supabase environment where operator classes and ore_block_u64_8_256
//! operators are excluded from the build. Verifies that ordering is NOT correct
//! without these components — both direct ORDER BY e and ORDER BY eql_v2.order_by(e)
//! produce wrong results because PostgreSQL falls back to record/bytea comparison
//! instead of ORE-aware comparison.
//!
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use anyhow::Result;
use eql_tests::{get_ore_encrypted, QueryAssertion};
use sqlx::{PgPool, Row};

// ============================================================================
// Verify fixture correctly drops operator classes
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn fixture_drops_encrypted_operator_class(pool: PgPool) -> Result<()> {
    // Verify the btree operator class for eql_v2_encrypted was dropped
    let row = sqlx::query(
        "SELECT count(*) as cnt FROM pg_opclass WHERE opcname = 'encrypted_operator_class'",
    )
    .fetch_one(&pool)
    .await?;
    let count: i64 = row.try_get("cnt")?;
    assert_eq!(
        count, 0,
        "encrypted_operator_class should not exist after fixture"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn fixture_drops_ore_block_operator_class(pool: PgPool) -> Result<()> {
    // Verify the btree operator class for ore_block_u64_8_256 was dropped
    let row = sqlx::query(
        "SELECT count(*) as cnt FROM pg_opclass WHERE opcname = 'ore_block_u64_8_256_operator_class'"
    )
    .fetch_one(&pool)
    .await?;
    let count: i64 = row.try_get("cnt")?;
    assert_eq!(
        count, 0,
        "ore_block_u64_8_256_operator_class should not exist after fixture"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn fixture_drops_ore_block_operators(pool: PgPool) -> Result<()> {
    // Verify all ore_block_u64_8_256 comparison operators were dropped
    let row = sqlx::query(
        "SELECT count(*) as cnt FROM pg_operator
         WHERE oprleft = 'eql_v2.ore_block_u64_8_256'::regtype
            OR oprright = 'eql_v2.ore_block_u64_8_256'::regtype",
    )
    .fetch_one(&pool)
    .await?;
    let count: i64 = row.try_get("cnt")?;
    assert_eq!(
        count, 0,
        "No operators should exist for ore_block_u64_8_256 after fixture"
    );
    Ok(())
}

// ============================================================================
// ORDER BY eql_v2.order_by(e) produces wrong results without operator classes
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_helper_desc_wrong_order_without_opclass(pool: PgPool) -> Result<()> {
    // Without ore_block_u64_8_256 operator class, ORDER BY eql_v2.order_by(e) DESC
    // falls back to composite type record comparison (bytea lexicographic),
    // which does NOT match ORE ordering semantics.

    let sql = "SELECT id FROM ore ORDER BY eql_v2.order_by(e) DESC LIMIT 1";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;

    assert_ne!(
        first_id, 99,
        "ORDER BY eql_v2.order_by(e) DESC should NOT return id=99 without operator class \
         (bytea comparison does not match ORE ordering)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_helper_asc_wrong_order_without_opclass(pool: PgPool) -> Result<()> {
    // Without operator class, ASC ordering also produces wrong results.

    let sql = "SELECT id FROM ore ORDER BY eql_v2.order_by(e) ASC LIMIT 1";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;

    assert_ne!(
        first_id, 1,
        "ORDER BY eql_v2.order_by(e) ASC should NOT return id=1 without operator class \
         (bytea comparison does not match ORE ordering)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_helper_not_sequential_without_opclass(pool: PgPool) -> Result<()> {
    // Verify the ordering is genuinely wrong — not just off by one,
    // but fundamentally broken.

    let sql = "SELECT id FROM ore ORDER BY eql_v2.order_by(e) DESC LIMIT 5";
    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    let expected = vec![99i64, 98, 97, 96, 95];

    assert_ne!(
        ids, expected,
        "Top 5 DESC results should NOT be [99,98,97,96,95] without operator class, got {:?}",
        ids
    );

    Ok(())
}

// ============================================================================
// Direct ORDER BY e also produces wrong results without operator class
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn direct_order_by_wrong_order_without_opclass(pool: PgPool) -> Result<()> {
    // Direct ORDER BY e falls back to JSONB record comparison without the
    // encrypted_operator_class. This does NOT use ORE-aware sorting.

    let sql = "SELECT id FROM ore ORDER BY e ASC LIMIT 1";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;

    assert_ne!(
        first_id, 1,
        "Direct ORDER BY e ASC should NOT return id=1 without operator class \
         (JSONB comparison does not match ORE ordering)"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn direct_order_by_desc_wrong_order_without_opclass(pool: PgPool) -> Result<()> {
    // Direct ORDER BY e DESC also produces wrong results.

    let sql = "SELECT id FROM ore ORDER BY e DESC LIMIT 1";
    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;

    assert_ne!(
        first_id, 99,
        "Direct ORDER BY e DESC should NOT return id=99 without operator class"
    );

    Ok(())
}

// ============================================================================
// Correlated subquery ranking as workaround (uses eql_v2.compare())
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn correlated_subquery_ranking_asc_without_opclass(pool: PgPool) -> Result<()> {
    // eql_v2.compare() is a standalone function (not an operator), so it survives
    // the operator class drops. A correlated subquery counts how many rows have a
    // smaller value than each row, producing a rank that orders correctly.

    let sql = "SELECT id FROM ore t \
               ORDER BY (SELECT COUNT(*) FROM ore t2 WHERE eql_v2.compare(t.e, t2.e) > 0)";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 99, "Should return all 99 records");

    // Verify first 5 ids are in ascending order
    let first_five: Vec<i64> = rows[..5].iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        first_five,
        vec![1i64, 2, 3, 4, 5],
        "First 5 results should be [1,2,3,4,5], got {:?}",
        first_five
    );

    // Verify last row
    let last_id: i64 = rows[98].try_get(0)?;
    assert_eq!(last_id, 99, "Last row should be id=99");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn correlated_subquery_ranking_desc_without_opclass(pool: PgPool) -> Result<()> {
    // Same correlated subquery with DESC — should return highest-ranked rows first.

    let sql = "SELECT id FROM ore t \
               ORDER BY (SELECT COUNT(*) FROM ore t2 WHERE eql_v2.compare(t.e, t2.e) > 0) DESC";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 99, "Should return all 99 records");

    let first_five: Vec<i64> = rows[..5].iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        first_five,
        vec![99i64, 98, 97, 96, 95],
        "First 5 DESC results should be [99,98,97,96,95], got {:?}",
        first_five
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn correlated_subquery_ranking_with_limit_without_opclass(pool: PgPool) -> Result<()> {
    // LIMIT 1 with ASC subquery ranking should return the smallest value (id=1)

    let sql = "SELECT id FROM ore t \
               ORDER BY (SELECT COUNT(*) FROM ore t2 WHERE eql_v2.compare(t.e, t2.e) > 0) \
               LIMIT 1";

    let row = sqlx::query(sql).fetch_one(&pool).await?;
    let id: i64 = row.try_get(0)?;
    assert_eq!(
        id, 1,
        "Correlated subquery ranking ASC LIMIT 1 should return id=1"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn correlated_subquery_ranking_with_where_without_opclass(pool: PgPool) -> Result<()> {
    // WHERE clause filters rows, then correlated subquery orders the result correctly.
    // Note: the subquery counts over the full table to produce a global rank.

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore t \
         WHERE e > '{}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore t2 WHERE eql_v2.compare(t.e, t2.e) > 0)",
        ore_term
    );

    // Should return 57 records (ids 43-99)
    QueryAssertion::new(&pool, &sql).count(57).await;

    // First record should be id=43 (lowest rank among filtered rows)
    let row = sqlx::query(&sql).fetch_one(&pool).await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 43,
        "Correlated subquery ranking with WHERE e > 42 should return id=43 first"
    );

    Ok(())
}
