//! The `date` encrypted-domain family — an ordered, non-integer scalar.
//! Same four-domain ordered shape as [`crate::v3::int4`] (ORE compares
//! ciphertext, so dates order like integers); see that module for the
//! capability table.

use crate::v3::terms::{Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use serde::{Deserialize, Serialize};

/// `eql_v3.date` — storage only; every operator is blocked.
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Date {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Date {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.date"
    }
}

/// `eql_v3.date_eq` — HMAC equality (`=`, `<>`).
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct DateEq {
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

impl DomainType for DateEq {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.date_eq"
    }
}

/// `eql_v3.date_ord_ore` — full comparison, scheme-explicit name.
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct DateOrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl DomainType for DateOrdOre {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.date_ord_ore"
    }
}

/// `eql_v3.date_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct DateOrd {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlockU64_8_256,
}

impl DomainType for DateOrd {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.date_ord"
    }
}
