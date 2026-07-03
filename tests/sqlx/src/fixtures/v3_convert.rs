//! Route generated fixture payloads through `eql_bindings::from_v2` — the
//! v2 → v3 envelope conversion seam of the fixture pipeline (CIP-3347).
//!
//! The pinned cipherstash-client (0.35) emits EQL **v2** storage payloads
//! (`v: 2`, `k` discriminator). After the envelope bump (#340) every
//! `eql_v3` domain CHECK pins `VALUE->>'v' = '3'`, so raw client output can
//! no longer be inserted into (or cast to) any v3 domain. This module
//! converts each client payload into its v3 form before the driver stages
//! it, using the same fail-closed converter downstream consumers
//! (protect-ffi) use — never by hand-editing the JSON.
//!
//! ## Target selection: the fixture's index set names the intent
//!
//! `from_v2` copies exactly the term keys its [`TargetDomain`] requires and
//! drops the rest, but a fixture payload is shared across every domain of
//! its family (the matrix casts the same `payload` column to `<T>`,
//! `<T>_eq`, `<T>_ord`, …), so it must carry the UNION of the terms the
//! fixture's indexes produced. No single catalog target requires that union
//! for the integer families (`int4_eq` requires `hm` alone, `int4_ord_ore`
//! requires `ob` alone), so conversion runs once per **coverable** family
//! domain and merges the outputs:
//!
//! - a domain is coverable when every term it requires was produced by the
//!   fixture's indexes (`Unique` → `hm`, `Ore` → `ob`, `Match` → `bf`);
//! - `_ord_ope` domains are NEVER coverable — the pinned client emits no
//!   `op` term (CIP-3280), so they are skipped by construction. The ope
//!   suites keep their hand-built literal payloads
//!   (`tests/encrypted_domain/ope/`); a fixture cannot silently claim ope
//!   coverage because `from_v2` would fail closed with `MissingTerm`;
//! - every produced term must be consumed by at least one selected domain,
//!   otherwise the generator errors loudly (a `Match` index on a family
//!   with no bloom domain would otherwise silently drop `bf`).
//!
//! Merging is safe because every per-target output copies `v`/`i`/`c` and
//! each term verbatim from the same source payload — overlapping keys are
//! identical by construction, and the merge fails closed if they ever
//! disagree. Every merged key still came out of a validated `from_v2` call.
//!
//! The SteVec document fixtures (`v3_ste_vec`, `v3_doc_int4`) convert with
//! the single [`TargetDomain::Json`] target — the v3 document keeps
//! `k: "sv"` (the #336 wire shape) and its per-entry `hm` XOR `oc` terms.

use anyhow::{anyhow, bail, Context, Result};
use eql_bindings::from_v2::{from_v2, TargetDomain};
use eql_domains::{ScalarKind, Term, FIXTURES};
use serde_json::{Map, Value};

use super::index_kind::IndexKind;

/// Convert a batch of cipherstash-client v2 storage payloads into v3
/// payloads for a fixture of scalar kind `kind` generated with `indexes`.
///
/// Order-preserving: `out[i]` is the conversion of `payloads[i]`, so the
/// driver's positional plaintext/payload pairing survives. Fails closed on
/// the first payload `from_v2` rejects (missing term, wrong version,
/// malformed shape) — a generator must crash loudly rather than write an
/// invalid fixture.
pub fn to_v3_payloads(
    payloads: Vec<Value>,
    kind: ScalarKind,
    indexes: &[IndexKind],
) -> Result<Vec<Value>> {
    let targets = targets_for(kind, indexes)?;
    payloads
        .into_iter()
        .enumerate()
        .map(|(i, payload)| {
            convert_one(&payload, &targets)
                .with_context(|| format!("converting payload #{i} to the v3 envelope"))
        })
        .collect()
}

/// The wire term key an `IndexKind` makes the client emit on a scalar
/// storage payload (`None` for `SteVec`, whose terms live per `sv` entry).
fn term_key_for(index: IndexKind) -> Option<&'static str> {
    match index {
        IndexKind::Unique => Some("hm"),
        IndexKind::Ore => Some("ob"),
        IndexKind::Match => Some("bf"),
        IndexKind::SteVec => None,
    }
}

/// Resolve the conversion targets for a fixture: the coverable domains of
/// the catalog family for `kind` (see the module docs for the rules), or
/// the single `json` document target for [`ScalarKind::Jsonb`].
fn targets_for(kind: ScalarKind, indexes: &[IndexKind]) -> Result<Vec<TargetDomain>> {
    if kind == ScalarKind::Jsonb {
        let target = TargetDomain::parse("json")
            .map_err(|e| anyhow!("resolving the SteVec document target: {e}"))?;
        return Ok(vec![target]);
    }

    let family = FIXTURES
        .iter()
        .find(|f| f.kind == kind)
        .map(|f| f.family)
        .ok_or_else(|| anyhow!("no catalog family for scalar kind {kind:?}"))?;

    let provided: Vec<&str> = indexes.iter().filter_map(|&ix| term_key_for(ix)).collect();

    let mut targets = Vec::new();
    let mut consumed: Vec<&str> = Vec::new();
    for domain in family.domains {
        // The pinned client emits no `op` term (CIP-3280), so an `_ord_ope`
        // domain can never be generated from client output — skip it rather
        // than fail `MissingTerm` on every fixture. The ope suites use
        // hand-built literal payloads instead.
        if domain.terms.contains(&Term::Ope) {
            continue;
        }
        let required: Vec<&str> = domain.terms.iter().map(|t| t.json_key()).collect();
        if !required.iter().all(|key| provided.contains(key)) {
            continue;
        }
        let name = family.domain_name(domain);
        let target = TargetDomain::parse(&name)
            .map_err(|e| anyhow!("resolving conversion target {name:?}: {e}"))?;
        targets.push(target);
        consumed.extend(required);
    }

    if targets.is_empty() {
        bail!(
            "no coverable v3 domain in family {:?} for indexes {indexes:?}",
            family.name
        );
    }
    if let Some(orphan) = provided.iter().find(|key| !consumed.contains(key)) {
        bail!(
            "fixture term `{orphan}` (from {indexes:?}) is not required by any \
             coverable domain in family {:?} — it would be silently dropped",
            family.name
        );
    }
    Ok(targets)
}

/// Convert one v2 payload: run `from_v2` once per target and merge the
/// outputs into the union payload. Overlapping keys must agree (they are
/// copies of the same source fields, so a disagreement means a converter
/// bug — fail closed rather than pick one).
fn convert_one(payload: &Value, targets: &[TargetDomain]) -> Result<Value> {
    let mut merged = Map::new();
    for &target in targets {
        let converted =
            from_v2(payload, target).map_err(|e| anyhow!("from_v2 conversion failed: {e}"))?;
        let obj = converted
            .as_object()
            .ok_or_else(|| anyhow!("from_v2 returned a non-object payload"))?;
        for (key, value) in obj {
            match merged.get(key) {
                Some(existing) if existing != value => {
                    bail!("conflicting values for key `{key}` while merging per-domain conversions")
                }
                Some(_) => {}
                None => {
                    merged.insert(key.clone(), value.clone());
                }
            }
        }
    }
    Ok(Value::Object(merged))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    /// A realistic v2 int-scalar storage payload as the pinned client emits
    /// it for a `unique` + `ore` column config.
    fn v2_int_payload() -> Value {
        json!({
            "v": 2,
            "k": "ct",
            "i": { "t": "_fixture_eql_v3_int4", "c": "payload" },
            "c": "mBbKmsMMkbKAJcY2ZE!ceh0e1t",
            "hm": "e0e1c4bd2ff81c9ad4cc9ae9ab6c47a4cf7d0f7cca6ae916c56008fd5e78c99e",
            "ob": ["0a0b0c", "0d0e0f"],
        })
    }

    #[test]
    fn int_payload_converts_to_v3_with_the_term_union_and_no_k() {
        let out = to_v3_payloads(
            vec![v2_int_payload()],
            ScalarKind::I32,
            &[IndexKind::Unique, IndexKind::Ore],
        )
        .unwrap();
        assert_eq!(out.len(), 1);
        let obj = out[0].as_object().unwrap();

        // v3 envelope: v bumped, k dropped, i/c verbatim.
        assert_eq!(obj.get("v"), Some(&json!(3)));
        assert!(!obj.contains_key("k"), "scalar v3 payloads carry no `k`");
        assert_eq!(obj.get("i"), v2_int_payload().get("i"));
        assert_eq!(obj.get("c"), v2_int_payload().get("c"));

        // The UNION of the index-produced terms survives — `hm` (for
        // `int4_eq`) AND `ob` (for `int4_ord`/`int4_ord_ore`) — even though
        // no single int4 domain requires both.
        assert_eq!(obj.get("hm"), v2_int_payload().get("hm"));
        assert_eq!(obj.get("ob"), v2_int_payload().get("ob"));

        // Nothing else: no `op` (ord_ope is skipped — the client emits no
        // OPE term), no stray keys.
        let mut keys: Vec<&str> = obj.keys().map(String::as_str).collect();
        keys.sort_unstable();
        assert_eq!(keys, ["c", "hm", "i", "ob", "v"]);
    }

    #[test]
    fn conversion_preserves_batch_order() {
        let mut second = v2_int_payload();
        second["hm"] = json!("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        let out = to_v3_payloads(
            vec![v2_int_payload(), second.clone()],
            ScalarKind::I32,
            &[IndexKind::Unique, IndexKind::Ore],
        )
        .unwrap();
        assert_eq!(out.len(), 2);
        assert_eq!(out[0].get("hm"), v2_int_payload().get("hm"));
        assert_eq!(out[1].get("hm"), second.get("hm"));
    }

    #[test]
    fn text_payload_keeps_bloom_and_reinterprets_bit_positions_as_smallint() {
        let payload = json!({
            "v": 2,
            "k": "ct",
            "i": { "t": "_fixture_eql_v3_text", "c": "payload" },
            "c": "mBbKmsMMkbKAJcY2ZE!ceh0e1t",
            "hm": "e0e1c4bd2ff81c9ad4cc9ae9ab6c47a4cf7d0f7cca6ae916c56008fd5e78c99e",
            "ob": ["0a0b0c"],
            // v2 bloom bit positions are unsigned u16; 40000 must wrap to
            // the signed smallint[] representation (40000 - 65536 = -25536).
            "bf": [0, 32767, 40000],
        });
        let out = to_v3_payloads(
            vec![payload],
            ScalarKind::Text,
            &[IndexKind::Unique, IndexKind::Ore, IndexKind::Match],
        )
        .unwrap();
        let obj = out[0].as_object().unwrap();
        assert_eq!(obj.get("v"), Some(&json!(3)));
        assert_eq!(obj.get("bf"), Some(&json!([0, 32767, -25536])));
        let mut keys: Vec<&str> = obj.keys().map(String::as_str).collect();
        keys.sort_unstable();
        assert_eq!(keys, ["bf", "c", "hm", "i", "ob", "v"]);
    }

    #[test]
    fn storage_only_payload_converts_to_the_bare_envelope() {
        // `bool` is storage-only: no index, so the client payload carries no
        // term key and the v3 payload is exactly `{v, i, c}`.
        let payload = json!({
            "v": 2,
            "k": "ct",
            "i": { "t": "_fixture_eql_v3_bool", "c": "payload" },
            "c": "mBbKmsMMkbKAJcY2ZE!ceh0e1t",
        });
        let out = to_v3_payloads(vec![payload], ScalarKind::Bool, &[]).unwrap();
        let obj = out[0].as_object().unwrap();
        assert_eq!(obj.get("v"), Some(&json!(3)));
        let mut keys: Vec<&str> = obj.keys().map(String::as_str).collect();
        keys.sort_unstable();
        assert_eq!(keys, ["c", "i", "v"]);
    }

    #[test]
    fn ste_vec_document_converts_to_v3_keeping_k_and_entry_order() {
        // SteVec emits one `hm` (equality) and one `oc` (ordered) entry per
        // ordered leaf, under distinct selectors; sv[0] is the decryption
        // root and order must survive conversion.
        let payload = json!({
            "v": 2,
            "k": "sv",
            "i": { "t": "_fixture_v3_ste_vec", "c": "payload" },
            "sv": [
                { "s": "87042b77604cf03ab1ec9a05b5f9c2f7", "c": "root-ct", "hm": "8477cf88d9be4f92503b0d31dd575704" },
                { "s": "3a114ad13d25b030f41175114347de59", "c": "leaf-ct", "oc": "00010203", "a": false },
            ],
        });
        let out = to_v3_payloads(vec![payload], ScalarKind::Jsonb, &[IndexKind::SteVec]).unwrap();
        let obj = out[0].as_object().unwrap();
        assert_eq!(obj.get("v"), Some(&json!(3)));
        assert_eq!(obj.get("k"), Some(&json!("sv")), "the v3 document keeps k");
        let sv = obj.get("sv").and_then(Value::as_array).unwrap();
        assert_eq!(sv.len(), 2);
        assert_eq!(
            sv[0].get("s"),
            Some(&json!("87042b77604cf03ab1ec9a05b5f9c2f7")),
            "sv[0] (the decryption root) must stay first"
        );
        assert!(sv[0].get("hm").is_some(), "sv[0] must keep its hm term");
        assert_eq!(sv[1].get("oc"), Some(&json!("00010203")));
        assert_eq!(sv[1].get("a"), Some(&json!(false)));
    }

    #[test]
    fn missing_term_fails_closed() {
        // A `unique`+`ore` fixture whose payload lost `ob` must crash the
        // generator, not write a fixture the `_ord` domains reject.
        let mut payload = v2_int_payload();
        payload.as_object_mut().unwrap().remove("ob");
        let err = to_v3_payloads(
            vec![payload],
            ScalarKind::I32,
            &[IndexKind::Unique, IndexKind::Ore],
        )
        .unwrap_err();
        assert!(
            format!("{err:#}").contains("ob"),
            "error should name the missing term: {err:#}"
        );
    }

    #[test]
    fn unconsumed_term_fails_closed() {
        // The int4 family has no bloom domain: a `Match` index there would
        // produce a `bf` term no conversion target keeps. That is a fixture
        // misconfiguration and must error, not silently drop the term.
        let err = to_v3_payloads(
            vec![v2_int_payload()],
            ScalarKind::I32,
            &[IndexKind::Unique, IndexKind::Ore, IndexKind::Match],
        )
        .unwrap_err();
        assert!(
            format!("{err:#}").contains("bf"),
            "error should name the orphaned term: {err:#}"
        );
    }

    #[test]
    fn a_v3_input_is_rejected() {
        // Fail closed on double conversion: once the client emits v3
        // natively this seam must be REMOVED, not silently pass through.
        let mut payload = v2_int_payload();
        payload["v"] = json!(3);
        let err = to_v3_payloads(
            vec![payload],
            ScalarKind::I32,
            &[IndexKind::Unique, IndexKind::Ore],
        )
        .unwrap_err();
        assert!(
            format!("{err:#}").to_lowercase().contains("version"),
            "error should mention the unsupported version: {err:#}"
        );
    }
}
