//! Tests for the XOR-aware equality term extractor: `eql_v2.eq_term(ste_vec_entry)`,
//! and the chained recipe `eql_v2.eq_term(col -> '<selector>')`.
//!
//! Coverage:
//! - Happy path: returns the matched element's hm bytes (hm-bearing
//!   selector) or oc bytes (oc-bearing selector).
//! - Missing selector / NULL input → NULL via STRICT propagation through
//!   the inlined `->` chain.
//! - Plan: functional hash index on `eql_v2.eq_term(col -> '<sel>')`
//!   engages structurally for bare equality and GROUP BY queries.
//!
//! This file is the post-2.3 replacement for the previous
//! `hmac_256_selector_tests.rs`, which tested the now-removed fused
//! `eql_v2.hmac_256(eql_v2_encrypted, text)`.

use anyhow::Result;
use eql_tests::{explain_query, Selectors};
use sqlx::{Acquire, PgPool, Row};

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn returns_term_for_matching_selector(pool: PgPool) -> Result<()> {
    let result: Option<Vec<u8>> = sqlx::query_scalar(&format!(
        "SELECT eql_v2.eq_term(e -> '{}'::text) FROM encrypted ORDER BY id LIMIT 1",
        Selectors::HELLO
    ))
    .fetch_one(&pool)
    .await?;

    assert!(
        result.is_some(),
        "eq_term(e -> $.hello-selector) should return the entry's hm-or-oc bytes"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn returns_null_for_missing_selector(pool: PgPool) -> Result<()> {
    let result: Option<Vec<u8>> = sqlx::query_scalar(
        "SELECT eql_v2.eq_term(e -> 'selector_does_not_exist'::text) \
         FROM encrypted ORDER BY id LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        result.is_none(),
        "eq_term with a non-existent selector should return NULL via STRICT, got: {:?}",
        result
    );
    Ok(())
}

#[sqlx::test]
async fn returns_null_for_null_encrypted_input(pool: PgPool) -> Result<()> {
    let result: Option<Vec<u8>> = sqlx::query_scalar(
        "SELECT eql_v2.eq_term((NULL::eql_v2_encrypted) -> 'any-selector'::text)",
    )
    .fetch_one(&pool)
    .await?;

    assert!(
        result.is_none(),
        "STRICT chain should return NULL for NULL input"
    );
    Ok(())
}

#[sqlx::test]
async fn returns_oc_bytes_for_oc_bearing_selector(pool: PgPool) -> Result<()> {
    // The XOR contract: an oc-bearing entry (string / number leaf) carries
    // `oc` and never `hm`. `eq_term` coalesces hm/oc, so the result is the
    // oc bytes. Pre-fix, the equality recipe was hmac_256-only and would
    // have returned NULL for this case.
    let sql = r#"
        SELECT eql_v2.eq_term(
            ('{"v": 2, "i": {"t": "t", "c": "c"},
              "sv": [{"s": "sel_x", "c": "ct", "oc": "ABCDEF"}]}'::jsonb::eql_v2_encrypted)
            -> 'sel_x'::text
        )
    "#;
    let result: Option<Vec<u8>> = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert_eq!(
        result.as_deref(),
        Some(&[0xAB, 0xCD, 0xEF][..]),
        "oc-bearing entry should yield its oc bytes via eq_term"
    );
    Ok(())
}

#[sqlx::test]
async fn returns_hm_bytes_for_hm_bearing_selector(pool: PgPool) -> Result<()> {
    // Symmetric to the test above: hm-bearing entry (bool leaf, array root,
    // object root) yields its hm bytes via eq_term.
    let sql = r#"
        SELECT eql_v2.eq_term(
            ('{"v": 2, "i": {"t": "t", "c": "c"},
              "sv": [{"s": "sel_x", "c": "ct", "hm": "DEADBEEF"}]}'::jsonb::eql_v2_encrypted)
            -> 'sel_x'::text
        )
    "#;
    let result: Option<Vec<u8>> = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert_eq!(result.as_deref(), Some(&[0xDE, 0xAD, 0xBE, 0xEF][..]));
    Ok(())
}

#[sqlx::test]
async fn returns_target_element_when_multiple_selectors(pool: PgPool) -> Result<()> {
    // Multi-element sv: should yield the eq_term of the element matching
    // the selector, not the first element overall.
    let sql = r#"
        SELECT eql_v2.eq_term(
            ('{"v": 2, "i": {"t": "t", "c": "c"},
              "sv": [
                {"s": "sel_first",  "c": "c1", "hm": "1111"},
                {"s": "sel_target", "c": "c2", "hm": "2222"},
                {"s": "sel_third",  "c": "c3", "hm": "3333"}
              ]}'::jsonb::eql_v2_encrypted)
            -> 'sel_target'::text
        )
    "#;
    let result: Option<Vec<u8>> = sqlx::query_scalar(sql).fetch_one(&pool).await?;
    assert_eq!(result.as_deref(), Some(&[0x22, 0x22][..]));
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn where_clause_uses_functional_hash_index(pool: PgPool) -> Result<()> {
    // Load-bearing plan assertion: a btree hash index on
    // `eql_v2.eq_term(col -> '<selector>')` engages structurally for
    // bare equality queries on the same expression. With seq scan
    // disabled, the planner must find the index match — proving the
    // chained `-> + eq_term` inlines cleanly.

    sqlx::query(&format!(
        "CREATE INDEX encrypted_hello_eq_term_idx \
         ON encrypted USING hash (eql_v2.eq_term(e -> '{}'::text))",
        Selectors::HELLO
    ))
    .execute(&pool)
    .await?;
    sqlx::query("ANALYZE encrypted").execute(&pool).await?;

    let mut conn = pool.acquire().await?;
    sqlx::query("SET enable_seqscan = off")
        .execute(conn.acquire().await?)
        .await?;

    let sql = format!(
        "EXPLAIN SELECT * FROM encrypted \
         WHERE eql_v2.eq_term(e -> '{}'::text) = '\\xdeadbeef'::bytea",
        Selectors::HELLO
    );
    let plan: String = sqlx::query(&sql)
        .fetch_all(conn.acquire().await?)
        .await?
        .into_iter()
        .map(|row| row.try_get::<String, _>(0).unwrap_or_default())
        .collect::<Vec<_>>()
        .join("\n");

    assert!(
        plan.contains("encrypted_hello_eq_term_idx"),
        "Expected the functional hash index to be used. Plan:\n{}",
        plan
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn group_by_uses_functional_hash_index(pool: PgPool) -> Result<()> {
    sqlx::query(&format!(
        "CREATE INDEX encrypted_hello_eq_term_grp_idx \
         ON encrypted USING hash (eql_v2.eq_term(e -> '{}'::text))",
        Selectors::HELLO
    ))
    .execute(&pool)
    .await?;
    sqlx::query("ANALYZE encrypted").execute(&pool).await?;

    // GROUP BY plan: HashAggregate on the inlined expression is the expected
    // shape (the planner sees `eql_v2.eq_term(e -> '<sel>'::text)` as the
    // group key even on small fixtures where Bitmap Index Scan won't engage).
    let sql = format!(
        "SELECT eql_v2.eq_term(e -> '{}'::text), count(*) FROM encrypted \
         GROUP BY eql_v2.eq_term(e -> '{}'::text)",
        Selectors::HELLO,
        Selectors::HELLO
    );

    let plan = explain_query(&pool, &sql).await?;
    assert!(
        plan.contains("HashAggregate") || plan.contains("Group"),
        "GROUP BY plan should aggregate on the eq_term expression. Plan:\n{}",
        plan
    );
    assert!(
        plan.contains("eq_term"),
        "Plan should reference the eq_term expression. Plan:\n{}",
        plan
    );
    Ok(())
}
