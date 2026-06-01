//! `IndexKind` — the typed EQL search-index identifier.
//!
//! Replaces the `&str` / `FixtureIdentifier`-validated string at the
//! spec/driver boundary. `FixtureIdentifier` proves the value matches
//! `^[a-z][a-z0-9_]*$`; it does NOT prove the name is a real index type.
//! `IndexKind` proves both, at compile time. A typo at spec construction
//! (`.with_index(IndexKind::Uniqu)`) is a compile error rather than a
//! runtime "unknown EQL index identifier" panic deep in the driver.

use std::fmt;

/// One of the EQL search-index identifiers cipherstash-config recognises.
/// Construction is through the variants — by construction every value is
/// in the allowlist. The wire-form `&str` (used in cipherstash-config and
/// the SQL renderers) is available via `as_str` / `Display`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum IndexKind {
    /// `unique` — drives `=` / `<>` via HMAC.
    Unique,
    /// `ore` — drives `<` / `<=` / `>` / `>=` via ORE block terms.
    Ore,
    /// `match` — drives `LIKE` / `ILIKE` via the bloom filter.
    Match,
}

impl IndexKind {
    pub fn as_str(self) -> &'static str {
        match self {
            IndexKind::Unique => "unique",
            IndexKind::Ore => "ore",
            IndexKind::Match => "match",
        }
    }
}

impl fmt::Display for IndexKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_as_the_eql_wire_form_string() {
        assert_eq!(IndexKind::Unique.as_str(), "unique");
        assert_eq!(IndexKind::Ore.as_str(), "ore");
        assert_eq!(IndexKind::Match.as_str(), "match");
    }

    #[test]
    fn display_matches_as_str() {
        assert_eq!(format!("{}", IndexKind::Unique), "unique");
        assert_eq!(format!("{}", IndexKind::Ore), "ore");
        assert_eq!(format!("{}", IndexKind::Match), "match");
    }
}
