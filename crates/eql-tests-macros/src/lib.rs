//! Proc-macros that expand ONE declarative scalar-harness list into all the
//! per-type SQLx-matrix wiring that used to be hand-maintained across four
//! locations.
//!
//! # Why a proc-macro (and why more than one)
//!
//! Adding a scalar encrypted-domain type used to require editing several
//! files in lock-step (see
//! `docs/reference/adding-a-scalar-encrypted-domain-type.md` §3). The harness
//! wiring — everything *except* the catalog row in `eql-scalars` and the
//! `EqlPlaintext` impl, which are owned by a separate task — is now driven by
//! a SINGLE list, e.g.:
//!
//! ```ignore
//! eql_tests::scalar_harness! {
//!     int4 => i32,
//!     int2 => i16,
//!     int8 => i64,
//! }
//! ```
//!
//! Rust macros emit code into the crate/module where they are invoked, and the
//! harness pieces live in three *different* compilation contexts:
//!
//! 1. the `ScalarType` impls + the fixture modules live in the `eql-tests`
//!    **library** (`src/`);
//! 2. the `ordered_numeric_matrix!` suites live in the `encrypted_domain`
//!    **integration-test binary** (`tests/`), a separate crate target;
//! 3. the `generate_all_fixtures` dispatch lives in *another* integration-test
//!    binary (`tests/generate_all_fixtures.rs`).
//!
//! A single macro invocation cannot emit into all three at once, so the design
//! is: ONE canonical list, captured by the `macro_rules! scalar_harness!`
//! re-exported from `eql-tests` (see `tests/sqlx/src/scalar_harness.rs`), which
//! forwards that same list to whichever proc-macro is appropriate for the call
//! site. Each proc-macro below parses the identical `token => rust_type` list
//! and emits only the items that belong where it is invoked. The list itself is
//! the single source of truth; the four emitters are pure functions of it.
//!
//! Each entry is `token => rust_type` where `token` is the Postgres type token
//! (e.g. `int4`, also the fixture/domain name suffix) and `rust_type` is the
//! Rust plaintext type (`i32`). The catalog value const is derived by
//! upper-casing the token and appending `_VALUES` (`int4` -> `INT4_VALUES`),
//! matching `eql_scalars::INT4_VALUES`.
//!
//! The four emitters are split into thin `#[proc_macro]` shims and pure
//! `proc_macro2::TokenStream` core functions (`*_tokens`) so the core logic is
//! unit-testable without a consumer crate — see the `tests` module.

use proc_macro::TokenStream;
use proc_macro2::TokenStream as TokenStream2;
use quote::{format_ident, quote};
use syn::parse::{Parse, ParseStream};
use syn::punctuated::Punctuated;
use syn::{Ident, Token, Type};

/// One `token => rust_type` entry from the harness list.
struct ScalarEntry {
    /// The Postgres type token (`int4`), also the fixture/domain name suffix
    /// and the `suite` ident in the matrix invocation.
    token: Ident,
    /// The Rust plaintext type (`i32`).
    rust_type: Type,
}

impl Parse for ScalarEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let token: Ident = input.parse()?;
        input.parse::<Token![=>]>()?;
        let rust_type: Type = input.parse()?;
        Ok(ScalarEntry { token, rust_type })
    }
}

/// The whole comma-separated list, with optional trailing comma.
struct ScalarList {
    entries: Vec<ScalarEntry>,
}

impl Parse for ScalarList {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let punctuated = Punctuated::<ScalarEntry, Token![,]>::parse_terminated(input)?;
        Ok(ScalarList {
            entries: punctuated.into_iter().collect(),
        })
    }
}

/// `int4` -> `INT4_VALUES` — the catalog value const for a token. Mirrors the
/// `int_values!(INT4_VALUES, ...)` naming in `eql_scalars`.
fn values_const_ident(token: &Ident) -> Ident {
    format_ident!("{}_VALUES", token.to_string().to_uppercase())
}

// ---------------------------------------------------------------------------
// Core token generators (pure, unit-testable).
// ---------------------------------------------------------------------------

/// Emit one `impl ScalarType for <rust_type>` per entry. See
/// [`emit_scalar_type_impls`].
fn scalar_type_impls_tokens(list: &ScalarList) -> TokenStream2 {
    let impls = list.entries.iter().map(|e| {
        let token_str = e.token.to_string();
        let rust_type = &e.rust_type;
        let values = values_const_ident(&e.token);
        quote! {
            impl ScalarType for #rust_type {
                const PG_TYPE: &'static str = #token_str;
                /// Single-sourced from the matching row in `eql-scalars::CATALOG`
                /// (`eql_scalars::*_VALUES`, materialised from its `Fixture`
                /// list) — the same list the fixture generator encrypts, so the
                /// oracle cannot drift from the fixture.
                const FIXTURE_VALUES: &'static [#rust_type] = ::eql_scalars::#values;
            }
        }
    });
    quote! { #(#impls)* }
}

/// Emit one `pub mod eql_v2_<token> { ... }` per entry. See
/// [`emit_scalar_fixture_modules`].
fn scalar_fixture_modules_tokens(list: &ScalarList) -> TokenStream2 {
    let mods = list.entries.iter().map(|e| {
        let token_str = e.token.to_string();
        let rust_type = &e.rust_type;
        let values = values_const_ident(&e.token);
        let mod_ident = format_ident!("eql_v2_{}", e.token);
        let fixture_name = format!("eql_v2_{}", token_str);
        quote! {
            #[doc = concat!("`eql_v2_", #token_str, "` scalar fixture — generated by `scalar_harness!`.")]
            pub mod #mod_ident {
                use ::eql_scalars::#values as VALUES;
                // `scalar_fixture!` is `#[macro_export]`ed from this crate
                // (`eql-tests`), so `crate::scalar_fixture!` resolves here since
                // the modules are emitted into the `eql-tests` lib.
                crate::scalar_fixture!(#fixture_name, #rust_type, VALUES);
            }
        }
    });
    quote! { #(#mods)* }
}

/// Emit the `generate_for_token` dispatch fn. See [`emit_fixture_dispatch`].
fn fixture_dispatch_tokens(list: &ScalarList) -> TokenStream2 {
    let arms = list.entries.iter().map(|e| {
        let token_str = e.token.to_string();
        let mod_ident = format_ident!("eql_v2_{}", e.token);
        quote! {
            #token_str => ::eql_tests::fixtures::#mod_ident::spec().run().await,
        }
    });
    quote! {
        /// Map a catalog token to its fixture generator and run it. Generated by
        /// `scalar_harness!` from the single harness list. A token present in the
        /// catalog but absent from that list hits the catch-all below and fails
        /// loudly so a new scalar type cannot silently skip fixture generation.
        async fn generate_for_token(token: &str) -> anyhow::Result<()> {
            match token {
                #(#arms)*
                other => anyhow::bail!(
                    "no fixture generator wired for catalog token '{other}'. \
                     Add it to the scalar_harness! list (tests/sqlx/src/scalar_harness.rs). \
                     See the encrypted-domain spec §3."
                ),
            }
        }
    }
}

/// Emit one `pub mod <token> { ordered_numeric_matrix! { ... } }` per entry.
/// See [`emit_scalar_matrix_suites`].
fn scalar_matrix_suites_tokens(list: &ScalarList) -> TokenStream2 {
    let mods = list.entries.iter().map(|e| {
        let token = &e.token;
        let token_str = e.token.to_string();
        let rust_type = &e.rust_type;
        let eql_type = format!("eql_v2_{}", token_str);
        quote! {
            #[doc = concat!("`eql_v2_", #token_str, "` matrix suite — generated by `scalar_harness!`.")]
            pub mod #token {
                ::eql_tests::ordered_numeric_matrix! {
                    suite = #token,
                    scalar = #rust_type,
                    eql_type = #eql_type,
                }
            }
        }
    });
    quote! { #(#mods)* }
}

// ---------------------------------------------------------------------------
// Proc-macro shims.
// ---------------------------------------------------------------------------

/// Emit one `impl ScalarType for <rust_type>` per entry.
///
/// Invoked (via `scalar_harness!`) inside `tests/sqlx/src/scalar_domains.rs`,
/// so the impls land in the `eql-tests` library next to the trait. Replaces the
/// three hand-written impls. `PG_TYPE` is the token string; `FIXTURE_VALUES`
/// is the catalog const `eql_scalars::<TOKEN_UPPER>_VALUES` — single-sourced
/// from the catalog so the oracle cannot drift from the fixture.
#[proc_macro]
pub fn emit_scalar_type_impls(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    scalar_type_impls_tokens(&list).into()
}

/// Emit one `pub mod eql_v2_<token> { ... }` per entry.
///
/// Invoked (via `scalar_harness!`) inside `tests/sqlx/src/fixtures/mod.rs`, so
/// the modules land at `crate::fixtures::eql_v2_<token>` — the path the matrix
/// and the fixture dispatch reference. Each module body is exactly what the old
/// per-type `fixtures/eql_v2_<token>.rs` file contained: a `use` of the catalog
/// value const plus a `scalar_fixture!` invocation. The per-type files are
/// therefore deleted.
#[proc_macro]
pub fn emit_scalar_fixture_modules(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    scalar_fixture_modules_tokens(&list).into()
}

/// Emit the `generate_for_token` dispatch as a single function driven by the
/// list.
///
/// Invoked (via `scalar_harness!`) inside `tests/generate_all_fixtures.rs`.
/// Emits an `async fn generate_for_token(token: &str) -> anyhow::Result<()>`
/// with one match arm per entry plus a loud catch-all, replacing the
/// hand-written match. A catalog token with no entry here (i.e. not in the
/// harness list) hits the catch-all and fails the generator loudly — preserving
/// the "a catalog type with no harness wiring fails loudly" guarantee at
/// generation time (the matrix-inventory cross-check enforces it at test time).
#[proc_macro]
pub fn emit_fixture_dispatch(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    fixture_dispatch_tokens(&list).into()
}

/// Emit one `pub mod <token> { ordered_numeric_matrix! { ... } }` per entry.
///
/// Invoked (via `scalar_harness!`) inside
/// `tests/sqlx/tests/encrypted_domain/scalars/mod.rs`, so the matrix suites land
/// in the `encrypted_domain` integration-test binary — the only place
/// `#[sqlx::test]` suites belong. This is a SEPARATE proc-macro from the
/// lib-side ones because that binary is a different crate target: a single macro
/// invocation in `src/` could not emit into `tests/`. The generated module +
/// `ordered_numeric_matrix!` invocation are byte-equivalent to the old per-type
/// `scalars/<token>.rs` files, so the emitted test names (`scalars::<token>::
/// matrix_*`) are unchanged and the token-normalized `matrix_tests.txt` snapshot
/// keeps matching.
#[proc_macro]
pub fn emit_scalar_matrix_suites(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    scalar_matrix_suites_tokens(&list).into()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> ScalarList {
        syn::parse_str::<ScalarList>("int4 => i32, int8 => i64,").unwrap()
    }

    /// The token-stream comparison is on the normalized `to_string()` form so
    /// whitespace/formatting differences don't make the assertions brittle.
    fn norm(ts: &TokenStream2) -> String {
        ts.to_string()
    }

    #[test]
    fn values_const_name_is_uppercased_with_suffix() {
        let token: Ident = syn::parse_str("int8").unwrap();
        assert_eq!(values_const_ident(&token).to_string(), "INT8_VALUES");
    }

    #[test]
    fn scalar_type_impls_emit_pg_type_and_fixture_values() {
        let out = norm(&scalar_type_impls_tokens(&sample()));
        // One impl per entry, with the right PG_TYPE string and catalog const.
        assert!(out.contains("impl ScalarType for i32"));
        assert!(out.contains("impl ScalarType for i64"));
        assert!(out.contains(r#"const PG_TYPE : & 'static str = "int4""#));
        assert!(out.contains(r#"const PG_TYPE : & 'static str = "int8""#));
        assert!(out.contains(":: eql_scalars :: INT4_VALUES"));
        assert!(out.contains(":: eql_scalars :: INT8_VALUES"));
    }

    #[test]
    fn fixture_modules_emit_named_mods_with_scalar_fixture() {
        let out = norm(&scalar_fixture_modules_tokens(&sample()));
        assert!(out.contains("pub mod eql_v2_int4"));
        assert!(out.contains("pub mod eql_v2_int8"));
        assert!(out.contains("crate :: scalar_fixture !"));
        assert!(out.contains(r#""eql_v2_int4""#));
        assert!(out.contains(":: eql_scalars :: INT4_VALUES as VALUES"));
    }

    #[test]
    fn fixture_dispatch_emits_one_arm_per_token_and_a_catch_all() {
        let out = norm(&fixture_dispatch_tokens(&sample()));
        assert!(out.contains("async fn generate_for_token"));
        assert!(out.contains(r#""int4" =>"#));
        assert!(out.contains(r#""int8" =>"#));
        assert!(out.contains(":: eql_tests :: fixtures :: eql_v2_int4 :: spec"));
        // Loud catch-all preserved.
        assert!(out.contains("other =>"));
        assert!(out.contains("no fixture generator wired"));
    }

    #[test]
    fn matrix_suites_emit_mods_with_unchanged_suite_and_eql_type() {
        let out = norm(&scalar_matrix_suites_tokens(&sample()));
        assert!(out.contains("pub mod int4"));
        assert!(out.contains("pub mod int8"));
        assert!(out.contains(":: eql_tests :: ordered_numeric_matrix !"));
        // suite/scalar/eql_type must match what the old per-type files used so
        // the generated test names (and the snapshot) are unchanged.
        assert!(out.contains("suite = int4"));
        assert!(out.contains("scalar = i32"));
        assert!(out.contains(r#"eql_type = "eql_v2_int4""#));
        assert!(out.contains("suite = int8"));
        assert!(out.contains("scalar = i64"));
        assert!(out.contains(r#"eql_type = "eql_v2_int8""#));
    }
}
