//! The `text` encrypted-domain family — the ordered shape of
//! [`crate::v3::int4`] plus a `_match` domain backed by the Bloom-filter
//! term (`@>`/`<@` containment for `LIKE`-style matching).

use std::marker::PhantomData;

use crate::v3::terms::{BloomFilter, Ciphertext, Hmac256, OreBlockU64_8_256};
use crate::v3::DomainType;
use crate::{Identifier, SchemaVersion};
use serde::{Deserialize, Serialize};

/// `eql_v3.text` — storage only; every operator is blocked.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
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

impl DomainType for PhantomData<Text> {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.text"
    }
}

/// `eql_v3.text_eq` — HMAC equality (`=`, `<>`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
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

impl DomainType for PhantomData<TextEq> {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.text_eq"
    }
}

/// `eql_v3.text_match` — Bloom-filter containment match.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
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

impl DomainType for PhantomData<TextMatch> {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.text_match"
    }
}

/// `eql_v3.text_ord_ore` — full lexicographic comparison,
/// scheme-explicit name.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct TextOrdOre {
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

impl DomainType for PhantomData<TextOrdOre> {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.text_ord_ore"
    }
}

/// `eql_v3.text_ord` — full lexicographic comparison
/// (`=` `<>` `<` `<=` `>` `>=`).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct TextOrd {
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

impl DomainType for PhantomData<TextOrd> {
    fn sql_domain(&self) -> &'static str {
        "eql_v3.text_ord"
    }
}
