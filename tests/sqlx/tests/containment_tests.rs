//! Containment operator tests (@> and <@)
//!
//! Converted from src/operators/@>_test.sql and <@_test.sql
//! Tests encrypted JSONB containment operations

use anyhow::Result;
use eql_tests::{QueryAssertion, Selectors};
use sqlx::{PgPool, Row};

// ============================================================================
// Task 10: Containment Operators (@> and <@)
// ============================================================================

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_self_containment(pool: PgPool) -> Result<()> {
    // Test: encrypted value contains itself
    // Original SQL lines 13-25 in src/operators/@>_test.sql
    // Tests that a @> b when a == b

    let sql = "SELECT e FROM encrypted WHERE e @> e LIMIT 1";

    QueryAssertion::new(&pool, sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_with_extracted_term(pool: PgPool) -> Result<()> {
    // Test: e @> term where term is extracted from encrypted value
    // Original SQL lines 34-51 in src/operators/@>_test.sql
    // Tests containment with extracted field ($.n selector)

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> (e -> '{}') LIMIT 1",
        Selectors::N
    );

    QueryAssertion::new(&pool, &sql).returns_rows().await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contains_operator_with_encrypted_term(pool: PgPool) -> Result<()> {
    // Test: e @> encrypted_term with encrypted selector
    // Original SQL lines 68-90 in src/operators/@>_test.sql
    // Uses encrypted test data with $.hello selector

    // Get encrypted term by extracting $.hello from first record
    let sql_create = format!(
        "SELECT (e -> '{}')::text FROM encrypted LIMIT 1",
        Selectors::HELLO
    );
    let row = sqlx::query(&sql_create).fetch_one(&pool).await?;
    let term: Option<String> = row.try_get(0)?;
    let term = term.expect("Should extract encrypted term");

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
    // Original SQL lines 84-87 in src/operators/@>_test.sql
    // Verifies count of records containing the term

    // Get encrypted term for $.hello
    let sql_create = format!(
        "SELECT (e -> '{}')::text FROM encrypted LIMIT 1",
        Selectors::HELLO
    );
    let row = sqlx::query(&sql_create).fetch_one(&pool).await?;
    let term: Option<String> = row.try_get(0)?;
    let term = term.expect("Should extract encrypted term");

    let sql = format!(
        "SELECT e FROM encrypted WHERE e @> '{}'::eql_v2_encrypted",
        term
    );

    // All 3 records in encrypted_json fixture have $.hello field
    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn contained_by_operator_with_encrypted_term(pool: PgPool) -> Result<()> {
    // Test: term <@ e (contained by)
    // Original SQL lines 19-41 in src/operators/<@_test.sql
    // Tests that extracted term is contained by the original encrypted value

    // Get encrypted term for $.hello
    let sql_create = format!(
        "SELECT (e -> '{}')::text FROM encrypted LIMIT 1",
        Selectors::HELLO
    );
    let row = sqlx::query(&sql_create).fetch_one(&pool).await?;
    let term: Option<String> = row.try_get(0)?;
    let term = term.expect("Should extract encrypted term");

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
    // Original SQL lines 35-38 in src/operators/<@_test.sql
    // Verifies count of records containing the term

    // Get encrypted term for $.hello
    let sql_create = format!(
        "SELECT (e -> '{}')::text FROM encrypted LIMIT 1",
        Selectors::HELLO
    );
    let row = sqlx::query(&sql_create).fetch_one(&pool).await?;
    let term: Option<String> = row.try_get(0)?;
    let term = term.expect("Should extract encrypted term");

    let sql = format!(
        "SELECT e FROM encrypted WHERE '{}'::eql_v2_encrypted <@ e",
        term
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}
