//! `eql_v2_int8` — the int4 reference scalar, widened to 64 bits.
//!
//! Adding a new ordered numeric scalar (f64, date, ...) is one
//! `impl ScalarType` in `tests/sqlx/src/scalar_domains.rs` plus an
//! `ordered_numeric_matrix!` invocation like this one. The matrix covers
//! everything generic over `T: ScalarType`.

use eql_tests::ordered_numeric_matrix;

ordered_numeric_matrix! {
    suite = int8,
    scalar = i64,
    eql_type = "eql_v2_int8",
}
