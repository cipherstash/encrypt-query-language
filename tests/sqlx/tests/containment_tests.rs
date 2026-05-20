//! Containment operator tests (@> and <@)
//!
//! Tests encrypted JSONB containment operations

use anyhow::Result;
use eql_tests::{get_encrypted_term, QueryAssertion, Selectors};
use sqlx::PgPool;

// ============================================================================
// Task 10: Containment Operators (@> and <@)
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_self_containment(pool: PgPool) -> Result<()> {
    // Test: encrypted value contains itself
    // Tests that a @> b when a == b

    let sql = "SELECT e FROM encrypted WHERE e @> e LIMIT 1";

    QueryAssertion::new(&pool, sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_with_extracted_term(pool: PgPool) -> Result<()> {
    // Test: e @> term where term is extracted from encrypted value
    // Tests containment with extracted field ($.n selector)

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> (e -> '{}'::text) LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_term_does_not_contain_full_value(pool: PgPool) -> Result<()> {
    // Containment is directional. The old shape `(e -> 'sel') @> e` no
    // longer type-checks — `->` now returns `ste_vec_entry`, which is not
    // a container type for `@>`. Express the same asymmetry between two
    // `eql_v2_encrypted` values: `single` is `e` reduced to its first sv
    // entry.
    //
    //   e      @> single  -> true   (superset contains subset)
    //   single @> e       -> false  (subset does not contain superset)
    //
    // The fixture rows each carry three sv entries ($, $.hello, $.n), so
    // the one-entry `single` is always a strict subset.
    let single_entry = "jsonb_set((e).data, '{sv}', \
                         jsonb_build_array((e).data -> 'sv' -> 0))::eql_v2_encrypted";

    // Positive direction: the full payload contains its one-entry subset.
    let contains = format!("SELECT e FROM encrypted WHERE e @> {single_entry} LIMIT 1");
    QueryAssertion::new(&pool, &contains).returns_rows().await;

    // Negative direction: same rows, operands swapped. A one-entry subset
    // never contains the full three-entry payload — so this returns nothing.
    let not_contains = format!("SELECT e FROM encrypted WHERE {single_entry} @> e LIMIT 1");
    QueryAssertion::new(&pool, &not_contains).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_with_encrypted_term(pool: PgPool) -> Result<()> {
    // Test: e @> entry with encrypted selector
    // Uses encrypted test data with $.hello selector

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::eql_v2.ste_vec_entry",
        term
    );

    // Should find at least the record we extracted from
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_count_matches(pool: PgPool) -> Result<()> {
    // Test: e @> entry returns correct count
    // Verifies count of records containing the term

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::eql_v2.ste_vec_entry",
        term
    );

    // Expects 1 match: containment checks the specific encrypted term value,
    // not just the presence of the $.hello field
    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contained_by_operator_with_encrypted_term(pool: PgPool) -> Result<()> {
    // Test: entry <@ e (contained by)
    // Tests that extracted term is contained by the original encrypted value

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::eql_v2.ste_vec_entry <@ e",
        term
    );

    // Should find records where term is contained
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contained_by_operator_count_matches(pool: PgPool) -> Result<()> {
    // Test: entry <@ e returns correct count
    // Verifies count of records containing the term

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::eql_v2.ste_vec_entry <@ e",
        term
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

// ============================================================================
// ste_vec element matching: same plaintext, different ciphertext bytes
//
// Regression coverage for the `ste_vec_contains` element comparison. Post-2.3
// ste_vec elements carry `hm` (HMAC-256) for selector-scoped equality. A
// freshly-built query payload has the same `hm` as the stored row (deterministic
// over plaintext + key) but a different `c` (ciphertext) field — so JSONB byte
// comparison would say they differ even though they're semantically equal.
//
// The existing tests above all extract terms directly from the database, so
// the bytes are identical and the literal-fallback path happens to return 0.
// These tests construct the query payload by hand to avoid that, exercising
// the hm-match path explicitly.
// ============================================================================

const HM_HELLO: &str = "7b4ffe5d60e4e4300dc3e28d9c300c87";

/// Builds a single-element ste_vec payload with a deterministic HMAC term
/// and a caller-provided ciphertext blob. Same `hm` + `s` across calls means
/// "same plaintext at same selector"; varying `ciphertext` means "different
/// JSONB byte representation" — together they exercise the hm-match path.
fn build_ste_vec_payload(selector: &str, hm: &str, ciphertext: &str) -> String {
    format!(r#"{{"v":2,"k":"sv","sv":[{{"hm":"{hm}","c":"{ciphertext}","s":"{selector}"}}]}}"#)
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_matches_hm_with_different_ciphertext(pool: PgPool) -> Result<()> {
    // Insert a row whose ste_vec element has HM_HELLO at the $.hello selector.
    let stored = build_ste_vec_payload(Selectors::HELLO, HM_HELLO, "stored_ciphertext_AAA");
    sqlx::query("INSERT INTO encrypted (e) VALUES ($1::jsonb::eql_v2_encrypted)")
        .bind(&stored)
        .execute(&pool)
        .await?;

    // Query with a freshly-built payload: same selector, same hm, different ciphertext bytes.
    let query_payload =
        build_ste_vec_payload(Selectors::HELLO, HM_HELLO, "fresh_query_ciphertext_BBB");

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::jsonb::eql_v2_encrypted",
        query_payload
    );

    // Should match the stored row by hm, despite the JSONB bytes differing.
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_does_not_match_different_hm(pool: PgPool) -> Result<()> {
    // Same shape as the test above but with a *different* hm in the query
    // payload. The hm guard must not produce a false positive when both
    // sides carry hm but the values differ.
    let stored = build_ste_vec_payload(Selectors::HELLO, HM_HELLO, "stored_ciphertext_AAA");
    sqlx::query("INSERT INTO encrypted (e) VALUES ($1::jsonb::eql_v2_encrypted)")
        .bind(&stored)
        .execute(&pool)
        .await?;

    let other_hm = "0000000000000000000000000000000000000000000000000000000000000000";
    let query_payload =
        build_ste_vec_payload(Selectors::HELLO, other_hm, "fresh_query_ciphertext_BBB");

    // The seed fixture inserted three rows whose $.hello sv element hm is
    // derived from a different source (the existing fixture ocv) — none of
    // them should match `other_hm`. Inspect the extracted entry's `s` via
    // JSONB field access on the `ste_vec_entry` returned by `->`.
    let sql = format!(
        "SELECT e FROM encrypted \
         WHERE e @> '{}'::jsonb::eql_v2_encrypted \
           AND (e -> '{}'::text) ->> 's' = '{}'",
        query_payload,
        Selectors::HELLO,
        Selectors::HELLO,
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}
