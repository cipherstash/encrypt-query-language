//! # EQL v2.3 wire types — FROZEN
//!
//! `eql_v2_encrypted` is in production use by customers. The shapes here are
//! the v2.3 wire contract and MUST NOT change — not field names, not
//! optionality, not enum tagging. They mirror `eql-payload-v2.3.schema.json`
//! exactly, including its imperfections:
//!
//! - [`EncryptedPayload`] carries `hm`/`bf`/`ob` as independent optionals
//!   ("any subset" — a column with several indexes carries several terms).
//! - [`SteVecTerm`] is an **untagged** enum — a consumer must sniff keys.
//!
//! New design work goes in sibling modules (see [`crate::int4`]), never here.

use crate::Identifier;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v2_encrypted` — the EQL v2.3 storage payload. Discriminated on `k`.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
#[serde(tag = "k")]
pub enum EqlEncrypted {
    /// Scalar ciphertext payload.
    #[serde(rename = "ct")]
    Ct(EncryptedPayload),
    /// STE-vector payload (jsonb / structured values).
    #[serde(rename = "sv")]
    Sv(SteVecPayload),
}

/// Scalar storage payload (`k = "ct"`).
///
/// FROZEN imperfection: `hm`/`bf`/`ob` are independently optional. A consumer
/// cannot tell from the type which terms are present — it must inspect at
/// runtime. This is precisely the gap the `protect-dynamodb` bug fell into.
/// The fix, for *new* types, is [`crate::int4`].
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct EncryptedPayload {
    /// Schema version — always [`crate::EQL_SCHEMA_VERSION`].
    pub v: u16,
    /// Table/column identifier.
    pub i: Identifier,
    /// mp_base85 ciphertext. Required.
    pub c: String,
    /// HMAC-SHA256 equality term — present iff a `unique` index is configured.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub hm: Option<String>,
    /// Bloom filter term — present iff a `match` index is configured.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub bf: Option<Vec<u16>>,
    /// Block ORE term — present iff an `ore` index is configured.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub ob: Option<Vec<String>>,
}

/// STE-vector storage payload (`k = "sv"`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct SteVecPayload {
    /// Schema version.
    pub v: u16,
    /// Table/column identifier.
    pub i: Identifier,
    /// Per-selector encrypted entries; root document ciphertext at `sv[0].c`.
    pub sv: Vec<SteVecElement>,
}

/// One STE-vector element.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
pub struct SteVecElement {
    /// Tokenized selector — deterministic per (path, key).
    pub s: String,
    /// Per-entry mp_base85 ciphertext. Required.
    pub c: String,
    /// Array marker — true when the selector points at a JSON array context.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub a: Option<bool>,
    /// Exactly one equality / ordering term, flattened onto the element.
    #[serde(flatten)]
    pub term: SteVecTerm,
}

/// SteVec element term. FROZEN as **untagged** — this is the v2.3 wire shape.
///
/// A consumer must narrow with `'hm' in term`; there is no literal
/// discriminant. A *new* type would tag this — see [`crate::int4`].
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export)]
#[serde(untagged)]
pub enum SteVecTerm {
    /// HMAC term — boolean leaves, and array / object root placeholders.
    Hmac { hm: String },
    /// CLLW ORE term — string / number leaves.
    OreCllw { oc: String },
}
