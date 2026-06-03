//! Generated-file marker, schema constants, and SQL-string escaping.

/// SQL generated-file marker. The SQL templates emit this as their first line;
/// the writer uses it only to recognise files it owns (overwrite/clean safety).
pub(crate) const AUTO_GENERATED_HEADER: &str = "-- AUTOMATICALLY GENERATED FILE.\n";

/// Schema housing the encrypted-domain families.
pub(crate) const DOMAIN_SCHEMA: &str = "eql_v3";
/// Schema owning the core index-term types/constructors.
pub(crate) const CORE_SCHEMA: &str = "eql_v2";

/// Always-present payload keys checked for presence in every domain CHECK, in
/// order: envelope version (`v`), ident (`i`), ciphertext (`c`). Term-specific
/// keys are appended after these by `context::domain_block`.
pub(crate) const ENVELOPE_KEYS: &[&str] = &["v", "i", "c"];

/// Escape a string for use inside a single-quoted SQL literal by doubling
/// embedded single quotes. Port of templates.py `_sql_str`.
pub(crate) fn sql_str(s: &str) -> String {
    s.replace('\'', "''")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sql_marker_is_grep_compatible_single_line() {
        // Validation scripts grep for this marker to skip generated SQL; keep them in sync.
        assert_eq!(AUTO_GENERATED_HEADER, "-- AUTOMATICALLY GENERATED FILE.\n");
        assert!(AUTO_GENERATED_HEADER.contains("AUTOMATICALLY GENERATED FILE"));
    }

    #[test]
    fn sql_str_doubles_single_quotes() {
        assert_eq!(sql_str("o'brien"), "o''brien");
        assert_eq!(sql_str("a'b'c"), "a''b''c");
        assert_eq!(sql_str("int4_eq"), "int4_eq");
        assert_eq!(sql_str("<="), "<=");
    }
}
