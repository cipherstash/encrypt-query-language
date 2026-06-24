//! The `timestamptz` encrypted-domain family — an ordered, non-integer scalar.
//! Same four-domain ordered shape as [`crate::v3::int4`] (ORE compares
//! ciphertext, so timestamps order like integers); see that module for the
//! capability table.
//!
//! cipherstash encrypts timestamps at native 12-block ORE width. The family
//! was equality-only while EQL's ORE comparator was hardcoded to 8 blocks;
//! now that `eql_v3.ore_block_256` derives the block count from the term
//! length, the 12-block `ob` term orders correctly and the ordered domains
//! ship. The wire shape is unchanged — the `ob` array just carries 12 blocks.

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{Ciphertext, Hmac256, OreBlock256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.timestamptz` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
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
    fn sql_domain_static() -> &'static str {
        "eql_v3.timestamptz"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Timestamptz)
    }
}

/// `eql_v3.timestamptz_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
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
    fn sql_domain_static() -> &'static str {
        "eql_v3.timestamptz_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TimestamptzEq)
    }
}

/// `eql_v3.timestamptz_ord_ore` — full comparison, scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TimestamptzOrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term (12 blocks for timestamptz). Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for TimestamptzOrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.timestamptz_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TimestamptzOrdOre)
    }
}

/// `eql_v3.timestamptz_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TimestamptzOrd {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term (12 blocks for timestamptz). Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for TimestamptzOrd {
    fn sql_domain_static() -> &'static str {
        "eql_v3.timestamptz_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TimestamptzOrd)
    }
}
