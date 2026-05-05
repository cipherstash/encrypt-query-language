//! Benchmark data verification tests
//!
//! Validates bench_data fixture (10K rows) and bench_setup fixture (indexes):
//! - 10K rows seeded correctly across 3 encrypted columns
//! - Index terms (hmac, bloom, ORE) are extractable
//! - Indexes are used by the query planner (EXPLAIN assertions)
//! - Sequential scan baseline without indexes

use anyhow::Result;
use eql_tests::{analyze_table, assert_uses_index, assert_uses_seq_scan, explain_query};
use sqlx::PgPool;

const BENCH_ROW_COUNT: i64 = 10000;

async fn fetch_sample_encrypted_text(pool: &PgPool) -> Result<String> {
    Ok(
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(pool)
            .await?,
    )
}

// ========== Data Integrity Tests ==========

/// Verify fixture seeded exactly 10K rows
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_table_has_expected_row_count(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM bench")
        .fetch_one(&pool)
        .await?;
    assert_eq!(
        count.0, BENCH_ROW_COUNT,
        "bench table should have 10000 rows"
    );
    Ok(())
}

/// Verify all three columns have non-null encrypted data
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_columns_are_populated(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench
         WHERE encrypted_text IS NOT NULL
           AND encrypted_int IS NOT NULL
           AND encrypted_bigint IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        count.0, BENCH_ROW_COUNT,
        "all rows should have non-null encrypted columns"
    );
    Ok(())
}

/// Verify hmac_256 index terms are extractable from encrypted_text
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_encrypted_text_has_hmac_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.hmac_256(encrypted_text) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        count.0, BENCH_ROW_COUNT,
        "all rows should have hmac_256 index terms"
    );
    Ok(())
}

/// Verify bloom_filter index terms are extractable from encrypted_text
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_encrypted_text_has_bloom_filter_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.bloom_filter(encrypted_text) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        count.0, BENCH_ROW_COUNT,
        "all rows should have bloom_filter index terms"
    );
    Ok(())
}

/// Verify ORE terms are extractable from encrypted_int (3 of 5 indexes are ORE btree)
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_encrypted_int_has_ore_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.ore_block_u64_8_256(encrypted_int) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        count.0, BENCH_ROW_COUNT,
        "all rows should have ORE block index terms"
    );
    Ok(())
}

/// Verify ORE terms are extractable from encrypted_bigint
///
/// Both int and bigint columns use the same eql_v2_encrypted type and ob index structure.
/// These tests verify that data seeding populated both columns, not that encoding differs.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_encrypted_bigint_has_ore_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.ore_block_u64_8_256(encrypted_bigint) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        count.0, BENCH_ROW_COUNT,
        "all rows should have ORE block index terms"
    );
    Ok(())
}

// ========== Index Usage Tests (with fixture) ==========

/// Verify hash index is used for hmac_256 equality lookup
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_hmac_equality_uses_hash_index(pool: PgPool) -> Result<()> {
    let encrypted = fetch_sample_encrypted_text(&pool).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    assert_uses_index(&pool, &sql, "bench_text_hmac_idx").await?;
    Ok(())
}

/// Verify btree index is used for ORDER BY with LIMIT on encrypted_int
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_ore_order_uses_btree_index(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM bench ORDER BY encrypted_int LIMIT 10";
    assert_uses_index(&pool, sql, "bench_int_ore_idx").await?;
    Ok(())
}

/// Verify GIN index is used for bloom_filter containment
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_bloom_containment_uses_gin_index(pool: PgPool) -> Result<()> {
    let encrypted = fetch_sample_encrypted_text(&pool).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    assert_uses_index(&pool, &sql, "bench_text_bloom_idx").await?;
    Ok(())
}

/// Verify btree index is used for ORDER BY with LIMIT on encrypted_text
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_ore_text_order_uses_btree_index(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM bench ORDER BY encrypted_text LIMIT 10";
    assert_uses_index(&pool, sql, "bench_text_ore_idx").await?;
    Ok(())
}

/// Verify btree index is used for ORDER BY with LIMIT on encrypted_bigint
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_ore_bigint_order_uses_btree_index(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM bench ORDER BY encrypted_bigint LIMIT 10";
    assert_uses_index(&pool, sql, "bench_bigint_ore_idx").await?;
    Ok(())
}

/// Verify sequential scan without indexes (before/after pattern sanity check)
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data")))]
#[cfg_attr(
    not(feature = "bench"),
    ignore = "perf-bench: gated, run via mise test:bench"
)]
async fn bench_hmac_without_index_uses_seq_scan(pool: PgPool) -> Result<()> {
    analyze_table(&pool, "bench").await?;

    let encrypted = fetch_sample_encrypted_text(&pool).await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    let explain = explain_query(&pool, &sql).await?;
    assert_uses_seq_scan(&explain);
    Ok(())
}
