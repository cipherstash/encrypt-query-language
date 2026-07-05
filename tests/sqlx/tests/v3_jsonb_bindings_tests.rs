//! Parse REAL generated SteVec ciphertext rows into the hand-written bindings —
//! the one test that ties eql-bindings to real cipherstash crypto AND to the
//! hand-written src/v3/jsonb/types.sql domain CHECK simultaneously.
//!
//! The fixture (`fixtures.v3_ste_vec`, column `payload public.json`) is GENERATED
//! by encrypting JSON documents through cipherstash-client's SteVec pipeline
//! (`mise run fixture:generate:all`), so this exercises the bindings against the
//! same wire shape the domain CHECK (`is_valid_ste_vec_document_payload`)
//! validated at INSERT — not a hand-written literal.

use eql_bindings::v3::jsonb::{SteVecDocument, SteVecEntry, SteVecQuery, SteVecTerm};
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

    // Every real sv element across the whole fixture parses as a (lax) entry with
    // a real term. Deterministic ordering (id, then selector) so the sample is
    // stable; no LIMIT so both leaf kinds are guaranteed present.
    let elems: Vec<serde_json::Value> = sqlx::query_scalar(
        "SELECT elem FROM fixtures.v3_ste_vec, \
         jsonb_array_elements(payload::jsonb -> 'sv') AS elem \
         ORDER BY id, elem ->> 's'",
    )
    .fetch_all(&pool)
    .await?;
    assert!(!elems.is_empty());

    // Assert BOTH index-term variants actually occur in real data — not merely
    // that entries parse. The fixture mixes object leaves (`hm`, hash-equality)
    // and scalar leaves (`oc`, CLLW-ORE), so a real SteVec document must exercise
    // both `SteVecTerm` arms; a fixture or binding regression that collapsed one
    // arm would slip past a bare "parses without error" check.
    let (mut saw_hm, mut saw_oc) = (false, false);
    for e in elems {
        // Fails if the real wire shape drifts from the bindings.
        let entry: SteVecEntry = serde_json::from_value(e)?;
        match entry.term {
            SteVecTerm::Hmac { .. } => saw_hm = true,
            SteVecTerm::OreCllw { .. } => saw_oc = true,
        }
    }
    assert!(
        saw_hm,
        "real SteVec entries must include an hm (hash-equality) term"
    );
    assert!(
        saw_oc,
        "real SteVec entries must include an oc (CLLW-ORE) term"
    );

    Ok(())
}

#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn real_ste_vec_query_parses_into_bindings(pool: PgPool) -> anyhow::Result<()> {
    // `eql_v3.to_ste_vec_query` turns an encrypted document into a containment
    // needle (`public.jsonb_query`), the shape a caller builds a `@>` / `<@`
    // query from. Parse a REAL one into `SteVecQuery` (and, transitively, its
    // `SteVecQueryEntry` elements), tying those two bindings to real crypto and
    // the hand-written `is_valid_ste_vec_query_payload` CHECK — the document/entry
    // test above covers the other two SteVec bindings.
    let query_json: serde_json::Value = sqlx::query_scalar(
        "SELECT eql_v3.to_ste_vec_query(payload)::jsonb \
         FROM fixtures.v3_ste_vec ORDER BY id LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;
    let query: SteVecQuery = serde_json::from_value(query_json)?;
    assert!(
        !query.sv.is_empty(),
        "a real SteVec query must have sv entries"
    );
    // Each query element carries a real term (SteVecQueryEntry parsed as part of
    // SteVecQuery above); confirm the term variants are well-formed.
    for entry in &query.sv {
        match &entry.term {
            SteVecTerm::Hmac { .. } | SteVecTerm::OreCllw { .. } => {}
        }
    }
    Ok(())
}
