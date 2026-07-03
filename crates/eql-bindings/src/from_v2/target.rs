//! The explicit conversion target: which v3 domain a v2 payload converts
//! into. v2 index terms are all optional on the wire, so the capability can
//! never be inferred from the payload — the caller (protect-ffi's column
//! config, a bench's per-table intent) must name it.

use super::FromV2Error;
use crate::v3::all;

/// The v3 domain a v2 payload converts into.
///
/// Resolved by [`TargetDomain::parse`] against the catalog-generated
/// inventory ([`crate::v3::all`]), so the accepted names — and each scalar
/// target's required term keys — cannot drift from `eql-domains::CATALOG`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TargetDomain {
    /// A flat scalar domain (`integer`, `text_eq`, `integer_ord_ope`, …): the v2
    /// payload must be the `k: "ct"` form.
    Scalar(ScalarTarget),
    /// The SteVec document domain `eql_v3.json`: the v2 payload must be the
    /// `k: "sv"` form.
    Json,
}

/// A resolved scalar target: the unqualified domain name plus the term keys
/// its payload requires, both borrowed from the generated `DomainType` impls
/// (parity with the catalog is pinned by `tests/catalog_parity.rs`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ScalarTarget {
    domain: &'static str,
    term_keys: &'static [&'static str],
}

impl ScalarTarget {
    /// The unqualified target domain name, e.g. `"text_eq"`.
    pub fn domain(&self) -> &'static str {
        self.domain
    }

    /// The term keys the target payload requires beyond the `v`/`i`/`c`
    /// envelope, in wire order (empty for a storage-only domain).
    pub fn term_json_keys(&self) -> &'static [&'static str] {
        self.term_keys
    }
}

impl TargetDomain {
    /// Resolve an unqualified v3 domain name (`"integer_ord_ope"`,
    /// `"text_search"`, `"float8"`, `"json"`, …) against the inventory.
    ///
    /// Shape-aware: scalar domains resolve to [`TargetDomain::Scalar`] with
    /// their catalog term keys; the SteVec document domain `json` resolves to
    /// [`TargetDomain::Json`]; the remaining SteVec shapes (`jsonb_entry`,
    /// `jsonb_query`) are inventory members but not conversion targets, so
    /// they — like any unknown name — return
    /// [`FromV2Error::UnknownDomain`].
    pub fn parse(name: &str) -> Result<Self, FromV2Error> {
        let entry = all().into_iter().find(|d| d.domain() == name);
        match entry {
            Some(d) => match d.term_json_keys() {
                Some(term_keys) => Ok(Self::Scalar(ScalarTarget {
                    domain: d.domain(),
                    term_keys,
                })),
                None if name == "json" => Ok(Self::Json),
                None => Err(FromV2Error::UnknownDomain { name: name.into() }),
            },
            None => Err(FromV2Error::UnknownDomain { name: name.into() }),
        }
    }

    /// The target's name for error messages: the scalar domain name, or
    /// `"json"`.
    pub(super) fn describe(&self) -> &'static str {
        match self {
            Self::Scalar(t) => t.domain(),
            Self::Json => "json",
        }
    }
}
