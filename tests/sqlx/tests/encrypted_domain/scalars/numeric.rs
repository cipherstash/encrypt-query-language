//! `eql_v2_numeric` — the ordered `numeric` scalar.
//!
//! Like `int4`, adding this scalar is one `impl ScalarType` in
//! `tests/sqlx/src/scalar_domains.rs` (`impl ScalarType for Decimal`) plus
//! the `ordered_numeric_matrix!` invocation below. The matrix covers
//! everything generic over `T: ScalarType`; only the `twin_sync` test stays
//! hand-written because it reads `src/encrypted_domain/numeric/` source files
//! at fixed paths — that's irreducibly per-type.

use eql_tests::ordered_numeric_matrix;
use rust_decimal::Decimal;

ordered_numeric_matrix! {
    suite = numeric,
    scalar = Decimal,
    eql_type = "eql_v2_numeric",
}

mod twin_sync {
    use std::path::PathBuf;

    /// Structural-sync guard for the two ordered numeric domain file pairs.
    ///
    /// `_ord_ore` (scheme-explicit) and `_ord` (D-E fallback concrete domain)
    /// are deliberate twins: same `eql_v2.ord_term` extractor, the 18
    /// comparison wrappers, the blockers, and the operator declarations,
    /// differing only by the `eql_v2_numeric_ord_ore` <-> `eql_v2_numeric_ord`
    /// type-name swap. After normalising both type names to a common token,
    /// the executable body of each file (file-header doc comments excluded)
    /// must be byte-identical between the twins.
    ///
    /// The build regenerates `src/encrypted_domain/numeric/` from
    /// `tasks/codegen/types/numeric.toml` (gitignored). This test runs against
    /// the materialised files and requires the build to have run.
    #[test]
    fn ordered_numeric_domain_files_stay_in_sync() {
        fn body(rel: &str, marker: &str) -> String {
            let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("../../src/encrypted_domain/numeric")
                .join(rel);
            let text = std::fs::read_to_string(&path)
                .unwrap_or_else(|e| panic!("failed to read {}: {}", path.display(), e));
            let start = text
                .find(marker)
                .unwrap_or_else(|| panic!("{} is missing the marker {:?}", path.display(), marker));
            text[start..]
                .replace("eql_v2_numeric_ord_ore", "ORDTYPE")
                .replace("eql_v2_numeric_ord", "ORDTYPE")
        }

        assert_eq!(
            body(
                "numeric_ord_ore_functions.sql",
                "CREATE FUNCTION eql_v2.ord_term"
            ),
            body(
                "numeric_ord_functions.sql",
                "CREATE FUNCTION eql_v2.ord_term"
            ),
            "numeric_ord_ore_functions.sql and numeric_ord_functions.sql have \
             drifted apart. They must stay mechanical twins (type-name swap \
             only) below the file header; mirror every change into both files."
        );

        assert_eq!(
            body("numeric_ord_ore_operators.sql", "CREATE OPERATOR"),
            body("numeric_ord_operators.sql", "CREATE OPERATOR"),
            "numeric_ord_ore_operators.sql and numeric_ord_operators.sql have \
             drifted apart. They must stay mechanical twins (type-name swap \
             only) below the file header; mirror every change into both files."
        );

        assert_eq!(
            body(
                "numeric_ord_ore_aggregates.sql",
                "CREATE FUNCTION eql_v2.min_sfunc"
            ),
            body(
                "numeric_ord_aggregates.sql",
                "CREATE FUNCTION eql_v2.min_sfunc"
            ),
            "numeric_ord_ore_aggregates.sql and numeric_ord_aggregates.sql have \
             drifted apart. They must stay mechanical twins (type-name swap \
             only) below the file header; mirror every change into both files."
        );
    }
}
