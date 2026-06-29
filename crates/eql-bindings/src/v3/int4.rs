//! The `int4` encrypted-domain family — the reference scalar.
//!
//! | Rust type      | SQL domain             | Required keys | Operators                  |
//! |----------------|------------------------|---------------|----------------------------|
//! | [`Int4`]       | `eql_v3.int4`          | `v` `i` `c`        | none (storage only)        |
//! | [`Int4Eq`]     | `eql_v3.int4_eq`       | `v` `i` `c` `hm`   | `=` `<>`                   |
//! | [`Int4OrdOre`] | `eql_v3.int4_ord_ore`  | `v` `i` `c` `ob`   | `=` `<>` `<` `<=` `>` `>=` |
//! | [`Int4Ord`]    | `eql_v3.int4_ord`      | `v` `i` `c` `ob`   | `=` `<>` `<` `<=` `>` `>=` |

use schemars::{schema_for, Schema};

use crate::v3::terms::{Ciphertext, Hmac256, OreBlock256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.int4` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4 {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Int4 {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> Schema {
        schema_for!(Int4)
    }
}

/// `eql_v3.int4_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4Eq {
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

impl DomainType for Int4Eq {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> Schema {
        schema_for!(Int4Eq)
    }
}

/// `eql_v3.int4_ord_ore` — full comparison (`=` `<>` `<` `<=` `>` `>=`),
/// scheme-explicit name. Same shape as [`Int4Ord`], distinct SQL domain.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4OrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too — ORE over a
    /// full-domain `int4` is lossless, so no separate `hm` is carried.
    pub ob: OreBlock256,
}

impl DomainType for Int4OrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> Schema {
        schema_for!(Int4OrdOre)
    }
}

/// `eql_v3.int4_ord` — full comparison (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Int4Ord {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Block-ORE order term. Serves equality too.
    pub ob: OreBlock256,
}

impl DomainType for Int4Ord {
    fn sql_domain_static() -> &'static str {
        "eql_v3.int4_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> Schema {
        schema_for!(Int4Ord)
    }
}
