//! End-to-end "empty sorts first" contract for `eql_v3.text_ord` (issue #262).
//!
//! Encrypting the empty string `""` as ordered text produces an empty ORE term
//! (`ob: []`, verified against cipherstash-client). Previously that collapsed to
//! NULL comparator output, so an empty-text row silently dropped out of ordered
//! queries (`ORDER BY` lost it, `max` wrongly returned it, counts went off by
//! one). The fix gives the empty term a deterministic position — it sorts BEFORE
//! every non-empty value — by yielding a zero-term composite the comparator's
//! cardinality guard orders first.
//!
//! These tests ride the committed `v3_text_empty` fixture (real ciphertexts for
//! `""`, `"frank"`, `"zebra"`; ids 1/2/3) and exercise the full user-facing
//! surface: `ORDER BY` (ASC/DESC) and the `min`/`max` aggregates over the
//! `text_ord` domain. The ordering key is the canonical
//! `eql_v3.ord_term((payload)::eql_v3.text_ord)`, matching the scalar matrix.

use anyhow::Result;
use sqlx::PgPool;

/// `ORDER BY` ascending must place `""` first, then the non-empty values in
/// lexical order. Before the fix the `""` row produced a NULL sort key and
/// dropped out of the result entirely.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn order_by_asc_sorts_empty_first(pool: PgPool) -> Result<()> {
    let actual: Vec<String> = sqlx::query_scalar(
        "SELECT plaintext FROM fixtures.v3_text_empty \
         ORDER BY eql_v3.ord_term((payload)::eql_v3.text_ord) ASC",
    )
    .fetch_all(&pool)
    .await?;
    assert_eq!(
        actual,
        vec!["".to_string(), "frank".to_string(), "zebra".to_string()],
        "empty string must sort first under ASC, then frank, then zebra"
    );
    Ok(())
}

/// `ORDER BY` descending mirrors it: `""` lands last (it is the minimum).
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn order_by_desc_sorts_empty_last(pool: PgPool) -> Result<()> {
    let actual: Vec<String> = sqlx::query_scalar(
        "SELECT plaintext FROM fixtures.v3_text_empty \
         ORDER BY eql_v3.ord_term((payload)::eql_v3.text_ord) DESC",
    )
    .fetch_all(&pool)
    .await?;
    assert_eq!(
        actual,
        vec!["zebra".to_string(), "frank".to_string(), "".to_string()],
        "empty string must sort last under DESC"
    );
    Ok(())
}

/// `eql_v3.min` over `text_ord` must return the `""` payload (the minimum),
/// recovered to its plaintext via the fixture's `payload` column.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn min_returns_the_empty_string(pool: PgPool) -> Result<()> {
    let plaintext: String = sqlx::query_scalar(
        "SELECT plaintext FROM fixtures.v3_text_empty WHERE payload = (\
            SELECT eql_v3.min(payload::eql_v3.text_ord)::jsonb FROM fixtures.v3_text_empty)",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(plaintext, "", "min over text_ord must be the empty string");
    Ok(())
}

/// `eql_v3.max` must return the largest real value (`"zebra"`), NOT the empty
/// string. Before the fix `max` wrongly returned the `""` payload because the
/// NULL comparison never displaced the empty state.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn max_returns_the_largest_value_not_empty(pool: PgPool) -> Result<()> {
    let plaintext: String = sqlx::query_scalar(
        "SELECT plaintext FROM fixtures.v3_text_empty WHERE payload = (\
            SELECT eql_v3.max(payload::eql_v3.text_ord)::jsonb FROM fixtures.v3_text_empty)",
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        plaintext, "zebra",
        "max over text_ord must be the largest real value, not the empty string"
    );
    Ok(())
}
