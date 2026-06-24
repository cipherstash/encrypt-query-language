//! The `text` encrypted-domain family — the ordered shape of
//! [`crate::v3::int4`] plus a `_match` domain backed by the Bloom-filter
//! term (`@>`/`<@` containment for `LIKE`-style matching).

use schemars::{schema::RootSchema, schema_for};

use crate::v3::terms::{BloomFilter, Ciphertext, Hmac256, OreBlock256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use ts_rs::TS;

/// `eql_v3.text` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct Text {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
}

impl DomainType for Text {
    fn sql_domain_static() -> &'static str {
        "eql_v3.text"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(Text)
    }
}

/// `eql_v3.text_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TextEq {
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

impl DomainType for TextEq {
    fn sql_domain_static() -> &'static str {
        "eql_v3.text_eq"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TextEq)
    }
}

/// `eql_v3.text_match` — Bloom-filter containment match.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TextMatch {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// Bloom-filter match term (signed smallint bit positions).
    pub bf: BloomFilter,
}

impl DomainType for TextMatch {
    fn sql_domain_static() -> &'static str {
        "eql_v3.text_match"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TextMatch)
    }
}

/// `eql_v3.text_ord_ore` — full lexicographic comparison,
/// scheme-explicit name. Unlike the integer ordered domains (`[Ore]` only),
/// text routes equality through `hm` rather than the ORE term, so the domain
/// carries both `hm` and `ob` (`[Hm, Ore]`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TextOrdOre {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term. Text routes `=`/`<>` through `hm`.
    pub hm: Hmac256,
    /// Block-ORE order term.
    pub ob: OreBlock256,
}

impl DomainType for TextOrdOre {
    fn sql_domain_static() -> &'static str {
        "eql_v3.text_ord_ore"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TextOrdOre)
    }
}

/// `eql_v3.text_ord` — full lexicographic comparison
/// (`=` `<>` `<` `<=` `>` `>=`). Carries both `hm` (equality) and `ob`
/// (ordering) — text routes equality through `hm` (`[Hm, Ore]`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TextOrd {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term. Text routes `=`/`<>` through `hm`.
    pub hm: Hmac256,
    /// Block-ORE order term.
    pub ob: OreBlock256,
}

impl DomainType for TextOrd {
    fn sql_domain_static() -> &'static str {
        "eql_v3.text_ord"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TextOrd)
    }
}

/// `eql_v3.text_search` — the full text search surface: HMAC equality, ORE
/// ordering, and Bloom-filter containment match (`[Hm, Ore, Bloom]`). The
/// superset domain combining `_eq`, `_ord`, and `_match`.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS, JsonSchema)]
#[ts(export, export_to = "v3/")]
#[serde(deny_unknown_fields)]
pub struct TextSearch {
    /// Envelope version — always `2` (`EQL_SCHEMA_VERSION`); any other
    /// value fails deserialization.
    pub v: SchemaVersion,
    /// Table/column identifier. Required by the domain CHECK.
    pub i: Identifier,
    /// mp_base85 source ciphertext. Required by the domain CHECK.
    pub c: Ciphertext,
    /// HMAC-SHA-256 equality term.
    pub hm: Hmac256,
    /// Block-ORE order term.
    pub ob: OreBlock256,
    /// Bloom-filter match term (signed smallint bit positions).
    pub bf: BloomFilter,
}

impl DomainType for TextSearch {
    fn sql_domain_static() -> &'static str {
        "eql_v3.text_search"
    }

    fn sql_domain(&self) -> &'static str {
        Self::sql_domain_static()
    }

    fn schema(&self) -> RootSchema {
        schema_for!(TextSearch)
    }
}
