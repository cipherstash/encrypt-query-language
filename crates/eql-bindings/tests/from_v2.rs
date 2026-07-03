//! Fixture-driven tests for the `from_v2` wire converter: EQL v2.3 payloads
//! (the JSON cipherstash-client emits, per
//! `docs/reference/schema/eql-payload-v2.3.schema.json`) into v3 payloads.
//! No database, no credentials — the v2 fixtures are literal wire shapes
//! modeled on the payload-schema test constants, and every converted output
//! is checked against the exact expected v3 JSON (the binding structs are the
//! contract; schema-file validation lives in
//! `tests/sqlx/tests/payload_schema_tests.rs`).

use eql_bindings::from_v2::{from_v2, from_v2_query, is_v3_payload, FromV2Error, TargetDomain};
use serde_json::{json, Value};

const CIPHERTEXT: &str = "mBbL@V^%dN?0W$;g)1-JP*cmqX%JhW0ZKZ^G?lNn$CfXJH";
const HEX: &str = "8067db44a848ab32c3056a3dbe4edf16";
const HEX_LONG: &str = "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793";
const SELECTOR: &str = "9493d6010fe7845d52149b697729c745";

fn ident() -> Value {
    json!({ "t": "users", "c": "email" })
}

/// A fully-populated v2.3 scalar (`k: "ct"`) payload: every index term the v2
/// wire can carry (plus `op`, which cipherstash-client adds for OPE-ordered
/// columns ahead of the v3 envelope), so conversions must both COPY the keys
/// the target requires and DROP the ones it doesn't.
fn v2_ct_full() -> Value {
    json!({
        "v": 2,
        "k": "ct",
        "c": CIPHERTEXT,
        "i": ident(),
        "hm": HEX,
        "bf": [12, 47, 91, 188],
        "ob": [HEX, HEX_LONG],
        "op": HEX
    })
}

/// A minimal v2.3 scalar payload: envelope only, no index terms.
fn v2_ct_minimal() -> Value {
    json!({ "v": 2, "k": "ct", "c": CIPHERTEXT, "i": ident() })
}

/// A v2.3 SteVec (`k: "sv"`) payload: an `hm` root entry first (the
/// decryption root — its `c` is the record ciphertext), then an `oc` leaf
/// carrying the optional array marker `a`.
fn v2_sv() -> Value {
    json!({
        "v": 2,
        "k": "sv",
        "i": ident(),
        "sv": [
            { "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX },
            { "s": SELECTOR, "a": true, "c": CIPHERTEXT, "oc": HEX_LONG }
        ]
    })
}

fn target(name: &str) -> TargetDomain {
    TargetDomain::parse(name).unwrap_or_else(|e| panic!("target {name} must parse: {e}"))
}

// ---------------------------------------------------------------------------
// TargetDomain::parse
// ---------------------------------------------------------------------------

#[test]
fn parse_resolves_every_catalog_scalar_domain_and_json() {
    // Shape-aware catalog resolution: every flat scalar domain name parses to
    // Scalar, the SteVec document parses to Json, and the SteVec entry/query
    // domains — real inventory members but not conversion targets — are
    // rejected, so `parse` can never drift from `eql-domains::CATALOG`.
    for family in eql_domains::CATALOG {
        for domain in family.domains {
            let name = family.domain_name(domain);
            let parsed = TargetDomain::parse(&name);
            if domain.is_scalar() {
                assert!(
                    matches!(parsed, Ok(TargetDomain::Scalar(_))),
                    "{name} must parse to Scalar, got {parsed:?}"
                );
            } else if name == "json" {
                assert_eq!(parsed.unwrap(), TargetDomain::Json);
            } else {
                assert!(
                    matches!(parsed, Err(FromV2Error::UnknownDomain { .. })),
                    "{name} is not a conversion target, got {parsed:?}"
                );
            }
        }
    }
}

#[test]
fn parse_rejects_unknown_domain_names() {
    for name in ["int5", "text_like", "eql_v3.integer_eq", "", "jsonb"] {
        let parsed = TargetDomain::parse(name);
        assert!(
            matches!(parsed, Err(FromV2Error::UnknownDomain { .. })),
            "{name:?} must be UnknownDomain, got {parsed:?}"
        );
    }
}

#[test]
fn target_domain_is_copy_and_comparable() {
    let a = target("integer_eq");
    let b = a; // Copy
    assert_eq!(a, b);
    assert_ne!(a, target("integer"));
    assert_ne!(a, TargetDomain::Json);
}

// ---------------------------------------------------------------------------
// Scalar conversions (k: "ct")
// ---------------------------------------------------------------------------

#[test]
fn storage_only_scalar_drops_k_and_all_terms() {
    let out = from_v2(&v2_ct_full(), target("integer")).unwrap();
    assert_eq!(out, json!({ "v": 3, "i": ident(), "c": CIPHERTEXT }));
    assert!(is_v3_payload(&out));
}

#[test]
fn text_eq_copies_hm_and_drops_the_rest() {
    let out = from_v2(&v2_ct_full(), target("text_eq")).unwrap();
    assert_eq!(
        out,
        json!({ "v": 3, "i": ident(), "c": CIPHERTEXT, "hm": HEX })
    );
    assert!(is_v3_payload(&out));
}

#[test]
fn integer_ord_ore_copies_ob_verbatim() {
    let out = from_v2(&v2_ct_full(), target("integer_ord_ore")).unwrap();
    assert_eq!(
        out,
        json!({ "v": 3, "i": ident(), "c": CIPHERTEXT, "ob": [HEX, HEX_LONG] })
    );
    assert!(is_v3_payload(&out));
}

#[test]
fn integer_ord_ope_copies_op_verbatim() {
    let out = from_v2(&v2_ct_full(), target("integer_ord_ope")).unwrap();
    assert_eq!(
        out,
        json!({ "v": 3, "i": ident(), "c": CIPHERTEXT, "op": HEX })
    );
}

#[test]
fn text_ord_ope_requires_both_hm_and_op() {
    let out = from_v2(&v2_ct_full(), target("text_ord_ope")).unwrap();
    assert_eq!(
        out,
        json!({ "v": 3, "i": ident(), "c": CIPHERTEXT, "hm": HEX, "op": HEX })
    );
}

#[test]
fn text_search_copies_hm_ob_and_bf() {
    let out = from_v2(&v2_ct_full(), target("text_search")).unwrap();
    assert_eq!(
        out,
        json!({
            "v": 3,
            "i": ident(),
            "c": CIPHERTEXT,
            "hm": HEX,
            "ob": [HEX, HEX_LONG],
            "bf": [12, 47, 91, 188]
        })
    );
    assert!(is_v3_payload(&out));
}

#[test]
fn missing_required_term_fails_closed() {
    let err = from_v2(&v2_ct_minimal(), target("text_eq")).unwrap_err();
    match err {
        FromV2Error::MissingTerm { domain, key, entry } => {
            assert_eq!(domain, "text_eq");
            assert_eq!(key, "hm");
            // Scalar payloads have no sv entries to index.
            assert_eq!(entry, None);
        }
        other => panic!("expected MissingTerm, got {other:?}"),
    }
    // Multi-term domain reports its first absent key.
    let err = from_v2(&v2_ct_minimal(), target("text_search")).unwrap_err();
    assert!(matches!(err, FromV2Error::MissingTerm { .. }));
}

#[test]
fn bloom_filter_upper_half_reinterprets_as_negative_i16() {
    // v2 emits unsigned bit positions; the upper half (32768..=65535) of a
    // 65536-wide filter wraps to negative i16 — 40000 - 65536 = -25536.
    let mut v2 = v2_ct_full();
    v2["bf"] = json!([0, 32767, 32768, 40000, 65535]);
    let out = from_v2(&v2, target("text_search")).unwrap();
    assert_eq!(out["bf"], json!([0, 32767, -32768, -25536, -1]));
}

#[test]
fn bloom_filter_already_signed_values_pass_through() {
    // The v2.3 schema also allows already-signed smallint values; they pass
    // through unchanged rather than double-wrapping.
    let mut v2 = v2_ct_full();
    v2["bf"] = json!([-1, -32768, 12]);
    let out = from_v2(&v2, target("text_search")).unwrap();
    assert_eq!(out["bf"], json!([-1, -32768, 12]));
}

#[test]
fn bloom_filter_element_above_u16_is_out_of_range() {
    let mut v2 = v2_ct_full();
    v2["bf"] = json!([12, 70000]);
    let err = from_v2(&v2, target("text_search")).unwrap_err();
    match err {
        FromV2Error::BloomOutOfRange { index, value } => {
            assert_eq!(index, 1);
            assert_eq!(value, 70000);
        }
        other => panic!("expected BloomOutOfRange, got {other:?}"),
    }
    // Below i16::MIN is equally unrepresentable.
    let mut v2 = v2_ct_full();
    v2["bf"] = json!([-32769]);
    assert!(matches!(
        from_v2(&v2, target("text_search")).unwrap_err(),
        FromV2Error::BloomOutOfRange { .. }
    ));
}

#[test]
fn bloom_filter_reinterpretation_is_exhaustively_correct() {
    // Exhaustive over EVERY representable input — stronger than a sampled
    // property test, and the domain is only ~98k values: the signed range is
    // identity, the unsigned upper half wraps two's-complement, and in both
    // cases the 16-bit pattern is preserved (`out as u16 == in as u16`, the
    // reinterpretation invariant).
    let inputs: Vec<i64> = (i64::from(i16::MIN)..=i64::from(u16::MAX)).collect();
    let mut v2 = v2_ct_full();
    v2["bf"] = json!(inputs);
    let out = from_v2(&v2, target("text_search")).unwrap();
    let out_bf = out["bf"].as_array().unwrap();
    assert_eq!(out_bf.len(), inputs.len());
    for (n, o) in inputs.iter().zip(out_bf) {
        let o = o.as_i64().unwrap();
        assert!((i64::from(i16::MIN)..=i64::from(i16::MAX)).contains(&o));
        assert_eq!(o as u16, *n as u16, "bit pattern must be preserved for {n}");
        if *n <= i64::from(i16::MAX) {
            assert_eq!(o, *n, "signed range is identity");
        } else {
            assert_eq!(o, *n - 65536, "unsigned upper half wraps negative");
        }
    }
    // The exact first values outside the representable domain are rejected.
    for bad in [i64::from(i16::MIN) - 1, i64::from(u16::MAX) + 1] {
        let mut v2 = v2_ct_full();
        v2["bf"] = json!([bad]);
        assert!(matches!(
            from_v2(&v2, target("text_search")).unwrap_err(),
            FromV2Error::BloomOutOfRange { index: 0, value } if value == bad
        ));
    }
}

#[test]
fn already_v3_input_is_rejected() {
    let v3 = json!({ "v": 3, "i": ident(), "c": CIPHERTEXT, "hm": HEX });
    let err = from_v2(&v3, target("text_eq")).unwrap_err();
    assert!(
        matches!(err, FromV2Error::UnsupportedVersion { found: Some(3) }),
        "got {err:?}"
    );
    // Non-envelope inputs (no `v` at all) are also unsupported-version.
    let err = from_v2(&json!({ "hello": "world" }), target("text_eq")).unwrap_err();
    assert!(matches!(
        err,
        FromV2Error::UnsupportedVersion { found: None }
    ));
    let err = from_v2(&json!("plaintext"), target("text_eq")).unwrap_err();
    assert!(matches!(err, FromV2Error::UnsupportedVersion { .. }));
}

#[test]
fn unknown_or_missing_kind_is_rejected() {
    let mut v2 = v2_ct_full();
    v2["k"] = json!("xx");
    assert!(matches!(
        from_v2(&v2, target("text_eq")).unwrap_err(),
        FromV2Error::UnknownKind { .. }
    ));
    let mut v2 = v2_ct_full();
    v2.as_object_mut().unwrap().remove("k");
    assert!(matches!(
        from_v2(&v2, target("text_eq")).unwrap_err(),
        FromV2Error::UnknownKind { found: None }
    ));
}

#[test]
fn kind_mismatch_is_rejected_in_both_directions() {
    // sv payload for a scalar target.
    assert!(matches!(
        from_v2(&v2_sv(), target("integer_eq")).unwrap_err(),
        FromV2Error::KindMismatch { .. }
    ));
    // ct payload for the Json target.
    assert!(matches!(
        from_v2(&v2_ct_full(), TargetDomain::Json).unwrap_err(),
        FromV2Error::KindMismatch { .. }
    ));
}

#[test]
fn v2_query_payload_without_ciphertext_is_rejected_by_from_v2() {
    // A v2 QUERY payload omits `c`; `from_v2` converts STORED payloads only,
    // and the final validation through the binding struct fails closed.
    let query = json!({ "v": 2, "k": "ct", "i": ident(), "hm": HEX });
    let err = from_v2(&query, target("text_eq")).unwrap_err();
    assert!(matches!(err, FromV2Error::Invalid(_)), "got {err:?}");
}

// ---------------------------------------------------------------------------
// SteVec conversions (k: "sv")
// ---------------------------------------------------------------------------

#[test]
fn ste_vec_document_converts_and_preserves_entry_order() {
    // Entry order is the decryption contract: sv[0] is the root entry whose
    // `c` is the record ciphertext (upstream `SteVec::into_root_ciphertext`),
    // so conversion must copy entries in order, `a` marker included. The root
    // `k: "sv"` form discriminator is carried through — the v3 document
    // models it (`SteVecDocument.k`, required on the wire).
    let out = from_v2(&v2_sv(), TargetDomain::Json).unwrap();
    assert_eq!(
        out,
        json!({
            "v": 3,
            "k": "sv",
            "i": ident(),
            "sv": [
                { "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX },
                { "s": SELECTOR, "c": CIPHERTEXT, "a": true, "oc": HEX_LONG }
            ]
        })
    );
    assert!(is_v3_payload(&out));
}

#[test]
fn ste_vec_entry_with_both_terms_is_ambiguous() {
    let mut v2 = v2_sv();
    v2["sv"][1] = json!({ "s": SELECTOR, "c": CIPHERTEXT, "hm": HEX, "oc": HEX_LONG });
    let err = from_v2(&v2, TargetDomain::Json).unwrap_err();
    assert!(matches!(err, FromV2Error::AmbiguousTerm { entry: 1 }));
}

#[test]
fn ste_vec_entry_with_neither_term_is_missing() {
    // Term-less entry at index 1: the error must locate it (mirroring
    // AmbiguousTerm) and name the document domain.
    let mut v2 = v2_sv();
    v2["sv"][1] = json!({ "s": SELECTOR, "c": CIPHERTEXT });
    let err = from_v2(&v2, TargetDomain::Json).unwrap_err();
    match err {
        FromV2Error::MissingTerm { domain, key, entry } => {
            assert_eq!(domain, "json");
            assert_eq!(key, "hm|oc");
            assert_eq!(entry, Some(1));
        }
        other => panic!("expected MissingTerm, got {other:?}"),
    }
}

// ---------------------------------------------------------------------------
// Query payloads
// ---------------------------------------------------------------------------

#[test]
fn ste_vec_query_converts_to_v3_needle() {
    // The v2.3 SteVecQueryPayload is `{sv:[{s, hm|oc}]}` — no envelope.
    let v2 = json!({
        "sv": [
            { "s": SELECTOR, "hm": HEX },
            { "s": SELECTOR, "oc": HEX_LONG }
        ]
    });
    let out = from_v2_query(&v2, TargetDomain::Json).unwrap();
    assert_eq!(out, v2);
}

#[test]
fn ste_vec_query_normalizes_c_and_a_away() {
    // Mirrors `eql_v3.to_ste_vec_query`: the canonical needle carries only
    // `s` + one term, so stray `a` markers (legal on v2 query elements) and
    // `c` (a stored-document entry re-used as a needle) are stripped.
    let v2 = json!({
        "v": 2,
        "k": "sv",
        "i": ident(),
        "sv": [ { "s": SELECTOR, "a": true, "c": CIPHERTEXT, "hm": HEX } ]
    });
    let out = from_v2_query(&v2, TargetDomain::Json).unwrap();
    assert_eq!(out, json!({ "sv": [ { "s": SELECTOR, "hm": HEX } ] }));
}

#[test]
fn ste_vec_query_entry_term_errors_match_document_rules() {
    let both = json!({ "sv": [ { "s": SELECTOR, "hm": HEX, "oc": HEX_LONG } ] });
    assert!(matches!(
        from_v2_query(&both, TargetDomain::Json).unwrap_err(),
        FromV2Error::AmbiguousTerm { entry: 0 }
    ));
    // The query path names ITS shape (jsonb_query, not json) and locates the
    // entry.
    let neither = json!({ "sv": [ { "s": SELECTOR, "hm": HEX }, { "s": SELECTOR } ] });
    match from_v2_query(&neither, TargetDomain::Json).unwrap_err() {
        FromV2Error::MissingTerm { domain, key, entry } => {
            assert_eq!(domain, "jsonb_query");
            assert_eq!(key, "hm|oc");
            assert_eq!(entry, Some(1));
        }
        other => panic!("expected MissingTerm, got {other:?}"),
    }
}

#[test]
fn scalar_query_targets_are_unsupported() {
    // No v3 scalar query wire shape exists (every scalar domain CHECK
    // requires `c`); inventing one here would guess ahead of the mapper
    // redesign, so the converter refuses.
    let query = json!({ "v": 2, "k": "ct", "i": ident(), "hm": HEX });
    let err = from_v2_query(&query, target("text_eq")).unwrap_err();
    match err {
        FromV2Error::UnsupportedQueryTarget { domain } => assert_eq!(domain, "text_eq"),
        other => panic!("expected UnsupportedQueryTarget, got {other:?}"),
    }
}

// ---------------------------------------------------------------------------
// is_v3_payload
// ---------------------------------------------------------------------------

#[test]
fn is_v3_payload_is_a_lenient_envelope_probe() {
    // True: converted outputs (asserted inline above) and hand-built v3
    // envelopes, scalar and SteVec.
    assert!(is_v3_payload(
        &json!({ "v": 3, "i": ident(), "c": CIPHERTEXT })
    ));
    assert!(is_v3_payload(&json!({ "v": 3, "i": ident(), "sv": [] })));

    // False: v2 payloads (scalar and sv), plaintext JSON, non-objects, and
    // fragments missing any probe key.
    assert!(!is_v3_payload(&v2_ct_full()));
    assert!(!is_v3_payload(&v2_sv()));
    assert!(!is_v3_payload(&json!({ "hello": "world", "v": 3 })));
    assert!(!is_v3_payload(&json!({ "v": 3, "c": CIPHERTEXT })));
    assert!(!is_v3_payload(
        &json!({ "v": 3, "i": "not-an-object", "c": CIPHERTEXT })
    ));
    assert!(!is_v3_payload(
        &json!({ "v": "3", "i": ident(), "c": CIPHERTEXT })
    ));
    assert!(!is_v3_payload(&json!("plaintext")));
    assert!(!is_v3_payload(&json!(3)));
    assert!(!is_v3_payload(&json!(null)));
}

// ---------------------------------------------------------------------------
// Error type contract
// ---------------------------------------------------------------------------

#[test]
fn errors_display_and_implement_std_error() {
    // Hand-rolled Display/Error (no thiserror): every variant renders a
    // non-empty, informative message, and Invalid exposes its serde source.
    let err = from_v2(&v2_ct_minimal(), target("text_eq")).unwrap_err();
    let msg = err.to_string();
    assert!(msg.contains("text_eq") && msg.contains("hm"), "got {msg:?}");

    let query = json!({ "v": 2, "k": "ct", "i": ident(), "hm": HEX });
    let invalid = from_v2(&query, target("text_eq")).unwrap_err();
    let source = std::error::Error::source(&invalid);
    assert!(
        source.is_some(),
        "Invalid must expose its serde_json source"
    );
}
