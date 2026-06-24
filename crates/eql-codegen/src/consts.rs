//! AUTO-GENERATED headers, schema constants, and SQL-string escaping.

/// SQL generated-file marker — the header's first line, with no trailing
/// newline. The SQL templates emit it (followed by a newline) as line 1, and the
/// writer uses it to recognise files it owns (overwrite/clean safety). Tests that
/// synthesise file bodies append `\n` to form the full header line.
pub(crate) const AUTO_GENERATED_MARKER: &str = "-- AUTOMATICALLY GENERATED FILE.";

/// The single schema housing the self-contained `eql_v3` surface: the
/// encrypted-domain families AND the SEM index-term types/constructors they
/// call. v3 has zero dependency on `eql_v2`, so domains and core index-term
/// types share one schema by construction — there is no second schema to point
/// the core types at.
pub(crate) const SCHEMA: &str = "eql_v3";

/// Always-present payload keys checked for presence in every domain CHECK.
/// Term-specific keys are appended after these by `context::domain_block`.
/// Defined in the catalog (`eql_domains::ENVELOPE_KEYS`) so the CHECKs and
/// the `eql-types` payload structs share one envelope definition.
pub(crate) const ENVELOPE_KEYS: &[&str] = eql_domains::ENVELOPE_KEYS;

/// Escape a string for use inside a single-quoted SQL literal by doubling
/// embedded single quotes.
pub(crate) fn sql_str(s: &str) -> String {
    s.replace('\'', "''")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sql_marker_is_grep_compatible_single_line() {
        // The `^-- AUTOMATICALLY GENERATED FILE` marker is what
        // tasks/docs/validate/{coverage,required-tags}.sh grep on to skip
        // generated SQL — keep this assertion and that grep in lockstep. The
        // marker is a single line with no embedded newline (tests append `\n`).
        assert_eq!(AUTO_GENERATED_MARKER, "-- AUTOMATICALLY GENERATED FILE.");
        assert!(!AUTO_GENERATED_MARKER.contains('\n'));
    }

    #[test]
    fn sql_str_doubles_single_quotes() {
        assert_eq!(sql_str("o'brien"), "o''brien");
        assert_eq!(sql_str("a'b'c"), "a''b''c");
        assert_eq!(sql_str("int4_eq"), "int4_eq");
        assert_eq!(sql_str("<="), "<=");
    }
}
