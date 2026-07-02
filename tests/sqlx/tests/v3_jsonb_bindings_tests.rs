//! Parse REAL generated SteVec ciphertext rows into the hand-written bindings —
//! the one test that ties eql-bindings to real cipherstash crypto AND to the
//! hand-written src/v3/jsonb/types.sql domain CHECK simultaneously.
//!
//! The fixture (`fixtures.v3_ste_vec`, column `payload eql_v3.json`) is GENERATED
//! by encrypting JSON documents through cipherstash-client's SteVec pipeline
//! (`mise run fixture:generate:all`), so this exercises the bindings against the
//! same wire shape the domain CHECK (`is_valid_ste_vec_document_payload`)
//! validated at INSERT — not a hand-written literal.

use eql_bindings::v3::jsonb::{SteVecDocument, SteVecEntry};
use sqlx::PgPool;

#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn real_ste_vec_row_parses_into_document_and_entries(pool: PgPool) -> anyhow::Result<()> {
    // Whole document parses (real ciphertext, real SQL-validated shape).
    let doc_json: serde_json::Value =
        sqlx::query_scalar("SELECT payload::jsonb FROM fixtures.v3_ste_vec ORDER BY id LIMIT 1")
            .fetch_one(&pool)
            .await?;
    let doc: SteVecDocument = serde_json::from_value(doc_json)?;
    assert!(
        !doc.sv.is_empty(),
        "a real SteVec document must have sv entries"
    );

    // Each real sv element parses as a (lax) entry with a real term.
    let elems: Vec<serde_json::Value> = sqlx::query_scalar(
        "SELECT elem FROM fixtures.v3_ste_vec, \
         jsonb_array_elements(payload::jsonb -> 'sv') AS elem LIMIT 5",
    )
    .fetch_all(&pool)
    .await?;
    assert!(!elems.is_empty());
    for e in elems {
        // Fails if the real wire shape drifts from the bindings.
        let _entry: SteVecEntry = serde_json::from_value(e)?;
    }
    Ok(())
}
