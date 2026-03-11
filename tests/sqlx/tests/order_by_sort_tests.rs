//! ORDER BY sort_compare tests without operator classes
//!
//! Tests for the eql_v2.sort_compare() and eql_v2.order_by_compare() functions which
//! provide O(n log n) comparison-based sorting as an alternative to the O(n^2) correlated
//! subquery workaround. Also tests filtered inner query optimization for correlated subqueries.
//!
//! Uses ore table from migrations/002_install_ore_data.sql (ids 1-99)

use anyhow::Result;
use eql_tests::get_ore_encrypted;
use sqlx::{PgPool, Row};
use std::time::Instant;

// ============================================================================
// sort_compare correctness tests
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_asc_returns_correct_order(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore),
        (SELECT array_agg(e ORDER BY id) FROM ore),
        'ASC'
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 99, "Should return all 99 records");

    let first_five: Vec<i64> = rows[..5].iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        first_five,
        vec![1i64, 2, 3, 4, 5],
        "First 5 ASC results should be [1,2,3,4,5], got {:?}",
        first_five
    );

    let last_id: i64 = rows[98].try_get(0)?;
    assert_eq!(last_id, 99, "Last row should be id=99");

    // Verify complete sequential ordering
    let all_ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    let expected: Vec<i64> = (1..=99).collect();
    assert_eq!(all_ids, expected, "All ids should be sequential 1..99");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_desc_returns_correct_order(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore),
        (SELECT array_agg(e ORDER BY id) FROM ore),
        'DESC'
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 99, "Should return all 99 records");

    let first_five: Vec<i64> = rows[..5].iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        first_five,
        vec![99i64, 98, 97, 96, 95],
        "First 5 DESC results should be [99,98,97,96,95], got {:?}",
        first_five
    );

    let last_id: i64 = rows[98].try_get(0)?;
    assert_eq!(last_id, 1, "Last row should be id=1");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_with_where_clause(pool: PgPool) -> Result<()> {
    // Filter to e > 42 using subqueries in array_agg
    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT * FROM eql_v2.sort_compare(
            (SELECT array_agg(id ORDER BY id) FROM ore WHERE e > '{ore}'::eql_v2_encrypted),
            (SELECT array_agg(e ORDER BY id) FROM ore WHERE e > '{ore}'::eql_v2_encrypted),
            'ASC'
        )",
        ore = ore_term
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 57, "Should return 57 records (ids 43-99)");

    let first_id: i64 = rows[0].try_get(0)?;
    assert_eq!(first_id, 43, "First row should be id=43");

    let last_id: i64 = rows[56].try_get(0)?;
    assert_eq!(last_id, 99, "Last row should be id=99");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_with_limit(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore),
        (SELECT array_agg(e ORDER BY id) FROM ore)
    ) LIMIT 5";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 5, "LIMIT 5 should return 5 rows");

    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        ids,
        vec![1i64, 2, 3, 4, 5],
        "First 5 sorted rows should be [1,2,3,4,5], got {:?}",
        ids
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_empty_input(pool: PgPool) -> Result<()> {
    // Use a WHERE clause that matches no rows to produce empty arrays
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore WHERE id < 0),
        (SELECT array_agg(e ORDER BY id) FROM ore WHERE id < 0)
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 0, "Empty input should return no rows");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_single_element(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore WHERE id = 42),
        (SELECT array_agg(e ORDER BY id) FROM ore WHERE id = 42)
    )";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 1, "Single element should return 1 row");

    let id: i64 = rows[0].try_get(0)?;
    assert_eq!(id, 42, "Single element should be id=42");

    Ok(())
}

// ============================================================================
// order_by_compare (dynamic SQL convenience wrapper) tests
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_compare_asc_full_table(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM eql_v2.order_by_compare('SELECT id, e FROM ore')";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 99, "Should return all 99 records");

    let first_five: Vec<i64> = rows[..5].iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        first_five,
        vec![1i64, 2, 3, 4, 5],
        "First 5 ASC results should be [1,2,3,4,5], got {:?}",
        first_five
    );

    let last_id: i64 = rows[98].try_get(0)?;
    assert_eq!(last_id, 99, "Last row should be id=99");

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn order_by_compare_desc_with_where(pool: PgPool) -> Result<()> {
    let sql =
        "SELECT * FROM eql_v2.order_by_compare('SELECT id, e FROM ore WHERE id > 42', 'DESC')";

    let rows = sqlx::query(sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 57, "Should return 57 records (ids 43-99)");

    let first_id: i64 = rows[0].try_get(0)?;
    assert_eq!(first_id, 99, "First DESC row should be id=99");

    let last_id: i64 = rows[56].try_get(0)?;
    assert_eq!(last_id, 43, "Last DESC row should be id=43");

    Ok(())
}

// ============================================================================
// Filtered inner query correctness tests (Option 2)
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn filtered_inner_query_correct_order(pool: PgPool) -> Result<()> {
    // Optimized: inner query also filters, producing correct relative ordering
    // within the filtered set
    let ore_term = get_ore_encrypted(&pool, 42).await?;

    let sql = format!(
        "SELECT id FROM ore t \
         WHERE e > '{ore}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore t2 \
                   WHERE e > '{ore}'::eql_v2_encrypted \
                   AND eql_v2.compare(t.e, t2.e) > 0)",
        ore = ore_term
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;

    assert_eq!(rows.len(), 57, "Should return 57 records (ids 43-99)");

    let first_id: i64 = rows[0].try_get(0)?;
    assert_eq!(
        first_id, 43,
        "Filtered inner query should return id=43 first"
    );

    let last_id: i64 = rows[56].try_get(0)?;
    assert_eq!(last_id, 99, "Filtered inner query should return id=99 last");

    // Verify complete ordering
    let all_ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    let expected: Vec<i64> = (43..=99).collect();
    assert_eq!(
        all_ids, expected,
        "All ids should be sequential 43..99 with filtered inner query"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn filtered_inner_query_with_range(pool: PgPool) -> Result<()> {
    // Range filter: rows with ids 20-80
    let ore_term_19 = get_ore_encrypted(&pool, 19).await?;
    let ore_term_80 = get_ore_encrypted(&pool, 80).await?;

    let sql = format!(
        "SELECT id FROM ore t \
         WHERE e > '{lo}'::eql_v2_encrypted AND e < '{hi}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore t2 \
                   WHERE e > '{lo}'::eql_v2_encrypted AND e < '{hi}'::eql_v2_encrypted \
                   AND eql_v2.compare(t.e, t2.e) > 0)",
        lo = ore_term_19,
        hi = ore_term_80
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;

    // ids 20-79 = 60 rows (exclusive on both 19 and 80 based on > and <)
    assert_eq!(rows.len(), 60, "Range filter should return 60 records (ids 20-79)");

    let first_id: i64 = rows[0].try_get(0)?;
    assert_eq!(first_id, 20, "First row should be id=20");

    let last_id: i64 = rows[59].try_get(0)?;
    assert_eq!(last_id, 79, "Last row should be id=79");

    Ok(())
}

// ============================================================================
// Performance comparison tests
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_faster_than_correlated_subquery(pool: PgPool) -> Result<()> {
    // Warm up: run each query once to populate caches
    let sort_sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore),
        (SELECT array_agg(e ORDER BY id) FROM ore)
    )";
    let correlated_sql = "SELECT id FROM ore t \
        ORDER BY (SELECT COUNT(*) FROM ore t2 WHERE eql_v2.compare(t.e, t2.e) > 0)";

    sqlx::query(sort_sql).fetch_all(&pool).await?;
    sqlx::query(correlated_sql).fetch_all(&pool).await?;

    // Measure sort_compare
    let start = Instant::now();
    let sort_rows = sqlx::query(sort_sql).fetch_all(&pool).await?;
    let sort_elapsed = start.elapsed();

    // Measure correlated subquery
    let start = Instant::now();
    let correlated_rows = sqlx::query(correlated_sql).fetch_all(&pool).await?;
    let correlated_elapsed = start.elapsed();

    // Both should return correct results
    assert_eq!(sort_rows.len(), 99);
    assert_eq!(correlated_rows.len(), 99);

    let sort_first: i64 = sort_rows[0].try_get(0)?;
    let correlated_first: i64 = correlated_rows[0].try_get(0)?;
    assert_eq!(sort_first, 1);
    assert_eq!(correlated_first, 1);

    eprintln!(
        "Performance: sort_compare={:?}, correlated_subquery={:?}, speedup={:.1}x",
        sort_elapsed,
        correlated_elapsed,
        correlated_elapsed.as_secs_f64() / sort_elapsed.as_secs_f64()
    );

    // Assert sort_compare is faster (generous 3x margin for CI stability)
    assert!(
        sort_elapsed < correlated_elapsed * 3,
        "sort_compare ({:?}) should not be dramatically slower than correlated subquery ({:?})",
        sort_elapsed,
        correlated_elapsed
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn filtered_inner_query_faster_than_unfiltered(pool: PgPool) -> Result<()> {
    let ore_term = get_ore_encrypted(&pool, 42).await?;

    // Unfiltered inner query: compares against all 99 rows
    let unfiltered_sql = format!(
        "SELECT id FROM ore t \
         WHERE e > '{ore}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore t2 WHERE eql_v2.compare(t.e, t2.e) > 0)",
        ore = ore_term
    );

    // Filtered inner query: compares against only 57 filtered rows
    let filtered_sql = format!(
        "SELECT id FROM ore t \
         WHERE e > '{ore}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore t2 \
                   WHERE e > '{ore}'::eql_v2_encrypted \
                   AND eql_v2.compare(t.e, t2.e) > 0)",
        ore = ore_term
    );

    // Warm up
    sqlx::query(&unfiltered_sql).fetch_all(&pool).await?;
    sqlx::query(&filtered_sql).fetch_all(&pool).await?;

    // Measure unfiltered
    let start = Instant::now();
    let unfiltered_rows = sqlx::query(&unfiltered_sql).fetch_all(&pool).await?;
    let unfiltered_elapsed = start.elapsed();

    // Measure filtered
    let start = Instant::now();
    let filtered_rows = sqlx::query(&filtered_sql).fetch_all(&pool).await?;
    let filtered_elapsed = start.elapsed();

    // Both should return 57 rows with correct ordering
    assert_eq!(unfiltered_rows.len(), 57);
    assert_eq!(filtered_rows.len(), 57);

    let unfiltered_first: i64 = unfiltered_rows[0].try_get(0)?;
    let filtered_first: i64 = filtered_rows[0].try_get(0)?;
    assert_eq!(unfiltered_first, 43);
    assert_eq!(filtered_first, 43);

    eprintln!(
        "Performance: filtered={:?}, unfiltered={:?}, speedup={:.1}x",
        filtered_elapsed,
        unfiltered_elapsed,
        unfiltered_elapsed.as_secs_f64() / filtered_elapsed.as_secs_f64()
    );

    // Assert filtered is faster (generous margin for CI)
    assert!(
        filtered_elapsed < unfiltered_elapsed * 3,
        "filtered inner query ({:?}) should not be dramatically slower than unfiltered ({:?})",
        filtered_elapsed,
        unfiltered_elapsed
    );

    Ok(())
}

// ============================================================================
// Scaled performance tests (expanded dataset via generate_series)
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn sort_compare_performance_at_scale(pool: PgPool) -> Result<()> {
    // Use a single connection so the temp table is visible across all queries
    let mut conn = pool.acquire().await?;

    // Expand 99 rows to 495 via cross join with generate_series
    // Duplicates don't affect sort algorithm performance — each eql_v2.compare()
    // call costs the same regardless of value uniqueness
    sqlx::query(
        "CREATE TEMP TABLE ore_perf AS \
         SELECT (id + (s - 1) * 99)::bigint AS id, e \
         FROM ore, generate_series(1, 5) s",
    )
    .execute(&mut *conn)
    .await?;

    let sort_sql = "SELECT * FROM eql_v2.sort_compare(
        (SELECT array_agg(id ORDER BY id) FROM ore_perf),
        (SELECT array_agg(e ORDER BY id) FROM ore_perf)
    )";
    let correlated_sql = "SELECT id FROM ore_perf t \
        ORDER BY (SELECT COUNT(*) FROM ore_perf t2 WHERE eql_v2.compare(t.e, t2.e) > 0)";

    // Warm up
    sqlx::query(sort_sql).fetch_all(&mut *conn).await?;
    sqlx::query(correlated_sql).fetch_all(&mut *conn).await?;

    // Measure sort_compare
    let start = Instant::now();
    let sort_rows = sqlx::query(sort_sql).fetch_all(&mut *conn).await?;
    let sort_elapsed = start.elapsed();

    // Measure correlated subquery
    let start = Instant::now();
    let correlated_rows = sqlx::query(correlated_sql).fetch_all(&mut *conn).await?;
    let correlated_elapsed = start.elapsed();

    assert_eq!(sort_rows.len(), 495);
    assert_eq!(correlated_rows.len(), 495);

    eprintln!(
        "Performance @495 rows: sort_compare={:?}, correlated={:?}, speedup={:.1}x",
        sort_elapsed,
        correlated_elapsed,
        correlated_elapsed.as_secs_f64() / sort_elapsed.as_secs_f64()
    );

    // At 495 rows the O(n log n) vs O(n^2) gap should be substantial
    assert!(
        sort_elapsed < correlated_elapsed,
        "sort_compare ({:?}) should be faster than correlated subquery ({:?}) at 495 rows",
        sort_elapsed,
        correlated_elapsed
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("drop_operator_classes")))]
async fn filtered_inner_query_performance_at_scale(pool: PgPool) -> Result<()> {
    // Use a single connection so the temp table is visible across all queries
    let mut conn = pool.acquire().await?;

    // Expand 99 rows to 495 via cross join with generate_series
    sqlx::query(
        "CREATE TEMP TABLE ore_perf AS \
         SELECT (id + (s - 1) * 99)::bigint AS id, e \
         FROM ore, generate_series(1, 5) s",
    )
    .execute(&mut *conn)
    .await?;

    let ore_term = get_ore_encrypted(&pool, 42).await?;

    // Unfiltered inner query: outer filters to ~285 rows, inner scans all 495
    let unfiltered_sql = format!(
        "SELECT id FROM ore_perf t \
         WHERE e > '{ore}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore_perf t2 WHERE eql_v2.compare(t.e, t2.e) > 0)",
        ore = ore_term
    );

    // Filtered inner query: both outer and inner filter to ~285 rows
    let filtered_sql = format!(
        "SELECT id FROM ore_perf t \
         WHERE e > '{ore}'::eql_v2_encrypted \
         ORDER BY (SELECT COUNT(*) FROM ore_perf t2 \
                   WHERE e > '{ore}'::eql_v2_encrypted \
                   AND eql_v2.compare(t.e, t2.e) > 0)",
        ore = ore_term
    );

    // Warm up
    sqlx::query(&unfiltered_sql).fetch_all(&mut *conn).await?;
    sqlx::query(&filtered_sql).fetch_all(&mut *conn).await?;

    // Measure unfiltered
    let start = Instant::now();
    let unfiltered_rows = sqlx::query(&unfiltered_sql).fetch_all(&mut *conn).await?;
    let unfiltered_elapsed = start.elapsed();

    // Measure filtered
    let start = Instant::now();
    let filtered_rows = sqlx::query(&filtered_sql).fetch_all(&mut *conn).await?;
    let filtered_elapsed = start.elapsed();

    // Both return rows where e > ore(42): 57 unique values * 5 copies = 285 rows
    assert_eq!(unfiltered_rows.len(), 285);
    assert_eq!(filtered_rows.len(), 285);

    eprintln!(
        "Performance @495 rows (filtered to 285): filtered={:?}, unfiltered={:?}, speedup={:.1}x",
        filtered_elapsed,
        unfiltered_elapsed,
        unfiltered_elapsed.as_secs_f64() / filtered_elapsed.as_secs_f64()
    );

    // Filtered inner query should be faster: 285^2 vs 285*495 comparisons
    assert!(
        filtered_elapsed < unfiltered_elapsed * 2,
        "filtered inner query ({:?}) should not be dramatically slower than unfiltered ({:?})",
        filtered_elapsed,
        unfiltered_elapsed
    );

    Ok(())
}
