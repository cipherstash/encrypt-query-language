//! Conformance for the v3 tier: explicit, readable tests for the reference
//! token (`integer`) plus the term shapes it doesn't carry. The exhaustive
//! catalog-driven sweep (every domain, every required key) lives in
//! `catalog_parity.rs`.

use eql_bindings::v3::integer::{Integer, IntegerEq, IntegerOrd, IntegerOrdOpe, IntegerOrdOre};
use eql_bindings::v3::text::TextMatch;
use eql_bindings::v3::DomainType;
use serde_json::json;

#[test]
fn integer_storage_round_trips() {
    let wire = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let parsed: Integer = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(Integer::sql_domain_static(), "public.integer");
}

#[test]
fn integer_eq_round_trips() {
    let wire = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: IntegerEq = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(IntegerEq::sql_domain_static(), "public.integer_eq");
}

#[test]
fn integer_ord_round_trips() {
    let wire = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "ob": ["ore_block_0", "ore_block_1"]
    });
    let parsed: IntegerOrd = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    // `_ord_ore` is the same shape under the scheme-explicit domain name.
    let parsed: IntegerOrdOre = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(IntegerOrdOre::sql_domain_static(), "public.integer_ord_ore");
}

#[test]
fn integer_ord_ope_round_trips() {
    // `_ord_ope` carries the CLLW-OPE term: `op` is a single hex string (not
    // an array like `ob`), natively bytea-sortable after hex-decode.
    let wire = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "op": "00ffab"
    });
    let parsed: IntegerOrdOpe = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(IntegerOrdOpe::sql_domain_static(), "public.integer_ord_ope");
}

#[test]
fn integer_ord_ope_rejects_missing_ope_term() {
    // Only the base fields, so the sole cause of failure is the absent `op`.
    let no_op = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let result: Result<IntegerOrdOpe, _> = serde_json::from_value(no_op);
    assert!(
        result.is_err(),
        "IntegerOrdOpe must reject a payload with no op"
    );
}

#[test]
fn integer_eq_rejects_missing_hmac() {
    // The capability is type-enforced: an `integer_eq` payload with no `hm` is
    // not representable. This is the bug class — a search term missing its
    // index term — closed at the type boundary, before any consumer runs.
    let no_hm = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let result: Result<IntegerEq, _> = serde_json::from_value(no_hm);
    assert!(
        result.is_err(),
        "IntegerEq must reject a payload with no hm"
    );
}

#[test]
fn rejects_missing_envelope_keys() {
    // v/i/c are the shared envelope contract every domain CHECK asserts. The
    // missing-term negatives cover hm/ob/bf; these cover the envelope itself —
    // dropping the version, identifier, or ciphertext fails at the type
    // boundary, the Rust analogue of the CHECK's NOT NULL envelope columns.
    let base = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    for key in ["v", "i", "c"] {
        let mut wire = base.clone();
        wire.as_object_mut().unwrap().remove(key);
        let result: Result<IntegerEq, _> = serde_json::from_value(wire);
        assert!(
            result.is_err(),
            "IntegerEq must reject a payload with no {key}"
        );
    }
}

#[test]
fn rejects_wrong_envelope_version() {
    // The SchemaVersion field is the Rust analogue of the domain CHECK's
    // `VALUE->>'v' = '3'`: any other version — the legacy 2, and a string
    // "3", which the CHECK's `->>` coercion would accept — fails at the type
    // boundary instead of at INSERT.
    for v in [json!(1), json!(2), json!("3")] {
        let wire = json!({
            "v": v,
            "i": { "t": "users", "c": "age" },
            "c": "mp_base85_ciphertext",
            "hm": "deadbeef"
        });
        let result: Result<IntegerEq, _> = serde_json::from_value(wire);
        assert!(result.is_err(), "IntegerEq must reject v = {v}");
    }
}

#[test]
fn rejects_unknown_keys() {
    // deny_unknown_fields: a payload carrying keys outside the domain's set
    // is not silently accepted-and-stripped — a pass-through consumer must
    // not lose data it didn't know about.
    let wire = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef",
        "ob": ["ore_block_0"]
    });
    let result: Result<IntegerEq, _> = serde_json::from_value(wire);
    assert!(
        result.is_err(),
        "IntegerEq must reject a payload carrying keys beyond its domain (here: ob)"
    );
}

#[test]
fn integer_ord_rejects_missing_ore_term() {
    // Omit `hm`: it is not an IntegerOrd field, so leaving it in would trip
    // deny_unknown_fields and the rejection could pass for the wrong reason.
    // This payload carries only the base fields, so the sole cause of failure
    // is the absent `ob`.
    let no_ob = json!({
        "v": 3,
        "i": { "t": "users", "c": "age" },
        "c": "mp_base85_ciphertext"
    });
    let result: Result<IntegerOrd, _> = serde_json::from_value(no_ob);
    assert!(
        result.is_err(),
        "IntegerOrd must reject a payload with no ob"
    );
}

#[test]
fn text_match_round_trips_signed_bloom_filter() {
    // `bf` is signed i16 (smallint[]): filters sized above 32768 emit
    // upper-half bit positions as negative values.
    let wire = json!({
        "v": 3,
        "i": { "t": "users", "c": "email" },
        "c": "mp_base85_ciphertext",
        "bf": [-1, -32768, 32767, 0]
    });
    let parsed: TextMatch = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);

    let no_bf = json!({
        "v": 3,
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
fn non_integer_tokens_round_trip_every_domain() {
    // integer is exercised exhaustively above; the other ordered tokens carry the
    // *same* wire field names but were serialized by no test, so a copy-paste
    // field typo (e.g. `hm` -> `hmm` in `bigint.rs`) would ship green —
    // `catalog_parity.rs` checks domain *names* only, never the wire shape.
    // This sweep roundtrips every non-integer domain and pins its catalog name,
    // failing the instant a token drifts from the shared envelope/term contract.
    use eql_bindings::v3::{
        bigint::*, boolean::*, date::*, double::*, numeric::*, real::*, smallint::*, text::*,
    };

    // Wire builders for the shapes the ordered tokens share.
    let storage = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct" });
    let eq = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef" });
    let ord = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct", "ob": ["b0", "b1"] });
    // `_ord_ope` carries the CLLW-OPE hex string `op` (not an array).
    let ope = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct", "op": "00ffab" });
    // Text routes equality through `hm`, so its ordered domains carry both `hm`
    // and the ordering term (`[Hm, Ore]` / `[Hm, Ope]`); `text_search` adds the
    // Bloom-filter match term.
    let text_ord = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef", "ob": ["b0", "b1"] });
    let text_ope = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef", "op": "00ffab" });
    let text_search = |t: &str| json!({ "v": 3, "i": { "t": t, "c": "x" }, "c": "ct", "hm": "deadbeef", "ob": ["b0", "b1"], "bf": [1, 2, 3] });

    // Roundtrip a payload byte-for-byte, then confirm the catalog domain name.
    macro_rules! round_trip {
        ($ty:ty, $wire:expr, $domain:expr) => {{
            let wire = $wire;
            let parsed: $ty = serde_json::from_value(wire.clone()).unwrap();
            assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
            assert_eq!(<$ty>::sql_domain_static(), $domain);
        }};
    }

    round_trip!(Smallint, storage("a"), "public.smallint");
    round_trip!(SmallintEq, eq("a"), "public.smallint_eq");
    round_trip!(SmallintOrd, ord("a"), "public.smallint_ord");
    round_trip!(SmallintOrdOre, ord("a"), "public.smallint_ord_ore");
    round_trip!(SmallintOrdOpe, ope("a"), "public.smallint_ord_ope");

    round_trip!(Bigint, storage("a"), "public.bigint");
    round_trip!(BigintEq, eq("a"), "public.bigint_eq");
    round_trip!(BigintOrd, ord("a"), "public.bigint_ord");
    round_trip!(BigintOrdOre, ord("a"), "public.bigint_ord_ore");
    round_trip!(BigintOrdOpe, ope("a"), "public.bigint_ord_ope");

    round_trip!(Date, storage("a"), "public.date");
    round_trip!(DateEq, eq("a"), "public.date_eq");
    round_trip!(DateOrd, ord("a"), "public.date_ord");
    round_trip!(DateOrdOre, ord("a"), "public.date_ord_ore");
    round_trip!(DateOrdOpe, ope("a"), "public.date_ord_ope");

    // numeric is the first scalar whose native ORE term exceeds 8 blocks (14);
    // the wire shape is identical, so the same `ord` builder applies.
    round_trip!(Numeric, storage("a"), "public.numeric");
    round_trip!(NumericEq, eq("a"), "public.numeric_eq");
    round_trip!(NumericOrd, ord("a"), "public.numeric_ord");
    round_trip!(NumericOrdOre, ord("a"), "public.numeric_ord_ore");
    round_trip!(NumericOrdOpe, ope("a"), "public.numeric_ord_ope");

    // real/double are the float scalars (renamed from float4/float8); they carry
    // the same ordered-token wire shape as the int scalars (`hm` eq, `ob` ord).
    round_trip!(Real, storage("a"), "public.real");
    round_trip!(RealEq, eq("a"), "public.real_eq");
    round_trip!(RealOrd, ord("a"), "public.real_ord");
    round_trip!(RealOrdOre, ord("a"), "public.real_ord_ore");

    round_trip!(Double, storage("a"), "public.double");
    round_trip!(DoubleEq, eq("a"), "public.double_eq");
    round_trip!(DoubleOrd, ord("a"), "public.double_ord");
    round_trip!(DoubleOrdOre, ord("a"), "public.double_ord_ore");

    // boolean is storage-only (no eq/ord term) — just the shared envelope.
    round_trip!(Boolean, storage("a"), "public.boolean");

    // text_match is covered by `text_match_round_trips_signed_bloom_filter`.
    round_trip!(Text, storage("a"), "public.text");
    round_trip!(TextEq, eq("a"), "public.text_eq");
    round_trip!(TextOrd, text_ord("a"), "public.text_ord");
    round_trip!(TextOrdOre, text_ord("a"), "public.text_ord_ore");
    round_trip!(TextOrdOpe, text_ope("a"), "public.text_ord_ope");
    round_trip!(TextSearch, text_search("a"), "public.text_search");
}

#[test]
fn timestamp_round_trips_and_enforces_term_capabilities() {
    // timestamp is an ordered token (12-block ORE) — it carries the full
    // storage/`_eq`/`_ord`/`_ord_ore` shape, the same as the int scalars. The
    // integer template was copy-pasted to produce it, so a dropped `hm`/`ob` or a
    // field typo would pass `catalog_parity` (domain names only) but is caught
    // here. (Was equality-only while the ORE comparator was hardcoded to 8
    // blocks; promoted once `eql_v3.ore_block_256` generalized to any width.)
    use eql_bindings::v3::timestamp::{
        Timestamp, TimestampEq, TimestampOrd, TimestampOrdOpe, TimestampOrdOre,
    };

    // Storage-only: envelope, no term.
    let storage = json!({
        "v": 3,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext"
    });
    let parsed: Timestamp = serde_json::from_value(storage.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), storage);
    assert_eq!(Timestamp::sql_domain_static(), "public.timestamp");

    // Equality: envelope + hm.
    let with_hm = json!({
        "v": 3,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext",
        "hm": "deadbeef"
    });
    let parsed: TimestampEq = serde_json::from_value(with_hm.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_hm);
    assert_eq!(TimestampEq::sql_domain_static(), "public.timestamp_eq");

    // Ordered: envelope + ob (a 12-block array on the wire; shape is the same).
    let with_ob = json!({
        "v": 3,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext",
        "ob": ["b0", "b1"]
    });
    let parsed: TimestampOrd = serde_json::from_value(with_ob.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_ob);
    assert_eq!(TimestampOrd::sql_domain_static(), "public.timestamp_ord");
    let parsed: TimestampOrdOre = serde_json::from_value(with_ob.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_ob);
    assert_eq!(
        TimestampOrdOre::sql_domain_static(),
        "public.timestamp_ord_ore"
    );

    // OPE ordered: envelope + op (a single CLLW-OPE hex string).
    let with_op = json!({
        "v": 3,
        "i": { "t": "events", "c": "occurred_at" },
        "c": "mp_base85_ciphertext",
        "op": "00ffab"
    });
    let parsed: TimestampOrdOpe = serde_json::from_value(with_op.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), with_op);
    assert_eq!(
        TimestampOrdOpe::sql_domain_static(),
        "public.timestamp_ord_ope"
    );

    // The searchable domains cannot let their term silently become optional.
    let no_hm = json!({
        "v": 3,
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

#[test]
fn stevec_document_round_trips_and_enforces_envelope() {
    use eql_bindings::v3::jsonb::SteVecDocument;
    use eql_bindings::v3::DomainType;
    // The real cipherstash SteVec document envelope carries the `k` form
    // discriminator (`"sv"`), required by the canonical eql-payload-v2.3
    // `SteVecPayload` (`required: [v,k,i,sv]`) and emitted on every real payload.
    // The document struct is strict, so it must MODEL `k` — omitting it would
    // reject the real wire (the bug this test's real-crypto sibling caught).
    let wire = json!({
        "v": 3,
        "k": "sv",
        "i": { "t": "users", "c": "profile" },
        "sv": [
            { "s": "sel_root", "c": "ct_root", "hm": "deadbeef" },
            { "s": "sel_age", "c": "ct_age", "a": true, "oc": "cllw_ore" }
        ]
    });
    let parsed: SteVecDocument = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(SteVecDocument::sql_domain_static(), "public.json");

    // Envelope negatives (parity with the scalar integer tests) — now including `k`.
    for missing in ["v", "k", "i", "sv"] {
        let mut w = wire.clone();
        w.as_object_mut().unwrap().remove(missing);
        assert!(
            serde_json::from_value::<SteVecDocument>(w).is_err(),
            "missing {missing} must fail"
        );
    }
    // Wrong version (the legacy 2 is rejected now the tier carries v: 3).
    let mut wrong_v = wire.clone();
    wrong_v["v"] = json!(2);
    assert!(serde_json::from_value::<SteVecDocument>(wrong_v).is_err());
    // Wrong form discriminator: `k` is pinned to "sv" (like `v` is pinned to 3),
    // so a scalar-ciphertext (`k:"ct"`) payload can't be read back as a document.
    let mut wrong_k = wire.clone();
    wrong_k["k"] = json!("ct");
    assert!(
        serde_json::from_value::<SteVecDocument>(wrong_k).is_err(),
        "k other than \"sv\" must fail"
    );
    // Unknown top-level key (deny_unknown_fields; no flatten on the document).
    let mut extra = wire.clone();
    extra
        .as_object_mut()
        .unwrap()
        .insert("bogus".into(), json!(1));
    assert!(serde_json::from_value::<SteVecDocument>(extra).is_err());
}

#[test]
fn stevec_entry_untagged_term_and_neither_term_rejected() {
    use eql_bindings::v3::jsonb::{SteVecEntry, SteVecTerm};
    // hm arm.
    let hm: SteVecEntry =
        serde_json::from_value(json!({ "s": "sel", "c": "ct", "hm": "deadbeef" })).unwrap();
    assert!(matches!(hm.term, SteVecTerm::Hmac { .. }));
    // oc arm.
    let oc: SteVecEntry =
        serde_json::from_value(json!({ "s": "sel", "c": "ct", "oc": "cllw" })).unwrap();
    assert!(matches!(oc.term, SteVecTerm::OreCllw { .. }));
    // Lax: tolerates root i/v merged in by `->`.
    let merged: SteVecEntry = serde_json::from_value(
        json!({ "s": "sel", "c": "ct", "hm": "x", "i": {"t":"a","c":"b"}, "v": 3 }),
    )
    .unwrap();
    assert!(matches!(merged.term, SteVecTerm::Hmac { .. }));
    // MARQUEE NEGATIVE: neither hm nor oc must fail (untagged enum has no matching arm).
    assert!(
        serde_json::from_value::<SteVecEntry>(json!({ "s": "sel", "c": "ct" })).is_err(),
        "an entry with neither hm nor oc must be rejected"
    );
}

#[test]
fn stevec_entry_both_terms_present_resolves_to_first_untagged_arm() {
    // The inverse of the "neither" negative above. On the wire an entry carries
    // exactly one of `hm` XOR `oc` (enforced by the SQL CHECK, NOT client-side —
    // `#[serde(untagged)]` cannot express XOR). If a malformed payload somehow
    // carries BOTH, serde's untagged enum resolves to the FIRST matching arm in
    // declaration order — `SteVecTerm::Hmac` (the `hm` arm is declared first) —
    // rather than erroring. This pins that resolution so a reorder of the
    // `SteVecTerm` variants (which would silently flip the winner to `oc`) is a
    // test failure, and documents that client-side parsing does not enforce XOR.
    use eql_bindings::v3::jsonb::{SteVecEntry, SteVecTerm};
    let both: SteVecEntry =
        serde_json::from_value(json!({ "s": "sel", "c": "ct", "hm": "deadbeef", "oc": "cllw" }))
            .expect(
                "an entry with both hm and oc parses (XOR is a SQL-CHECK invariant, not serde)",
            );
    assert!(
        matches!(both.term, SteVecTerm::Hmac { .. }),
        "with both hm and oc present, the untagged enum must resolve to the first \
         arm (Hmac); a flip means the SteVecTerm variant order changed"
    );
}

#[test]
fn stevec_query_round_trips() {
    use eql_bindings::v3::jsonb::SteVecQuery;
    use eql_bindings::v3::DomainType;
    let wire = json!({ "sv": [ { "s": "sel", "hm": "deadbeef" } ] });
    let parsed: SteVecQuery = serde_json::from_value(wire.clone()).unwrap();
    assert_eq!(serde_json::to_value(&parsed).unwrap(), wire);
    assert_eq!(SteVecQuery::sql_domain_static(), "eql_v3.query_jsonb");
    // Unknown top-level key rejected (SteVecQuery has no flatten field).
    assert!(serde_json::from_value::<SteVecQuery>(json!({ "sv": [], "bogus": 1 })).is_err());
    // NOTE: a query ELEMENT carrying `c` is NOT rejected here — SteVecQueryEntry
    // has a flattened term, so deny_unknown_fields is inert. The "no ciphertext"
    // rule is enforced by the SQL CHECK (is_valid_ste_vec_query_payload) and
    // exercised in the real-crypto test (v3_ste_vec).
}

#[test]
fn stevec_document_and_query_schemas_are_strict() {
    use eql_bindings::v3::jsonb::{SteVecDocument, SteVecForm, SteVecQuery};
    use eql_bindings::v3::DomainType;
    use eql_bindings::{Identifier, SchemaVersion};
    let doc = SteVecDocument {
        v: SchemaVersion::CURRENT,
        k: SteVecForm::SV,
        i: Identifier {
            t: "x".into(),
            c: "y".into(),
        },
        sv: vec![],
    };
    let sdoc = serde_json::to_value(doc.schema()).unwrap();
    assert_eq!(sdoc.pointer("/additionalProperties"), Some(&json!(false)));
    assert_eq!(
        sdoc.pointer("/properties/v/$ref"),
        Some(&json!("#/$defs/SchemaVersion"))
    );
    assert_eq!(
        sdoc.pointer("/$defs/SchemaVersion/const"),
        Some(&json!(eql_bindings::EQL_SCHEMA_VERSION))
    );
    // `k` is pinned to the const "sv" via SteVecForm, exactly like `v`/SchemaVersion.
    assert_eq!(
        sdoc.pointer("/properties/k/$ref"),
        Some(&json!("#/$defs/SteVecForm"))
    );
    assert_eq!(sdoc.pointer("/$defs/SteVecForm/const"), Some(&json!("sv")));
    let q = SteVecQuery { sv: vec![] };
    let sq = serde_json::to_value(q.schema()).unwrap();
    assert_eq!(sq.pointer("/additionalProperties"), Some(&json!(false)));
    // SteVecDocument/Query domain names.
    assert_eq!(SteVecDocument::sql_domain_static(), "public.json");
    assert_eq!(SteVecQuery::sql_domain_static(), "eql_v3.query_jsonb");
}

#[test]
fn stevec_ts_exports_have_expected_shape() {
    // The ts-rs flatten/untagged risk: pin the emitted .ts STRUCTURALLY so a
    // regression is a test failure, not a human-inspection miss. Assertions match
    // against the `export type <Name> = ...;` BODY LINE — never loose single-char
    // `contains` over the whole file, which the generated header / imports / doc
    // comment satisfy trivially (a dropped field would still pass). During
    // `types:check`, read the freshly exported TS_RS_EXPORT_DIR output; plain
    // `cargo test` falls back to committed bindings next to the crate manifest.
    let base = match std::env::var("TS_RS_EXPORT_DIR") {
        Ok(dir) if !dir.is_empty() => format!("{dir}/v3"),
        _ => format!("{}/bindings/v3", env!("CARGO_MANIFEST_DIR")),
    };

    // The single `export type <Name> = ...;` body line, isolated from the header,
    // imports, and doc comment so substring checks pin the emitted TYPE, not prose.
    let export_line = |file: &str, name: &str| -> String {
        let text = std::fs::read_to_string(format!("{base}/{file}")).unwrap();
        text.lines()
            .find(|l| l.trim_start().starts_with(&format!("export type {name} ")))
            .unwrap_or_else(|| panic!("{file}: no `export type {name}` line"))
            .to_string()
    };

    // SteVecTerm: the untagged `{ hm } | { oc }` union — both arms present, joined.
    let term = export_line("SteVecTerm.ts", "SteVecTerm");
    assert!(
        term.contains("{ hm: Hmac256, }")
            && term.contains("{ oc: OreCllw, }")
            && term.contains('|'),
        "SteVecTerm.ts must be the `{{ hm }} | {{ oc }}` union, got: {term}"
    );

    // SteVecEntry: direct fields s/c, the flattened hm|oc term union, and the
    // OPTIONAL nullable array marker `a`. `a?: boolean | null` (not `a: boolean |
    // null`) pins ts-rs optionality so the TS binding agrees with the JSON Schema,
    // which excludes `a` from `required` — the drift a bare `Option<bool>` without
    // `#[ts(optional = nullable)]` silently reintroduces.
    let entry = export_line("SteVecEntry.ts", "SteVecEntry");
    for needle in [
        "s: Selector",
        "c: Ciphertext",
        "a?: boolean | null",
        "{ hm: Hmac256, }",
        "{ oc: OreCllw, }",
    ] {
        assert!(
            entry.contains(needle),
            "SteVecEntry.ts body must contain `{needle}`, got: {entry}"
        );
    }

    // Property ORDER pin. The generic `ts_property_order.rs` guard structurally
    // skips non-scalar (jsonb) domains, so the SteVec property order has no other
    // regression guard. Assert the exact ordered field prefix so a field reorder
    // in `jsonb.rs` (which changes the wire/consumer contract) fails here rather
    // than escaping to a manual diff.
    assert!(
        entry.contains("{ s: Selector, c: Ciphertext, a?: boolean | null, }"),
        "SteVecEntry.ts field order must be s, c, a (then the flattened term union), got: {entry}"
    );
    let document = export_line("SteVecDocument.ts", "SteVecDocument");
    assert!(
        document.contains(
            "{ v: SchemaVersion, k: SteVecForm, i: Identifier, sv: Array<SteVecEntry>, }"
        ),
        "SteVecDocument.ts field order must be v, k, i, sv, got: {document}"
    );
}
