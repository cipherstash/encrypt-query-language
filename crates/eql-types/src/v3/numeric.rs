//! The `numeric` encrypted-domain family — an ordered, non-integer scalar
//! backed by `rust_decimal::Decimal`. Same four-domain ordered shape as
//! [`crate::v3::int4`] (ORE compares ciphertext, so decimals order like
//! integers); see that module for the capability table.
//!
//! `numeric` is the first scalar whose native ORE term is wider than 8 blocks
//! (14 blocks): the wire shape is unchanged — the `ob` array simply carries
//! more block strings — and the generalized `eql_v3.ore_block_256` comparator
//! orders any block count, so no new type is needed here.

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{Ciphertext, Hmac256, OreBlock256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.numeric` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Numeric {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Numeric {
    fn sql_domain_static() -> &'static str {
        "eql_v3.numeric"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Numeric)
    }
}

/// `eql_v3.numeric_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct NumericEq {
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

impl DomainType for NumericEq {
    fn sql_domain_static() -> &'static str {
        "eql_v3.numeric_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(NumericEq)
    }
}

/// `eql_v3.numeric_ord_ore` — full comparison, scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct NumericOrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term (14 blocks for numeric). Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for NumericOrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.numeric_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(NumericOrdOre)
    }
}

/// `eql_v3.numeric_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct NumericOrd {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term (14 blocks for numeric). Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for NumericOrd {
    fn sql_domain_static() -> &'static str {
        "eql_v3.numeric_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(NumericOrd)
    }
}
