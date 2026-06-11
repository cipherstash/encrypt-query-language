//! Conformance for the v3 tier: explicit, readable tests for the reference
//! token (`int4`) plus the term shapes it doesn't carry. The exhaustive
//! catalog-driven sweep (every domain, every required key) lives in
//! `catalog_parity.rs`.

use eql_types::v3::int4::{Int4, Int4Eq, Int4Ord, Int4OrdOre};
use eql_types::v3::text::TextMatch;
use eql_types::v3::DomainType;
use serde_json::json;

#[test]
fn int4_storage_round_trips() {
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let parsed: Int4 = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(Int4::sql_domain_static(), "eql_v3.int4");
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
    assert_eq!(Int4Eq::sql_domain_static(), "eql_v3.int4_eq");
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
    assert_eq!(Int4OrdOre::sql_domain_static(), "eql_v3.int4_ord_ore");
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
fn rejects_wrong_envelope_version() {
    // The SchemaVersion field is the Rust analogue of the domain CHECK's
    // `VALUE->>'v' = '2'`: any other version — including a string "2",
    // which the CHECK's `->>` coercion would accept — fails at the type
    // boundary instead of at INSERT.
    for v in [json!(1), json!(3), json!("2")] {
        let wire = json!({
            "v": v,
            "i": { "t": "users", "c": "age" },
            "c": "mp_base85_ciphertext",
            "hm": "deadbeef"
        });
        let result: Result<Int4Eq, _> = serde_json::from_value(wire);
        assert!(result.is_err(), "Int4Eq must reject v = {v}");
    }
}

#[test]
fn rejects_unknown_keys() {
    // deny_unknown_fields: a payload carrying keys outside the domain's set
    // is not silently accepted-and-stripped — a pass-through consumer must
    // not lose data it didn't know about.
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef",
        "ob": ["ore_block_0"]
    });
    let result: Result<Int4Eq, _> = serde_json::from_value(wire);
    assert!(
        result.is_err(),
        "Int4Eq must reject a payload carrying keys beyond its domain (here: ob)"
    );
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
