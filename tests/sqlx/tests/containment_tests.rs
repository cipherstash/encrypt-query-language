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
