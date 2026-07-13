//! Inherent impls for [`DomainFamily`] — the per-type helpers `domain_name`
//! (the installed SQL typname: family-name + `_` + domain-name, public column
//! domains carrying the `eql_v3_` version prefix — CIP-3472) and `is_eq_only`
//! (no `ord` domain).
//! Definitions for [`DomainFamily`] and [`Domain`] live in `lib.rs`.

use crate::{Domain, DomainFamily};

impl Domain {
    /// The full (unqualified) domain name for this domain under `family_name`:
    /// the family name joined to the bare domain name with a `_` separator (an
    /// empty domain name => the bare family name). The **single** site that owns
    /// the `_` join — codegen builds every domain name through this, so the
    /// "domain name starts with the family name" rule is structural.
    ///
    /// Two documented exceptions, both on the `jsonb` family:
    ///
    /// - the document domain (`public.eql_v3_json`, `Domain.name == "json"`) predates
    ///   the catalog and doesn't follow the family+suffix convention
    ///   (`family_name` is `"jsonb"`, not `"json"`), so its `name` is returned
    ///   verbatim instead of being joined;
    /// - the containment needle (`Domain.name == "query"`) follows the
    ///   query-operand PREFIX convention (CIP-3442): `query_jsonb`, matching
    ///   the scalar `query_<name>` twins so every query-operand type sorts
    ///   apart from the column domains in alphabetical type listings.
    ///
    /// Every other domain — scalar or the SteVec entry — uses the join.
    pub fn full_name(&self, family_name: &str) -> String {
        // The two jsonb column domains — storage-only `json` (`Shape::Scalar`,
        // `public.eql_v3_json`) and searchable `json_search` (`Shape::SteVec`,
        // `public.eql_v3_json_search`) — keep their established literal names
        // rather than following the family+suffix convention (family is
        // "jsonb", not "json"). CIP-3512.
        if self.name == "json" || self.name == "json_search" {
            return self.name.to_string();
        }
        if matches!(self.shape, crate::Shape::SteVec) && self.name == "query" {
            return format!("query_{family_name}");
        }
        if self.name.is_empty() {
            family_name.to_string()
        } else {
            format!("{family_name}_{}", self.name)
        }
    }

    /// The unqualified SQL type name (pg_type `typname`) of this domain as
    /// installed. Public-schema column domains carry the
    /// [`crate::PUBLIC_TYPNAME_PREFIX`] version prefix
    /// (`eql_v3_integer_eq`, `eql_v3_json` — CIP-3472); the SteVec containment
    /// needle (`query_jsonb`) lives in the `eql_v3` schema, which already
    /// versions it, so it stays bare like the scalar `query_<name>` twins.
    /// The **single** site that owns the prefix decision — codegen (SQL +
    /// bindings) and the eql-bindings parity tests both resolve installed
    /// names through this (usually via [`DomainFamily::domain_name`]).
    pub fn sql_typname(&self, family_name: &str) -> String {
        let full = self.full_name(family_name);
        if matches!(self.shape, crate::Shape::SteVec) && self.name == "query" {
            return full;
        }
        format!("{}{full}", crate::PUBLIC_TYPNAME_PREFIX)
    }

    /// The full (unqualified) name of this domain's query-operand twin under
    /// `family_name`: the `query_` PREFIX joined to [`Self::full_name`]
    /// (`"query_integer_eq"`). The **single** site that owns the query-twin
    /// naming convention — codegen (SQL + bindings) builds every query-domain
    /// name through this. A prefix (not the earlier `_query` suffix) so query
    /// operands sort together, apart from the column domains they twin, in
    /// alphabetical type listings such as Supabase Studio's type picker
    /// (CIP-3442).
    pub fn query_name(&self, family_name: &str) -> String {
        format!("query_{}", self.full_name(family_name))
    }

    /// The PascalCase Rust/TS struct identifier for this domain under
    /// `family_name`: the [`Self::full_name`] snake_case name mangled to
    /// PascalCase (`"integer_ord_ore"` -> `"IntegerOrdOre"`, storage `""` ->
    /// `"Integer"`). The SINGLE source of truth for the mangler — the bindings
    /// emitter (`eql-codegen`) and the TS-property-order guard (`eql-bindings`)
    /// both call this instead of carrying private copies that could drift.
    pub fn struct_ident(&self, family_name: &str) -> String {
        self.full_name(family_name)
            .split('_')
            .filter(|s| !s.is_empty())
            .map(capitalize)
            .collect()
    }

    /// True when this domain carries the flat scalar payload shape. False for
    /// the SteVec shapes (the `jsonb` family). The per-domain primitive that
    /// [`DomainFamily::is_scalar`] and [`crate::scalar_families`] are built on —
    /// most scalar-only consumers filter through those family-level helpers, not
    /// this predicate directly (the `ts_property_order` guard is the exception).
    pub const fn is_scalar(&self) -> bool {
        matches!(self.shape, crate::Shape::Scalar)
    }

    /// The Rust/TS struct identifier that represents this domain's payload —
    /// shape-aware, unlike [`Self::struct_ident`]. For [`crate::Shape::Scalar`]
    /// this is exactly `struct_ident` (derived from the domain name). The
    /// SteVec shapes' struct bodies are hand-written (not name-derivable — see
    /// `crates/eql-bindings/src/v3/jsonb.rs`), but their identifiers ARE
    /// name-derivable (`"SteVec" + capitalize(name)`), with one irregular case:
    /// the document domain's established name `"json"` maps to `SteVecDocument`,
    /// not `SteVecJson` (mirroring the exception `full_name` already carries).
    /// The SINGLE source of truth for that mapping — `eql-codegen`'s inventory
    /// renderer calls this instead of carrying its own copy of the shape match.
    pub fn rust_struct_name(&self, family_name: &str) -> String {
        match self.shape {
            // Storage-only `json` is `Shape::Scalar`, so it mangles like any
            // scalar storage domain: `struct_ident("json")` -> `Json`.
            crate::Shape::Scalar => self.struct_ident(family_name),
            crate::Shape::SteVec if self.name == "json_search" => "SteVecDocument".to_string(),
            crate::Shape::SteVec => format!("SteVec{}", capitalize(self.name)),
        }
    }
}

/// PascalCase a single snake_case segment (no `_` splitting — callers split
/// first): `"ord_ore"`'s `"ore"` segment -> `"Ore"`, `"entry"` -> `"Entry"`.
fn capitalize(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
        None => String::new(),
    }
}

impl DomainFamily {
    /// The unqualified SQL type name of `domain` as installed — see
    /// [`Domain::sql_typname`]: public-schema column domains carry the
    /// `eql_v3_` version prefix (CIP-3472); query-operand domains stay bare
    /// (the `eql_v3` schema already versions them). For the bare
    /// family-name + `_` + domain-name join (file names, struct identifiers,
    /// matrix test names), use [`Domain::full_name`].
    pub fn domain_name(&self, domain: &Domain) -> String {
        domain.sql_typname(self.name)
    }

    /// True when this type declares no ordered (`ord`) domain — i.e. equality-only
    /// (storage + `eq`). Replaces the future `[eq_only]` marker: the domain set
    /// already carries this. The `ord_ore` twin only appears alongside `ord`, so
    /// testing `ord` suffices.
    ///
    /// A **flat-scalar** predicate: it describes the storage/`_eq`/`_ord` shape,
    /// which the non-scalar SteVec `jsonb` family does not have (its ordered `op`
    /// capability is carried structurally, not as an `ord` domain). So it is
    /// guarded by [`Self::is_scalar`] — a non-scalar family is never "eq-only",
    /// even though it happens to declare no domain literally named `ord`.
    pub fn is_eq_only(&self) -> bool {
        self.is_scalar() && !self.domains.iter().any(|d| d.name == "ord")
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

    /// True when every domain in this family is [`crate::Shape::Scalar`] — i.e. it
    /// is a flat scalar family, not the SteVec `jsonb` family.
    pub fn is_scalar(&self) -> bool {
        self.domains.iter().all(|d| d.is_scalar())
    }
}

#[cfg(test)]
mod tests {
    use crate::{Domain, Shape, Term};

    #[test]
    fn struct_ident_mangles_full_name_to_pascalcase() {
        let storage = Domain {
            name: "",
            terms: &[],
            shape: Shape::Scalar,
        };
        let ord_ore = Domain {
            name: "ord_ore",
            terms: &[Term::Ore],
            shape: Shape::Scalar,
        };
        // storage domain => bare family name
        assert_eq!(storage.struct_ident("integer"), "Integer");
        // multi-segment bare name joins under the family
        assert_eq!(ord_ore.struct_ident("integer"), "IntegerOrdOre");
        assert_eq!(ord_ore.struct_ident("timestamp"), "TimestampOrdOre");
        // single-segment bare name
        let eq = Domain {
            name: "eq",
            terms: &[Term::Hm],
            shape: Shape::Scalar,
        };
        assert_eq!(eq.struct_ident("double"), "DoubleEq");
    }

    #[test]
    fn query_name_prefixes_the_full_name() {
        // `query_` is a PREFIX so query twins sort apart from the column
        // domains in alphabetical type listings (Supabase Studio — CIP-3442).
        let eq = Domain {
            name: "eq",
            terms: &[Term::Hm],
            shape: Shape::Scalar,
        };
        assert_eq!(eq.query_name("integer"), "query_integer_eq");
        let ord_ore = Domain {
            name: "ord_ore",
            terms: &[Term::Ore],
            shape: Shape::Scalar,
        };
        assert_eq!(ord_ore.query_name("timestamp"), "query_timestamp_ord_ore");
    }

    #[test]
    fn scalar_families_exclude_non_scalar_families_after_jsonb_flip() {
        use crate::{scalar_families, CATALOG, JSONB};
        let names: Vec<&str> = scalar_families().map(|f| f.name).collect();
        assert_eq!(names.len(), CATALOG.len() - 1);
        assert!(!names.contains(&JSONB.name));
        for f in scalar_families() {
            assert!(f.is_scalar());
        }
    }

    #[test]
    fn jsonb_domain_names_follow_the_documented_conventions() {
        // The entry carries the family+suffix naming every scalar family uses.
        // The document is one documented exception — its established name
        // `json` doesn't match the family name `jsonb`, so `full_name` returns
        // it verbatim rather than concatenating. The containment needle is the
        // other — it follows the query-operand PREFIX convention (CIP-3442),
        // like the scalar `query_<name>` twins. Real SQL names:
        // public.eql_v3_json, public.eql_v3_jsonb_entry, eql_v3.query_jsonb —
        // the public column domains carry the version prefix (CIP-3472); the
        // needle lives in the already-versioned `eql_v3` schema, so it stays
        // bare.
        use crate::JSONB;
        assert_eq!(JSONB.domain_name(&JSONB.domains[0]), "eql_v3_json");
        assert_eq!(JSONB.domain_name(&JSONB.domains[1]), "eql_v3_json_search");
        assert_eq!(JSONB.domain_name(&JSONB.domains[2]), "eql_v3_jsonb_entry");
        assert_eq!(JSONB.domain_name(&JSONB.domains[3]), "query_jsonb");
    }

    #[test]
    fn rust_struct_name_is_shape_aware() {
        // Scalar: derived, same as struct_ident. Non-scalar: the hand-written
        // SteVec struct names — the ONE place these two universes diverge.
        use crate::JSONB;
        let integer_eq = Domain {
            name: "eq",
            terms: &[Term::Hm],
            shape: Shape::Scalar,
        };
        assert_eq!(integer_eq.rust_struct_name("integer"), "IntegerEq");
        // Storage-only json is Shape::Scalar, so it mangles like a scalar
        // storage domain: `Json`. The searchable document (json_search) keeps
        // the hand-written `SteVecDocument` identifier.
        assert_eq!(JSONB.domains[0].rust_struct_name(JSONB.name), "Json");
        assert_eq!(
            JSONB.domains[1].rust_struct_name(JSONB.name),
            "SteVecDocument"
        );
        assert_eq!(JSONB.domains[2].rust_struct_name(JSONB.name), "SteVecEntry");
        assert_eq!(JSONB.domains[3].rust_struct_name(JSONB.name), "SteVecQuery");
    }

    #[test]
    fn is_eq_only_is_false_for_the_non_scalar_jsonb_family() {
        // `is_eq_only` describes the flat-scalar shape (storage + `_eq`, no
        // `_ord`). The non-scalar jsonb family has no flat eq/ord concept — its
        // ordered `oc` capability is carried structurally, not as an `ord`
        // domain — so a bare `!any(name == "ord")` would misreport it as
        // eq-only. It must return false. Guards the latent footgun where jsonb
        // gets wired into the eq-only-sensitive matrix macros.
        use crate::JSONB;
        assert!(
            !JSONB.is_eq_only(),
            "the non-scalar jsonb family must not be classified eq-only"
        );
    }
}
