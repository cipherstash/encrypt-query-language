//! Scalar/term catalog for EQL encrypted-domain codegen.
//!
//! Replaces the Python `tasks/codegen/scalars.py`, `terms.py`, and `spec.py`
//! plus the `tasks/codegen/types/*.toml` manifests. Plain Rust data + enums;
//! std-only, no dependencies.
//!
//! Plans 2 and 3 depend on the public names here verbatim — do not rename.

/// The native Rust scalar a domain type maps onto.
///
/// Mirrors `scalars.py`'s `ScalarKind` rendering facts. `min_value`/`max_value`
/// are widened to `i128` so a single accessor type covers `i16`..`i64` bounds.
/// This is the fixed capability layer: a variant being present here only means
/// the generator *can* render that Rust kind; the `CATALOG` registry below is
/// what declares which scalar types actually exist.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScalarKind {
    I16,
    I32,
    I64,
}

impl ScalarKind {
    /// The Rust type name as it appears in generated source (e.g. `"i32"`).
    pub const fn rust_type(self) -> &'static str {
        match self {
            ScalarKind::I16 => "i16",
            ScalarKind::I32 => "i32",
            ScalarKind::I64 => "i64",
        }
    }

    /// The `MIN` named-constant symbol (e.g. `"i32::MIN"`).
    pub const fn min_symbol(self) -> &'static str {
        match self {
            ScalarKind::I16 => "i16::MIN",
            ScalarKind::I32 => "i32::MIN",
            ScalarKind::I64 => "i64::MIN",
        }
    }

    /// The `MAX` named-constant symbol (e.g. `"i32::MAX"`).
    pub const fn max_symbol(self) -> &'static str {
        match self {
            ScalarKind::I16 => "i16::MAX",
            ScalarKind::I32 => "i32::MAX",
            ScalarKind::I64 => "i64::MAX",
        }
    }

    /// The zero literal symbol (always `"0"`).
    pub const fn zero_symbol(self) -> &'static str {
        "0"
    }

    /// Inclusive lower bound of the representable range, widened to `i128`.
    pub const fn min_value(self) -> i128 {
        match self {
            ScalarKind::I16 => i16::MIN as i128,
            ScalarKind::I32 => i32::MIN as i128,
            ScalarKind::I64 => i64::MIN as i128,
        }
    }

    /// Inclusive upper bound of the representable range, widened to `i128`.
    pub const fn max_value(self) -> i128 {
        match self {
            ScalarKind::I16 => i16::MAX as i128,
            ScalarKind::I32 => i32::MAX as i128,
            ScalarKind::I64 => i64::MAX as i128,
        }
    }
}

/// A fixed index term known to the scalar materializer.
///
/// Mirrors `terms.py`'s `TERM_CATALOG`. `Hm` provides equality; `Ore` provides
/// equality plus ordering. The `json_key`/`extractor`/`returns`/`ctor` values
/// are the cross-schema SQL contract and are copied verbatim from `terms.py` —
/// changing one is a generated-SQL behaviour change, not a refactor.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Term {
    Hm,
    Ore,
}

impl Term {
    /// JSON payload key carrying this term (`"hm"` / `"ob"`).
    pub const fn json_key(self) -> &'static str {
        match self {
            Term::Hm => "hm",
            Term::Ore => "ob",
        }
    }

    /// The generated extractor function name (`"eq_term"` / `"ord_term"`).
    pub const fn extractor(self) -> &'static str {
        match self {
            Term::Hm => "eq_term",
            Term::Ore => "ord_term",
        }
    }

    /// Cross-schema return type of the extractor (in `eql_v2`).
    pub const fn returns(self) -> &'static str {
        match self {
            Term::Hm => "eql_v2.hmac_256",
            Term::Ore => "eql_v2.ore_block_u64_8_256",
        }
    }

    /// Constructor name for the index-term type (unqualified).
    pub const fn ctor(self) -> &'static str {
        match self {
            Term::Hm => "hmac_256",
            Term::Ore => "ore_block_u64_8_256",
        }
    }

    /// Generated-file role label for a domain whose first term is this one.
    pub const fn role(self) -> &'static str {
        match self {
            Term::Hm => "eq",
            Term::Ore => "ord",
        }
    }

    /// SQL operators this term supports, in catalog order.
    pub const fn operators(self) -> &'static [&'static str] {
        match self {
            Term::Hm => &["=", "<>"],
            Term::Ore => &["=", "<>", "<", "<=", ">", ">="],
        }
    }

    /// SQL `-- REQUIRE:` edges this term pulls in, in catalog order.
    pub const fn requires(self) -> &'static [&'static str] {
        match self {
            Term::Hm => &["src/hmac_256/functions.sql"],
            Term::Ore => &[
                "src/ore_block_u64_8_256/functions.sql",
                "src/ore_block_u64_8_256/operators.sql",
            ],
        }
    }
}

impl Term {
    /// Stable dedupe — first occurrence wins. The Rust analogue of
    /// `terms.py`'s `dict.fromkeys` ordering contract.
    fn dedupe_preserving_order<'a>(
        items: impl IntoIterator<Item = &'a str>,
    ) -> Vec<&'a str> {
        let mut out: Vec<&'a str> = Vec::new();
        for item in items {
            if !out.contains(&item) {
                out.push(item);
            }
        }
        out
    }

    /// Supported operators for the union of a domain's terms (catalog order,
    /// deduped). Mirrors `terms.py::operators_for_terms`.
    pub fn operators_for_terms(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(
            terms.iter().flat_map(|t| t.operators().iter().copied()),
        )
    }

    /// JSON payload keys required by these terms (deduped, in order).
    /// Mirrors `terms.py::term_json_keys`.
    pub fn term_json_keys(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().map(|t| t.json_key()))
    }

    /// SQL `-- REQUIRE:` edges needed by these terms (deduped, in order).
    /// Mirrors `terms.py::term_requires`.
    pub fn term_requires(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(
            terms.iter().flat_map(|t| t.requires().iter().copied()),
        )
    }

    /// The extractor that supports `op` for a domain carrying `terms`, or
    /// `None`. First supporting term wins. Mirrors
    /// `terms.py::extractor_for_operator`.
    pub fn extractor_for_operator(terms: &[Term], op: &str) -> Option<&'static str> {
        terms
            .iter()
            .find(|t| t.operators().contains(&op))
            .map(|t| t.extractor())
    }

    /// Generated-file role label for a domain with these terms. No terms =>
    /// `"storage"`; otherwise the first term's role. Mirrors
    /// `terms.py::role_for_terms`.
    pub fn role_for_terms(terms: &[Term]) -> &'static str {
        match terms.first() {
            None => "storage",
            Some(t) => t.role(),
        }
    }
}

/// A single fixture plaintext value for a scalar type.
///
/// Mirrors `scalars.py`'s fixture-token handling, but typed: the sentinels
/// `MIN`/`MAX`/`ZERO` (the matrix comparison pivots) are dedicated variants,
/// and `N(i128)` is any explicit numeric literal. Range validity of committed
/// catalog data is enforced by the invariant `#[test]`s, not here.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Fixture {
    Min,
    Max,
    Zero,
    N(i128),
}

impl Fixture {
    /// Resolve this fixture to its numeric value for the given scalar kind.
    /// Mirrors `scalars.py::numeric_value`. Infallible: `Min`/`Max` resolve to
    /// the kind's bounds, `Zero` to `0`, and `N(n)` to `n` verbatim. It does
    /// NOT range-check — for committed catalog data the range is statically
    /// un-failable, and the bounds guard the old `Result` encoded lives in the
    /// invariant test `every_fixture_value_is_within_kind_bounds`
    /// (which compares this value against `[min_value(), max_value()]`).
    pub fn numeric_value(self, kind: ScalarKind) -> i128 {
        match self {
            Fixture::Min => kind.min_value(),
            Fixture::Max => kind.max_value(),
            Fixture::Zero => 0,
            Fixture::N(n) => n,
        }
    }

    /// Render this fixture as a Rust source literal of the given scalar kind.
    /// Sentinels render to their named constant; `N` renders the integer.
    /// Mirrors `scalars.py::render_literal`.
    pub fn render_literal(self, kind: ScalarKind) -> String {
        match self {
            Fixture::Min => kind.min_symbol().to_string(),
            Fixture::Max => kind.max_symbol().to_string(),
            Fixture::Zero => kind.zero_symbol().to_string(),
            Fixture::N(n) => n.to_string(),
        }
    }
}

/// One generated public domain: a suffix appended to the type token and the
/// fixed index terms it carries. Suffix `""` is the storage-only domain.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DomainSpec {
    pub suffix: &'static str,
    pub terms: &'static [Term],
}

/// A scalar encrypted-domain type: its SQL token, native Rust type, generated
/// domains, and fixture plaintext list. The Rust analogue of one `*.toml`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ScalarSpec {
    pub token: &'static str,
    pub kind: ScalarKind,
    pub domains: &'static [DomainSpec],
    pub fixtures: &'static [Fixture],
}

impl ScalarSpec {
    /// The fully-qualified domain name: `token` + `suffix`. Makes the old
    /// "domain name must start with the token" validation structural.
    pub fn domain_name(&self, domain: &DomainSpec) -> String {
        format!("{}{}", self.token, domain.suffix)
    }
}

/// Domains shared by every ordered-integer scalar, in manifest file order:
/// storage (no terms), `_eq` (hm), `_ord_ore` (ore), `_ord` (ore).
const ORDERED_INT_DOMAINS: &[DomainSpec] = &[
    DomainSpec { suffix: "", terms: &[] },
    DomainSpec { suffix: "_eq", terms: &[Term::Hm] },
    DomainSpec { suffix: "_ord_ore", terms: &[Term::Ore] },
    DomainSpec { suffix: "_ord", terms: &[Term::Ore] },
];

/// int4 fixture plaintexts — verbatim from `tasks/codegen/types/int4.toml`.
const INT4_FIXTURES: &[Fixture] = &[
    Fixture::Min,
    Fixture::N(-100),
    Fixture::N(-1),
    Fixture::Zero,
    Fixture::N(1),
    Fixture::N(2),
    Fixture::N(5),
    Fixture::N(10),
    Fixture::N(17),
    Fixture::N(25),
    Fixture::N(42),
    Fixture::N(50),
    Fixture::N(100),
    Fixture::N(250),
    Fixture::N(1000),
    Fixture::N(9999),
    Fixture::Max,
];

/// int2 fixture plaintexts — verbatim from `tasks/codegen/types/int2.toml`.
const INT2_FIXTURES: &[Fixture] = &[
    Fixture::Min,
    Fixture::N(-30000),
    Fixture::N(-100),
    Fixture::N(-1),
    Fixture::Zero,
    Fixture::N(1),
    Fixture::N(2),
    Fixture::N(5),
    Fixture::N(10),
    Fixture::N(17),
    Fixture::N(25),
    Fixture::N(42),
    Fixture::N(50),
    Fixture::N(100),
    Fixture::N(250),
    Fixture::N(1000),
    Fixture::N(9999),
    Fixture::N(30000),
    Fixture::Max,
];

const INT4: ScalarSpec = ScalarSpec {
    token: "int4",
    kind: ScalarKind::I32,
    domains: ORDERED_INT_DOMAINS,
    fixtures: INT4_FIXTURES,
};

const INT2: ScalarSpec = ScalarSpec {
    token: "int2",
    kind: ScalarKind::I16,
    domains: ORDERED_INT_DOMAINS,
    fixtures: INT2_FIXTURES,
};

/// The scalar catalog: the single source of truth replacing the TOML manifests
/// present on this branch (`int4`, `int2`). Order is significant (it drives
/// generation/enumeration order). `int8` is intentionally absent here — it is
/// added on the branch that introduces the int8 SQL surface by appending its
/// `ScalarSpec`; the capability layer above (`ScalarKind::I64`) already supports
/// it, so that addition is a pure append.
pub const CATALOG: &[ScalarSpec] = &[INT4, INT2];

#[cfg(test)]
mod rust_tests {
    use super::*;

    #[test]
    fn i32_facts_match_int4() {
        assert_eq!(ScalarKind::I32.rust_type(), "i32");
        assert_eq!(ScalarKind::I32.min_symbol(), "i32::MIN");
        assert_eq!(ScalarKind::I32.max_symbol(), "i32::MAX");
        assert_eq!(ScalarKind::I32.zero_symbol(), "0");
        assert_eq!(ScalarKind::I32.min_value(), -2_147_483_648_i128);
        assert_eq!(ScalarKind::I32.max_value(), 2_147_483_647_i128);
    }

    #[test]
    fn i16_facts_match_int2() {
        assert_eq!(ScalarKind::I16.rust_type(), "i16");
        assert_eq!(ScalarKind::I16.min_symbol(), "i16::MIN");
        assert_eq!(ScalarKind::I16.max_symbol(), "i16::MAX");
        assert_eq!(ScalarKind::I16.zero_symbol(), "0");
        assert_eq!(ScalarKind::I16.min_value(), -32_768_i128);
        assert_eq!(ScalarKind::I16.max_value(), 32_767_i128);
    }

    #[test]
    fn i64_facts() {
        // Capability-layer fact: i64 is the Rust kind a future int8 maps onto.
        // Present here so adding int8 later is a pure `CATALOG` append.
        assert_eq!(ScalarKind::I64.rust_type(), "i64");
        assert_eq!(ScalarKind::I64.min_symbol(), "i64::MIN");
        assert_eq!(ScalarKind::I64.max_symbol(), "i64::MAX");
        assert_eq!(ScalarKind::I64.zero_symbol(), "0");
        assert_eq!(ScalarKind::I64.min_value(), -9_223_372_036_854_775_808_i128);
        assert_eq!(ScalarKind::I64.max_value(), 9_223_372_036_854_775_807_i128);
    }
}

#[cfg(test)]
mod term_tests {
    use super::*;

    #[test]
    fn hm_term_provides_equality() {
        let hm = Term::Hm;
        assert_eq!(hm.json_key(), "hm");
        assert_eq!(hm.extractor(), "eq_term");
        assert_eq!(hm.returns(), "eql_v2.hmac_256");
        assert_eq!(hm.ctor(), "hmac_256");
        assert_eq!(hm.role(), "eq");
        assert_eq!(hm.operators(), &["=", "<>"]);
        assert_eq!(hm.requires(), &["src/hmac_256/functions.sql"]);
    }

    #[test]
    fn ore_term_preserves_int4_sql_contract() {
        let ore = Term::Ore;
        assert_eq!(ore.json_key(), "ob");
        assert_eq!(ore.extractor(), "ord_term");
        assert_eq!(ore.returns(), "eql_v2.ore_block_u64_8_256");
        assert_eq!(ore.ctor(), "ore_block_u64_8_256");
        assert_eq!(ore.role(), "ord");
        assert_eq!(ore.operators(), &["=", "<>", "<", "<=", ">", ">="]);
        assert_eq!(
            ore.requires(),
            &[
                "src/ore_block_u64_8_256/functions.sql",
                "src/ore_block_u64_8_256/operators.sql",
            ]
        );
    }
}

#[cfg(test)]
mod term_helper_tests {
    use super::*;

    #[test]
    fn operators_are_union_in_catalog_order() {
        // ore then hm: ore's six ops first, hm adds nothing new.
        assert_eq!(
            Term::operators_for_terms(&[Term::Ore, Term::Hm]),
            vec!["=", "<>", "<", "<=", ">", ">="]
        );
    }

    #[test]
    fn operators_for_terms_handles_empty() {
        assert!(Term::operators_for_terms(&[]).is_empty());
    }

    #[test]
    fn json_keys_come_from_catalog() {
        assert_eq!(
            Term::term_json_keys(&[Term::Hm, Term::Ore]),
            vec!["hm", "ob"]
        );
        assert!(Term::term_json_keys(&[]).is_empty());
    }

    #[test]
    fn requires_are_deduplicated_in_order() {
        assert_eq!(
            Term::term_requires(&[Term::Ore, Term::Ore, Term::Hm]),
            vec![
                "src/ore_block_u64_8_256/functions.sql",
                "src/ore_block_u64_8_256/operators.sql",
                "src/hmac_256/functions.sql",
            ]
        );
        assert!(Term::term_requires(&[]).is_empty());
    }

    #[test]
    fn role_for_terms_handles_storage_eq_ord() {
        assert_eq!(Term::role_for_terms(&[]), "storage");
        assert_eq!(Term::role_for_terms(&[Term::Hm]), "eq");
        assert_eq!(Term::role_for_terms(&[Term::Ore]), "ord");
    }

    #[test]
    fn extractor_for_operator_picks_first_supporting_term() {
        assert_eq!(Term::extractor_for_operator(&[Term::Hm], "="), Some("eq_term"));
        assert_eq!(Term::extractor_for_operator(&[Term::Ore], "<"), Some("ord_term"));
        assert_eq!(
            Term::extractor_for_operator(&[Term::Hm, Term::Ore], "="),
            Some("eq_term")
        );
        assert_eq!(
            Term::extractor_for_operator(&[Term::Hm, Term::Ore], "<"),
            Some("ord_term")
        );
    }

    #[test]
    fn extractor_for_operator_none_when_unsupported() {
        assert_eq!(Term::extractor_for_operator(&[Term::Hm], "<"), None);
        assert_eq!(Term::extractor_for_operator(&[], "="), None);
    }
}

#[cfg(test)]
mod fixture_tests {
    use super::*;

    #[test]
    fn numeric_value_resolves_sentinels_and_literals_for_i32() {
        assert_eq!(Fixture::Min.numeric_value(ScalarKind::I32), -2_147_483_648);
        assert_eq!(Fixture::Max.numeric_value(ScalarKind::I32), 2_147_483_647);
        assert_eq!(Fixture::Zero.numeric_value(ScalarKind::I32), 0);
        assert_eq!(Fixture::N(42).numeric_value(ScalarKind::I32), 42);
        assert_eq!(Fixture::N(-1).numeric_value(ScalarKind::I32), -1);
    }

    #[test]
    fn numeric_value_resolves_sentinels_per_kind() {
        // Sentinels resolve to the kind's bounds; zero is always 0.
        assert_eq!(Fixture::Min.numeric_value(ScalarKind::I16), -32_768);
        assert_eq!(Fixture::Max.numeric_value(ScalarKind::I16), 32_767);
        assert_eq!(Fixture::Min.numeric_value(ScalarKind::I64), -9_223_372_036_854_775_808);
        assert_eq!(Fixture::Max.numeric_value(ScalarKind::I64), 9_223_372_036_854_775_807);
        assert_eq!(Fixture::Zero.numeric_value(ScalarKind::I64), 0);
        // `numeric_value` is infallible: it resolves a literal verbatim and does
        // NOT range-check. Range validity of committed catalog data is enforced
        // by the invariant test `every_fixture_value_is_within_kind_bounds`,
        // which compares `numeric_value` against `[min_value(), max_value()]`.
        assert_eq!(Fixture::N(5_000_000_000).numeric_value(ScalarKind::I64), 5_000_000_000);
    }

    #[test]
    fn render_literal_maps_sentinels() {
        assert_eq!(Fixture::Min.render_literal(ScalarKind::I32), "i32::MIN");
        assert_eq!(Fixture::Max.render_literal(ScalarKind::I32), "i32::MAX");
        assert_eq!(Fixture::Zero.render_literal(ScalarKind::I32), "0");
        assert_eq!(Fixture::Min.render_literal(ScalarKind::I16), "i16::MIN");
        assert_eq!(Fixture::Max.render_literal(ScalarKind::I64), "i64::MAX");
    }

    #[test]
    fn render_literal_passes_through_numeric() {
        assert_eq!(Fixture::N(-100).render_literal(ScalarKind::I32), "-100");
        assert_eq!(Fixture::N(9999).render_literal(ScalarKind::I32), "9999");
        assert_eq!(Fixture::N(5_000_000_000).render_literal(ScalarKind::I64), "5000000000");
    }
}

#[cfg(test)]
mod catalog_tests {
    use super::*;

    fn scalar(token: &str) -> &'static ScalarSpec {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .unwrap_or_else(|| panic!("{token} missing from CATALOG"))
    }

    #[test]
    fn catalog_has_int4_int2_in_order() {
        let tokens: Vec<&str> = CATALOG.iter().map(|s| s.token).collect();
        assert_eq!(tokens, vec!["int4", "int2"]);
    }

    #[test]
    fn int4_maps_to_i32_with_four_domains() {
        let s = scalar("int4");
        assert_eq!(s.kind, ScalarKind::I32);
        let suffixes: Vec<&str> = s.domains.iter().map(|d| d.suffix).collect();
        // File order from int4.toml: storage, _eq, _ord_ore, _ord.
        assert_eq!(suffixes, vec!["", "_eq", "_ord_ore", "_ord"]);
    }

    #[test]
    fn int4_domain_terms_match_manifest() {
        let s = scalar("int4");
        assert_eq!(s.domains[0].terms, &[] as &[Term]); // storage
        assert_eq!(s.domains[1].terms, &[Term::Hm]); // _eq
        assert_eq!(s.domains[2].terms, &[Term::Ore]); // _ord_ore
        assert_eq!(s.domains[3].terms, &[Term::Ore]); // _ord
    }

    #[test]
    fn int2_rust_type() {
        assert_eq!(scalar("int2").kind, ScalarKind::I16);
    }

    #[test]
    fn all_types_share_the_same_domain_shape() {
        // Every scalar declares the same four domains with the same terms;
        // only the token differs (the matrix-snapshot collapse depends on this).
        for s in CATALOG {
            let suffixes: Vec<&str> = s.domains.iter().map(|d| d.suffix).collect();
            assert_eq!(
                suffixes,
                vec!["", "_eq", "_ord_ore", "_ord"],
                "{} has unexpected domain set",
                s.token
            );
        }
    }

    #[test]
    fn domain_name_concatenates_token_and_suffix() {
        let s = scalar("int4");
        assert_eq!(s.domain_name(&s.domains[0]), "int4"); // storage
        assert_eq!(s.domain_name(&s.domains[1]), "int4_eq");
        assert_eq!(s.domain_name(&s.domains[3]), "int4_ord");
    }

    #[test]
    fn int4_fixtures_match_manifest() {
        let s = scalar("int4");
        // From int4.toml [fixture] values, in order.
        let expected = vec![
            Fixture::Min,
            Fixture::N(-100),
            Fixture::N(-1),
            Fixture::Zero,
            Fixture::N(1),
            Fixture::N(2),
            Fixture::N(5),
            Fixture::N(10),
            Fixture::N(17),
            Fixture::N(25),
            Fixture::N(42),
            Fixture::N(50),
            Fixture::N(100),
            Fixture::N(250),
            Fixture::N(1000),
            Fixture::N(9999),
            Fixture::Max,
        ];
        assert_eq!(s.fixtures, expected.as_slice());
    }

    #[test]
    fn int2_fixtures_match_manifest() {
        let s = scalar("int2");
        // From int2.toml [fixture] values, in order — includes the wide
        // ±30000 values that exercise the i16 bounds.
        assert!(s.fixtures.contains(&Fixture::N(-30000)));
        assert!(s.fixtures.contains(&Fixture::N(30000)));
        assert_eq!(s.fixtures.first(), Some(&Fixture::Min));
        assert_eq!(s.fixtures.last(), Some(&Fixture::Max));
    }
}

#[cfg(test)]
mod invariant_tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn every_domain_name_starts_with_its_token() {
        for s in CATALOG {
            for d in s.domains {
                let name = s.domain_name(d);
                assert!(
                    name == s.token || name.starts_with(&format!("{}_", s.token)),
                    "{name} does not start with token {}",
                    s.token
                );
            }
        }
    }

    #[test]
    fn every_type_has_at_least_one_domain() {
        for s in CATALOG {
            assert!(!s.domains.is_empty(), "{} has no domains", s.token);
        }
    }

    #[test]
    fn fixtures_include_min_max_and_zero() {
        for s in CATALOG {
            let resolved: Vec<i128> = s
                .fixtures
                .iter()
                .map(|f| f.numeric_value(s.kind))
                .collect();
            assert!(
                resolved.contains(&s.kind.min_value()),
                "{} fixtures missing MIN",
                s.token
            );
            assert!(
                resolved.contains(&s.kind.max_value()),
                "{} fixtures missing MAX",
                s.token
            );
            assert!(resolved.contains(&0), "{} fixtures missing zero", s.token);
        }
    }

    #[test]
    fn fixture_values_are_distinct_by_resolved_number() {
        for s in CATALOG {
            let mut seen: HashMap<i128, Fixture> = HashMap::new();
            for f in s.fixtures {
                let n = f.numeric_value(s.kind);
                if let Some(prev) = seen.insert(n, *f) {
                    panic!(
                        "{}: {f:?} duplicates {prev:?} (both resolve to {n})",
                        s.token
                    );
                }
            }
        }
    }

    #[test]
    fn every_fixture_value_is_within_kind_bounds() {
        // `numeric_value` is infallible, so the range guarantee the old
        // `Result` encoded is asserted explicitly here: this is the ONLY guard
        // against an out-of-range `N` in committed catalog data.
        for s in CATALOG {
            let (lo, hi) = (s.kind.min_value(), s.kind.max_value());
            for f in s.fixtures {
                let n = f.numeric_value(s.kind);
                assert!(
                    n >= lo && n <= hi,
                    "{}: fixture {f:?} resolves to {n}, out of range [{lo}, {hi}]",
                    s.token
                );
            }
        }
    }

    #[test]
    fn helper_outputs_match_for_known_domains() {
        // Cross-check the Term helpers against a known domain shape on int4.
        let s = CATALOG.iter().find(|s| s.token == "int4").unwrap();
        // storage domain: no terms.
        assert_eq!(Term::role_for_terms(s.domains[0].terms), "storage");
        assert!(Term::operators_for_terms(s.domains[0].terms).is_empty());
        // _eq domain: hm => equality only.
        assert_eq!(Term::role_for_terms(s.domains[1].terms), "eq");
        assert_eq!(
            Term::operators_for_terms(s.domains[1].terms),
            vec!["=", "<>"]
        );
        assert_eq!(Term::term_json_keys(s.domains[1].terms), vec!["hm"]);
        // _ord domain: ore => full ordering.
        assert_eq!(Term::role_for_terms(s.domains[3].terms), "ord");
        assert_eq!(
            Term::operators_for_terms(s.domains[3].terms),
            vec!["=", "<>", "<", "<=", ">", ">="]
        );
        assert_eq!(Term::term_json_keys(s.domains[3].terms), vec!["ob"]);
        assert_eq!(
            Term::extractor_for_operator(s.domains[3].terms, "<"),
            Some("ord_term")
        );
    }
}
