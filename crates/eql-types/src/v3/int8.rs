//! The `int8` encrypted-domain family. Same four-domain ordered shape as
//! [`crate::v3::int4`] — see that module for the capability table.

use crate::v3::terms::{Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::Identifier;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.int8` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Int8 {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl Int8 {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.int8";
}

/// `eql_v3.int8_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Int8Eq {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term.
    pub hm: Hmac256,
}

impl Int8Eq {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.int8_eq";
}

/// `eql_v3.int8_ord_ore` — full comparison, scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Int8OrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl Int8OrdOre {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.int8_ord_ore";
}

/// `eql_v3.int8_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Int8Ord {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl Int8Ord {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.int8_ord";
}
