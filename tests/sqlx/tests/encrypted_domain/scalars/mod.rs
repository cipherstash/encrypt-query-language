//! Per-scalar matrix suites. Each `pub mod <token>` targets one scalar type and
//! holds its `ordered_numeric_matrix!` invocation.
//!
//! The modules are generated from the single harness list in
//! `tests/sqlx/src/scalar_types.rs` — adding a type there adds its suite here
//! automatically. The old per-type `scalars/<token>.rs` files are gone.

eql_tests::scalar_types!(matrix_suites);
