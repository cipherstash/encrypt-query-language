//! Inline per-statement correlation tag for the log-as-arbiter capture
//! (Stage 2 of the matrix log-verification design).
//!
//! Every statement the scalar matrix issues is prefixed with an SQL comment
//! `/* eqlmatrix:<case_id> */` so the captured server log is self-describing.
//! `log_statement=all` and `auto_explain`'s "Query Text" both echo the comment
//! verbatim, so the ledger normalizer keys each logged statement on its
//! `case_id` with NO reliance on backend PID — immune to sqlx's 5-connection
//! test pool, to PID recycling on the shared logging server, and to parallel
//! `nextest`. See the design doc "Correlation: inline per-statement tag".
//!
//! The `case_id` is the generated test-function name (the matrix leaves pass
//! it via `stringify!` of the `paste!`-assembled identifier), so it is exactly
//! the join key the Stage 4 matcher expects.

/// The fixed open/close delimiters of the inline correlation comment. A
/// statement is tagged iff its text contains `/* eqlmatrix:<case_id> */`.
///
/// IMPORTANT — these are NOT a single shared source of truth across the system.
/// The byte string `/* eqlmatrix:` is duplicated in THREE places: here (the
/// producer), and twice in `crates/eql-codegen/src/ledger.rs` (the consumer:
/// `extract_case_id` and `strip_eqlmatrix_comment`). Those crates do not depend
/// on each other, so keeping them identical is a **manual byte-identical
/// obligation**, not a structural guarantee — if you change the delimiter here
/// you MUST change both sites in `ledger.rs` (and vice versa). The `ledger.rs`
/// parser test (Task 7) parsing this exact tag is the regression that catches a
/// drift across the boundary.
pub const TAG_OPEN: &str = "/* eqlmatrix:";
pub const TAG_CLOSE: &str = " */";

/// Prepend the inline correlation comment to `sql`.
///
/// `case_id` is `Some(<generated test-function name>)` for matrix leaves and
/// `None` for non-matrix (hand-written-suite) callers. When `None`, NO comment
/// is prepended at all — the bare SQL is returned. This is deliberately
/// asymmetric with an empty `case_id`: there is no `/* eqlmatrix: */`
/// empty-comment artifact, so an untagged statement is simply untagged in the
/// log rather than carrying a meaningless empty tag the normalizer must special-
/// case. The returned string is the statement actually sent to Postgres;
/// `log_statement=all` echoes it verbatim.
///
/// The comment is a leading block comment, which PostgreSQL accepts before any
/// statement keyword (SELECT/CREATE/INSERT/…), so the tag is uniform across
/// every statement shape the matrix emits.
pub fn tag(case_id: Option<&str>, sql: &str) -> String {
    match case_id {
        Some(id) => format!("{TAG_OPEN}{id}{TAG_CLOSE} {sql}"),
        None => sql.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tag_prepends_the_eqlmatrix_comment() {
        let out = tag(Some("matrix_int4_eq_eq_pivot_mid_correctness"), "SELECT 1");
        assert_eq!(
            out,
            "/* eqlmatrix:matrix_int4_eq_eq_pivot_mid_correctness */ SELECT 1"
        );
    }

    #[test]
    fn tag_is_a_leading_block_comment_before_the_keyword() {
        let out = tag(Some("c"), "CREATE TEMP TABLE t (x int)");
        assert!(out.starts_with("/* eqlmatrix:c */ "));
        assert!(out.ends_with("CREATE TEMP TABLE t (x int)"));
    }

    #[test]
    fn tag_none_returns_bare_sql_with_no_comment() {
        // None ⇒ no tag emitted at all (no empty `/* eqlmatrix: */` artifact).
        assert_eq!(tag(None, "SELECT 1"), "SELECT 1");
    }

    #[test]
    fn generated_case_id_cannot_contain_the_close_delimiter() {
        // The close delimiter ` */` must never appear inside a case_id, or the
        // normalizer would truncate the tag early. Generated case_ids are
        // `[A-Za-z0-9_]+` (paste-assembled identifiers), so this holds by
        // construction; pin it so a future grammar change that admits other
        // chars fails here.
        let case_id = "matrix_int4_eq_eq_pivot_mid_correctness";
        assert!(!case_id.contains(" */"));
        assert!(case_id.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'_'));
    }
}
