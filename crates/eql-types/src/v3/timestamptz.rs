//! The `timestamptz` encrypted-domain family — **equality-only** (storage +
//! `_eq`). There is no ordered domain: cipherstash encrypts timestamps at
//! native 12-block ORE width, but EQL's only ORE comparator is hardcoded to
//! 8 blocks, so an ordered timestamptz domain would silently mis-order.
//! Ordering arrives with a future wide-ORE term (see `eql-scalars`).

use crate::v3::terms::{Ciphertext, Hmac256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use serde::{Deserialize, Serialize};

/// `eql_v3.timestamptz` — storage only; every operator is blocked.
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Timestamptz {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Timestamptz {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.timestamptz"
    }
}

/// `eql_v3.timestamptz_eq` — HMAC equality (`=`, `<>`).
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct TimestamptzEq {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term.
    pub hm: Hmac256,
}

impl DomainType for TimestamptzEq {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.timestamptz_eq"
    }
}
