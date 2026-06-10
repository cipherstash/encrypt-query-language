//! The `text` encrypted-domain family — the ordered shape of
//! [`crate::v3::int4`] plus a `_match` domain backed by the Bloom-filter
//! term (`@>`/`<@` containment for `LIKE`-style matching).

use crate::v3::terms::{BloomFilter, Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::Identifier;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.text` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Text {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl Text {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.text";
}

/// `eql_v3.text_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct TextEq {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term.
    pub hm: Hmac256,
}

impl TextEq {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.text_eq";
}

/// `eql_v3.text_match` — Bloom-filter containment match.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct TextMatch {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Bloom-filter match term (signed smallint bit positions).
    pub bf: BloomFilter,
}

impl TextMatch {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.text_match";
}

/// `eql_v3.text_ord_ore` — full lexicographic comparison,
/// scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct TextOrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl TextOrdOre {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.text_ord_ore";
}

/// `eql_v3.text_ord` — full lexicographic comparison
/// (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct TextOrd {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl TextOrd {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.text_ord";
}
