//! Conformance for the v3 tier: explicit, readable tests for the reference
//! token (`int4`) plus the term shapes it doesn't carry. The exhaustive
//! catalog-driven sweep (every domain, every required key) lives in
//! `catalog_parity.rs`.

use eql_bindings::v3::int4::{Int4, Int4Eq, Int4Ord, Int4OrdOre};
use eql_bindings::v3::text::TextMatch;
use eql_bindings::v3::DomainType;
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
fn rejects_missing_envelope_keys() {
    // v/i/c are the shared envelope contract every domain CHECK asserts. The
    // missing-term negatives cover hm/ob/bf; these cover the envelope itself —
    // dropping the version, identifier, or ciphertext fails at the type
    // boundary, the Rust analogue of the CHECK's NOT NULL envelope columns.
    let base = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    for key in ["v", "i", "c"] {
        let mut wire = base.clone();
        wire.as_object_mut().unwrap().remove(key);
        let result: Result<Int4Eq, _> = serde_json::from_value(wire);
        assert!(
            result.is_err(),
            "Int4Eq must reject a payload with no {key}"
        );
    }
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
    // Omit `hm`: it is not an Int4Ord field, so leaving it in would trip
    // deny_unknown_fields and the rejection could pass for the wrong reason.
    // This payload carries only the base fields, so the sole cause of failure
    // is the absent `ob`.
    let no_ob = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
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

#[test]
fn non_int4_tokens_round_trip_every_domain() {
    // int4 is exercised exhaustively above; the other ordered tokens carry the
    // *same* wire field names but were serialized by no test, so a copy-paste
    // field typo (e.g. `hm` -> `hmm` in `int8.rs`) would ship green —
    // `catalog_parity.rs` checks domain *names* only, never the wire shape.
    // This sweep roundtrips every non-int4 domain and pins its catalog name,
    // failing the instant a token drifts from the shared envelope/term contract.
    use eql_bindings::v3::{date::*, int2::*, int8::*, numeric::*, text::*};

    // Wire builders for the three shapes the ordered tokens share.
    let storage = |t: &str| json!({ "v": 2, "i": { "t": t, "c": "x" }, "c": "ct" });
    let eq = |t: &str| json!({ "v": 2, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef" });
    let ord = |t: &str| json!({ "v": 2, "i": { "t": t, "c": "x" }, "c": "ct", "ob": ["b0", "b1"] });
    // Text routes equality through `hm`, so its ordered domains carry both `hm`
    // and `ob` (`[Hm, Ore]`); `text_search` adds the Bloom-filter match term.
    let text_ord = |t: &str| json!({ "v": 2, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef", "ob": ["b0", "b1"] });
    let text_search = |t: &str| json!({ "v": 2, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef", "ob": ["b0", "b1"], "bf": [1, 2, 3] });

    // Roundtrip a payload byte-for-byte, then confirm the catalog domain name.
    macro_rules! round_trip {
        ($ty:ty, $wire:expr, $domain:expr) => {{
            let wire = $wire;
            let parsed: $ty = serde_json::from_value(wire.clone()).unwrap();
            assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
            assert_eq!(<$ty>::sql_domain_static(), $domain);
        }};
    }

    round_trip!(Int2, storage("a"), "eql_v3.int2");
    round_trip!(Int2Eq, eq("a"), "eql_v3.int2_eq");
    round_trip!(Int2Ord, ord("a"), "eql_v3.int2_ord");
    round_trip!(Int2OrdOre, ord("a"), "eql_v3.int2_ord_ore");

    round_trip!(Int8, storage("a"), "eql_v3.int8");
    round_trip!(Int8Eq, eq("a"), "eql_v3.int8_eq");
    round_trip!(Int8Ord, ord("a"), "eql_v3.int8_ord");
    round_trip!(Int8OrdOre, ord("a"), "eql_v3.int8_ord_ore");

    round_trip!(Date, storage("a"), "eql_v3.date");
    round_trip!(DateEq, eq("a"), "eql_v3.date_eq");
    round_trip!(DateOrd, ord("a"), "eql_v3.date_ord");
    round_trip!(DateOrdOre, ord("a"), "eql_v3.date_ord_ore");

    // numeric is the first scalar whose native ORE term exceeds 8 blocks (14);
    // the wire shape is identical, so the same `ord` builder applies.
    round_trip!(Numeric, storage("a"), "eql_v3.numeric");
    round_trip!(NumericEq, eq("a"), "eql_v3.numeric_eq");
    round_trip!(NumericOrd, ord("a"), "eql_v3.numeric_ord");
    round_trip!(NumericOrdOre, ord("a"), "eql_v3.numeric_ord_ore");

    // text_match is covered by `text_match_round_trips_signed_bloom_filter`.
    round_trip!(Text, storage("a"), "eql_v3.text");
    round_trip!(TextEq, eq("a"), "eql_v3.text_eq");
    round_trip!(TextOrd, text_ord("a"), "eql_v3.text_ord");
    round_trip!(TextOrdOre, text_ord("a"), "eql_v3.text_ord_ore");
    round_trip!(TextSearch, text_search("a"), "eql_v3.text_search");
}

#[test]
fn timestamp_round_trips_and_enforces_term_capabilities() {
    // timestamp is an ordered token (12-block ORE) — it carries the full
    // storage/`_eq`/`_ord`/`_ord_ore` shape, the same as the int scalars. The
    // int4 template was copy-pasted to produce it, so a dropped `hm`/`ob` or a
    // field typo would pass `catalog_parity` (domain names only) but is caught
    // here. (Was equality-only while the ORE comparator was hardcoded to 8
    // blocks; promoted once `eql_v3.ore_block_256` generalized to any width.)
    use eql_bindings::v3::timestamp::{Timestamp, TimestampEq, TimestampOrd, TimestampOrdOre};

    // Storage-only: envelope, no term.
    let storage = json!({
        "v": 2,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext"
    });
    let parsed: Timestamp = serde_json::from_value(storage.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), storage);
    assert_eq!(Timestamp::sql_domain_static(), "eql_v3.timestamp");

    // Equality: envelope + hm.
    let with_hm = json!({
        "v": 2,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: TimestampEq = serde_json::from_value(with_hm.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_hm);
    assert_eq!(TimestampEq::sql_domain_static(), "eql_v3.timestamp_eq");

    // Ordered: envelope + ob (a 12-block array on the wire; shape is the same).
    let with_ob = json!({
        "v": 2,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext",
        "ob": ["b0", "b1"]
    });
    let parsed: TimestampOrd = serde_json::from_value(with_ob.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_ob);
    assert_eq!(TimestampOrd::sql_domain_static(), "eql_v3.timestamp_ord");
    let parsed: TimestampOrdOre = serde_json::from_value(with_ob.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_ob);
    assert_eq!(
        TimestampOrdOre::sql_domain_static(),
        "eql_v3.timestamp_ord_ore"
    );

    // The searchable domains cannot let their term silently become optional.
    let no_hm = json!({
        "v": 2,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext"
    });
    let result: Result<TimestampEq, _> = serde_json::from_value(no_hm.clone());
    assert!(
        result.is_err(),
        "TimestampEq must reject a payload with no hm"
    );
    let result: Result<TimestampOrd, _> = serde_json::from_value(no_hm);
    assert!(
        result.is_err(),
        "TimestampOrd must reject a payload with no ob"
    );
}
