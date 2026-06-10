//! Conformance for the v3 tier: explicit per-domain tests for the reference
//! token (`int4`, plus the term shapes it doesn't carry), then a generic
//! sweep over the whole registry — every domain type round-trips its wire
//! shape and rejects a payload missing any required key.

use eql_types::v3::int4::{Int4, Int4Eq, Int4Ord, Int4OrdOre};
use eql_types::v3::registry;
use eql_types::v3::text::TextMatch;
use serde_json::{json, Value};

#[test]
fn int4_storage_round_trips() {
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let parsed: Int4 = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(Int4::SQL_DOMAIN, "eql_v3.int4");
}

#[test]
fn int4_eq_round_trips() {
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: Int4Eq = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(Int4Eq::SQL_DOMAIN, "eql_v3.int4_eq");
}

#[test]
fn int4_ord_round_trips() {
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "ob": ["ore_block_0", "ore_block_1"]
    });
    let parsed: Int4Ord = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    // `_ord_ore` is the same shape under the scheme-explicit domain name.
    let parsed: Int4OrdOre = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(Int4OrdOre::SQL_DOMAIN, "eql_v3.int4_ord_ore");
}

#[test]
fn int4_eq_rejects_missing_hmac() {
    // The capability is type-enforced: an `int4_eq` payload with no `hm` is
    // not representable. This is the bug class — a search term missing its
    // index term — closed at the type boundary, before any consumer runs.
    let no_hm = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let result: Result<Int4Eq, _> = serde_json::from_value(no_hm);
    assert!(result.is_err(), "Int4Eq must reject a payload with no hm");
}

#[test]
fn int4_ord_rejects_missing_ore_term() {
    let no_ob = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let result: Result<Int4Ord, _> = serde_json::from_value(no_ob);
    assert!(result.is_err(), "Int4Ord must reject a payload with no ob");
}

#[test]
fn text_match_round_trips_signed_bloom_filter() {
    // `bf` is signed i16 (smallint[]): filters sized above 32768 emit
    // upper-half bit positions as negative values.
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "email" },
        "c": "mp_base85_ciphertext",
        "bf": [-1, -32768, 32767, 0]
    });
    let parsed: TextMatch = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);

    let no_bf = json!({
        "v": 2,
        "i": { "t": "users", "c": "email" },
        "c": "mp_base85_ciphertext"
    });
    let result: Result<TextMatch, _> = serde_json::from_value(no_bf);
    assert!(
        result.is_err(),
        "TextMatch must reject a payload with no bf"
    );
}

/// A synthetic wire value for a required key, by key name.
fn synthesize(key: &str) -> Value {
    match key {
        "v" => json!(2),
        "i" => json!({ "t": "users", "c": "field" }),
        "c" => json!("mp_base85_ciphertext"),
        "hm" => json!("deadbeef"),
        "ob" => json!(["ore_block_0", "ore_block_1"]),
        "bf" => json!([-1, 0, 32767]),
        other => panic!("no synthetic value for unexpected required key {other:?}"),
    }
}

/// The registry sweep: every domain type round-trips a payload synthesized
/// from its schema's required keys, and rejects the payload with any one
/// required key removed. (That the required keys are the *right* ones is
/// `catalog_parity.rs`'s job.)
#[test]
fn every_registered_domain_round_trips_and_rejects_missing_keys() {
    for entry in registry::all() {
        let schema = (entry.schema)();
        let required: Vec<String> = schema
            .schema
            .object
            .as_ref()
            .expect("object schema")
            .required
            .iter()
            .cloned()
            .collect();
        assert!(!required.is_empty(), "{}: no required keys", entry.domain);

        let full: Value = required
            .iter()
            .map(|k| (k.clone(), synthesize(k)))
            .collect::<serde_json::Map<_, _>>()
            .into();
        let round_tripped = (entry.roundtrip)(full.clone())
            .unwrap_or_else(|e| panic!("{}: round-trip failed: {e}", entry.domain));
        assert_eq!(
            round_tripped, full,
            "{}: round-trip not identity",
            entry.domain
        );

        for key in &required {
            let mut partial = full.clone();
            partial.as_object_mut().unwrap().remove(key);
            assert!(
                (entry.roundtrip)(partial).is_err(),
                "{}: must reject payload missing required key {key:?}",
                entry.domain
            );
        }
    }
}
