//! Conformance fixtures — the real guarantee that Rust / TS / JSON Schema and
//! the wire format agree. Codegen guarantees *shape*; these round-trips
//! guarantee *behaviour*.

use eql_types::int4::{Int4Eq, Int4Tagged};
use eql_types::v2_3::EqlEncrypted;
use serde_json::json;

#[test]
fn v2_3_scalar_round_trips() {
    let wire = json!({
        "k": "ct", "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: EqlEncrypted = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
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
fn legacy_payload_silently_accepts_missing_terms() {
    // Contrast: the frozen v2.3 scalar type accepts a payload carrying no
    // index terms at all — `hm`/`bf`/`ob` are optional. Nothing is wrong with
    // the payload *as v2.3*; the point is the type tells a consumer nothing
    // about which operators it can support. Hence the runtime guard.
    let bare = json!({
        "k": "ct", "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let parsed: EqlEncrypted = serde_json::from_value(bare).unwrap();
    match parsed {
        EqlEncrypted::Ct(p) => {
            assert!(p.hm.is_none() && p.bf.is_none() && p.ob.is_none());
        }
        EqlEncrypted::Sv(_) => panic!("expected Ct"),
    }
}

#[test]
fn v2_3_scalar_without_k_is_accepted() {
    // The canonical v2.3 schema makes `k` optional on the scalar form
    // (required: v, c, i) and check_encrypted discriminates on c-vs-sv, not k.
    // A scalar payload that omits `k` must still deserialize as `Ct`.
    let wire = json!({
        "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: EqlEncrypted = serde_json::from_value(wire).unwrap();
    assert!(matches!(parsed, EqlEncrypted::Ct(_)));
    // Serialization always re-emits the discriminator.
    assert_eq!(
        serde_json::to_value(&parsed).unwrap(),
        json!({
            "k": "ct", "v": 2,
            "i": { "t": "users", "c": "age" },
            "c": "mp_base85_ciphertext",
            "hm": "deadbeef"
        })
    );
}

#[test]
fn v2_3_bf_accepts_negative_smallint() {
    // `bf` is stored as smallint[] (signed i16). A `match` filter sized above
    // 32768 (allowed up to 65536) emits upper-half bit positions as negative
    // signed smallints; the type must round-trip them.
    let wire = json!({
        "k": "ct", "v": 2,
        "i": { "t": "users", "c": "email" },
        "c": "mp_base85_ciphertext",
        "bf": [-1, -32768, 32767, 0]
    });
    let parsed: EqlEncrypted = serde_json::from_value(wire.clone()).unwrap();
    assert!(matches!(parsed, EqlEncrypted::Ct(_)));
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
}

#[test]
fn v2_3_ste_vec_round_trips() {
    // Exercises the `sv` path: SteVecPayload plus the flatten + untagged
    // SteVecTerm (both `hm` and `oc` elements) — the crate's most fragile serde
    // construct, and the route the hand-written EqlEncrypted::deserialize takes.
    let wire = json!({
        "k": "sv", "v": 2,
        "i": { "t": "users", "c": "profile" },
        "sv": [
            { "s": "selector_root", "c": "ct_root", "hm": "deadbeef" },
            { "s": "selector_name", "c": "ct_name", "oc": "00cafe", "a": true }
        ]
    });
    let parsed: EqlEncrypted = serde_json::from_value(wire.clone()).unwrap();
    assert!(matches!(parsed, EqlEncrypted::Sv(_)));
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
}

#[test]
fn int4_tagged_proposal_round_trips_and_discriminates() {
    let wire = json!({
        "x": "int4_eq", "v": 2,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: Int4Tagged = serde_json::from_value(wire.clone()).unwrap();
    assert!(matches!(parsed, Int4Tagged::Eq { .. }));
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
}

#[test]
fn dump_json_schemas() {
    use schemars::schema_for;
    std::fs::create_dir_all("schema").unwrap();
    let schemas = [
        ("EqlEncrypted", schema_for!(EqlEncrypted)),
        ("Int4Eq", schema_for!(Int4Eq)),
        ("Int4Tagged", schema_for!(Int4Tagged)),
    ];
    for (name, schema) in schemas {
        std::fs::write(
            format!("schema/{name}.json"),
            serde_json::to_string_pretty(&schema).unwrap(),
        )
        .unwrap();
    }
}
