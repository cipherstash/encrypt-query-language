//! The `timestamptz` encrypted-domain family — **equality-only** (storage +
//! `_eq`). There is no ordered domain: cipherstash encrypts timestamps at
//! native 12-block ORE width, but EQL's only ORE comparator is hardcoded to
//! 8 blocks, so an ordered timestamptz domain would silently mis-order.
//! Ordering arrives with a future wide-ORE term (see `eql-scalars`).

use crate::v3::terms::{Ciphertext, Hmac256};
use crate::Identifier;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.timestamptz` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct Timestamptz {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl Timestamptz {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.timestamptz";
}

/// `eql_v3.timestamptz_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
pub struct TimestamptzEq {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`).
    pub v: u16,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term.
    pub hm: Hmac256,
}

impl TimestamptzEq {
    /// Fully-qualified SQL domain this payload inhabits.
    pub const SQL_DOMAIN: &'static str = "eql_v3.timestamptz_eq";
}
