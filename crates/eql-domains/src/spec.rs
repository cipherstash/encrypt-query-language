//! Inherent impls for [`DomainFamily`] — the per-type helpers `domain_name`
//! (family-name + `_` + domain-name) and `is_eq_only` (no `ord` domain).
//! Definitions for [`DomainFamily`] and [`Domain`] live in `lib.rs`.

use crate::{Domain, DomainFamily};

impl Domain {
    /// The full (unqualified) domain name for this domain under `family_name`:
    /// the family name joined to the bare domain name with a `_` separator (an
    /// empty domain name => the bare family name). The **single** site that owns
    /// the `_` join — codegen builds every domain name through this, so the
    /// "domain name starts with the family name" rule is structural.
    pub fn full_name(&self, family_name: &str) -> String {
        if self.name.is_empty() {
            family_name.to_string()
        } else {
            format!("{family_name}_{}", self.name)
        }
    }

    /// The PascalCase Rust/TS struct identifier for this domain under
    /// `family_name`: the [`Self::full_name`] snake_case name mangled to
    /// PascalCase (`"int4_ord_ore"` -> `"Int4OrdOre"`, storage `""` ->
    /// `"Int4"`). The SINGLE source of truth for the mangler — the bindings
    /// emitter (`eql-codegen`) and the TS-property-order guard (`eql-bindings`)
    /// both call this instead of carrying private copies that could drift.
    pub fn struct_ident(&self, family_name: &str) -> String {
        self.full_name(family_name)
            .split('_')
            .filter(|s| !s.is_empty())
            .map(|s| {
                let mut chars = s.chars();
                match chars.next() {
                    Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                    None => String::new(),
                }
            })
            .collect()
    }
}

impl DomainFamily {
    /// The fully-qualified domain name: family-name + `_` + domain-name. Makes
    /// the old "domain name must start with the family name" validation
    /// structural.
    pub fn domain_name(&self, domain: &Domain) -> String {
        domain.full_name(self.name)
    }

    /// True when this type declares no ordered (`ord`) domain — i.e. equality-only
    /// (storage + `eq`). Replaces the future `[eq_only]` marker: the domain set
    /// already carries this. The `ord_ore` twin only appears alongside `ord`, so
    /// testing `ord` suffices.
    pub fn is_eq_only(&self) -> bool {
        !self.domains.iter().any(|d| d.name == "ord")
    }

    /// True when this type is **storage-only / encryption-only**: it declares a
    /// single term-less domain (the bare-family-name storage domain) and no
    /// comparison domain (`eq`/`ord`/`match`/…). The shape for a scalar encrypted
    /// at rest but never searched server-side (e.g. `bool`, whose two-value
    /// cardinality makes any searchable index a plaintext leak). Stricter than
    /// `is_eq_only()` — a storage-only type is also `is_eq_only()` (no `ord`),
    /// but has no `eq` either.
    pub fn is_storage_only(&self) -> bool {
        self.domains.len() == 1
            && self.domains[0].name.is_empty()
            && self.domains[0].terms.is_empty()
    }

    /// The domain on this scalar with the given (bare) `name`, or `None`.
    /// Centralizes the `domains.iter().find(|d| d.name == n)` lookup duplicated
    /// across the catalog tests and the SQLx harness.
    pub fn domain_by_name(&self, name: &str) -> Option<&Domain> {
        self.domains.iter().find(|d| d.name == name)
    }
}

#[cfg(test)]
mod tests {
    use crate::{Domain, Term};

    #[test]
    fn struct_ident_mangles_full_name_to_pascalcase() {
        let storage = Domain {
            name: "",
            terms: &[],
        };
        let ord_ore = Domain {
            name: "ord_ore",
            terms: &[Term::Ore],
        };
        // storage domain => bare family name
        assert_eq!(storage.struct_ident("int4"), "Int4");
        // multi-segment bare name joins under the family
        assert_eq!(ord_ore.struct_ident("int4"), "Int4OrdOre");
        assert_eq!(ord_ore.struct_ident("timestamp"), "TimestampOrdOre");
        // single-segment bare name
        let eq = Domain {
            name: "eq",
            terms: &[Term::Hm],
        };
        assert_eq!(eq.struct_ident("float8"), "Float8Eq");
    }
}
