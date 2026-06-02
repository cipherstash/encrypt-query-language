//! AUTO-GENERATED headers, schema constants, and SQL-string escaping.

/// SQL generated-file marker. The SQL templates emit this as their first line;
/// the writer uses it only to recognise files it owns (overwrite/clean safety).
pub const AUTO_GENERATED_HEADER: &str = "-- AUTOMATICALLY GENERATED FILE.\n";

/// Rust generated-file marker, prepended to `<T>_values.rs` (which has no
/// template). Rust comment syntax so the `.rs` file stays valid.
pub const AUTO_GENERATED_HEADER_RS: &str = "// AUTOMATICALLY GENERATED FILE.\n";

/// Schema housing the encrypted-domain families.
pub const DOMAIN_SCHEMA: &str = "eql_v3";
/// Schema owning the core index-term types/constructors.
pub const CORE_SCHEMA: &str = "eql_v2";

/// Envelope keys checked for presence in every domain CHECK, in order.
pub const ENVELOPE_KEYS: &[&str] = &["v", "i"];
/// Ciphertext payload key.
pub const CIPHERTEXT_KEY: &str = "c";
/// Envelope-version key whose value is pinned.
pub const VERSION_KEY: &str = "v";
/// EQL payload-format version pinned by the domain CHECK.
pub const ENVELOPE_VERSION: u32 = 2;

/// Escape a string for use inside a single-quoted SQL literal by doubling
/// embedded single quotes. Port of templates.py `_sql_str`.
pub fn sql_str(s: &str) -> String {
    s.replace('\'', "''")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sql_marker_is_grep_compatible_single_line() {
        // The `^-- AUTOMATICALLY GENERATED FILE` marker is what
        // tasks/docs/validate/{coverage,required-tags}.sh grep on to skip
        // generated SQL — keep this assertion and that grep in lockstep.
        assert_eq!(AUTO_GENERATED_HEADER, "-- AUTOMATICALLY GENERATED FILE.\n");
        assert!(AUTO_GENERATED_HEADER.contains("AUTOMATICALLY GENERATED FILE"));
    }

    #[test]
    fn rust_marker_is_a_rust_comment() {
        assert_eq!(AUTO_GENERATED_HEADER_RS, "// AUTOMATICALLY GENERATED FILE.\n");
        for line in AUTO_GENERATED_HEADER_RS.lines() {
            assert!(
                !line.starts_with("--"),
                "rust marker must not contain SQL comments"
            );
        }
    }

    #[test]
    fn sql_str_doubles_single_quotes() {
        assert_eq!(sql_str("o'brien"), "o''brien");
        assert_eq!(sql_str("a'b'c"), "a''b''c");
        assert_eq!(sql_str("int4_eq"), "int4_eq");
        assert_eq!(sql_str("<="), "<=");
    }
}
