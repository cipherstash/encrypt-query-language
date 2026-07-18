//! The `json` (SteVec) encrypted-JSON payload types — HAND-WRITTEN.
//!
//! Unlike the scalar families, the SteVec struct bodies (fields, `#[serde(flatten)]`,
//! the `Option<bool>` array marker, per-struct serde strictness) are not derivable
//! from `eql-domains::CATALOG`, so they live here by hand — symmetric with the
//! hand-written SQL under `src/v3/json/`. The generated `inventory.rs` still lists
//! these three domains (in CATALOG order) via its `Shape` branch. See the SteVec
//! caveat in `mod.rs` for why the entry/query structs are necessarily lax.

use schemars::{schema_for, JsonSchema, Schema};
use serde::{Deserialize, Serialize};
use ts_rs::TS;

use crate::v3::terms::{EntryCiphertext, KeyHeader, OpeCllw, Selector};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};

/// The bare ciphertext-only storage domain `public.eql_v3_json` — a flat
/// `{v,i,c}` scalar struct, GENERATED (unlike the SteVec structs in this
/// module) into `json_storage.rs` by the catalog materializer. Re-exported here
/// so the generated `inventory.rs` / `payload.rs`, which reference every json
/// domain's struct through `super::json::<Struct>`, resolve `Json` without a
/// shape-aware module path in the renderer.
pub use crate::v3::json_storage::Json;

/// The `k` envelope key — the EQL payload **form discriminator**, always the
/// literal `"sv"` for an encrypted-JSONB document.
///
/// `k` distinguishes the payload forms in the canonical wire contract (`"ct"` =
/// scalar ciphertext, `"sv"` = STE-vec). `eql_v3` itself does not consume `k`
/// (the typed domain + the structural `c`-vs-`sv` shape already discriminate,
/// and no `eql_v3` SQL reads it), but the canonical `SteVecPayload`
/// (`eql-payload-v2.3.schema.json`, `required: [v,k,i,sv]`) mandates it and
/// cipherstash-client emits it on every SteVec document — so the strict document
/// struct must model it or it rejects the real wire.
///
/// Pinned exactly like [`SchemaVersion`] pins `v`: deserialization rejects any
/// value other than `"sv"`, so a scalar (`k:"ct"`) payload cannot be read back
/// as a document. The inner value is private; the only constructible instance is
/// [`SteVecForm::SV`].
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Serialize, TS)]
#[ts(export, export_to = "v3/")]
pub struct SteVecForm(#[ts(type = "\"sv\"")] &'static str);

impl SteVecForm {
    /// The only valid form for a document: the STE-vec discriminator `"sv"`.
    pub const SV: Self = Self("sv");
}

impl<'de> Deserialize<'de> for SteVecForm {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let k = String::deserialize(deserializer)?;
        if k == "sv" {
            Ok(Self::SV)
        } else {
            Err(serde::de::Error::custom(format!(
                "unsupported SteVec form discriminator {k:?} (expected \"sv\")"
            )))
        }
    }
}

/// Manual schema: pins `k` to the literal `"sv"` (`const`), mirroring the
/// `SchemaVersion` schema — the derive would emit an unconstrained string.
impl JsonSchema for SteVecForm {
    fn schema_name() -> std::borrow::Cow<'static, str> {
        "SteVecForm".into()
    }

    fn json_schema(_: &mut schemars::SchemaGenerator) -> schemars::Schema {
        schemars::json_schema!({
            "type": "string",
            "const": "sv",
            "description": "The `k` envelope form discriminator — always `\"sv\"` for a SteVec document.",
        })
    }
}

/// `public.eql_v3_json_search` — a SteVec encrypted-JSON document
/// (`{v, k, i, h, sv:[entry]}`, no root ciphertext — the root document
/// ciphertext lives on the root sv entry). Strict. `k` is the `"sv"` form
/// discriminator (see [`SteVecForm`]); `h` is the document [`KeyHeader`],
/// stored once for the whole document (every entry encrypts under the
/// document's single data key, with per-entry nonces derived from the
/// entries' selectors).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct SteVecDocument {
    pub v: SchemaVersion,
    pub k: SteVecForm,
    pub i: Identifier,
    pub h: KeyHeader,
    pub sv: Vec<SteVecEntry>,
}

/// `public.eql_v3_json_entry` — one sv element (returned by `->`). Carries a
/// selector `s`, raw AEAD ciphertext `c` (see [`EntryCiphertext`] — the
/// decryption unit is `h` + `s` + `c`, with the document `h` grafted onto
/// extracted entries by `->`), an optional array-membership marker `a`
/// (emitted only when true), and — for ordered (number/string) path entries
/// only — the `op` ordering term. Value entries (value-inclusive selectors)
/// and non-orderable path entries are term-less: exact matching is selector
/// presence, so no per-entry equality term exists (`hm` is retired). LAX
/// (flatten precludes `deny_unknown_fields`): tolerates the root `i`/`v`/`h`
/// merged in by `->`.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct SteVecEntry {
    pub s: Selector,
    pub c: EntryCiphertext,
    // `#[ts(optional = nullable)]` emits `a?: boolean | null` — ts-rs does NOT
    // infer optionality from serde `default`/`skip_serializing_if` (10.1: only an
    // explicit `#[ts(optional)]`/`optional = nullable` does), so without this the
    // TS binding would render `a` REQUIRED and drift from the JSON Schema, which
    // excludes `a` from `required`. `= nullable` keeps the `| null`.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[ts(optional = nullable)]
    pub a: Option<bool>,
    // Flattened, NOT `Option<SteVecTerm>`: ts-rs does not flatten `Option`
    // (it would emit a literal `term` property and drift from the wire), so
    // term-lessness is the enum's own `None {}` arm — serde flattens it to
    // no keys at all, and both generators render the union faithfully.
    #[serde(flatten)]
    pub term: SteVecTerm,
}

/// `eql_v3.query_json` — a containment needle (`{sv:[query-entry]}`). Strict.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct SteVecQuery {
    pub sv: Vec<SteVecQueryEntry>,
}

/// One element of a SteVec containment needle: a selector plus — for ordered
/// path entries only — the `op` ordering term; value-selector and structural
/// entries are selector-only (matched on presence), and (per the SQL CHECK)
/// no element carries a ciphertext. LAX for the same flatten reason as
/// `SteVecEntry`; the "no `c`" contract is enforced by `is_valid_ste_vec_query_payload`.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct SteVecQueryEntry {
    pub s: Selector,
    // Same flattened-enum modeling as `SteVecEntry.term` (see there for why
    // this is not an `Option`).
    #[serde(flatten)]
    pub term: SteVecTerm,
}

/// The per-entry ordering term: `op` (CLLW-OPE) on ordered (number/string)
/// path entries, or nothing at all — value entries (value-inclusive
/// selectors) and non-orderable path entries are term-less, because exact
/// matching is selector presence, not a per-entry term (`hm` is retired).
///
/// Untagged, with term-lessness as the explicit `None` arm rather than an
/// `Option` on the field: serde serializes `None {}` to no keys (flattened:
/// nothing), and — unlike a flattened `Option`, which ts-rs renders as a
/// literal `term` property — both ts-rs and schemars render this union
/// faithfully (`{ op } | {}`). Arm ORDER is load-bearing: `None {}` matches
/// any object, so it must be declared last.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(untagged)]
pub enum SteVecTerm {
    /// Ordered (number/string) path entry: the CLLW-OPE `op` term.
    OpeCllw { op: OpeCllw },
    /// Term-less: a value entry or a non-orderable path entry.
    None {},
}

impl SteVecTerm {
    /// True for the term-less arm.
    pub fn is_none(&self) -> bool {
        matches!(self, Self::None {})
    }
}

macro_rules! ste_vec_domain_type {
    ($ty:ident, $sql:literal) => {
        impl DomainType for $ty {
            fn sql_domain_static() -> &'static str {
                $sql
            }
            fn sql_domain(&self) -> &'static str {
                Self::sql_domain_static()
            }
            // `term_json_keys` keeps the trait default (`None`): SteVec index
            // terms live per sv leaf (`hm` XOR `op`), not as flat payload keys.
            fn parse_value(&self, value: &serde_json::Value) -> Result<(), serde_json::Error> {
                <$ty as Deserialize>::deserialize(value).map(|_| ())
            }
            fn schema(&self) -> Schema {
                schema_for!($ty)
            }
        }
    };
}

ste_vec_domain_type!(SteVecDocument, "public.eql_v3_json_search");
ste_vec_domain_type!(SteVecEntry, "public.eql_v3_json_entry");
ste_vec_domain_type!(SteVecQuery, "eql_v3.query_json");
