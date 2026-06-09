//! Inherent impls for [`ScalarSpec`] — the per-type helpers `domain_name`
//! (token + suffix) and `is_eq_only` (no `_ord` domain). Definitions for
//! [`ScalarSpec`] and [`DomainSpec`] live in `lib.rs`.

use crate::{DomainSpec, ScalarSpec};

impl ScalarSpec {
    /// The fully-qualified domain name: `token` + `suffix`. Makes the old
    /// "domain name must start with the token" validation structural.
    pub fn domain_name(&self, domain: &DomainSpec) -> String {
        format!("{}{}", self.token, domain.suffix)
    }

    /// True when this type declares no ordered (`_ord`) domain — i.e. equality-only
    /// (storage + `_eq`). Replaces the future `[eq_only]` marker: the domain set
    /// already carries this. The `_ord_ore` twin only appears alongside `_ord`, so
    /// testing `_ord` suffices.
    pub fn is_eq_only(&self) -> bool {
        !self.domains.iter().any(|d| d.suffix == "_ord")
    }
}
