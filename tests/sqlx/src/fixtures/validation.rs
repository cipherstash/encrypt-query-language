//! Pure SQL-token validators. No name, type, cast, or index reaches generated
//! SQL unless it passes the relevant check here. Run at `FixtureSpec`
//! construction so a bad token is a hard error before any SQL is built.

/// Lowercase snake-case identifier, must start with a letter: `^[a-z][a-z0-9_]*$`.
/// Used for the fixture name (a SQL identifier and a filename) and index names.
pub fn is_valid_identifier(s: &str) -> bool {
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

pub fn is_valid_column_type(s: &str) -> bool {
    ALLOWED_COLUMN_TYPES.contains(&s)
}

/// EQL's server-side `add_search_config` cast allowlist (mirrors the
/// `cast_as` check in `src/config/functions.sql`). Asserted client-side too
/// for a clear early error.
pub const ALLOWED_CASTS: &[&str] = &[
    "text", "int", "small_int", "big_int", "real", "double", "boolean",
    "date", "jsonb", "json", "float", "decimal", "timestamp",
];

pub fn is_valid_cast(s: &str) -> bool {
    ALLOWED_CASTS.contains(&s)
}

/// Allowlist of `plaintext` oracle-column SQL types — one entry per shipped
/// `EqlPlaintext` impl. `{ integer }` for #224 (`i32`). A new plaintext type
/// adds its SQL column type here alongside its `EqlPlaintext` impl. An
/// allowlist (not merely the identifier charset) is what upholds the spec's
/// "no type reaches generated SQL unvalidated" guarantee: the charset check
/// alone would admit a bogus type like `"nonsense"`.
pub const ALLOWED_PLAINTEXT_TYPES: &[&str] = &["integer"];

pub fn is_valid_plaintext_type(s: &str) -> bool {
    ALLOWED_PLAINTEXT_TYPES.contains(&s)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_valid_identifiers() {
        assert!(is_valid_identifier("eql_v2_int4"));
        assert!(is_valid_identifier("a"));
        assert!(is_valid_identifier("x9_y"));
    }

    #[test]
    fn rejects_invalid_identifiers() {
        assert!(!is_valid_identifier(""));
        assert!(!is_valid_identifier("9abc"));        // leading digit
        assert!(!is_valid_identifier("_abc"));        // leading underscore
        assert!(!is_valid_identifier("Abc"));         // uppercase
        assert!(!is_valid_identifier("a-b"));         // hyphen
        assert!(!is_valid_identifier("a b"));         // space
        assert!(!is_valid_identifier("a;DROP"));      // injection attempt
    }

    #[test]
    fn column_type_allowlist_is_jsonb_only() {
        assert!(is_valid_column_type("jsonb"));
        assert!(!is_valid_column_type("text"));
        assert!(!is_valid_column_type("eql_v2_int4"));
        assert!(!is_valid_column_type("jsonb; DROP TABLE x"));
    }

    #[test]
    fn cast_allowlist_matches_eql() {
        assert!(is_valid_cast("int"));
        assert!(is_valid_cast("text"));
        assert!(!is_valid_cast("int4"));      // not an EQL cast name
        assert!(!is_valid_cast("nonsense"));
    }

    #[test]
    fn plaintext_type_allowlist_is_integer_only() {
        assert!(is_valid_plaintext_type("integer"));
        assert!(!is_valid_plaintext_type("nonsense"));   // passes the charset check, not a real type
        assert!(!is_valid_plaintext_type("int"));        // an EQL cast name, not a SQL type
        assert!(!is_valid_plaintext_type("integer; DROP TABLE x"));
    }
}
