//! Operator class tests for `eql_v3.ore_cllw` (the self-contained v3 SEM fork).
//!
//! Mirrors `ore_cllw_opclass_tests.rs` (which covers `eql_v2.ore_cllw`) for the
//! hand-written `eql_v3` copy under `src/v3/sem/ore_cllw/`. Because v3 is a fork,
//! not generated from v2, its comparator, operators, opclass wiring, and extractor
//! NULL semantics can drift independently — the existing v3 coverage is only
//! pg_proc inlinability metadata (`ore_cllw_opclass_tests.rs::backing_functions_are_inlinable`
//! and `encrypted_domain/family/inlinability.rs`), which would not catch a
//! behavioural regression. This file closes that gap.
//!
//! Validates that:
//! - the same-type comparison operators (`=`, `<>`, `<`, `<=`, `>`, `>=`) on
//!   `eql_v3.ore_cllw` reduce to `compare_ore_cllw_term(a, b) <op> 0` and return
//!   the correct semantics under the CLLW per-byte protocol;
//! - the leading domain-tag byte (`0x00` numeric, `0x01` string) produces the
//!   right cross-domain ordering (numeric < string);
//! - the btree operator class `eql_v3.ore_cllw_ops` is registered as
//!   `DEFAULT FOR TYPE`, so functional btree indexes on `eql_v3.ore_cllw(col)`
//!   pick it up without an explicit opclass annotation;
//! - the planner engages the functional index for `ORDER BY ... LIMIT n`
//!   (Index Scan, not Sort) and for a `WHERE` range qual (Index Cond).
//!
//! **v3 surface differences from v2** (confirmed in `src/v3/sem/ore_cllw/`):
//! - composite is `eql_v3.ore_cllw AS (bytes bytea)`; literals via
//!   `ROW(decode('<hex>','hex'))::eql_v3.ore_cllw`.
//! - there is only ONE extractor overload, `eql_v3.ore_cllw(jsonb)` — v3 has no
//!   encrypted-column type, no `ste_vec_entry` domain, and no `->` selector. So
//!   the functional-index tests build on a plain `jsonb` column via
//!   `eql_v3.ore_cllw(value)`, and the v2 `..._via_arrow_chain` test has no v3
//!   analogue.
//!
//! The test data is hand-crafted byte strings rather than real CLLW ciphertexts;
//! sufficient for opclass-wiring and protocol assertions (the per-byte protocol
//! is identical to v2's, which `ore_cllw_opclass_tests.rs` also exercises).

use anyhow::Result;
use sqlx::PgPool;

// Helper: construct an `eql_v3.ore_cllw` literal from a hex string.
// Format: `[tag_byte][cllw_ciphertext_bytes]`.
fn ore_cllw(hex: &str) -> String {
    format!("ROW(decode('{hex}', 'hex'))::eql_v3.ore_cllw")
}

// ===========================================================================
// Operator wiring + CLLW per-byte semantics
// ===========================================================================

#[sqlx::test]
async fn eq_same_bytes(pool: PgPool) -> Result<()> {
    let a = ore_cllw("00aabbcc");
    let result: bool = sqlx::query_scalar(&format!("SELECT {a} = {a}"))
        .fetch_one(&pool)
        .await?;
    assert!(result, "= should be true for identical ore_cllw values");
    Ok(())
}

#[sqlx::test]
async fn neq_different_bytes(pool: PgPool) -> Result<()> {
    let a = ore_cllw("00aabbcc");
    let b = ore_cllw("00aabbcd");
    let result: bool = sqlx::query_scalar(&format!("SELECT {a} <> {b}"))
        .fetch_one(&pool)
        .await?;
    assert!(result, "<> should be true for different ore_cllw values");
    Ok(())
}

#[sqlx::test]
async fn lt_within_domain(pool: PgPool) -> Result<()> {
    // Both numeric domain (tag 0x00). Differ at byte 1: a=0x01, b=0x02.
    // CLLW: at diff position, y+1 == x means x>y. Here y=0x02 (b), x=0x01 (a).
    // y+1 = 0x03 != x → x < y → a < b.
    let a = ore_cllw("0001");
    let b = ore_cllw("0002");
    let result: bool = sqlx::query_scalar(&format!("SELECT {a} < {b}"))
        .fetch_one(&pool)
        .await?;
    assert!(result, "< should be true under the CLLW per-byte protocol");
    Ok(())
}

#[sqlx::test]
async fn gt_within_domain(pool: PgPool) -> Result<()> {
    // Reverse of lt_within_domain: differ at byte 1, a=0x02, b=0x01.
    // y+1 = 0x02 = x → x > y → a > b.
    let a = ore_cllw("0002");
    let b = ore_cllw("0001");
    let result: bool = sqlx::query_scalar(&format!("SELECT {a} > {b}"))
        .fetch_one(&pool)
        .await?;
    assert!(result, "> should be true under the CLLW per-byte protocol");
    Ok(())
}

#[sqlx::test]
async fn lte_includes_equal(pool: PgPool) -> Result<()> {
    let a = ore_cllw("0001");
    let b = ore_cllw("0002");
    for sql in [format!("SELECT {a} <= {b}"), format!("SELECT {a} <= {a}")] {
        let r: bool = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert!(r, "<= true for both less-than and equal: {sql}");
    }
    Ok(())
}

#[sqlx::test]
async fn gte_includes_equal(pool: PgPool) -> Result<()> {
    let a = ore_cllw("0002");
    let b = ore_cllw("0001");
    for sql in [format!("SELECT {a} >= {b}"), format!("SELECT {a} >= {a}")] {
        let r: bool = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert!(r, ">= true for both greater-than and equal: {sql}");
    }
    Ok(())
}

// ===========================================================================
// Cross-domain ordering via the leading tag byte
// ===========================================================================

#[sqlx::test]
async fn numeric_sorts_before_string_via_tag_byte(pool: PgPool) -> Result<()> {
    // Numeric tag = 0x00, string tag = 0x01. They differ at byte 0.
    // y(string)=0x01, x(numeric)=0x00. y+1=0x02 != x → numeric < string.
    let numeric = ore_cllw("00ffffff");
    let string = ore_cllw("01000000");
    let result: bool = sqlx::query_scalar(&format!("SELECT {numeric} < {string}"))
        .fetch_one(&pool)
        .await?;
    assert!(
        result,
        "numeric (tag 0x00) should sort before string (tag 0x01)"
    );

    let reverse: bool = sqlx::query_scalar(&format!("SELECT {string} > {numeric}"))
        .fetch_one(&pool)
        .await?;
    assert!(
        reverse,
        "string (tag 0x01) should sort after numeric (tag 0x00)"
    );
    Ok(())
}

// ===========================================================================
// Opclass registration: DEFAULT FOR TYPE
// ===========================================================================

#[sqlx::test]
async fn opclass_is_default_for_type(pool: PgPool) -> Result<()> {
    // Confirms `eql_v3.ore_cllw_ops` is the default btree opclass for
    // `eql_v3.ore_cllw`. Without this, functional btree indexes on the type
    // would need an explicit `USING btree (... eql_v3.ore_cllw_ops)` annotation.
    let is_default: bool = sqlx::query_scalar(
        "SELECT opcdefault
         FROM pg_opclass oc
         JOIN pg_namespace n ON n.oid = oc.opcnamespace
         WHERE n.nspname = 'eql_v3'
           AND oc.opcname = 'ore_cllw_ops'",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        is_default,
        "eql_v3.ore_cllw_ops should be DEFAULT FOR TYPE eql_v3.ore_cllw"
    );
    Ok(())
}

// ===========================================================================
// Extractor NULL semantics — `eql_v3.ore_cllw(jsonb)` (the single overload)
// ===========================================================================

#[sqlx::test]
async fn ore_cllw_extractor_returns_null_when_oc_absent(pool: PgPool) -> Result<()> {
    let is_null: bool = sqlx::query_scalar(
        "SELECT eql_v3.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"hm\":\"abc\"}'::jsonb) IS NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        is_null,
        "eql_v3.ore_cllw(jsonb) should return SQL NULL when `oc` is absent"
    );
    Ok(())
}

#[sqlx::test]
async fn ore_cllw_extractor_returns_composite_when_oc_present(pool: PgPool) -> Result<()> {
    let is_null: bool = sqlx::query_scalar(
        "SELECT eql_v3.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"oc\":\"deadbeef\"}'::jsonb) IS NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        !is_null,
        "eql_v3.ore_cllw(jsonb) should NOT be NULL when `oc` is present"
    );
    Ok(())
}

#[sqlx::test]
async fn comparator_returns_null_on_null_composite(pool: PgPool) -> Result<()> {
    // The comparator returns SQL NULL (not a raise) when handed a SQL-NULL
    // composite — the shape the extractor produces for a missing-`oc` row, which
    // btree's NULL handling then filters from range queries. (A non-NULL
    // composite with a NULL `bytes` field would raise instead, but that shape is
    // unreachable via the extractor.)
    let cmp: Option<i32> = sqlx::query_scalar(
        "SELECT eql_v3.compare_ore_cllw_term(\
           eql_v3.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"hm\":\"abc\"}'::jsonb), \
           eql_v3.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"oc\":\"00ff\"}'::jsonb)\
         )",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        cmp.is_none(),
        "compare_ore_cllw_term with a NULL composite should return SQL NULL"
    );
    Ok(())
}

// ===========================================================================
// Functional-index match: ORDER BY engages Index Scan, not Sort
//
// v3 has no encrypted-column type, so the index is built on a plain jsonb
// column via the single `eql_v3.ore_cllw(jsonb)` extractor overload.
// ===========================================================================

#[sqlx::test]
async fn functional_index_engages_for_order_by(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE ore_cllw_v3_test
           (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            value jsonb NOT NULL)",
    )
    .execute(&mut *tx)
    .await?;

    // Seed 20 rows with synthetic data: each `value` carries an `oc` field of
    // varying bytes (numeric domain tag, then a counter).
    for i in 0..20u8 {
        let hex = format!("00{:02x}", i);
        let sql = format!(
            "INSERT INTO ore_cllw_v3_test(value) \
             VALUES (jsonb_build_object('oc', '{hex}'))"
        );
        sqlx::query(&sql).execute(&mut *tx).await?;
    }

    // Functional btree on the extractor — no opclass annotation needed because
    // `eql_v3.ore_cllw_ops` is DEFAULT FOR TYPE.
    sqlx::query(
        "CREATE INDEX ore_cllw_v3_test_idx
         ON ore_cllw_v3_test (eql_v3.ore_cllw(value))",
    )
    .execute(&mut *tx)
    .await?;

    // Force the planner to prefer the index even on a tiny fixture (seq scan is
    // usually cheaper at 20 rows).
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    let explain_rows = sqlx::query_scalar::<_, String>(
        "EXPLAIN SELECT id FROM ore_cllw_v3_test \
         ORDER BY eql_v3.ore_cllw(value) LIMIT 5",
    )
    .fetch_all(&mut *tx)
    .await?;
    let explain = explain_rows.join("\n");

    assert!(
        explain.contains("Index Scan") || explain.contains("Index Only Scan"),
        "Expected Index Scan via ore_cllw_v3_test_idx, got:\n{explain}"
    );
    assert!(
        !explain.contains("Sort"),
        "Expected no Sort node (index walks in order), got:\n{explain}"
    );

    tx.rollback().await?;
    Ok(())
}

// ===========================================================================
// Functional-index match: WHERE-clause range engages Index Cond
// ===========================================================================

#[sqlx::test]
async fn functional_index_engages_for_where_range(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE ore_cllw_v3_where_test
           (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            value jsonb NOT NULL)",
    )
    .execute(&mut *tx)
    .await?;

    // Seed 100 rows so the planner can plausibly prefer an index scan.
    for i in 0..100u8 {
        let hex = format!("00{:02x}", i);
        let sql = format!(
            "INSERT INTO ore_cllw_v3_where_test(value) \
             VALUES (jsonb_build_object('oc', '{hex}'))"
        );
        sqlx::query(&sql).execute(&mut *tx).await?;
    }

    sqlx::query(
        "CREATE INDEX ore_cllw_v3_where_test_idx
         ON ore_cllw_v3_where_test (eql_v3.ore_cllw(value))",
    )
    .execute(&mut *tx)
    .await?;

    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    let explain_rows = sqlx::query_scalar::<_, String>(
        "EXPLAIN SELECT id FROM ore_cllw_v3_where_test \
         WHERE eql_v3.ore_cllw(value) \
             < eql_v3.ore_cllw('{\"oc\":\"00aa\"}'::jsonb)",
    )
    .fetch_all(&mut *tx)
    .await?;
    let explain = explain_rows.join("\n");

    // Accept either Index Scan or Bitmap Index Scan — both are valid
    // index-engaging plans for a range qual. The key negative: NO Seq Scan.
    assert!(
        explain.contains("Index Scan") || explain.contains("Bitmap Index Scan"),
        "Expected Index Scan via ore_cllw_v3_where_test_idx for WHERE range, got:\n{explain}"
    );
    assert!(
        explain.contains("Index Cond"),
        "Expected Index Cond clause on the WHERE range, got:\n{explain}"
    );

    tx.rollback().await?;
    Ok(())
}
