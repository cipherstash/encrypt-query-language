//! Pure SQL-token validators. Validated tokens are wrapped in newtypes
//! (`FixtureIdentifier`, `ColumnType`) so a renderer that accepts the newtype
//! receives type-level proof of validation — an unvalidated `&str` cannot
//! reach the renderer's format strings.

use std::fmt;

/// Lowercase snake-case identifier, must start with a letter: `^[a-z][a-z0-9_]*$`.
fn is_valid_identifier(s: &str) -> bool {
    let mut chars = s.chars();
    match chars.next() {
        Some(c) if c.is_ascii_lowercase() => {}
        _ => return false,
    }
    chars.all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_')
}

/// Allowlist of committed `payload` column types. `{ jsonb }` for #224 — no
/// domain types exist yet. Extending to domain-typed fixtures means extending
/// this list with validated, optionally schema-qualified type tokens.
pub const ALLOWED_COLUMN_TYPES: &[&str] = &["jsonb"];

fn is_valid_column_type(s: &str) -> bool {
    ALLOWED_COLUMN_TYPES.contains(&s)
}

/// A validated SQL identifier. Construction proves the string matches
/// `^[a-z][a-z0-9_]*$`. Renderers interpolate via `Display`, so the bare
/// `&str` cannot reach generated SQL once it has been validated into this type.
#[derive(Debug, Clone)]
pub struct FixtureIdentifier(String);

impl FixtureIdentifier {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<&str> for FixtureIdentifier {
    type Error = String;
    fn try_from(s: &str) -> Result<Self, Self::Error> {
        if is_valid_identifier(s) {
            Ok(Self(s.to_string()))
        } else {
            Err(format!(
                "{s:?} is not a valid identifier (^[a-z][a-z0-9_]*$)"
            ))
        }
    }
}

impl fmt::Display for FixtureIdentifier {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

/// A validated committed-payload column type token. Construction proves the
/// string is in `ALLOWED_COLUMN_TYPES`.
#[derive(Debug, Clone)]
pub struct ColumnType(String);

impl ColumnType {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<&str> for ColumnType {
    type Error = String;
    fn try_from(s: &str) -> Result<Self, Self::Error> {
        if is_valid_column_type(s) {
            Ok(Self(s.to_string()))
        } else {
            Err(format!(
                "{s:?} is not in the allowlist {ALLOWED_COLUMN_TYPES:?}"
            ))
        }
    }
}

impl fmt::Display for ColumnType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_valid_identifiers() {
        assert!(FixtureIdentifier::try_from("eql_v2_int4").is_ok());
        assert!(FixtureIdentifier::try_from("a").is_ok());
        assert!(FixtureIdentifier::try_from("x9_y").is_ok());
    }

    #[test]
    fn rejects_invalid_identifiers() {
        assert!(FixtureIdentifier::try_from("").is_err());
        assert!(FixtureIdentifier::try_from("9abc").is_err()); // leading digit
        assert!(FixtureIdentifier::try_from("_abc").is_err()); // leading underscore
        assert!(FixtureIdentifier::try_from("Abc").is_err()); // uppercase
        assert!(FixtureIdentifier::try_from("a-b").is_err()); // hyphen
        assert!(FixtureIdentifier::try_from("a b").is_err()); // space
        assert!(FixtureIdentifier::try_from("a;DROP").is_err()); // injection attempt
    }

    #[test]
    fn identifier_renders_via_display() {
        let id = FixtureIdentifier::try_from("eql_v2_int4").unwrap();
        assert_eq!(format!("{id}"), "eql_v2_int4");
    }

    #[test]
    fn column_type_accepts_jsonb_only() {
        assert!(ColumnType::try_from("jsonb").is_ok());
        assert!(ColumnType::try_from("text").is_err());
        assert!(ColumnType::try_from("eql_v2_int4").is_err());
        assert!(ColumnType::try_from("jsonb; DROP TABLE x").is_err());
    }

    #[test]
    fn column_type_renders_via_display() {
        let ct = ColumnType::try_from("jsonb").unwrap();
        assert_eq!(format!("{ct}"), "jsonb");
    }
}
