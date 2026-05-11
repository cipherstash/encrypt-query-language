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
    // Test: term does NOT contain full encrypted value (asymmetric containment)
    // Verifies that while e @> term is true, term @> e is false

    let sql = format!(
        "SELECT e FROM encrypted WHERE (e -> '{}'::text) @> e LIMIT 1",
        Selectors::N
    );

    // Should return 0 records - extracted term cannot contain the full encrypted value
    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_with_encrypted_term(pool: PgPool) -> Result<()> {
    // Test: e @> encrypted_term with encrypted selector
    // Uses encrypted test data with $.hello selector

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::eql_v2_encrypted",
        term
    );

    // Should find at least the record we extracted from
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_count_matches(pool: PgPool) -> Result<()> {
    // Test: e @> term returns correct count
    // Verifies count of records containing the term

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::eql_v2_encrypted",
        term
    );

    // Expects 1 match: containment checks the specific encrypted term value,
    // not just the presence of the $.hello field
    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contained_by_operator_with_encrypted_term(pool: PgPool) -> Result<()> {
    // Test: term <@ e (contained by)
    // Tests that extracted term is contained by the original encrypted value

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::eql_v2_encrypted <@ e",
        term
    );

    // Should find records where term is contained
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contained_by_operator_count_matches(pool: PgPool) -> Result<()> {
    // Test: term <@ e returns correct count
    // Verifies count of records containing the term

    let term = get_encrypted_term(&pool, Selectors::HELLO).await?;

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::eql_v2_encrypted <@ e",
        term
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

// ============================================================================
// ste_vec element matching: same plaintext, different ciphertext bytes
//
// Regression coverage for the `ste_vec_contains` element comparison. ste_vec
// elements carry `b3` (Blake3) for selector-scoped equality. A freshly-built
// query payload has the same `b3` as the stored row (Blake3 is deterministic
// over plaintext) but a different `c` (ciphertext) field — so JSONB byte
// comparison would say they differ even though they're semantically equal.
//
// The existing tests above all extract terms directly from the database, so
// the bytes are identical and the literal-fallback path happens to return 0.
// These tests construct the query payload by hand to avoid that, exercising
// the b3-match path explicitly.
// ============================================================================

const B3_HELLO: &str = "7b4ffe5d60e4e4300dc3e28d9c300c87";

/// Builds a single-element ste_vec payload with a deterministic Blake3 term
/// and a caller-provided ciphertext blob. Same `b3` + `s` across calls means
/// "same plaintext at same selector"; varying `ciphertext` means "different
/// JSONB byte representation" — together they exercise the b3-match path.
fn build_ste_vec_payload(selector: &str, b3: &str, ciphertext: &str) -> String {
    format!(
        r#"{{"v":2,"k":"sv","sv":[{{"b3":"{b3}","c":"{ciphertext}","s":"{selector}"}}]}}"#
    )
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_matches_b3_with_different_ciphertext(pool: PgPool) -> Result<()> {
    // Insert a row whose ste_vec element has B3_HELLO at the $.hello selector.
    let stored = build_ste_vec_payload(Selectors::HELLO, B3_HELLO, "stored_ciphertext_AAA");
    sqlx::query("INSERT INTO encrypted (e) VALUES ($1::jsonb::eql_v2_encrypted)")
        .bind(&stored)
        .execute(&pool)
        .await?;

    // Query with a freshly-built payload: same selector, same b3, different ciphertext bytes.
    let query_payload =
        build_ste_vec_payload(Selectors::HELLO, B3_HELLO, "fresh_query_ciphertext_BBB");

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::jsonb::eql_v2_encrypted",
        query_payload
    );

    // Should match the stored row by b3, despite the JSONB bytes differing.
    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_does_not_match_different_b3(pool: PgPool) -> Result<()> {
    // Same shape as the test above but with a *different* b3 in the query
    // payload. The b3 guard must not produce a false positive when both
    // sides carry b3 but the values differ.
    let stored = build_ste_vec_payload(Selectors::HELLO, B3_HELLO, "stored_ciphertext_AAA");
    sqlx::query("INSERT INTO encrypted (e) VALUES ($1::jsonb::eql_v2_encrypted)")
        .bind(&stored)
        .execute(&pool)
        .await?;

    let other_b3 = "0000000000000000000000000000000000000000000000000000000000000000";
    let query_payload =
        build_ste_vec_payload(Selectors::HELLO, other_b3, "fresh_query_ciphertext_BBB");

    // The seed fixture inserted three rows whose root b3 happens to equal
    // B3_HELLO at the $.hello selector — none of them should match `other_b3`.
    let sql = format!(
        "SELECT e FROM encrypted \
         WHERE e @> '{}'::jsonb::eql_v2_encrypted \
           AND eql_v2.selector(e -> '{}'::text) = '{}'",
        query_payload,
        Selectors::HELLO,
        Selectors::HELLO,
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}
