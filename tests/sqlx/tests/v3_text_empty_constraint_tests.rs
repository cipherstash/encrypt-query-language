//! End-to-end "empty ORE term is rejected" contract for the ORE-bearing
//! `eql_v3` text domains (issue #262).
//!
//! Encrypting the empty string `""` as ordered text produces an empty ORE term
//! (`ob: []`, verified against cipherstash-client) — the only value that does.
//! Rather than ordering such a degenerate term, the ORE-bearing domains reject
//! it at the boundary: their `CHECK` requires `ob` to be a non-empty array, so
//! casting an empty-`ob` payload to `eql_v3.text_ord` / `eql_v3.text_ord_ore`
//! fails with a check violation (SQLSTATE `23514`). The comparator's
//! "empty sorts first" cardinality guard remains in place as defense-in-depth
//! for any path that bypasses the domain (e.g. a composite built directly).
//!
//! These tests ride the committed `v3_text_empty` fixture (real ciphertexts for
//! `""`, `"frank"`, `"zebra"`; ids 1/2/3). The fixture's `payload` column is
//! plain `jsonb`, so every row loads; the rejection happens at the cast in each
//! test, not at fixture load. The fixture carries `hm` + `ob` (Unique + Ore, no
//! bloom), so it exercises `text_ord` and `text_ord_ore` — not `text_search`,
//! which additionally requires a `bf` key the fixture does not emit.

use anyhow::Result;
use eql_tests::assert_db_error;
use sqlx::PgPool;

/// Casting the empty-string row (`id = 1`, `ob: []`) to `eql_v3.text_ord` is
/// rejected by the domain's non-empty-`ob` CHECK.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn empty_string_rejected_by_text_ord(pool: PgPool) -> Result<()> {
    let err =
        sqlx::query("SELECT payload::eql_v3.text_ord FROM fixtures.v3_text_empty WHERE id = 1")
            .fetch_all(&pool)
            .await
            .expect_err("empty ORE term (ob: []) must violate the text_ord CHECK");
    // Auto-generated domain constraint name is not pinned — only the SQLSTATE.
    assert_db_error(&err, "23514", None);
    Ok(())
}

/// Same rejection for the `eql_v3.text_ord_ore` domain.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn empty_string_rejected_by_text_ord_ore(pool: PgPool) -> Result<()> {
    let err =
        sqlx::query("SELECT payload::eql_v3.text_ord_ore FROM fixtures.v3_text_empty WHERE id = 1")
            .fetch_all(&pool)
            .await
            .expect_err("empty ORE term (ob: []) must violate the text_ord_ore CHECK");
    assert_db_error(&err, "23514", None);
    Ok(())
}

/// The non-empty controls (`"frank"`, `"zebra"`) carry a real `ob` array, so
/// they cast cleanly into `eql_v3.text_ord` — the CHECK only rejects the empty
/// term, not ordered text in general.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn non_empty_controls_accepted_by_text_ord(pool: PgPool) -> Result<()> {
    let plaintexts: Vec<String> = sqlx::query_scalar(
        "SELECT plaintext FROM fixtures.v3_text_empty \
         WHERE id IN (2, 3) AND payload::eql_v3.text_ord IS NOT NULL \
         ORDER BY id",
    )
    .fetch_all(&pool)
    .await?;
    assert_eq!(
        plaintexts,
        vec!["frank".to_string(), "zebra".to_string()],
        "non-empty ordered text must cast cleanly into text_ord"
    );
    Ok(())
}

/// The controls also order correctly via `ord_term` once cast — the CHECK does
/// not disturb ordering of real values.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_text_empty")))]
async fn non_empty_controls_order_under_text_ord(pool: PgPool) -> Result<()> {
    let plaintexts: Vec<String> = sqlx::query_scalar(
        "SELECT plaintext FROM fixtures.v3_text_empty \
         WHERE id IN (2, 3) \
         ORDER BY eql_v3.ord_term(payload::eql_v3.text_ord) ASC",
    )
    .fetch_all(&pool)
    .await?;
    assert_eq!(
        plaintexts,
        vec!["frank".to_string(), "zebra".to_string()],
        "frank must order before zebra"
    );
    Ok(())
}
