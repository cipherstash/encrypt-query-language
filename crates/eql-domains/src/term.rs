//! Inherent impls for [`Term`] — the per-term SQL contract (`json_key`,
//! `extractor`, `ctor`, `role`, `operators`, `requires`) plus the cross-term
//! helpers that resolve a domain's `&[Term]` to its operators, keys, requires,
//! role, and extractor. Definition lives in `lib.rs`.

use crate::{Role, Term};

impl Term {
    /// JSON payload key carrying this term (`"hm"` / `"ob"`).
    pub const fn json_key(self) -> &'static str {
        match self {
            Term::Hm => "hm",
            Term::Ore => "ob",
            Term::Bloom => "bf",
        }
    }

    /// The generated extractor function name (`"eq_term"` / `"ord_term"`).
    pub const fn extractor(self) -> &'static str {
        match self {
            Term::Hm => "eq_term",
            Term::Ore => "ord_term",
            Term::Bloom => "match_term",
        }
    }

    /// Constructor name for the index-term type (unqualified).
    pub const fn ctor(self) -> &'static str {
        match self {
            Term::Hm => "hmac_256",
            Term::Ore => "ore_block_256",
            Term::Bloom => "bloom_filter",
        }
    }

    /// Generated-file [`Role`] contributed by this single term. A domain's role
    /// is the richest of its terms' roles — see [`Term::role_for_terms`].
    pub const fn role(self) -> Role {
        match self {
            Term::Hm => Role::Eq,
            Term::Ore => Role::Ord,
            Term::Bloom => Role::Match,
        }
    }

    /// SQL operators this term supports, in catalog order.
    pub const fn operators(self) -> &'static [&'static str] {
        match self {
            Term::Hm => &["=", "<>"],
            Term::Ore => &["=", "<>", "<", "<=", ">", ">="],
            Term::Bloom => &["@>", "<@"],
        }
    }

    /// SQL `-- REQUIRE:` edges this term pulls in, in catalog order.
    pub const fn requires(self) -> &'static [&'static str] {
        match self {
            Term::Hm => &["src/v3/sem/hmac_256/functions.sql"],
            Term::Ore => &[
                "src/v3/sem/ore_block_256/functions.sql",
                "src/v3/sem/ore_block_256/operators.sql",
            ],
            Term::Bloom => &["src/v3/sem/bloom_filter/functions.sql"],
        }
    }

    /// True when this term provides ordering operators (`<` `<=` `>` `>=`).
    /// A per-term *capability*, distinct from [`Role`] (the whole-domain file
    /// role derived from the first term). New ordering terms opt in here, so
    /// `is_ord_capable` never hardcodes a single ordering term.
    pub const fn provides_ordering(self) -> bool {
        matches!(self, Term::Ore)
    }

    /// JSON key whose payload must be a NON-EMPTY array for this term to be
    /// well-formed, or `None` if the term imposes no such structural rule. The
    /// ORE term (`ob`) is an array of block terms; an empty array (`ob: []`) is
    /// only ever produced by encrypting the empty string into an ordered column,
    /// and the domain CHECK rejects it at the boundary rather than ordering it
    /// (issue #262). A new array-backed term opts in here, so the domain CHECK
    /// never hardcodes a single key.
    pub const fn nonempty_array_key(self) -> Option<&'static str> {
        match self {
            Term::Ore => Some(self.json_key()),
            Term::Hm | Term::Bloom => None,
        }
    }
}

impl Term {
    /// Stable dedupe — first occurrence wins.
    fn dedupe_preserving_order<'a>(items: impl IntoIterator<Item = &'a str>) -> Vec<&'a str> {
        let mut out: Vec<&'a str> = Vec::new();
        for item in items {
            if !out.contains(&item) {
                out.push(item);
            }
        }
        out
    }

    /// Supported operators for the union of a domain's terms (catalog order,
    /// deduped).
    pub fn operators_for_terms(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().flat_map(|t| t.operators().iter().copied()))
    }

    /// JSON payload keys required by these terms (deduped, in order).
    pub fn term_json_keys(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().map(|t| t.json_key()))
    }

    /// JSON keys whose payload must be a non-empty array across these terms
    /// (deduped, in order). Symmetric to [`Term::term_json_keys`]; drives the
    /// domain CHECK's non-empty-array clauses. See [`Term::nonempty_array_key`].
    pub fn nonempty_array_keys(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().filter_map(|t| t.nonempty_array_key()))
    }

    /// Distinct extractor-bearing terms, first occurrence per extractor wins.
    /// Two terms sharing an extractor collapse to the first, since the generated
    /// `eq_term`/`ord_term`/`match_term` function is emitted once per extractor.
    pub fn extractor_terms(terms: &[Term]) -> Vec<Term> {
        let mut seen: Vec<&str> = Vec::new();
        let mut out: Vec<Term> = Vec::new();
        for &t in terms {
            if !seen.contains(&t.extractor()) {
                seen.push(t.extractor());
                out.push(t);
            }
        }
        out
    }

    /// SQL `-- REQUIRE:` edges needed by these terms (deduped, in order).
    pub fn term_requires(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().flat_map(|t| t.requires().iter().copied()))
    }

    /// The extractor that supports `op` for a domain carrying `terms`, or
    /// `None`. First supporting term wins.
    pub fn extractor_for_operator(terms: &[Term], op: &str) -> Option<&'static str> {
        terms
            .iter()
            .find(|t| t.operators().contains(&op))
            .map(|t| t.extractor())
    }

    /// Generated-file [`Role`] for a domain with these terms. No terms =>
    /// [`Role::Storage`]; otherwise the **richest** role across the terms by
    /// [`Role::rank`] precedence (`Ord > Eq > Match > Storage`). For the current
    /// single-term catalog this equals the lone term's role, so generated SQL is
    /// unchanged; the precedence only disambiguates a future mixed-term domain
    /// (e.g. `[Hm, Ore]` => `Ord`), keeping this consistent with
    /// [`Term::operators_for_terms`], which unions across all terms rather than
    /// reading only the first.
    pub fn role_for_terms(terms: &[Term]) -> Role {
        terms
            .iter()
            .map(|t| t.role())
            .max_by_key(|r| r.rank())
            .unwrap_or(Role::Storage)
    }
}
