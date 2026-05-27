//! `eql_v2_int4` — the reference scalar implementation.
//!
//! Adding a new ordered numeric scalar (i64, f64, date, ...) is one
//! `impl ScalarType` in `tests/sqlx/src/scalar_domains.rs` plus an
//! `ordered_numeric_matrix!` invocation like this one. The matrix covers
//! everything generic over `T: ScalarType`; only the `twin_sync` test
//! below stays hand-written because it reads `src/encrypted_domain/int4/`
//! source files at fixed paths — that's irreducibly per-type.

use eql_tests::ordered_numeric_matrix;

ordered_numeric_matrix! {
    suite = int4,
    scalar = i32,
    fixture_script = "eql_v2_int4",
    // 3 climbs out of tests/encrypted_domain/scalars/ to reach
    // tests/sqlx/fixtures/. include_str! inside #[sqlx::test] resolves
    // relative to the source file containing the attribute.
    fixture_path = "../../../fixtures",
    // Pivots cover the four interesting numeric regions:
    //   `min` / `max` — i32 signed extremes, where ORE block encoding
    //                   has sign-bit edge cases.
    //   `zero`        — additive identity and the predicate boundary
    //                   for `WHERE plaintext > 0` cases.
    //   `neg` / `mid` / `high` — small / medium / large magnitudes
    //                            producing distinct range cardinalities.
    pivots = [
        (min, i32::MIN),
        (neg, -1),
        (zero, 0),
        (mid, 10),
        (high, 42),
        (max, i32::MAX),
    ],
}

mod twin_sync {
    use std::path::PathBuf;

    /// Structural-sync guard for the two ordered int4 domain file pairs.
    ///
    /// `_ord_ore` (scheme-explicit) and `_ord` (D-E fallback concrete domain)
    /// are deliberate twins: same `eql_v2.ord_term` extractor, the 18
    /// comparison wrappers, the blockers, and the operator declarations,
    /// differing only by the `eql_v2_int4_ord_ore` <-> `eql_v2_int4_ord`
    /// type-name swap. After normalising both type names to a common token,
    /// the executable body of each file (file-header doc comments excluded)
    /// must be byte-identical between the twins.
    ///
    /// The build regenerates `src/encrypted_domain/int4/` from
    /// `tasks/codegen/types/int4.toml` (gitignored). This test runs against
    /// the materialised files and requires the build to have run.
    #[test]
    fn ordered_int4_domain_files_stay_in_sync() {
        fn body(rel: &str, marker: &str) -> String {
            let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("../../src/encrypted_domain/int4")
                .join(rel);
            let text = std::fs::read_to_string(&path)
                .unwrap_or_else(|e| panic!("failed to read {}: {}", path.display(), e));
            let start = text.find(marker).unwrap_or_else(|| {
                panic!("{} is missing the marker {:?}", path.display(), marker)
            });
            text[start..]
                .replace("eql_v2_int4_ord_ore", "ORDTYPE")
                .replace("eql_v2_int4_ord", "ORDTYPE")
        }

        assert_eq!(
            body(
                "int4_ord_ore_functions.sql",
                "CREATE FUNCTION eql_v2.ord_term"
            ),
            body("int4_ord_functions.sql", "CREATE FUNCTION eql_v2.ord_term"),
            "int4_ord_ore_functions.sql and int4_ord_functions.sql have \
             drifted apart. They must stay mechanical twins (type-name swap \
             only) below the file header; mirror every change into both files."
        );

        assert_eq!(
            body("int4_ord_ore_operators.sql", "CREATE OPERATOR"),
            body("int4_ord_operators.sql", "CREATE OPERATOR"),
            "int4_ord_ore_operators.sql and int4_ord_operators.sql have \
             drifted apart. They must stay mechanical twins (type-name swap \
             only) below the file header; mirror every change into both files."
        );

        assert_eq!(
            body(
                "int4_ord_ore_aggregates.sql",
                "CREATE FUNCTION eql_v2.min_sfunc"
            ),
            body(
                "int4_ord_aggregates.sql",
                "CREATE FUNCTION eql_v2.min_sfunc"
            ),
            "int4_ord_ore_aggregates.sql and int4_ord_aggregates.sql have \
             drifted apart. They must stay mechanical twins (type-name swap \
             only) below the file header; mirror every change into both files."
        );
    }
}
