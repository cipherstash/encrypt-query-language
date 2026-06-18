//! Inherent impls for [`ScalarSpec`] — the per-type helpers `domain_name`
//! (token + suffix) and `is_eq_only` (no `_ord` domain). Definitions for
//! [`ScalarSpec`] and [`DomainSpec`] live in `lib.rs`.

use crate::{DomainSpec, ScalarSpec};

impl DomainSpec {
    /// The full (unqualified) domain name for this domain under `token`:
    /// `token` + `suffix` (suffix `""` => bare token). The **single** source for
    /// the token+suffix concatenation — codegen builds every domain name through
    /// this, so the "domain name starts with the token" rule is structural.
    pub fn name_with_token(&self, token: &str) -> String {
        format!("{token}{}", self.suffix)
    }
}

impl ScalarSpec {
    /// The fully-qualified domain name: `token` + `suffix`. Makes the old
    /// "domain name must start with the token" validation structural.
    pub fn domain_name(&self, domain: &DomainSpec) -> String {
        domain.name_with_token(self.token)
    }

    /// True when this type declares no ordered (`_ord`) domain — i.e. equality-only
    /// (storage + `_eq`). Replaces the future `[eq_only]` marker: the domain set
    /// already carries this. The `_ord_ore` twin only appears alongside `_ord`, so
    /// testing `_ord` suffices.
    pub fn is_eq_only(&self) -> bool {
        !self.domains.iter().any(|d| d.suffix == "_ord")
    }

    /// True when this type is **storage-only / encryption-only**: it declares a
    /// single term-less domain (the bare-token storage domain) and no comparison
    /// domain (`_eq`/`_ord`/`_match`/…). The shape for a scalar encrypted at rest
    /// but never searched server-side (e.g. `bool`, whose two-value cardinality
    /// makes any searchable index a plaintext leak). Stricter than
    /// `is_eq_only()` — a storage-only type is also `is_eq_only()` (no `_ord`),
    /// but has no `_eq` either.
    pub fn is_storage_only(&self) -> bool {
        self.domains.len() == 1 && self.domains[0].suffix.is_empty() && self.domains[0].terms.is_empty()
    }

    /// The domain on this scalar with the given `suffix`, or `None`. Centralizes
    /// the `domains.iter().find(|d| d.suffix == s)` lookup duplicated across the
    /// catalog tests and the SQLx harness.
    pub fn domain_by_suffix(&self, suffix: &str) -> Option<&DomainSpec> {
        self.domains.iter().find(|d| d.suffix == suffix)
    }
}
