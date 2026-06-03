//! The single declarative list of scalar types under matrix test — the
//! harness source of truth.
//!
//! Adding a scalar encrypted-domain type to the SQLx matrix used to require
//! editing several files in lock-step. That wiring is now generated from the
//! ONE list embedded in the `scalar_types!` macro below. To add a type, add
//! one `token => rust_type` line here (plus the catalog row in `eql-scalars`
//! and the `EqlPlaintext` impl, which are owned separately — see
//! `docs/reference/adding-a-scalar-encrypted-domain-type.md` §3).
//!
//! # How it works
//!
//! Proc-macros emit into the crate/module where they're invoked, and the
//! harness pieces live in three different compilation contexts (the `eql-tests`
//! lib, the `encrypted_domain` integration-test binary, and the
//! `generate_all_fixtures` integration-test binary). One proc-macro invocation
//! can't reach all three. So the canonical list is held *here once*, inside the
//! `scalar_types!` `macro_rules!`, and each call site invokes
//! `scalar_types!(<mode>)` to forward that same list to the
//! `eql_tests_macros` proc-macro appropriate for that site:
//!
//! - `scalar_types!(scalar_type_impls)` — in `scalar_domains.rs` (lib): the
//!   `impl ScalarType` block.
//! - `scalar_types!(fixture_modules)` — in `fixtures/mod.rs` (lib): the
//!   `pub mod eql_v2_<T>` fixture modules.
//! - `scalar_types!(matrix_suites)` — in
//!   `tests/encrypted_domain/scalars/mod.rs` (test binary): the
//!   `ordered_numeric_matrix!` suites.
//! - `scalar_types!(fixture_dispatch)` — in `tests/generate_all_fixtures.rs`
//!   (test binary): the `generate_for_token` dispatch fn.
//!
//! The list appears once; the four mode arms are pure expansions of it, so the
//! list is genuinely the single source of truth. The matrix-inventory
//! cross-check (`mise run test:matrix:inventory`) still compares the type set
//! the binary actually emits against `eql-codegen list-types`, so a catalog
//! type missing from this list fails loudly.

/// Forward the single canonical scalar-type list to the `eql_tests_macros`
/// proc-macro selected by `$mode`. See the module docs for the call sites.
///
/// THE LIST. This is the only place the harness token set is declared. Keep it
/// in sync with `eql-scalars::CATALOG` — the matrix-inventory cross-check
/// enforces that they agree.
#[macro_export]
macro_rules! scalar_types {
    (scalar_type_impls) => {
        $crate::scalar_types!(@dispatch emit_scalar_type_impls);
    };
    (fixture_modules) => {
        $crate::scalar_types!(@dispatch emit_scalar_fixture_modules);
    };
    (matrix_suites) => {
        $crate::scalar_types!(@dispatch emit_scalar_matrix_suites);
    };
    (fixture_dispatch) => {
        $crate::scalar_types!(@dispatch emit_fixture_dispatch);
    };
    (@dispatch $emitter:ident) => {
        $crate::eql_tests_macros::$emitter! {
            int4 => i32,
            int2 => i16,
            int8 => i64,
        }
    };
}
