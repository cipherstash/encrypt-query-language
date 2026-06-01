//! `eql_v2_int2` — the int4 reference scalar, clamped to 16 bits.
//!
//! Adding a new ordered numeric scalar (i64, f64, date, ...) is one
//! `impl ScalarType` in `tests/sqlx/src/scalar_domains.rs` plus an
//! `ordered_numeric_matrix!` invocation like this one. The matrix covers
//! everything generic over `T: ScalarType`.

use eql_tests::ordered_numeric_matrix;

ordered_numeric_matrix! {
    suite = int2,
    scalar = i16,
    eql_type = "eql_v2_int2",
}
