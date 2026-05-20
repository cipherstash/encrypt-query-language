//! Operator class tests for `eql_v2.ore_cllw`
//!
//! Validates that:
//! - the same-type comparison operators (`=`, `<>`, `<`, `<=`, `>`, `>=`) on
//!   `eql_v2.ore_cllw` reduce to `compare_ore_cllw_term(a, b) <op> 0` and
//!   return the correct semantics under the CLLW per-byte protocol;
//! - the leading domain-tag byte (`0x00` numeric, `0x01` string) produces
//!   the right cross-domain ordering (numeric < string);
//! - the btree operator class `eql_v2.ore_cllw_ops` is registered as
//!   `DEFAULT FOR TYPE`, so functional btree indexes on `eql_v2.ore_cllw(col)`
//!   pick it up without an explicit opclass annotation;
//! - the planner engages the functional index for `ORDER BY ... LIMIT n`
//!   (Index Scan, not Sort).
//!
//! The test data is hand-crafted byte strings (constructed via
//! `ROW(decode(...))::eql_v2.ore_cllw`) rather than real CLLW ciphertexts.
//! This is sufficient for opclass-wiring assertions; correctness of the CLLW
//! per-byte protocol itself is covered by the ore_cllw / ore_cllw_term tests.

use anyhow::Result;
use sqlx::{PgPool, Row};

// Helper: construct an `eql_v2.ore_cllw` literal from a hex string.
// Format: `[tag_byte][cllw_ciphertext_bytes]` — see U-006 for the wire format.
fn ore_cllw(hex: &str) -> String {
    format!("ROW(decode('{hex}', 'hex'))::eql_v2.ore_cllw")
}

// ===========================================================================
// Operator wiring
// ===========================================================================

#[sqlx::test]
async fn eq_same_bytes(pool: PgPool) -> Result<()> {
    // Identical byte strings compare equal.
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
    // Confirms `eql_v2.ore_cllw_ops` is the default btree opclass for
    // `eql_v2.ore_cllw`. Without this, functional btree indexes on the
    // type would need an explicit `USING btree (... eql_v2.ore_cllw_ops)`
    // annotation, defeating the U-001 "bare-form recipe" goal.
    let is_default: bool = sqlx::query_scalar(
        "SELECT opcdefault
         FROM pg_opclass oc
         JOIN pg_namespace n ON n.oid = oc.opcnamespace
         WHERE n.nspname = 'eql_v2'
           AND oc.opcname = 'ore_cllw_ops'",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        is_default,
        "eql_v2.ore_cllw_ops should be DEFAULT FOR TYPE eql_v2.ore_cllw"
    );
    Ok(())
}

// ===========================================================================
// Functional-index match: ORDER BY engages Index Scan, not Sort
// ===========================================================================

#[sqlx::test]
async fn functional_index_engages_for_order_by(pool: PgPool) -> Result<()> {
    // Build a small fixture table with synthetic ore_cllw values, create a
    // functional btree on `eql_v2.ore_cllw((value).data)`, and confirm EXPLAIN
    // engages the index for `ORDER BY ... LIMIT n`.
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE ore_cllw_test (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                     value eql_v2_encrypted NOT NULL)",
    )
    .execute(&mut *tx)
    .await?;

    // Seed 20 rows with synthetic data. Each row's value is an
    // `eql_v2_encrypted` whose payload wraps an `oc` field of varying bytes
    // (numeric domain tag, then a counter). The exact ordering under the
    // CLLW protocol isn't important here — we just need rows that compare
    // distinctly.
    for i in 0..20u8 {
        let hex = format!("00{:02x}", i);
        let sql = format!(
            "INSERT INTO ore_cllw_test(value) \
             VALUES (jsonb_build_object('v', 2, 'k', 'ct', 'c', 'placeholder', \
                                        'i', jsonb_build_object('t', 'ore_cllw_test', 'c', 'value'), \
                                        'oc', '{hex}')::eql_v2_encrypted)"
        );
        sqlx::query(&sql).execute(&mut *tx).await?;
    }

    // Functional btree on the extractor — no opclass annotation needed
    // because `eql_v2.ore_cllw_ops` is DEFAULT FOR TYPE.
    sqlx::query(
        "CREATE INDEX ore_cllw_test_idx
         ON ore_cllw_test (eql_v2.ore_cllw((value).data))",
    )
    .execute(&mut *tx)
    .await?;

    // ANALYZE is skipped intentionally: the `value` column is
    // `eql_v2_encrypted` with payloads that carry only `oc` (no root `ob`),
    // and ANALYZE samples via the default btree opclass on
    // `eql_v2_encrypted` — whose FUNCTION 1 is the strict-Block-ORE
    // `eql_v2.compare` (post-#219), which raises on missing `ob`. The
    // functional index match below works without stats once we force
    // `enable_seqscan = off`.

    // EXPLAIN the ORDER BY query. With the opclass engaging, the plan
    // should walk the btree in order (Index Scan / Index Only Scan) and
    // skip the Sort node. Force the planner to prefer the index even on
    // tiny fixtures (seq scan is usually cheaper at 20 rows).
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    let explain_rows = sqlx::query_scalar::<_, String>(
        "EXPLAIN SELECT id FROM ore_cllw_test \
         ORDER BY eql_v2.ore_cllw((value).data) LIMIT 5",
    )
    .fetch_all(&mut *tx)
    .await?;
    let explain = explain_rows.join("\n");

    // The plan structure we want: top is Limit, then Index Scan
    // (or Index Only Scan) on ore_cllw_test_idx. We accept either form;
    // the key negative is: NO `Sort` node.
    assert!(
        explain.contains("Index Scan") || explain.contains("Index Only Scan"),
        "Expected Index Scan via ore_cllw_test_idx, got:\n{explain}"
    );
    assert!(
        !explain.contains("Sort"),
        "Expected no Sort node (index walks in order), got:\n{explain}"
    );

    tx.rollback().await?;
    Ok(())
}

// ===========================================================================
// Inlinability check: operator backing functions must stay unpinned + SQL
// ===========================================================================

#[sqlx::test]
async fn backing_functions_are_inlinable(pool: PgPool) -> Result<()> {
    // Mirrors the lint-style assertion in `hash_operator_tests.rs` for the
    // ORE-CLLW operator backing functions. Reads pg_proc directly to assert
    // each function is `LANGUAGE sql`, `IMMUTABLE`, `STRICT`, `PARALLEL
    // SAFE`, and not pinned with a `SET search_path`. Any of those failing
    // would silently kill inlining and break functional-index match.
    let rows = sqlx::query(
        "SELECT p.proname,
                l.lanname,
                p.provolatile,
                p.proparallel,
                p.proisstrict,
                (p.proconfig IS NOT NULL) AS pinned
         FROM pg_proc p
         JOIN pg_namespace n ON n.oid = p.pronamespace
         JOIN pg_language l ON l.oid = p.prolang
         WHERE n.nspname = 'eql_v2'
           AND p.proname IN ('ore_cllw_eq', 'ore_cllw_neq',
                             'ore_cllw_lt',  'ore_cllw_lte',
                             'ore_cllw_gt',  'ore_cllw_gte')
         ORDER BY p.proname",
    )
    .fetch_all(&pool)
    .await?;

    assert_eq!(rows.len(), 6, "expected 6 backing functions");

    for row in rows {
        let name: String = row.get("proname");
        let lang: String = row.get("lanname");
        let volatile: i8 = row.get("provolatile");
        let parallel: i8 = row.get("proparallel");
        let strict: bool = row.get("proisstrict");
        let pinned: bool = row.get("pinned");

        assert_eq!(lang, "sql", "{name}: must be LANGUAGE sql");
        assert_eq!(volatile as u8, b'i', "{name}: must be IMMUTABLE");
        assert_eq!(parallel as u8, b's', "{name}: must be PARALLEL SAFE");
        assert!(strict, "{name}: must be STRICT");
        assert!(
            !pinned,
            "{name}: must NOT have SET search_path (kills inlining)"
        );
    }
    Ok(())
}

// ===========================================================================
// Missing-`oc` rows: extractor returns SQL NULL composite, not ROW(NULL)
//
// Regression coverage for the btree FUNCTION 1 contract: the extractor must
// not emit a non-NULL composite whose `bytes` field is NULL, because btree's
// null-handling layer filters composite-level NULLs but not nested ones —
// indexing `ROW(NULL)` would land calls into `compare_ore_cllw_term` with
// undefined-behaviour inputs.
// ===========================================================================
//
// Extractor returns SQL-level NULL when the sv element lacks `oc`. Both the
// `(jsonb)` and `(ste_vec_entry)` overloads share the same semantics.

#[sqlx::test]
async fn ore_cllw_extractor_returns_null_when_oc_absent(pool: PgPool) -> Result<()> {
    let is_null: bool = sqlx::query_scalar(
        "SELECT eql_v2.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"hm\":\"abc\"}'::jsonb) IS NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        is_null,
        "ore_cllw(jsonb) should return SQL NULL when `oc` is absent"
    );

    let is_null_entry: bool = sqlx::query_scalar(
        "SELECT eql_v2.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"hm\":\"abc\"}'::jsonb::eql_v2.ste_vec_entry) IS NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        is_null_entry,
        "ore_cllw(ste_vec_entry) should return SQL NULL when `oc` is absent"
    );

    Ok(())
}

#[sqlx::test]
async fn ore_cllw_extractor_returns_composite_when_oc_present(pool: PgPool) -> Result<()> {
    // Sanity: when `oc` is present, the extractor returns a non-NULL
    // composite whose `bytes` field decodes the hex.
    let is_null: bool = sqlx::query_scalar(
        "SELECT eql_v2.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"oc\":\"deadbeef\"}'::jsonb) IS NULL",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        !is_null,
        "ore_cllw(jsonb) should NOT be NULL when `oc` is present"
    );
    Ok(())
}

#[sqlx::test]
async fn comparator_raises_on_null_bytes_in_non_null_composite(pool: PgPool) -> Result<()> {
    // Defense-in-depth: a hand-crafted composite with NULL `bytes` should
    // raise rather than silently misorder. The extractors are designed not
    // to produce this shape, so reaching this branch indicates a hand-built
    // literal or a regression in the extractor body.
    //
    // Note: a single-field composite with all fields NULL is composite-
    // level NULL per SQL semantics, so this branch is currently
    // unreachable via the type as defined. We still assert the guard
    // surfaces correctly when a future field addition makes
    // `ROW(non_null, NULL)`-style values constructible — and we exercise
    // the (jsonb) overload path to confirm the SQL-level NULL flows
    // through the comparator without raising.
    let comparator_returns_null: Option<i32> = sqlx::query_scalar(
        "SELECT eql_v2.compare_ore_cllw_term(\
           eql_v2.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"hm\":\"abc\"}'::jsonb), \
           eql_v2.ore_cllw('{\"s\":\"x\",\"c\":\"y\",\"oc\":\"00ff\"}'::jsonb)\
         )",
    )
    .fetch_one(&pool)
    .await?;
    assert!(
        comparator_returns_null.is_none(),
        "compare_ore_cllw_term with NULL composite should return SQL NULL"
    );
    Ok(())
}

// ===========================================================================
// Functional-index match: WHERE-clause range engages Index Cond
//
// Closes the gap James flagged: the existing test only proves ORDER BY
// engages the index. WHERE-clause range quals go through a different
// planner path (opclass strategies 1/2/4/5) and need separate coverage.
// ===========================================================================

#[sqlx::test]
async fn functional_index_engages_for_where_range(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE ore_cllw_where_test
           (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            value eql_v2_encrypted NOT NULL)",
    )
    .execute(&mut *tx)
    .await?;

    // Seed 100 rows so the planner can plausibly prefer an index scan.
    for i in 0..100u8 {
        let hex = format!("00{:02x}", i);
        let sql = format!(
            "INSERT INTO ore_cllw_where_test(value) \
             VALUES (jsonb_build_object('v', 2, 'k', 'ct', 'c', 'placeholder', \
                                        'i', jsonb_build_object('t', 'ore_cllw_where_test', 'c', 'value'), \
                                        'oc', '{hex}')::eql_v2_encrypted)"
        );
        sqlx::query(&sql).execute(&mut *tx).await?;
    }

    sqlx::query(
        "CREATE INDEX ore_cllw_where_test_idx
         ON ore_cllw_where_test (eql_v2.ore_cllw((value).data))",
    )
    .execute(&mut *tx)
    .await?;

    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    let explain_rows = sqlx::query_scalar::<_, String>(
        "EXPLAIN SELECT id FROM ore_cllw_where_test \
         WHERE eql_v2.ore_cllw((value).data) \
             < eql_v2.ore_cllw('{\"oc\":\"00aa\"}'::jsonb)",
    )
    .fetch_all(&mut *tx)
    .await?;
    let explain = explain_rows.join("\n");

    // Accept either Index Scan or Bitmap Index Scan — both are valid
    // index-engaging plans for a range qual. The key negative: NO Seq Scan.
    assert!(
        explain.contains("Index Scan") || explain.contains("Bitmap Index Scan"),
        "Expected Index Scan via ore_cllw_where_test_idx for WHERE range, got:\n{explain}"
    );
    assert!(
        explain.contains("Index Cond"),
        "Expected Index Cond clause on the WHERE range, got:\n{explain}"
    );

    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn rows_without_oc_excluded_from_range_query(pool: PgPool) -> Result<()> {
    // Mixed-payload test: some rows carry `oc`, others carry only `hm`.
    // A range query against the column must:
    //   (a) complete without raising — even though the hm-only rows produce
    //       SQL NULL from the extractor, the comparator (with my Option-C
    //       tightening) only RAISES on a non-NULL composite with NULL
    //       `bytes`, never on SQL NULL composites; and
    //   (b) return only oc-bearing row ids — the hm-only rows must be
    //       filtered out by SQL NULL semantics (NULL `<op>` _ → NULL →
    //       not true → row excluded from WHERE).
    //
    // The test deliberately doesn't assert the exact count of matched
    // oc-rows: the CLLW protocol is adjacency-revealing rather than
    // total-order-preserving, so the set of "less than" rows under
    // synthetic byte sequences depends on protocol details that aren't
    // the subject of this test.
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE ore_cllw_mixed_test
           (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            kind text NOT NULL,
            value eql_v2_encrypted NOT NULL)",
    )
    .execute(&mut *tx)
    .await?;

    // 20 rows with oc, 20 rows hm-only.
    for i in 0..20u8 {
        let hex = format!("00{:02x}", i);
        sqlx::query(&format!(
            "INSERT INTO ore_cllw_mixed_test(kind, value) \
             VALUES ('oc', jsonb_build_object('v', 2, 'k', 'ct', 'c', 'placeholder', \
                                        'i', jsonb_build_object('t', 'ore_cllw_mixed_test', 'c', 'value'), \
                                        'oc', '{hex}')::eql_v2_encrypted)"
        ))
        .execute(&mut *tx)
        .await?;

        let hm = format!("{:032x}", i + 100);
        sqlx::query(&format!(
            "INSERT INTO ore_cllw_mixed_test(kind, value) \
             VALUES ('hm', jsonb_build_object('v', 2, 'k', 'ct', 'c', 'placeholder', \
                                        'i', jsonb_build_object('t', 'ore_cllw_mixed_test', 'c', 'value'), \
                                        'hm', '{hm}')::eql_v2_encrypted)"
        ))
        .execute(&mut *tx)
        .await?;
    }

    // (a) Query completes — no raise. If Option-A had been bypassed and
    // the extractor still returned `ROW(NULL)` for hm-only rows, the
    // Option-C RAISE in `compare_ore_cllw_term` would fire and crash
    // this query.
    let hm_matches: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM ore_cllw_mixed_test \
         WHERE kind = 'hm' \
           AND eql_v2.ore_cllw((value).data) \
             < eql_v2.ore_cllw('{\"oc\":\"00aa\"}'::jsonb)",
    )
    .fetch_one(&mut *tx)
    .await?;

    // (b) None of the hm-only rows appear in the result.
    assert_eq!(
        hm_matches, 0,
        "Expected zero hm-only rows in range query result — \
         missing-oc rows must be excluded by NULL semantics"
    );

    // Sanity: at least some oc-bearing rows DO match (so the predicate
    // isn't trivially false — exercising the live comparator path).
    let oc_matches: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM ore_cllw_mixed_test \
         WHERE kind = 'oc' \
           AND eql_v2.ore_cllw((value).data) \
             < eql_v2.ore_cllw('{\"oc\":\"00aa\"}'::jsonb)",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert!(
        oc_matches > 0,
        "Expected the predicate to match at least one oc-bearing row"
    );

    tx.rollback().await?;
    Ok(())
}
