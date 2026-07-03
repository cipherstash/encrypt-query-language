//! # `from_v2` — EQL v2.3 → v3 wire conversion
//!
//! Converts the EQL v2.3 payloads cipherstash-client emits (reference
//! contract: `docs/reference/schema/eql-payload-v2.3.schema.json`) into v3
//! payloads for the `eql_v3` domains. Consumers: protect-ffi (which knows the
//! column configuration at runtime), the benches (which know per-table
//! intent), and potentially CipherStash Proxy.
//!
//! ## The target domain is explicit input
//!
//! Every v2 index term is optional on the wire, so a payload's capability
//! cannot be inferred — an `{v,k,c,i,hm}` payload could target `text_eq` or
//! be an over-provisioned `text` storage column. The caller names the target
//! via [`TargetDomain::parse`], which resolves against the catalog-generated
//! inventory ([`crate::v3::all`]) so the accepted names and required term
//! keys can never drift from `eql-domains::CATALOG`.
//!
//! ## Conversion rules
//!
//! **Scalar** (v2 `k: "ct"` → [`TargetDomain::Scalar`]): requires `v == 2`
//! and `k == "ct"`; copies `i` and `c` verbatim; emits `v: 3`; copies exactly
//! the term keys the target requires (`hm`/`ob`/`bf`/`op`), failing closed
//! with [`FromV2Error::MissingTerm`] when one is absent; DROPS `k` and every
//! term key the target does not require. `bf` is reinterpreted from v2's
//! unsigned bit positions into the signed `smallint[]` representation
//! (`32768..=65535` wrap negative; anything beyond is
//! [`FromV2Error::BloomOutOfRange`]; already-negative values pass through).
//! `ob` and `op` pass through verbatim.
//!
//! Two deliberate points of divergence from the v2.3 schema file:
//!
//! - **`k` is required.** The v2.3 schema marks `k` optional on the `ct`
//!   form; this converter requires it (cipherstash-client emits it on every
//!   payload). A `k`-less input is [`FromV2Error::UnknownKind`] — fail-closed
//!   beats guessing the shape of an unlabelled payload.
//! - **`op` is accepted as a scalar term key.** The v2.3 schema predates the
//!   CLLW-OPE term and cannot carry it (`additionalProperties: false`);
//!   cipherstash-client emits `op` for OPE-ordered columns ahead of the v3
//!   envelope, and the `_ord_ope` targets require it.
//!
//! **SteVec** (v2 `k: "sv"` → [`TargetDomain::Json`]): keeps the root `k`
//! (the v3 document models the `"sv"` form discriminator — required on the
//! wire), sets `v: 3`, keeps `i`; per entry keeps `s`, `c`, the optional
//! array-membership marker `a` (the v3 [`crate::v3::jsonb::SteVecEntry`]
//! retains it), and exactly one of `hm` XOR `oc`
//! ([`FromV2Error::AmbiguousTerm`] / [`FromV2Error::MissingTerm`] on
//! both/neither). v3 sv entries carry no per-entry `v`/`i`/`k` — the
//! envelope lives only at the root `{v, k, i, sv}`, exactly the
//! [`crate::v3::jsonb::SteVecDocument`] shape.
//!
//! Every converted payload is validated by a final strict parse through the
//! target's binding struct (`deny_unknown_fields` + [`crate::SchemaVersion`])
//! before it is returned — the converter never emits a payload the v3 domain
//! CHECK would reject. The parse happens exactly once per conversion:
//! [`from_v2`] validates and discards it
//! (via [`crate::v3::DomainType::parse_value`]) and returns the wire `Value`;
//! [`from_v2_typed`] KEEPS it, returning the matching
//! [`crate::v3::DomainPayload`] variant (whose untagged serialization is
//! byte-identical to the `Value` [`from_v2`] returns).
//!
//! ## Query payloads
//!
//! [`from_v2_query`] covers the jsonb containment needle
//! (`{sv: [{s, hm|oc}]}` → the [`crate::v3::jsonb::SteVecQuery`] shape),
//! normalizing entries down to `s` + one term exactly as the SQL cast
//! `eql_v3.to_ste_vec_query` does (stray `a` markers and `c` ciphertexts are
//! stripped). Scalar query targets return
//! [`FromV2Error::UnsupportedQueryTarget`]: no v3 scalar query wire shape
//! exists (every scalar domain CHECK requires the ciphertext `c` a query
//! payload omits), and this crate will not invent one ahead of the mapper
//! redesign.
//!
//! ## Decryption root: `sv[0]`
//!
//! The record ciphertext of a SteVec document — the `c` downstream decrypt
//! must hand to cipherstash-client — is carried by the FIRST `sv` entry
//! (`sv[0].c`, the root-selector entry). This mirrors upstream
//! `SteVec::into_root_ciphertext` and is exactly how v2 consumers treated
//! `sv[0].c` (see protect-ffi's `encrypted_record_from_mp_base85`). The v3
//! SQL surface does not re-state this invariant (its CHECKs validate shape,
//! not entry order), so conversion preserves `sv` entry order verbatim —
//! reordering entries would silently break decryption.

mod error;
mod target;

pub use error::FromV2Error;
pub use target::{ScalarTarget, TargetDomain};

use serde::de::Error as _;
use serde_json::{json, Map, Value};

use crate::v3::{all, DomainPayload};

/// The v2 wire version this converter accepts.
const V2_WIRE_VERSION: u64 = 2;

/// Convert a STORED EQL v2.3 payload into the v3 payload for `target`.
///
/// See the [module docs](self) for the conversion rules. Fails closed: the
/// returned value has already passed a strict parse through the target
/// domain's binding struct. Wire-oriented callers keep the `Value`; callers
/// that want the payload typed use [`from_v2_typed`] instead (same
/// conversion, same failures, one strict parse either way).
pub fn from_v2(v2: &Value, target: TargetDomain) -> Result<Value, FromV2Error> {
    let out = convert(v2, target)?;
    validate_as(target.describe(), &out)?;
    Ok(out)
}

/// Convert a STORED EQL v2.3 payload into the TYPED v3 payload for `target`:
/// [`from_v2`] returning the [`DomainPayload`] variant for the target domain
/// instead of a shape-erased `Value`.
///
/// Same conversion rules and same failures as [`from_v2`] — one shared
/// conversion path, and the final strict parse through the target's binding
/// struct happens exactly once (here it is KEPT as the enum variant; in
/// [`from_v2`] it is a validate-and-discard check). Because
/// [`DomainPayload`]'s serialization is untagged,
/// `serde_json::to_value(&from_v2_typed(v2, t)?)` equals `from_v2(v2, t)?`
/// exactly (pinned by `tests/domain_payload.rs`).
pub fn from_v2_typed(v2: &Value, target: TargetDomain) -> Result<DomainPayload, FromV2Error> {
    let out = convert(v2, target)?;
    DomainPayload::parse(target.describe(), &out)
        .unwrap_or_else(|| {
            // Every conversion target (all scalar domains + "json") has a
            // generated DomainPayload variant; TargetDomain::parse resolved
            // `target` against the same catalog.
            unreachable!(
                "conversion target {} must have a DomainPayload variant",
                target.describe()
            )
        })
        .map_err(FromV2Error::Invalid)
}

/// The shared conversion path behind [`from_v2`] / [`from_v2_typed`]:
/// dispatch on the v2 `k` form against the target shape and build the v3
/// payload `Value`. Does NOT run the final strict parse — each public entry
/// point does that exactly once (validate-and-discard in [`from_v2`],
/// parse-and-keep in [`from_v2_typed`]).
fn convert(v2: &Value, target: TargetDomain) -> Result<Value, FromV2Error> {
    let obj = require_v2_envelope(v2)?;
    let kind = obj.get("k").and_then(Value::as_str);
    match (kind, target) {
        (Some("ct"), TargetDomain::Scalar(t)) => convert_scalar(obj, t),
        (Some("sv"), TargetDomain::Json) => convert_ste_vec(obj),
        (Some(kind @ ("ct" | "sv")), _) => Err(FromV2Error::KindMismatch {
            kind: kind.into(),
            target: target.describe().into(),
        }),
        (found, _) => Err(FromV2Error::UnknownKind {
            found: found.map(String::from),
        }),
    }
}

/// Convert an EQL v2.3 QUERY payload into the v3 query payload for `target`.
///
/// Only [`TargetDomain::Json`] is supported: the v2 containment needle
/// (`{sv: [{s, hm|oc}]}`, per the v2.3 schema's `SteVecQueryPayload`)
/// converts to the [`crate::v3::jsonb::SteVecQuery`] shape, entries
/// normalized to `s` + exactly one term (mirroring `eql_v3.to_ste_vec_query`
/// — stray `a`/`c` keys are stripped, so a stored document payload can also
/// be normalized into a needle). A `v`/`k` envelope, if present, must be
/// v2/`sv`; `i` is dropped.
///
/// Scalar targets return [`FromV2Error::UnsupportedQueryTarget`]: v2 scalar
/// query payloads omit `c`, no v3 scalar domain admits a `c`-less payload,
/// and this crate will not invent a wire shape ahead of the mapper redesign.
pub fn from_v2_query(v2: &Value, target: TargetDomain) -> Result<Value, FromV2Error> {
    let scalar = match target {
        TargetDomain::Json => return convert_ste_vec_query(v2),
        TargetDomain::Scalar(t) => t,
    };
    Err(FromV2Error::UnsupportedQueryTarget {
        domain: scalar.domain().into(),
    })
}

/// Lenient v3 envelope probe for format sniffing (protect-ffi / proxy): true
/// when the value is an object with integer `v == 3`, an object `i`, and a
/// stored-payload body (string `c` for scalars, or array `sv` for SteVec
/// documents). Deliberately NOT a validator — it answers "should this go
/// down the v3 path?", not "is this a valid v3 payload?" (that is
/// [`crate::v3::DomainType::parse_value`]). Note a v3 containment needle
/// (`{sv: [...]}` with no envelope) is not a stored payload and probes false.
pub fn is_v3_payload(value: &Value) -> bool {
    let Some(obj) = value.as_object() else {
        return false;
    };
    obj.get("v").and_then(Value::as_u64) == Some(u64::from(crate::EQL_SCHEMA_VERSION))
        && obj.get("i").is_some_and(Value::is_object)
        && (obj.get("c").is_some_and(Value::is_string)
            || obj.get("sv").is_some_and(Value::is_array))
}

/// Require an object input carrying integer `v == 2`; return the object.
fn require_v2_envelope(v2: &Value) -> Result<&Map<String, Value>, FromV2Error> {
    let found = v2.get("v").and_then(Value::as_u64);
    if found != Some(V2_WIRE_VERSION) {
        return Err(FromV2Error::UnsupportedVersion { found });
    }
    // `get` above only succeeds on objects (or arrays, which cannot carry a
    // string key), so this cannot fail once the version matched.
    v2.as_object()
        .ok_or(FromV2Error::UnsupportedVersion { found: None })
}

/// A structurally-malformed-input error (non-array `sv`/`bf`, non-object
/// entry, …), wrapped as [`FromV2Error::Invalid`].
fn invalid(msg: &str) -> FromV2Error {
    FromV2Error::Invalid(serde_json::Error::custom(msg))
}

/// Final gate: strict-parse `value` through `domain`'s binding struct.
///
/// Rebuilds the inventory per call (as [`TargetDomain::parse`] does): a
/// static cache would need `all()` to return `dyn DomainType + Send + Sync`
/// — public API churn not worth ~50 zero-sized boxes per conversion unless
/// bulk-migration profiling ever says otherwise.
fn validate_as(domain: &str, value: &Value) -> Result<(), FromV2Error> {
    let entry = all()
        .into_iter()
        .find(|d| d.domain() == domain)
        .unwrap_or_else(|| {
            // `domain` always came from the same inventory via
            // `TargetDomain::parse` (or is the literal "json"/"jsonb_query").
            unreachable!("domain {domain} resolved by parse must be in the inventory")
        });
    entry.parse_value(value).map_err(FromV2Error::Invalid)
}

/// v2 `k: "ct"` → flat scalar `{v: 3, i, c, <required terms>}`.
fn convert_scalar(obj: &Map<String, Value>, target: ScalarTarget) -> Result<Value, FromV2Error> {
    let mut out = Map::new();
    out.insert("v".into(), json!(crate::EQL_SCHEMA_VERSION));
    for key in ["i", "c"] {
        if let Some(v) = obj.get(key) {
            out.insert(key.into(), v.clone());
        }
        // A missing envelope key fails the entry point's final strict parse
        // (e.g. a v2 QUERY payload, which omits `c`, is rejected there —
        // from_v2 converts stored payloads only).
    }
    for &key in target.term_json_keys() {
        let v = obj.get(key).ok_or_else(|| FromV2Error::MissingTerm {
            domain: target.domain().into(),
            key: key.into(),
            entry: None,
        })?;
        let converted = if key == "bf" {
            convert_bloom(v)?
        } else {
            // `hm` is a hex string, `ob` an array of hex blocks, `op` a hex
            // string — all representation-identical in v2 and v3.
            v.clone()
        };
        out.insert(key.into(), converted);
    }
    Ok(Value::Object(out))
}

/// Reinterpret a v2 `bf` array into the signed `smallint[]` representation:
/// in-range `i16` values pass through, the unsigned upper half
/// (`32768..=65535`) wraps negative (two's complement), anything else is
/// [`FromV2Error::BloomOutOfRange`].
fn convert_bloom(bf: &Value) -> Result<Value, FromV2Error> {
    let arr = bf
        .as_array()
        .ok_or_else(|| invalid("`bf` must be an array of bit positions"))?;
    let mut out = Vec::with_capacity(arr.len());
    for (index, el) in arr.iter().enumerate() {
        let value = el
            .as_i64()
            .ok_or_else(|| invalid("`bf` elements must be integers"))?;
        let reinterpreted: i16 = if (i64::from(i16::MIN)..=i64::from(i16::MAX)).contains(&value) {
            value as i16
        } else if (i64::from(i16::MAX) + 1..=i64::from(u16::MAX)).contains(&value) {
            (value as u16) as i16
        } else {
            return Err(FromV2Error::BloomOutOfRange { index, value });
        };
        out.push(Value::from(reinterpreted));
    }
    Ok(Value::Array(out))
}

/// v2 `k: "sv"` → SteVec document `{v: 3, k: "sv", i, sv: [{s, c, a?, hm|oc}]}`.
/// Entry order is preserved verbatim — `sv[0]` is the decryption root (see
/// the module docs).
fn convert_ste_vec(obj: &Map<String, Value>) -> Result<Value, FromV2Error> {
    let mut out = Map::new();
    out.insert("v".into(), json!(crate::EQL_SCHEMA_VERSION));
    // The root `k: "sv"` form discriminator is carried through: the v3
    // document models it ([`crate::v3::jsonb::SteVecDocument`]'s `k`,
    // required on the wire). `from_v2` already dispatched on `k == "sv"`, so
    // emitting the literal is exact.
    out.insert("k".into(), json!("sv"));
    if let Some(i) = obj.get("i") {
        out.insert("i".into(), i.clone());
        // Absent `i` fails the entry point's final strict parse.
    }
    let sv = obj
        .get("sv")
        .and_then(Value::as_array)
        .ok_or_else(|| invalid("`sv` must be an array of entries"))?;
    let entries = sv
        .iter()
        .enumerate()
        .map(|(idx, entry)| convert_entry(idx, entry, EntryShape::Document))
        .collect::<Result<Vec<_>, _>>()?;
    out.insert("sv".into(), Value::Array(entries));
    Ok(Value::Object(out))
}

/// v2 query needle `{sv: [{s, hm|oc, …}]}` → v3 `SteVecQuery` shape.
fn convert_ste_vec_query(v2: &Value) -> Result<Value, FromV2Error> {
    let obj = v2
        .as_object()
        .ok_or_else(|| invalid("a query payload must be a JSON object"))?;
    // The v2.3 SteVecQueryPayload carries no envelope, but tolerate one:
    // a versioned input must be v2, and a kind-discriminated one must be sv.
    if let Some(v) = obj.get("v") {
        if v.as_u64() != Some(V2_WIRE_VERSION) {
            return Err(FromV2Error::UnsupportedVersion { found: v.as_u64() });
        }
    }
    match obj.get("k").and_then(Value::as_str) {
        None | Some("sv") => {}
        Some(kind) => {
            return Err(FromV2Error::KindMismatch {
                kind: kind.into(),
                target: "json".into(),
            })
        }
    }
    let sv = obj
        .get("sv")
        .and_then(Value::as_array)
        .ok_or_else(|| invalid("`sv` must be an array of query entries"))?;
    let entries = sv
        .iter()
        .enumerate()
        .map(|(idx, entry)| convert_entry(idx, entry, EntryShape::Query))
        .collect::<Result<Vec<_>, _>>()?;
    let out = json!({ "sv": entries });
    validate_as("jsonb_query", &out)?;
    Ok(out)
}

/// Which keys an sv entry keeps after conversion.
#[derive(Clone, Copy)]
enum EntryShape {
    /// Document entry: `s`, `c`, optional `a`, one term.
    Document,
    /// Query entry: `s` + one term only (the `eql_v3.to_ste_vec_query`
    /// normalization — `a`/`c` are stripped).
    Query,
}

impl EntryShape {
    /// The keys the converted entry keeps beyond its term.
    fn kept_keys(self) -> &'static [&'static str] {
        match self {
            Self::Document => &["s", "c", "a"],
            Self::Query => &["s"],
        }
    }

    /// The (unqualified) SQL domain this entry shape belongs to, for error
    /// context.
    fn domain(self) -> &'static str {
        match self {
            Self::Document => "json",
            Self::Query => "jsonb_query",
        }
    }
}

/// Convert one v2 sv element: copy the shape's keys and exactly one of
/// `hm` XOR `oc`.
fn convert_entry(idx: usize, entry: &Value, shape: EntryShape) -> Result<Value, FromV2Error> {
    let obj = entry
        .as_object()
        .ok_or_else(|| invalid("`sv` entries must be JSON objects"))?;
    let mut out = Map::new();
    for &key in shape.kept_keys() {
        if let Some(v) = obj.get(key) {
            out.insert(key.into(), v.clone());
        }
        // A missing `s`/`c` fails the final document/query validation.
    }
    match (obj.get("hm"), obj.get("oc")) {
        (Some(_), Some(_)) => return Err(FromV2Error::AmbiguousTerm { entry: idx }),
        (Some(hm), None) => {
            out.insert("hm".into(), hm.clone());
        }
        (None, Some(oc)) => {
            out.insert("oc".into(), oc.clone());
        }
        (None, None) => {
            return Err(FromV2Error::MissingTerm {
                domain: shape.domain().into(),
                key: "hm|oc".into(),
                entry: Some(idx),
            })
        }
    }
    Ok(Value::Object(out))
}
