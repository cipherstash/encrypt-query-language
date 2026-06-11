//! The `int2` encrypted-domain family. Same four-domain ordered shape as
//! [`crate::v3::int4`] — see that module for the capability table.

use crate::v3::terms::{Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use serde::{Deserialize, Serialize};

/// `eql_v3.int2` — storage only; every operator is blocked.
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Int2 {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Int2 {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.int2"
    }
}

/// `eql_v3.int2_eq` — HMAC equality (`=`, `<>`).
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Int2Eq {
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

impl DomainType for Int2Eq {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.int2_eq"
    }
}

/// `eql_v3.int2_ord_ore` — full comparison, scheme-explicit name.
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Int2OrdOre {
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

impl DomainType for Int2OrdOre {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.int2_ord_ore"
    }
}

/// `eql_v3.int2_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Default, Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Int2Ord {
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

impl DomainType for Int2Ord {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.int2_ord"
    }
}
