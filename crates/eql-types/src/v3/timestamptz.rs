//! The `timestamptz` encrypted-domain family — **equality-only** (storage +
//! `_eq`). There is no ordered domain: cipherstash encrypts timestamps at
//! native 12-block ORE width, but EQL's only ORE comparator is hardcoded to
//! 8 blocks, so an ordered timestamptz domain would silently mis-order.
//! Ordering arrives with a future wide-ORE term (see `eql-scalars`).

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{Ciphertext, Hmac256};
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
