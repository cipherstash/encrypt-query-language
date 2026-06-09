//! Inherent impls for [`Term`] — the per-term SQL contract (`json_key`,
//! `extractor`, `ctor`, `role`, `operators`, `requires`) plus the cross-term
//! helpers that resolve a domain's `&[Term]` to its operators, keys, requires,
//! role, and extractor. Definition lives in `lib.rs`.

use crate::Term;

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
            Term::Hm => &["src/v3/sem/hmac_256/functions.sql"],
            Term::Ore => &[
                "src/v3/sem/ore_block_u64_8_256/functions.sql",
                "src/v3/sem/ore_block_u64_8_256/operators.sql",
            ],
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

    /// Generated-file role label for a domain with these terms. No terms =>
    /// `"storage"`; otherwise the first term's role.
    pub fn role_for_terms(terms: &[Term]) -> &'static str {
        match terms.first() {
            None => "storage",
            Some(t) => t.role(),
        }
    }
}
