//! ORE text ordering tests
//!
//! Tests ORDER BY and sort_compare with text ORE encryption.
//! Uses ore_text table from migrations/006_install_ore_text_data.sql (ids 1-100)
//! Words are lexicographically sorted: id=1 is 'aardvark', id=100 is 'zinc'.

use anyhow::Result;
use eql_tests::{assert_sequential_ids, get_ore_text_encrypted};
use sqlx::{PgPool, Row};

// ============================================================================
// ORDER BY with operator classes (ORDER BY e)
// ============================================================================

#[sqlx::test]
async fn order_by_text_asc_returns_alphabetical_order(pool: PgPool) -> Result<()> {
    let sql = "SELECT id FROM ore_text ORDER BY e ASC";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");
    assert_sequential_ids(&rows, 1, 100);

    Ok(())
}

#[sqlx::test]
async fn order_by_text_desc_returns_reverse_alphabetical(pool: PgPool) -> Result<()> {
    let sql = "SELECT id FROM ore_text ORDER BY e DESC";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");

    let first_id: i64 = rows[0].try_get(0)?;
    assert_eq!(first_id, 100, "First DESC row should be id=100 (zinc)");

    let last_id: i64 = rows[99].try_get(0)?;
    assert_eq!(last_id, 1, "Last DESC row should be id=1 (aardvark)");

    Ok(())
}

#[sqlx::test]
async fn order_by_text_with_limit(pool: PgPool) -> Result<()> {
    let sql = "SELECT id FROM ore_text ORDER BY e ASC LIMIT 5";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 5, "LIMIT 5 should return 5 rows");
    assert_sequential_ids(&rows, 1, 5);

    Ok(())
}

#[sqlx::test]
async fn order_by_text_comparison_less_than(pool: PgPool) -> Result<()> {
    // horizon is id=56, so e < horizon should return 55 rows (ids 1-55)
    let ore_term = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e < '{}'::eql_v2_encrypted ORDER BY e ASC",
        ore_term
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 55, "Should return 55 records (ids 1-55)");

    Ok(())
}

#[sqlx::test]
async fn order_by_text_comparison_greater_than(pool: PgPool) -> Result<()> {
    // horizon is id=56, so e > horizon should return 44 rows (ids 57-100)
    let ore_term = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e > '{}'::eql_v2_encrypted ORDER BY e ASC",
        ore_term
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 44, "Should return 44 records (ids 57-100)");

    Ok(())
}

#[sqlx::test]
async fn order_by_text_helper_function(pool: PgPool) -> Result<()> {
    let sql = "SELECT id FROM ore_text ORDER BY eql_v2.order_by(e) ASC";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");
    assert_sequential_ids(&rows, 1, 100);

    Ok(())
}

// ============================================================================
// sort_compare without operator classes
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_asc(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore_text),
        (SELECT array_agg(e ORDER BY id) FROM ore_text),
        'ASC'
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");
    assert_sequential_ids(&rows, 1, 100);

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_desc(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore_text),
        (SELECT array_agg(e ORDER BY id) FROM ore_text),
        'DESC'
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");

    let first_id: i64 = rows[0].try_get(0)?;
    assert_eq!(first_id, 100, "First DESC row should be id=100 (zinc)");

    let last_id: i64 = rows[99].try_get(0)?;
    assert_eq!(last_id, 1, "Last DESC row should be id=1 (aardvark)");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_with_filter(pool: PgPool) -> Result<()> {
    // Filter to e > horizon (id=56), sort remaining 44 rows
    let ore_term = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT * FROM eql_v2.sort_compare(
            (SELECT array_agg(id ORDER BY id) FROM ore_text WHERE e > '{ore}'::eql_v2_encrypted),
            (SELECT array_agg(e ORDER BY id) FROM ore_text WHERE e > '{ore}'::eql_v2_encrypted),
            'ASC'
        )",
        ore = ore_term
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 44, "Should return 44 records (ids 57-100)");
    assert_sequential_ids(&rows, 57, 100);

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_table_ref(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare('id', 'e', 'ore_text', 'ASC')";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");
    assert_sequential_ids(&rows, 1, 100);

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_table_ref_schema_qualified(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare('id', 'e', 'public.ore_text', 'ASC')";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");
    assert_sequential_ids(&rows, 1, 100);

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_order_by_compare(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.order_by_compare('SELECT id, e FROM ore_text')";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 100, "Should return all 100 records");
    assert_sequential_ids(&rows, 1, 100);

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_with_limit(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore_text),
        (SELECT array_agg(e ORDER BY id) FROM ore_text)
    ) LIMIT 5";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 5, "LIMIT 5 should return 5 rows");
    assert_sequential_ids(&rows, 1, 5);

    Ok(())
}

// ============================================================================
// Text-specific edge cases
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_prefix_ordering(pool: PgPool) -> Result<()> {
    // Verify 'app'(id=6) < 'apple'(id=7) < 'application'(id=8)
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore_text WHERE id IN (6, 7, 8)),
        (SELECT array_agg(e ORDER BY id) FROM ore_text WHERE id IN (6, 7, 8)),
        'ASC'
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 3, "Should return 3 records");

    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        ids,
        vec![6i64, 7, 8],
        "Prefix ordering: app(6) < apple(7) < application(8), got {:?}",
        ids
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_text_similar_starts(pool: PgPool) -> Result<()> {
    // Verify 'car'(id=22) < 'card'(id=23) < 'care'(id=24)
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore_text WHERE id IN (22, 23, 24)),
        (SELECT array_agg(e ORDER BY id) FROM ore_text WHERE id IN (22, 23, 24)),
        'ASC'
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 3, "Should return 3 records");

    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        ids,
        vec![22i64, 23, 24],
        "Similar starts: car(22) < card(23) < care(24), got {:?}",
        ids
    );

    Ok(())
}
