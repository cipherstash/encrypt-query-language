//! Inlinability regression net (issue #199)
//!
//! Each test runs `EXPLAIN` on a query that should be served by a functional
//! index, and asserts that the index is in the plan. Failure means the
//! relevant operator wrapper has stopped inlining — which can happen if
//! someone adds `SET search_path` to the function (directly or via the
//! pinner), changes its `LANGUAGE`, drops `IMMUTABLE`, etc.
//!
//! These tests exist as a safety net **independent of the splinter
//! allowlist**: they catch any cause of inlining failure, not just
//! pinner-related ones. They were prompted by the silent regression risk
//! described in #199 (fixed by switching the pinner to opt-in semantics).
//!
//! All tests use the `bench` fixture (10K rows of encrypted text/int/bigint)
//! and the indexes defined in `bench_setup.sql`. The fixture pattern matches
//! `bench_plan_tests.rs`.

use anyhow::{Context, Result};
use eql_tests::{assert_uses_index, explain_query, get_bench_encrypted_text};
use sqlx::PgPool;

const BENCH_TEXT_HMAC_IDX: &str = "bench_text_hmac_idx";
const BENCH_TEXT_BLOOM_IDX: &str = "bench_text_bloom_idx";

// ---------------------------------------------------------------------------
// hmac_256-index inlining: `=` and `<>` operators
// ---------------------------------------------------------------------------

/// `WHERE col = val` must inline `eql_v2.=` to expose
/// `eql_v2.hmac_256(col) = eql_v2.hmac_256(val)` so the hash index matches.
///
/// Currently ignored because `eql_v2."="` is still LANGUAGE plpgsql on main.
/// PR #196 (Phase 1 operator inlining) flips it to LANGUAGE sql; un-ignore
/// when that lands.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "operator form needs #196 (Phase 1 inlining); direct hmac_256 expression is covered separately"]
async fn bench_eq_uses_hmac_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;
    let sql = format!(
        "SELECT id FROM bench WHERE encrypted_text = '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_HMAC_IDX)
        .await
        .context("`=` lost inlinability — eql_v2.\"=\" must remain LANGUAGE sql IMMUTABLE without SET search_path")?;
    Ok(())
}

/// `WHERE col <> val` should inline `eql_v2.<>` analogously.
///
/// The hash index supports equality but not inequality, so a Bitmap Index
/// Scan is unlikely; what matters here is that the plan references the
/// indexed expression `eql_v2.hmac_256(col)`, proving the wrapper inlined.
/// We assert by looking at the EXPLAIN text directly rather than relying on
/// the index name being mentioned by node type.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "operator form needs #196 (Phase 1 inlining); direct hmac_256 expression is covered separately"]
async fn bench_neq_inlines_to_hmac_expression(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;
    let sql = format!(
        "SELECT id FROM bench WHERE encrypted_text <> '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    let plan = explain_query(&pool, &sql).await?;
    assert!(
        plan.contains("eql_v2.hmac_256"),
        "`<>` lost inlinability — expected `eql_v2.hmac_256(...)` in EXPLAIN, got:\n{plan}"
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// bloom_filter-index inlining: `~~` (LIKE) and `~~*` (ILIKE) operators
// ---------------------------------------------------------------------------

/// `WHERE col ~~ pattern` must inline `eql_v2.~~` (and the `eql_v2.like`
/// helper it delegates to) so the planner sees
/// `eql_v2.bloom_filter(col) @> eql_v2.bloom_filter(pattern)` and matches
/// the GIN index.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "operator form needs #196 (Phase 1 inlining); direct bloom_filter expression is covered separately"]
async fn bench_like_uses_bloom_filter_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;
    let sql = format!(
        "SELECT id FROM bench WHERE encrypted_text ~~ '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_BLOOM_IDX)
        .await
        .context(
            "`~~` lost inlinability — eql_v2.\"~~\" and eql_v2.like must both remain \
             LANGUAGE sql IMMUTABLE without SET search_path so the chain unfolds to \
             `eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b)`",
        )?;
    Ok(())
}

/// `WHERE col ~~* pattern` (ILIKE) reuses the same `eql_v2.~~` implementation
/// as `~~`; case sensitivity lives in the bloom filter's match-index token
/// filters, not here. Same plan shape expected.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
#[ignore = "operator form needs #196 (Phase 1 inlining); direct bloom_filter expression is covered separately"]
async fn bench_ilike_uses_bloom_filter_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;
    let sql = format!(
        "SELECT id FROM bench WHERE encrypted_text ~~* '{}'::jsonb::eql_v2_encrypted",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_BLOOM_IDX)
        .await
        .context(
            "`~~*` lost inlinability — eql_v2.\"~~\" and eql_v2.ilike must both remain \
             LANGUAGE sql IMMUTABLE without SET search_path",
        )?;
    Ok(())
}

// ---------------------------------------------------------------------------
// Direct-expression inlining: jsonb_array, hmac_256, bloom_filter
// ---------------------------------------------------------------------------
//
// Even when called directly (not via an operator wrapper), these helpers
// must produce expressions the planner can match against functional indexes.
// `jsonb_array(col) @> ARRAY[...]` is exercised in
// `containment_with_index_tests.rs`; here we cover the two flat cases.

/// `WHERE eql_v2.hmac_256(col) = eql_v2.hmac_256(val)` directly — proves
/// the indexed expression matches even without the `=` operator wrapper.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn bench_direct_hmac_expression_uses_hash_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;
    let sql = format!(
        "SELECT id FROM bench WHERE eql_v2.hmac_256(encrypted_text) = \
         eql_v2.hmac_256('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_HMAC_IDX).await?;
    Ok(())
}

/// `WHERE eql_v2.bloom_filter(col) @> eql_v2.bloom_filter(val)` directly.
#[sqlx::test(fixtures(path = "../fixtures", scripts("bench_data", "bench_setup")))]
async fn bench_direct_bloom_filter_expression_uses_gin_index(pool: PgPool) -> Result<()> {
    let encrypted = get_bench_encrypted_text(&pool, 1).await?;
    let sql = format!(
        "SELECT id FROM bench WHERE eql_v2.bloom_filter(encrypted_text) @> \
         eql_v2.bloom_filter('{}'::jsonb::eql_v2_encrypted)",
        encrypted
    );
    assert_uses_index(&pool, &sql, BENCH_TEXT_BLOOM_IDX).await?;
    Ok(())
}
