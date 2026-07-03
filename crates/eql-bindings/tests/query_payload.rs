//! Tests for the hand-written [`QueryPayload`] enum and the typed query
//! conversion path [`from_v2_query_typed`].
//!
//! The load-bearing contract mirrors `tests/domain_payload.rs`: the
//! byte-identical serialization pin — `serde_json::to_value(&from_v2_query_typed(..))`
//! must equal the `Value` the wire-oriented `from_v2_query` returns (the enum
//! is `#[serde(untagged)]`, so typing a query payload can never change the
//! wire) — plus failure parity: both entry points reject the same inputs with
//! the same errors, including [`FromV2Error::UnsupportedQueryTarget`] for
//! EVERY scalar target (no v3 scalar-query wire shape exists yet).

use eql_bindings::from_v2::{from_v2_query, from_v2_query_typed, FromV2Error, TargetDomain};
use eql_bindings::v3::{DomainType, QueryPayload};
use serde_json::{json, Value};

const CIPHERTEXT: &str = "mBbL@V^%dN?0W$;g)1-JP*cmqX%JhW0ZKZ^G?lNn$CfXJH";
const HEX: &str = "8067db44a848ab32c3056a3dbe4edf16";
const HEX_LONG: &str = "fbc7a11fc81f2a321553bc06a91f240bb7d8f3a9c6aec445a5ba6793";
const SELECTOR: &str = "9493d6010fe7845d52149b697729c745";

fn ident() -> Value {
    json!({ "t": "users", "c": "email" })
}

fn target(name: &str) -> TargetDomain {
    TargetDomain::parse(name).unwrap_or_else(|e| panic!("target {name} must parse: {e}"))
}

/// The serialization pin for one query conversion: the typed payload must
/// serialize to exactly the `Value` the untyped `from_v2_query` returns — as
/// a `Value` and as a canonical JSON string (mirrors
/// `tests/domain_payload.rs::assert_serialization_pin`).
fn assert_serialization_pin(v2: &Value) -> QueryPayload {
    let typed = from_v2_query_typed(v2, TargetDomain::Json).expect("typed conversion succeeds");
    let untyped = from_v2_query(v2, TargetDomain::Json).expect("untyped conversion succeeds");

    let typed_value = serde_json::to_value(&typed).expect("typed payload serializes");
    assert_eq!(
        typed_value, untyped,
        "to_value must match from_v2_query exactly"
    );

    assert_eq!(
        serde_json::to_string(&typed_value).unwrap(),
        serde_json::to_string(&untyped).unwrap(),
        "canonical string form must be byte-identical"
    );
    let direct: Value =
        serde_json::from_str(&serde_json::to_string(&typed).unwrap()).expect("direct form parses");
    assert_eq!(direct, untyped, "direct string form must round-trip equal");

    typed
}

// ---------------------------------------------------------------------------
// from_v2_query_typed — happy path (the jsonb containment needle)
// ---------------------------------------------------------------------------

#[test]
fn typed_needle_yields_the_ste_vec_variant() {
    // The v2.3 SteVecQueryPayload is `{sv:[{s, hm|oc}]}` — no envelope.
    let v2 = json!({
        "sv": [
            { "s": SELECTOR, "hm": HEX },
            { "s": SELECTOR, "oc": HEX_LONG }
        ]
    });
    let typed = assert_serialization_pin(&v2);
    assert_eq!(typed.domain(), "jsonb_query");
    assert_eq!(typed.sql_domain(), "eql_v3.jsonb_query");
    match &typed {
        QueryPayload::SteVec(q) => {
            assert_eq!(q.sv.len(), 2, "entry order/count preserved");
            assert_eq!(q.sql_domain(), "eql_v3.jsonb_query");
        }
    }
}

#[test]
fn typed_needle_normalizes_exactly_like_from_v2_query() {
    // A stored-document payload used as a needle: the envelope is dropped and
    // entries normalize to `s` + one term (`a`/`c` stripped) — pinned equal
    // to from_v2_query byte-for-byte.
    let v2 = json!({
        "v": 2,
        "k": "sv",
        "i": ident(),
        "sv": [ { "s": SELECTOR, "a": true, "c": CIPHERTEXT, "hm": HEX } ]
    });
    let typed = assert_serialization_pin(&v2);
    assert_eq!(
        serde_json::to_value(&typed).unwrap(),
        json!({ "sv": [ { "s": SELECTOR, "hm": HEX } ] })
    );
}

// ---------------------------------------------------------------------------
// from_v2_query_typed — failure parity with from_v2_query
// ---------------------------------------------------------------------------

#[test]
fn every_scalar_target_is_unsupported_on_both_entry_points() {
    // No v3 scalar-query wire shape exists (every scalar domain CHECK
    // requires the ciphertext `c` a query payload omits); QueryPayload fails
    // closed rather than inventing one ahead of the mapper redesign —
    // exhaustively, for every scalar domain in the catalog, on BOTH entry
    // points.
    let query = json!({ "v": 2, "k": "ct", "i": ident(), "hm": HEX });
    for family in eql_domains::scalar_families() {
        for domain in family.domains {
            let name = family.domain_name(domain);
            let t = target(&name);
            match from_v2_query_typed(&query, t).unwrap_err() {
                FromV2Error::UnsupportedQueryTarget { domain } => assert_eq!(domain, name),
                other => panic!("expected UnsupportedQueryTarget for {name}, got {other:?}"),
            }
            match from_v2_query(&query, t).unwrap_err() {
                FromV2Error::UnsupportedQueryTarget { domain } => assert_eq!(domain, name),
                other => panic!("expected UnsupportedQueryTarget for {name}, got {other:?}"),
            }
        }
    }
}

#[test]
fn typed_entry_term_errors_match_from_v2_query() {
    let both = json!({ "sv": [ { "s": SELECTOR, "hm": HEX, "oc": HEX_LONG } ] });
    assert!(matches!(
        from_v2_query_typed(&both, TargetDomain::Json).unwrap_err(),
        FromV2Error::AmbiguousTerm { entry: 0 }
    ));
    let neither = json!({ "sv": [ { "s": SELECTOR, "hm": HEX }, { "s": SELECTOR } ] });
    match from_v2_query_typed(&neither, TargetDomain::Json).unwrap_err() {
        FromV2Error::MissingTerm { domain, key, entry } => {
            assert_eq!(domain, "jsonb_query");
            assert_eq!(key, "hm|oc");
            assert_eq!(entry, Some(1));
        }
        other => panic!("expected MissingTerm, got {other:?}"),
    }
}

#[test]
fn typed_rejects_the_same_envelopes_as_from_v2_query() {
    // A versioned input must be v2, and a kind-discriminated one must be sv —
    // shared conversion path, so both entry points agree.
    let v3 = json!({ "v": 3, "sv": [ { "s": SELECTOR, "hm": HEX } ] });
    for err in [
        from_v2_query_typed(&v3, TargetDomain::Json).unwrap_err(),
        from_v2_query(&v3, TargetDomain::Json).unwrap_err(),
    ] {
        assert!(matches!(
            err,
            FromV2Error::UnsupportedVersion { found: Some(3) }
        ));
    }
    let ct = json!({ "k": "ct", "sv": [ { "s": SELECTOR, "hm": HEX } ] });
    for err in [
        from_v2_query_typed(&ct, TargetDomain::Json).unwrap_err(),
        from_v2_query(&ct, TargetDomain::Json).unwrap_err(),
    ] {
        assert!(matches!(err, FromV2Error::KindMismatch { .. }));
    }
}

// ---------------------------------------------------------------------------
// QueryPayload::parse — construct-from-known-domain
// ---------------------------------------------------------------------------

#[test]
fn parse_constructs_the_needle_from_its_domain_name() {
    let needle = json!({ "sv": [ { "s": SELECTOR, "hm": HEX } ] });
    let parsed = QueryPayload::parse("jsonb_query", &needle)
        .expect("jsonb_query must be a QueryPayload domain")
        .expect("strict parse must succeed");
    assert_eq!(parsed.domain(), "jsonb_query");
    assert_eq!(serde_json::to_value(&parsed).unwrap(), needle);
}

#[test]
fn parse_is_strict_exactly_like_the_binding_struct() {
    // SteVecQuery is `deny_unknown_fields` at the root — a stray root key
    // fails, exactly as the untyped path's validate_as does.
    let stray = json!({ "sv": [ { "s": SELECTOR, "hm": HEX } ], "extra": 1 });
    assert!(
        QueryPayload::parse("jsonb_query", &stray).unwrap().is_err(),
        "deny_unknown_fields must reject a stray root key"
    );
}

#[test]
fn parse_returns_none_for_non_query_domains() {
    // Stored-payload domains (DomainPayload territory), the entry shape, and
    // unknown names are not query payloads.
    for name in [
        "json",
        "jsonb_entry",
        "integer_eq",
        "eql_v3.jsonb_query",
        "",
    ] {
        assert!(
            QueryPayload::parse(name, &json!({})).is_none(),
            "{name:?} must not resolve to a QueryPayload variant"
        );
    }
}
