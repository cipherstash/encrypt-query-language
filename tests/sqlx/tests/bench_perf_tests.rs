//! Tier 2 scheduled benchmarks.
//!
//! All tests are marked #[ignore] so regular CI doesn't run them. The scheduled
//! workflow in .github/workflows/benchmark.yml invokes them via
//! `cargo test --test bench_perf_tests -- --ignored`.
//!
//! Unlike Tier 1 tests, these use #[tokio::test] with a manual pool connected
//! via BENCH_DATABASE_URL against a pre-loaded 100K-row dataset.
//!
//! Each test:
//!   1. Resets pg_stat_statements
//!   2. Runs its query pattern 1000 times
//!   3. Reads pg_stat_statements for the match
//!   4. Appends a PerfResult to the shared accumulator
//!
//! A single `zz_write_reports` test (alphabetical last) flushes the accumulator
//! to JSON + Markdown. --test-threads=1 guarantees ordering.

use anyhow::Result;
use eql_tests::{
    append_result, ensure_pg_stat_statements, read_pg_stat_statements,
    reset_pg_stat_statements, write_reports, PerfResult,
};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

const RUNS: i64 = 1000;
const DATASET_ROWS: i64 = 100_000;

async fn connect() -> Result<PgPool> {
    let url = std::env::var("BENCH_DATABASE_URL")
        .expect("BENCH_DATABASE_URL must be set (run `mise run bench:full`)");
    let pool = PgPoolOptions::new()
        .max_connections(4)
        .connect(&url)
        .await?;
    ensure_pg_stat_statements(&pool).await?;
    Ok(pool)
}

/// P0 baseline: hmac_256 equality should stay ~0.5ms at 100K rows.
#[tokio::test]
#[ignore = "Tier 2: requires BENCH_DATABASE_URL and pre-loaded bench data"]
async fn hmac_256_equality() -> Result<()> {
    let pool = connect().await?;

    let encrypted: String = sqlx::query_scalar(
        "SELECT (encrypted_text).data::text FROM bench WHERE id = 1",
    )
    .fetch_one(&pool)
    .await?;

    reset_pg_stat_statements(&pool).await?;

    for _ in 0..RUNS {
        sqlx::query(
            "SELECT * FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256($1::jsonb::eql_v2_encrypted)",
        )
        .bind(&encrypted)
        .fetch_all(&pool)
        .await?;
    }

    let stats = read_pg_stat_statements(
        &pool,
        "%FROM bench WHERE eql_v2.hmac_256(encrypted_text) = eql_v2.hmac_256($%",
    )
    .await?;

    append_result(PerfResult {
        name: "hmac_256_equality".into(),
        priority: "P0".into(),
        runs: stats.calls,
        plan_type: "Index Scan".into(),
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });

    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P2: bloom_filter containment — expected ~3.35ms at 100K rows.
#[tokio::test]
#[ignore = "Tier 2: requires BENCH_DATABASE_URL and pre-loaded bench data"]
async fn bloom_filter_containment() -> Result<()> {
    let pool = connect().await?;
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(&pool).await?;

    reset_pg_stat_statements(&pool).await?;
    for _ in 0..RUNS {
        sqlx::query(
            "SELECT * FROM bench WHERE eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter($1::jsonb::eql_v2_encrypted)",
        )
        .bind(&encrypted)
        .fetch_all(&pool).await?;
    }
    let stats = read_pg_stat_statements(
        &pool,
        "%eql_v2.bloom_filter(encrypted_text) @> eql_v2.bloom_filter($%",
    ).await?;

    append_result(PerfResult {
        name: "bloom_filter_containment".into(),
        priority: "P2".into(),
        runs: stats.calls,
        plan_type: "Bitmap Index Scan".into(),
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P0: eql_cast equality — currently seq scans (CIP-2831). Report records the
/// actual plan + timing so the number is visible week-over-week until the fix ships.
#[tokio::test]
#[ignore = "Tier 2: requires BENCH_DATABASE_URL and pre-loaded bench data"]
async fn eql_cast_equality() -> Result<()> {
    let pool = connect().await?;
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_text).data::text FROM bench WHERE id = 1")
            .fetch_one(&pool).await?;

    reset_pg_stat_statements(&pool).await?;
    for _ in 0..RUNS {
        sqlx::query("SELECT * FROM bench WHERE encrypted_text = $1::jsonb::eql_v2_encrypted")
            .bind(&encrypted)
            .fetch_all(&pool).await?;
    }
    let stats = read_pg_stat_statements(
        &pool,
        "%FROM bench WHERE encrypted_text = $%::jsonb::eql_v2_encrypted%",
    ).await?;

    append_result(PerfResult {
        name: "eql_cast_equality".into(),
        priority: "P0".into(),
        runs: stats.calls,
        plan_type: "Seq Scan".into(),
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P0: ORE equality via operator class — currently seq scans (CIP-2831).
#[tokio::test]
#[ignore = "Tier 2: requires BENCH_DATABASE_URL and pre-loaded bench data"]
async fn ore_equality_opclass() -> Result<()> {
    let pool = connect().await?;
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_int).data::text FROM bench WHERE id = 1")
            .fetch_one(&pool).await?;

    reset_pg_stat_statements(&pool).await?;
    for _ in 0..RUNS {
        sqlx::query("SELECT * FROM bench WHERE encrypted_int = $1::jsonb::eql_v2_encrypted")
            .bind(&encrypted)
            .fetch_all(&pool).await?;
    }
    let stats = read_pg_stat_statements(
        &pool,
        "%FROM bench WHERE encrypted_int = $%::jsonb::eql_v2_encrypted%",
    ).await?;

    append_result(PerfResult {
        name: "ore_equality_opclass".into(),
        priority: "P0".into(),
        runs: stats.calls,
        plan_type: "Seq Scan".into(),
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P1: ORE range < with LIMIT — expected ~1.93ms at 100K rows.
#[tokio::test]
#[ignore = "Tier 2: requires BENCH_DATABASE_URL and pre-loaded bench data"]
async fn ore_range_lt_limit() -> Result<()> {
    let pool = connect().await?;
    let encrypted: String =
        sqlx::query_scalar("SELECT (encrypted_int).data::text FROM bench WHERE id = 50000")
            .fetch_one(&pool).await?;

    reset_pg_stat_statements(&pool).await?;
    for _ in 0..RUNS {
        sqlx::query(
            "SELECT * FROM bench WHERE encrypted_int < $1::jsonb::eql_v2_encrypted ORDER BY encrypted_int LIMIT 10",
        )
        .bind(&encrypted)
        .fetch_all(&pool).await?;
    }
    let stats = read_pg_stat_statements(
        &pool,
        "%FROM bench WHERE encrypted_int < $%ORDER BY encrypted_int LIMIT %",
    ).await?;

    append_result(PerfResult {
        name: "ore_range_lt_limit".into(),
        priority: "P1".into(),
        runs: stats.calls,
        plan_type: "Index Scan".into(),
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// P1: ORE ORDER BY encrypted_int LIMIT 10 — design doc observes ~543ms at 10K,
/// so expect several seconds at 100K. Report captures actual number.
#[tokio::test]
#[ignore = "Tier 2: requires BENCH_DATABASE_URL and pre-loaded bench data"]
async fn ore_order_by_limit() -> Result<()> {
    let pool = connect().await?;

    reset_pg_stat_statements(&pool).await?;
    for _ in 0..RUNS {
        sqlx::query("SELECT * FROM bench ORDER BY encrypted_int LIMIT 10")
            .fetch_all(&pool).await?;
    }
    let stats = read_pg_stat_statements(
        &pool,
        "%FROM bench ORDER BY encrypted_int LIMIT %",
    ).await?;

    append_result(PerfResult {
        name: "ore_order_by_limit".into(),
        priority: "P1".into(),
        runs: stats.calls,
        plan_type: "Index Scan".into(),
        mean_ms: stats.mean_exec_time,
        stddev_ms: stats.stddev_exec_time,
        total_ms: stats.total_exec_time,
    });
    assert_eq!(stats.calls, RUNS, "expected {RUNS} recorded calls");
    Ok(())
}

/// Alphabetical-last test — flushes accumulated results to disk.
/// Requires `--test-threads=1` so it runs after all benchmark cases.
#[tokio::test]
#[ignore = "Tier 2: report writer, runs last under --test-threads=1"]
async fn zz_write_reports() -> Result<()> {
    let pool = connect().await?;
    let pg_version: String =
        sqlx::query_scalar("SHOW server_version_num").fetch_one(&pool).await?;
    // server_version_num is "170004" etc — take the major version digits
    let pg_major = pg_version
        .get(..pg_version.len().saturating_sub(4))
        .unwrap_or(&pg_version)
        .to_string();

    let date = std::env::var("BENCH_REPORT_DATE").unwrap_or_else(|_| today_utc());
    let output_dir = std::env::var("BENCH_REPORT_DIR")
        .unwrap_or_else(|_| "../../tests/benchmarks/reports".into());
    let (json, md) = write_reports(&output_dir, &date, &pg_major, DATASET_ROWS)?;
    eprintln!("wrote {} and {}", json.display(), md.display());
    Ok(())
}

fn today_utc() -> String {
    // Avoid adding the `chrono` dep; shell out to `date -u` for UTC.
    let out = std::process::Command::new("date")
        .args(["-u", "+%Y-%m-%d"])
        .output()
        .expect("invoking date");
    String::from_utf8(out.stdout).unwrap().trim().to_string()
}
