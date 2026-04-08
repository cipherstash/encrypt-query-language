//! Benchmark data verification tests
//!
//! Validates migration 007_install_bench_data.sql and bench_setup fixture:
//! - 10K rows seeded correctly across 3 encrypted columns
//! - Index terms (hmac, bloom, ORE) are extractable
//! - Indexes are used by the query planner (EXPLAIN assertions)
//! - Sequential scan baseline without indexes

use anyhow::Result;
use eql_tests::{analyze_table, assert_uses_index, assert_uses_seq_scan, explain_query};
use sqlx::PgPool;

// ========== Data Integrity Tests ==========

/// Verify migration seeded exactly 10K rows
#[sqlx::test]
async fn bench_table_has_expected_row_count(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM bench")
        .fetch_one(&pool)
        .await?;
    assert_eq!(count.0, 10000, "bench table should have 10000 rows");
    Ok(())
}

/// Verify all three columns have non-null encrypted data
#[sqlx::test]
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
        count.0, 10000,
        "all rows should have non-null encrypted columns"
    );
    Ok(())
}

/// Verify hmac_256 index terms are extractable from encrypted_text
#[sqlx::test]
async fn bench_encrypted_text_has_hmac_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.hmac_256(encrypted_text) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(count.0, 10000, "all rows should have hmac_256 index terms");
    Ok(())
}

/// Verify bloom_filter index terms are extractable from encrypted_text
#[sqlx::test]
async fn bench_encrypted_text_has_bloom_filter_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.bloom_filter(encrypted_text) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        count.0, 10000,
        "all rows should have bloom_filter index terms"
    );
    Ok(())
}

/// Verify ORE terms are extractable from encrypted_int (3 of 5 indexes are ORE btree)
#[sqlx::test]
async fn bench_encrypted_int_has_ore_terms(pool: PgPool) -> Result<()> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM bench WHERE eql_v2.ore_block_u64_8_256(encrypted_int) IS NOT NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(count.0, 10000, "all rows should have ORE block index terms");
    Ok(())
}

// ========== Index Usage Tests (with fixture) ==========

/// Verify hash index is used for hmac_256 equality lookup
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_setup")))]
async fn bench_hmac_equality_uses_hash_index(pool: PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(&pool)
            .await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    assert_uses_index(&pool, &sql, "bench_text_hmac_idx").await?;
    Ok(())
}

/// Verify btree index is used for ORDER BY with LIMIT on encrypted_int
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_setup")))]
async fn bench_ore_order_uses_btree_index(pool: PgPool) -> Result<()> {
    let sql = "SELECT * FROM bench ORDER BY encrypted_int LIMIT 10";
    assert_uses_index(&pool, sql, "bench_int_ore_idx").await?;
    Ok(())
}

/// Verify GIN index is used for bloom_filter containment
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_setup")))]
async fn bench_bloom_containment_uses_gin_index(pool: PgPool) -> Result<()> {
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(&pool)
            .await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    assert_uses_index(&pool, &sql, "bench_text_bloom_idx").await?;
    Ok(())
}

/// Verify sequential scan without indexes (before/after pattern sanity check)
#[sqlx::test]
async fn bench_hmac_without_index_uses_seq_scan(pool: PgPool) -> Result<()> {
    analyze_table(&pool, "bench").await?;

    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(&pool)
            .await?;

    let sql = format!(
        "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    let explain = explain_query(&pool, &sql).await?;
    assert_uses_seq_scan(&explain);
    Ok(())
}
