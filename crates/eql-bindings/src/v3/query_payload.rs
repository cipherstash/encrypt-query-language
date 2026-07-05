//! The `QueryPayload` enum — every v3 QUERY payload shape in one Rust type —
//! HAND-WRITTEN, unlike the generated [`DomainPayload`](super::DomainPayload).
//!
//! ## Why hand-written and not codegen-emitted
//!
//! `DomainPayload` is generated because its variant set IS the catalog: one
//! variant per stored-payload domain, so a catalog change must reshape the
//! enum. Query payloads are **term-shaped, not catalog-per-domain**: a scalar
//! query value is a single index term (one Ore / Ope / Bloom / Hm value, not
//! a per-domain envelope), and the term set lives in the hand-written
//! `Term`-level code (`terms.rs`, mirroring `Term::ctor()` in `eql-domains`)
//! rather than in the catalog rows the generator walks. With the variant set
//! anchored to that stable hand-written surface — and exactly one variant
//! constructible today — a generator would add drift surface, not remove it.
//! This module lives next to the equally hand-written `jsonb.rs` that defines
//! its inner type.
//!
//! ## Why there is only one variant today
//!
//! See [`QueryPayload`]: the scalar-term variants are deliberately absent
//! until the eql-mapper redesign defines a v3 scalar-query wire shape.

use serde::Serialize;

use super::domain_type::DomainType;
use super::jsonb::SteVecQuery;

/// Every v3 query payload shape in one type. Today that is exactly one:
/// the SteVec containment needle ([`SteVecQuery`], `public.jsonb_query`).
///
/// Serialization is exactly the inner type's (`#[serde(untagged)]` adds no
/// tagging), so typing a query payload never changes the wire. Deliberately
/// NO `Deserialize` — a variant is only constructible from a KNOWN domain
/// ([`QueryPayload::parse`] or [`crate::from_v2::from_v2_query_typed`]),
/// never inferred from bytes — and no ts-rs/schemars: the enum adds no wire
/// shape of its own, so it must not churn the exported TS/JSON-Schema
/// artifacts.
///
/// ## Future scalar-term variants (deliberately absent)
///
/// A scalar query value is a SINGLE index term — one `Ore` ([`super::terms::OreBlock256`]),
/// `Ope` ([`super::terms::OpeCllw`]), `Bloom` ([`super::terms::BloomFilter`]),
/// or `Hm` ([`super::terms::Hmac256`]) term value — not a stored envelope
/// (every scalar domain CHECK requires the ciphertext `c` a query payload
/// omits). No v3 scalar-query wire shape exists yet, and this crate will not
/// invent one ahead of the eql-mapper redesign: the converter fails closed
/// ([`crate::from_v2::FromV2Error::UnsupportedQueryTarget`]) instead. When
/// the mapper redesign defines the shape, this enum grows the matching
/// single-term variants and [`crate::from_v2::from_v2_query_typed`] starts
/// producing them.
#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(untagged)]
pub enum QueryPayload {
    /// The `public.jsonb_query` containment needle (`{sv: [{s, hm|oc}]}`).
    SteVec(SteVecQuery),
}

impl QueryPayload {
    /// Strictly parse `value` as `domain`'s QUERY payload, KEEPING the parsed
    /// value — the query-side counterpart of
    /// [`DomainPayload::parse`](super::DomainPayload::parse). `domain` is the
    /// unqualified name (`"jsonb_query"`). `None` when `domain` is not a
    /// query-payload domain (stored-payload domains and the sv entry shape
    /// included); `Some(Err)` when the strict parse fails
    /// ([`SteVecQuery`] is `deny_unknown_fields` at the root).
    pub fn parse(
        domain: &str,
        value: &serde_json::Value,
    ) -> Option<Result<Self, serde_json::Error>> {
        use serde::Deserialize as _;
        match domain {
            "jsonb_query" => Some(SteVecQuery::deserialize(value).map(Self::SteVec)),
            _ => None,
        }
    }

    /// The inner payload as a [`DomainType`] trait object.
    pub fn as_domain_type(&self) -> &dyn DomainType {
        match self {
            Self::SteVec(payload) => payload,
        }
    }

    /// Fully-qualified SQL domain name, e.g. `"public.jsonb_query"`.
    pub fn sql_domain(&self) -> &'static str {
        self.as_domain_type().sql_domain()
    }

    /// Unqualified SQL domain name, e.g. `"jsonb_query"` — the name
    /// [`QueryPayload::parse`] accepts.
    pub fn domain(&self) -> &'static str {
        self.as_domain_type().domain()
    }
}
