//! JSON Schema validation tests for the EQL v2.2 baseline and v2.3 target
//! payload formats. These do not touch the database.
//!
//! Goals:
//! - Lock the on-the-wire payload contracts as code so format drift is caught
//!   in CI rather than discovered at integration time.
//! - Document the v2.2 -> v2.3 delta as executable assertions: payloads that
//!   are valid in 2.2 (e.g. `b3` everywhere, `opf`/`opv` and `ocf`/`ocv`
//!   splits) must fail under 2.3, and vice versa.

use std::path::PathBuf;
use std::sync::OnceLock;

use jsonschema::Validator;
use serde_json::{json, Value};

// ---------- helpers ----------

fn load_schema(filename: &str) -> Value {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../docs/reference/schema")
        .join(filename);
    let text = std::fs::read_to_string(&path)
        .unwrap_or_else(|e| panic!("failed to read {}: {}", path.display(), e));
    serde_json::from_str(&text).unwrap_or_else(|e| panic!("schema is not valid JSON: {e}"))
}

fn compile(schema: &Value) -> Validator {
    // `validator_for` auto-detects the draft from the schema's `$schema`
    // keyword. Both files declare draft 2020-12, which is supported natively
    // by jsonschema >= 0.18.
    jsonschema::validator_for(schema).expect("schema fails to compile")
}

fn schema_v2_2() -> &'static Validator {
    static S: OnceLock<Validator> = OnceLock::new();
    S.get_or_init(|| compile(&load_schema("eql-payload-v2.2.schema.json")))
}

fn schema_v2_3() -> &'static Validator {
    static S: OnceLock<Validator> = OnceLock::new();
    S.get_or_init(|| compile(&load_schema("eql-payload-v2.3.schema.json")))
}

#[track_caller]
fn assert_valid(schema: &Validator, instance: &Value, label: &str) {
    if !schema.is_valid(instance) {
        let msgs: Vec<String> = schema
            .iter_errors(instance)
            .map(|e| format!("  - {} (at {})", e, e.instance_path()))
            .collect();
        panic!(
            "expected `{label}` to validate, but got:\n{}\ninstance:\n{}",
            msgs.join("\n"),
            serde_json::to_string_pretty(instance).unwrap()
        );
    }
}

#[track_caller]
fn assert_invalid(schema: &Validator, instance: &Value, label: &str) {
    if schema.is_valid(instance) {
        panic!(
            "expected `{label}` to fail validation, but it passed:\n{}",
            serde_json::to_string_pretty(instance).unwrap()
        );
    }
}

const CIPHERTEXT: &str = "mBbL@V^%dN?0W$;g)1-JP*cmqX%JhW0ZKZ^G?lNn$CfXJH";
const HEX: &str = "8067db44a848ab32c3056a3dbe4edf16";
const HEX_LONG: &str = "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793";
const SELECTOR: &str = "9493d6010fe7845d52149b697729c745";

fn ident() -> Value {
    json!({ "t": "users", "c": "email" })
}

// ===========================================================================
// v2.2 schema
// ===========================================================================

#[test]
fn v2_2_minimal_encrypted_payload_is_valid() {
    let p = json!({ "v": 2, "c": CIPHERTEXT, "i": ident() });
    assert_valid(schema_v2_2(), &p, "minimal encrypted payload");
}

#[test]
fn v2_2_full_encrypted_payload_with_all_index_terms_is_valid() {
    // v2.2 still has b3, opf and opv as separate fields.
    let p = json!({
        "v": 2,
        "k": "ct",
        "c": CIPHERTEXT,
        "i": ident(),
        "hm": HEX,
        "b3": HEX,
        "bf": [12, 47, 91, 188],
        "ob": [HEX, HEX_LONG],
        "ocf": HEX,
        "ocv": HEX_LONG,
        "opf": HEX,
        "opv": HEX_LONG
    });
    assert_valid(schema_v2_2(), &p, "fully populated encrypted payload");
}

#[test]
fn v2_2_ste_vec_payload_is_valid() {
    let p = json!({
        "v": 2,
        "k": "sv",
        "i": ident(),
        "sv": [
            { "s": SELECTOR, "a": false, "c": CIPHERTEXT, "b3": HEX },
            { "s": SELECTOR, "a": false, "c": CIPHERTEXT, "ocv": HEX_LONG },
            { "s": SELECTOR, "a": true,  "c": CIPHERTEXT, "ocf": HEX, "opv": HEX }
        ]
    });
    assert_valid(schema_v2_2(), &p, "ste_vec payload");
}

#[test]
fn v2_2_encrypted_missing_required_fields_fails() {
    let cases = [
        ("missing v", json!({ "c": CIPHERTEXT, "i": ident() })),
        ("missing c", json!({ "v": 2, "i": ident() })),
        ("missing i", json!({ "v": 2, "c": CIPHERTEXT })),
        (
            "ident missing t",
            json!({ "v": 2, "c": CIPHERTEXT, "i": { "c": "email" } }),
        ),
        (
            "ident missing c",
            json!({ "v": 2, "c": CIPHERTEXT, "i": { "t": "users" } }),
        ),
    ];
    for (label, p) in cases {
        assert_invalid(schema_v2_2(), &p, label);
    }
}

#[test]
fn v2_2_encrypted_with_wrong_version_fails() {
    let p = json!({ "v": 1, "c": CIPHERTEXT, "i": ident() });
    assert_invalid(schema_v2_2(), &p, "wrong version");
}

#[test]
fn v2_2_encrypted_payload_with_sv_fails() {
    // EncryptedPayload is mutually exclusive with SteVecPayload.
    let p = json!({
        "v": 2, "k": "ct", "c": CIPHERTEXT, "i": ident(),
        "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX }]
    });
    assert_invalid(schema_v2_2(), &p, "encrypted payload carrying sv");
}

#[test]
fn v2_2_ste_vec_payload_with_top_level_ciphertext_fails() {
    // SteVecPayload is metadata + sv only — no top-level c.
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "c": CIPHERTEXT,
        "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX }]
    });
    assert_invalid(schema_v2_2(), &p, "ste_vec payload with top-level c");
}

#[test]
fn v2_2_ste_vec_element_with_hm_fails() {
    // v2.2 forbids hm at the sv-element level (root-only term).
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX }]
    });
    assert_invalid(schema_v2_2(), &p, "sv element carrying hm");
}

#[test]
fn v2_2_ste_vec_element_with_root_only_fields_fails() {
    let cases = [
        (
            "element with i",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX, "i": ident() }]
            }),
        ),
        (
            "element with v",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX, "v": 2 }]
            }),
        ),
        (
            "element with nested sv",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{
                    "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX,
                    "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX }]
                }]
            }),
        ),
    ];
    for (label, p) in cases {
        assert_invalid(schema_v2_2(), &p, label);
    }
}

#[test]
fn v2_2_unknown_top_level_field_fails() {
    // additionalProperties: false at the root.
    let p = json!({
        "v": 2, "c": CIPHERTEXT, "i": ident(),
        "x": "not a known field"
    });
    assert_invalid(schema_v2_2(), &p, "unknown top-level field");
}

// ===========================================================================
// v2.3 schema
// ===========================================================================

#[test]
fn v2_3_minimal_encrypted_payload_is_valid() {
    let p = json!({ "v": 2, "c": CIPHERTEXT, "i": ident() });
    assert_valid(schema_v2_3(), &p, "minimal encrypted payload");
}

#[test]
fn v2_3_encrypted_payload_with_ob_only_is_valid() {
    // Root-only Block ORE. `oc` is sv-element only by convention, but the
    // schema doesn't restrict it to that level today — covered separately.
    let p = json!({
        "v": 2, "k": "ct", "c": CIPHERTEXT, "i": ident(),
        "hm": HEX, "ob": [HEX, HEX_LONG]
    });
    assert_valid(schema_v2_3(), &p, "encrypted with Block ORE only");
}

#[test]
fn v2_3_sv_element_with_oc_is_valid() {
    // `oc` covers string and number leaves. `hm` is NOT present on the
    // same element — the two are mutually exclusive per v2.3.
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [
            { "s": SELECTOR, "a": false, "c": CIPHERTEXT, "oc": HEX_LONG }
        ]
    });
    assert_valid(schema_v2_3(), &p, "sv element with single oc term");
}

#[test]
fn v2_3_ste_vec_payload_with_hm_in_elements_is_valid() {
    // v2.3 promotes element equality from b3 -> hm for boolean leaves and
    // for the placeholder entries that represent array / object roots.
    // String / number leaves carry `oc` instead. Every sv element has
    // exactly one — the two are mutually exclusive.
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [
            { "s": SELECTOR, "a": false, "c": CIPHERTEXT, "hm": HEX },
            { "s": SELECTOR, "a": true,  "c": CIPHERTEXT, "oc": HEX_LONG }
        ]
    });
    assert_valid(
        schema_v2_3(),
        &p,
        "ste_vec payload with hm-bearing + oc-bearing elements",
    );
}

#[test]
fn v2_3_sv_element_with_both_hm_and_oc_is_rejected() {
    // hm and oc are mutually exclusive: hm covers boolean leaves and the
    // placeholders for array / object roots; oc covers string / number
    // leaves. cipherstash-suite never emits both on the same entry.
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [
            { "s": SELECTOR, "a": false, "c": CIPHERTEXT, "hm": HEX, "oc": HEX_LONG }
        ]
    });
    assert_invalid(schema_v2_3(), &p, "sv element carrying both hm and oc");
}

#[test]
fn v2_3_sv_element_with_neither_hm_nor_oc_is_rejected() {
    // Every sv element carries exactly one of hm or oc — neither is also
    // malformed.
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [
            { "s": SELECTOR, "a": false, "c": CIPHERTEXT }
        ]
    });
    assert_invalid(schema_v2_3(), &p, "sv element with neither hm nor oc");
}

#[test]
fn v2_3_b3_field_is_rejected_everywhere() {
    let root = json!({
        "v": 2, "c": CIPHERTEXT, "i": ident(),
        "b3": HEX
    });
    assert_invalid(schema_v2_3(), &root, "encrypted payload carrying b3");

    let element = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "b3": HEX }]
    });
    assert_invalid(schema_v2_3(), &element, "sv element carrying b3");
}

#[test]
fn v2_3_legacy_split_ore_fields_are_rejected() {
    // v2.2 had `ocf` (ORE CLLW fixed) and `ocv` (ORE CLLW var) as separate
    // ordered fields. v2.3 collapses them into a single `oc` field. Width
    // information that was implied by the field name is now carried in a
    // leading domain-tag byte on the ciphertext.
    //
    // The OPE-side legacy fields (`opf` / `opv`) are also rejected — v2.3
    // doesn't support OPE on `eql_v2_encrypted` (deferred to a future
    // separate type).
    let cases = [
        (
            "encrypted payload with legacy ocf",
            json!({ "v": 2, "c": CIPHERTEXT, "i": ident(), "ocf": HEX }),
        ),
        (
            "encrypted payload with legacy ocv",
            json!({ "v": 2, "c": CIPHERTEXT, "i": ident(), "ocv": HEX_LONG }),
        ),
        (
            "encrypted payload with legacy opf",
            json!({ "v": 2, "c": CIPHERTEXT, "i": ident(), "opf": HEX }),
        ),
        (
            "encrypted payload with legacy opv",
            json!({ "v": 2, "c": CIPHERTEXT, "i": ident(), "opv": HEX_LONG }),
        ),
        (
            "sv element with legacy ocv",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX, "ocv": HEX_LONG }]
            }),
        ),
        (
            "sv element with `op` (OPE not supported in v2.3)",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX, "op": HEX }]
            }),
        ),
    ];
    for (label, p) in cases {
        assert_invalid(schema_v2_3(), &p, label);
    }
}

#[test]
fn v2_3_ob_and_oc_are_mutually_exclusive_at_root() {
    let p = json!({
        "v": 2, "c": CIPHERTEXT, "i": ident(),
        "oc": HEX_LONG, "ob": [HEX, HEX_LONG]
    });
    assert_invalid(schema_v2_3(), &p, "ob + oc");
}

#[test]
fn v2_3_ob_and_oc_are_mutually_exclusive_in_sv_element() {
    let p = json!({
        "v": 2, "k": "sv", "i": ident(),
        "sv": [{
            "s": SELECTOR, "c": CIPHERTEXT,
            "hm": HEX, "ob": [HEX, HEX_LONG], "oc": HEX_LONG
        }]
    });
    assert_invalid(schema_v2_3(), &p, "sv element with both ob and oc");
}

#[test]
fn v2_3_encrypted_payload_with_sv_is_rejected() {
    let p = json!({
        "v": 2, "k": "ct", "c": CIPHERTEXT, "i": ident(),
        "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX }]
    });
    assert_invalid(schema_v2_3(), &p, "encrypted payload with sv");
}

#[test]
fn v2_3_minimum_required_fields_enforced() {
    let cases = [
        ("missing v", json!({ "c": CIPHERTEXT, "i": ident() })),
        ("missing c (encrypted)", json!({ "v": 2, "i": ident() })),
        ("missing i (encrypted)", json!({ "v": 2, "c": CIPHERTEXT })),
        (
            "ste_vec missing sv",
            json!({ "v": 2, "k": "sv", "i": ident() }),
        ),
        (
            "ste_vec missing k",
            json!({ "v": 2, "i": ident(), "sv": [{ "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX }] }),
        ),
        (
            "sv element missing s",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{ "c": CIPHERTEXT, "hm": HEX }]
            }),
        ),
        (
            "sv element missing c",
            json!({
                "v": 2, "k": "sv", "i": ident(),
                "sv": [{ "s": SELECTOR, "hm": HEX }]
            }),
        ),
    ];
    for (label, p) in cases {
        assert_invalid(schema_v2_3(), &p, label);
    }
}
