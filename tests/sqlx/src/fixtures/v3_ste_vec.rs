//! The `v3_ste_vec` jsonb (SteVec document) fixture — the document analogue
//! of the scalar `eql_v3_<T>` fixtures, generated through the SAME
//! `FixtureSpec` machinery.
//!
//! A `serde_json::Value` is a first-class `EqlPlaintext` (see
//! `eql_plaintext.rs`), so the document fixture is just a
//! `FixtureSpec<serde_json::Value>` with the `IndexKind::SteVec` index and an
//! `eql_v3.json` generated `payload` column. `FixtureSpec::run` encrypts each
//! document through cipherstash-client into a SteVec payload, stages it, and
//! writes `tests/sqlx/fixtures/v3_ste_vec.sql` (gitignored — regenerated on
//! every `mise run test:sqlx`) with the identical
//! `fixtures.<name> (id, plaintext, payload)` shape the scalar fixtures use.
//!
//! Unlike the scalars there is no plaintext-vs-decrypt oracle column relation
//! to maintain; the `plaintext` column simply carries the source JSON document
//! for debuggability, exactly as the scalar fixtures carry the source scalar.

use anyhow::Result;
use serde_json::{json, Value};

use super::index_kind::IndexKind;
use super::spec::FixtureSpec;

/// The canonical fixture name → table `fixtures.v3_ste_vec`, script
/// `v3_ste_vec.sql`, SQLx ref `scripts("v3_ste_vec")`.
const NAME: &str = "v3_ste_vec";

/// The canonical `payload` column type — the `eql_v3.json` DOMAIN, so the
/// domain CHECK runs when the fixture loads.
const PAYLOAD_TYPE: &str = "eql_v3.json";

/// Number of fixture rows. Ten matches the historical fixture and gives the
/// harness's containment / index tests a non-trivial set.
const ROW_COUNT: i64 = 10;

/// The ten plaintext documents — the source of truth for the fixture.
///
/// `hello` VARIES across all rows (10 distinct values → 10 distinct `$.hello`
/// `oc` leaves) so the W1 containment oracle (`fwd == expected`, where
/// `expected` = rows whose `$.hello` oc equals the row-1 self-needle) and the
/// D11 ORE-btree test have real discrimination — a constant `$.hello` would
/// make `expected == ROW_COUNT` and silently hollow the oracle. `number` also
/// varies (its own `$.number` oc). `nested` is a constant object so `$` and
/// `$.nested` carry stable `hm` leaves across all rows (LB2 / LB4).
fn documents() -> Vec<Value> {
    (1..=ROW_COUNT)
        .map(|i| {
            json!({
                "hello": format!("world-{i}"),
                "number": i,
                "nested": { "deep": "constant" },
            })
        })
        .collect()
}

/// Generate `tests/sqlx/fixtures/v3_ste_vec.sql` by encrypting the plaintext
/// documents through the shared `FixtureSpec` pipeline (connection-from-env,
/// stage → `format('%L')` render → drop-on-error teardown → file write — the
/// same code path the scalar fixtures use). The document set lives for the
/// duration of the call; the spec borrows it and `run()` completes before
/// return.
pub async fn generate() -> Result<()> {
    let docs = documents();
    FixtureSpec::new(NAME)
        .with_index(IndexKind::SteVec)
        .with_column_type(PAYLOAD_TYPE)
        .with_values(&docs)
        .run()
        .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn documents_are_ten_rows_with_distinct_hello_and_varying_number() {
        let docs = documents();
        assert_eq!(docs.len(), 10);
        // `$.hello` must be DISTINCT per row (oracle discrimination — Risk #0).
        let hellos: std::collections::HashSet<&str> =
            docs.iter().map(|d| d["hello"].as_str().unwrap()).collect();
        assert_eq!(hellos.len(), 10, "$.hello must be distinct across all rows");
        // `nested` is a constant object so `$.nested` carries a stable hm leaf.
        assert!(docs
            .iter()
            .all(|d| d["nested"] == json!({ "deep": "constant" })));
        let numbers: Vec<i64> = docs.iter().map(|d| d["number"].as_i64().unwrap()).collect();
        assert_eq!(numbers, (1..=10).collect::<Vec<_>>());
    }

    #[test]
    fn spec_builds_a_json_document_fixture() {
        let docs = documents();
        let spec = FixtureSpec::new(NAME)
            .with_index(IndexKind::SteVec)
            .with_column_type(PAYLOAD_TYPE)
            .with_values(&docs);
        assert_eq!(spec.fixture_table(), "fixtures.v3_ste_vec");
        assert_eq!(spec.column_type().as_str(), "eql_v3.json");
        assert_eq!(spec.indexes(), &[IndexKind::SteVec]);
        assert!(spec.check_complete().is_ok());
    }
}
