//! `eql_v2_int4` — the reference scalar implementation.
//!
//! Adding a new ordered numeric scalar (i64, f64, date, ...) is one
//! `impl ScalarType` in `tests/sqlx/src/scalar_domains.rs` plus an
//! `ordered_numeric_matrix!` invocation like this one. The matrix covers
//! everything generic over `T: ScalarType`.

use eql_tests::ordered_numeric_matrix;

ordered_numeric_matrix! {
    suite = int4,
    scalar = i32,
    eql_type = "eql_v2_int4",
}
