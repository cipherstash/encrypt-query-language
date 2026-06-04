//! Proc-macros that expand one declarative scalar-type list into the per-type
//! SQLx-matrix wiring that used to be hand-maintained across four locations.
//!
//! The list lives once in the `scalar_types!` `macro_rules!` in
//! `tests/sqlx/src/scalar_types.rs`:
//!
//! ```ignore
//! eql_tests::scalar_types! {
//!     int4 => i32,
//!     int2 => i16,
//! }
//! ```
//!
//! The harness pieces live in three separate compilation contexts — the
//! `eql-tests` lib, the `encrypted_domain` integration-test binary, and the
//! `generate_all_fixtures` integration-test binary — so no single invocation
//! can emit them all. `scalar_types!` forwards the same list to whichever
//! proc-macro below fits the call site; each parses the list and emits only the
//! items belonging there. The list is the single source of truth; the four
//! emitters are pure functions of it.
//!
//! Each entry is `token => rust_type`: `token` is the Postgres type token
//! (`int4`, also the fixture/domain suffix), `rust_type` is the Rust plaintext
//! type (`i32`). The catalog value const is the upper-cased token plus
//! `_VALUES` (`int4` -> `eql_scalars::INT4_VALUES`).
//!
//! Each emitter is split into a thin `#[proc_macro]` shim and a pure `*_tokens`
//! core so the core is unit-testable without a consumer crate.

use proc_macro::TokenStream;
use proc_macro2::TokenStream as TokenStream2;
use quote::{format_ident, quote};
use syn::parse::{Parse, ParseStream};
use syn::punctuated::Punctuated;
use syn::{bracketed, Ident, Token, Type};

/// One `token => rust_type` entry, with an optional trailing `[temporal]` flag.
struct ScalarEntry {
    /// Postgres type token (`int4`); also the fixture/domain suffix and the
    /// matrix `suite` ident.
    token: Ident,
    /// Rust plaintext type (`i32`).
    rust_type: Type,
    /// Whether this entry is a **temporal** (chrono-backed) scalar rather than a
    /// fixed-width integer. Declared explicitly via a trailing `[temporal]`
    /// marker in the dispatch list (`date => chrono::NaiveDate [temporal]`)
    /// rather than sniffed from the Rust type path — so a temporal type that
    /// isn't chrono-spelled, or a non-temporal type whose path happens to
    /// contain `DateTime`, cannot be misclassified.
    temporal: bool,
}

/// The recognised optional entry markers, written in `[brackets]` after the
/// rust type (`date => chrono::NaiveDate [temporal]`). `temporal` is the only
/// one today; a new marker is added here so the accepted set stays a single
/// source of truth — `parse_optional_marker` validates against this slice and
/// the rejection message lists it verbatim.
const SUPPORTED_MARKERS: &[&str] = &["temporal"];

/// Parse the optional trailing `[marker]` on a scalar entry, returning whether
/// the `temporal` marker was present.
///
/// Absent brackets → `false` (an ordinary integer scalar). When brackets are
/// present they must hold exactly one recognised identifier: an unknown marker
/// (`[temporial]`), empty brackets (`[]`), or trailing junk (`[temporal foo]`)
/// are all hard parse errors. The whole point of the explicit marker is that a
/// typo fails loudly rather than silently defaulting an entry to integer, so
/// the parse is strict on every malformed shape, not just unknown names.
fn parse_optional_marker(input: ParseStream) -> syn::Result<bool> {
    if !input.peek(syn::token::Bracket) {
        return Ok(false);
    }
    let content;
    bracketed!(content in input);

    let marker: Ident = content.parse()?;
    // Reject anything after the single marker ident (`[temporal foo]`,
    // `[temporal, bar]`) — otherwise `bracketed!` would silently drop it.
    if !content.is_empty() {
        let rest: TokenStream2 = content.parse()?;
        return Err(syn::Error::new_spanned(
            rest,
            "expected a single marker identifier, e.g. `[temporal]`",
        ));
    }

    let name = marker.to_string();
    if !SUPPORTED_MARKERS.contains(&name.as_str()) {
        let supported = SUPPORTED_MARKERS
            .iter()
            .map(|m| format!("`{m}`"))
            .collect::<Vec<_>>()
            .join(", ");
        return Err(syn::Error::new(
            marker.span(),
            format!("unknown scalar marker `{name}`; supported markers: {supported}"),
        ));
    }

    // Only `temporal` flips the temporal flag; a future non-temporal marker
    // would pass validation above but leave this `false`.
    Ok(name == "temporal")
}

impl Parse for ScalarEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let token: Ident = input.parse()?;
        input.parse::<Token![=>]>()?;
        let rust_type: Type = input.parse()?;
        let temporal = parse_optional_marker(input)?;
        Ok(ScalarEntry {
            token,
            rust_type,
            temporal,
        })
    }
}

impl ScalarEntry {
    /// Whether this entry is a **temporal** (chrono-backed) scalar rather than a
    /// fixed-width integer, as declared by the `[temporal]` marker. It drives
    /// two divergences:
    ///
    /// 1. The `impl ScalarType` for a temporal scalar is **hand-written** in
    ///    `scalar_domains.rs` (chrono values can't be a `const` slice and the
    ///    pivots are explicit sentinels), so `emit_scalar_type_impls` skips it.
    /// 2. The integer-only fixture asserts (`<T>::MIN`, `contains(&0)`,
    ///    `any(|v| v < 0)`) don't typecheck for a date, so `scalar_fixture!`
    ///    stamps a temporal (pivot-presence) variant instead.
    fn is_temporal(&self) -> bool {
        self.temporal
    }
}

/// The comma-separated list (optional trailing comma).
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

/// `int4` -> `INT4_VALUES`, the catalog value const in `eql_scalars`.
fn values_const_ident(token: &Ident) -> Ident {
    format_ident!("{}_VALUES", token.to_string().to_uppercase())
}

// ---------------------------------------------------------------------------
// Core token generators (pure, unit-testable).
// ---------------------------------------------------------------------------

/// Emit one `impl ScalarType for <rust_type>` per entry. See
/// [`emit_scalar_type_impls`].
fn scalar_type_impls_tokens(list: &ScalarList) -> TokenStream2 {
    // Temporal scalars hand-write their `impl ScalarType` (see `is_temporal`);
    // only integer scalars get a macro-generated impl.
    let impls = list.entries.iter().filter(|e| !e.is_temporal()).map(|e| {
        let token_str = e.token.to_string();
        let rust_type = &e.rust_type;
        let values = values_const_ident(&e.token);
        quote! {
            impl ScalarType for #rust_type {
                const PG_TYPE: &'static str = #token_str;

                /// The catalog `eql_scalars::*_VALUES` list — the same values
                /// the fixture generator encrypts, so the oracle can't drift
                /// from the fixture.
                fn fixture_values() -> &'static [#rust_type] {
                    ::eql_scalars::#values
                }

                /// Integer scalars pivot on their inherent `MIN`/`MAX` consts;
                /// the fixture lists include both (`fixtures!(int …; Min, …, Max)`).
                fn min_pivot() -> #rust_type {
                    <#rust_type>::MIN
                }

                fn max_pivot() -> #rust_type {
                    <#rust_type>::MAX
                }
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
        let mod_ident = format_ident!("eql_v2_{}", e.token);
        let fixture_name = format!("eql_v2_{}", token_str);
        if e.is_temporal() {
            // Temporal scalars have no `eql_scalars::<T>_VALUES` const (chrono
            // is not `const`-friendly). The values come from the harness
            // accessor (`<token>_values()`), and the fixture stamps the
            // `temporal` kind so the integer-only signed-extreme asserts are
            // replaced by a pivot-presence assert. The accessor name mirrors
            // the token (`date` -> `date_values`).
            let values_fn = format_ident!("{}_values", e.token);
            quote! {
                #[doc = concat!("`eql_v2_", #token_str, "` temporal scalar fixture — generated by `scalar_types!`.")]
                pub mod #mod_ident {
                    use crate::scalar_domains::#values_fn as values;
                    crate::scalar_fixture!(temporal, #fixture_name, #rust_type, values());
                }
            }
        } else {
            let values = values_const_ident(&e.token);
            quote! {
                #[doc = concat!("`eql_v2_", #token_str, "` scalar fixture — generated by `scalar_types!`.")]
                pub mod #mod_ident {
                    use ::eql_scalars::#values as VALUES;
                    // `scalar_fixture!` is `#[macro_export]`ed by `eql-tests`;
                    // these modules expand into that lib, so `crate::` resolves it.
                    crate::scalar_fixture!(int, #fixture_name, #rust_type, VALUES);
                }
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
        /// Map a catalog token to its fixture generator and run it. A token in
        /// the catalog but absent from the harness list hits the catch-all and
        /// fails loudly, so a new scalar type can't silently skip generation.
        async fn generate_for_token(token: &str) -> anyhow::Result<()> {
            match token {
                #(#arms)*
                other => anyhow::bail!(
                    "no fixture generator wired for catalog token '{other}'. \
                     Add it to the scalar_types! list (tests/sqlx/src/scalar_types.rs). \
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
            #[doc = concat!("`eql_v2_", #token_str, "` matrix suite — generated by `scalar_types!`.")]
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
/// Invoked via `scalar_types!` in `tests/sqlx/src/scalar_domains.rs`, so the
/// impls land in the `eql-tests` lib next to the trait. `PG_TYPE` is the token
/// string; `FIXTURE_VALUES` is the catalog const `eql_scalars::<TOKEN>_VALUES`.
#[proc_macro]
pub fn emit_scalar_type_impls(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    scalar_type_impls_tokens(&list).into()
}

/// Emit one `pub mod eql_v2_<token> { ... }` per entry.
///
/// Invoked via `scalar_types!` in `tests/sqlx/src/fixtures/mod.rs`, so the
/// modules land at `crate::fixtures::eql_v2_<token>` — the path the matrix and
/// fixture dispatch reference. Each body is a `use` of the catalog value const
/// plus a `scalar_fixture!` invocation.
#[proc_macro]
pub fn emit_scalar_fixture_modules(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    scalar_fixture_modules_tokens(&list).into()
}

/// Emit the `generate_for_token` dispatch fn.
///
/// Invoked via `scalar_types!` in `tests/generate_all_fixtures.rs`. Emits an
/// `async fn generate_for_token(token: &str)` with one match arm per entry plus
/// a loud catch-all, so a catalog token missing from the harness list fails the
/// generator loudly. (The matrix-inventory cross-check enforces the same at
/// test time.)
#[proc_macro]
pub fn emit_fixture_dispatch(input: TokenStream) -> TokenStream {
    let list = syn::parse_macro_input!(input as ScalarList);
    fixture_dispatch_tokens(&list).into()
}

/// Emit one `pub mod <token> { ordered_numeric_matrix! { ... } }` per entry.
///
/// Invoked via `scalar_types!` in
/// `tests/sqlx/tests/encrypted_domain/scalars/mod.rs`, so the matrix suites land
/// in the `encrypted_domain` integration-test binary where `#[sqlx::test]`
/// suites belong. Separate from the lib-side macros because that binary is a
/// different crate target. The emitted test names (`scalars::<token>::matrix_*`)
/// match the old per-type files, so the `matrix_tests.txt` snapshot still holds.
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

    /// Normalize to the `to_string()` form so whitespace differences don't make
    /// assertions brittle.
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
        // const→fn: fixture values is a method now, plus the integer pivots.
        assert!(out.contains("fn fixture_values"));
        // Assert the emitted pivot bodies, not bare `MIN`/`MAX` substrings:
        // the latter also appear in the doc comment, so a loose check would
        // pass even if the bodies stopped returning the inherent bounds.
        assert!(out.contains("fn min_pivot () -> i32 { < i32 > :: MIN }"));
        assert!(out.contains("fn max_pivot () -> i32 { < i32 > :: MAX }"));
        assert!(out.contains("fn min_pivot () -> i64 { < i64 > :: MIN }"));
        assert!(out.contains("fn max_pivot () -> i64 { < i64 > :: MAX }"));
    }

    #[test]
    fn fixture_modules_emit_named_mods_with_scalar_fixture() {
        let out = norm(&scalar_fixture_modules_tokens(&sample()));
        assert!(out.contains("pub mod eql_v2_int4"));
        assert!(out.contains("pub mod eql_v2_int8"));
        assert!(out.contains("crate :: scalar_fixture !"));
        assert!(out.contains(r#""eql_v2_int4""#));
        assert!(out.contains(":: eql_scalars :: INT4_VALUES as VALUES"));
        // Integer entries stamp the `int` kind discriminator.
        assert!(out.contains("int ,"));
    }

    #[test]
    fn temporal_entry_skips_impl_and_stamps_temporal_fixture() {
        let list =
            syn::parse_str::<ScalarList>("int4 => i32, date => chrono::NaiveDate [temporal],")
                .unwrap();
        // Impl emitter skips the temporal entry (hand-written impl).
        let impls = norm(&scalar_type_impls_tokens(&list));
        assert!(impls.contains("impl ScalarType for i32"));
        assert!(!impls.contains("NaiveDate"));
        // Fixture-module emitter stamps the temporal kind + harness accessor.
        let mods = norm(&scalar_fixture_modules_tokens(&list));
        assert!(mods.contains("pub mod eql_v2_date"));
        assert!(mods.contains("temporal ,"));
        assert!(mods.contains("date_values"));
        // Matrix + dispatch emitters include the temporal entry like any other.
        let suites = norm(&scalar_matrix_suites_tokens(&list));
        assert!(suites.contains("pub mod date"));
        assert!(suites.contains("scalar = chrono :: NaiveDate"));
        let dispatch = norm(&fixture_dispatch_tokens(&list));
        assert!(dispatch.contains(r#""date" =>"#));
    }

    /// Parse a single entry, asserting it parses, and return whether it is
    /// temporal. Keeps the per-shape assertions below to one line each.
    fn parse_entry_is_temporal(src: &str) -> bool {
        syn::parse_str::<ScalarEntry>(src)
            .unwrap_or_else(|e| panic!("`{src}` should parse: {e}"))
            .is_temporal()
    }

    /// Parse a single entry expecting a parse error, returning the message.
    fn parse_entry_err(src: &str) -> String {
        match syn::parse_str::<ScalarEntry>(src) {
            Ok(_) => panic!("`{src}` should have failed to parse"),
            Err(e) => e.to_string(),
        }
    }

    #[test]
    fn no_marker_is_integer() {
        // No brackets → integer, even when the type path mentions chrono:
        // temporal-ness is declared, never inferred from the rust type.
        assert!(!parse_entry_is_temporal("int4 => i32"));
        assert!(!parse_entry_is_temporal("date => chrono::NaiveDate"));
    }

    #[test]
    fn temporal_marker_sets_the_flag() {
        assert!(parse_entry_is_temporal(
            "date => chrono::NaiveDate [temporal]"
        ));
        // Marker binds to its own entry, not the next one, across a list.
        let list =
            syn::parse_str::<ScalarList>("date => chrono::NaiveDate [temporal], int4 => i32,")
                .unwrap();
        assert!(list.entries[0].is_temporal());
        assert!(!list.entries[1].is_temporal());
    }

    #[test]
    fn unknown_marker_errors_and_lists_the_supported_set() {
        let msg = parse_entry_err("date => chrono::NaiveDate [temporial]");
        // Names the offending marker and the supported set, so the message is
        // actionable rather than just "parse error".
        assert!(msg.contains("unknown scalar marker"), "got: {msg}");
        assert!(
            msg.contains("temporial"),
            "should name the bad marker: {msg}"
        );
        assert!(
            msg.contains("`temporal`"),
            "should list supported markers: {msg}"
        );
    }

    #[test]
    fn empty_marker_brackets_error() {
        // `[]` has no marker ident to parse — a malformed entry, not a no-op.
        let msg = parse_entry_err("date => chrono::NaiveDate []");
        assert!(!msg.is_empty());
    }

    #[test]
    fn trailing_junk_in_marker_brackets_errors() {
        // Regression guard: `[temporal foo]` / `[temporal, bar]` must NOT be
        // silently accepted as `temporal` with the extra tokens dropped.
        let msg = parse_entry_err("date => chrono::NaiveDate [temporal foo]");
        assert!(msg.contains("single marker identifier"), "got: {msg}");
        let msg = parse_entry_err("date => chrono::NaiveDate [temporal, bar]");
        assert!(msg.contains("single marker identifier"), "got: {msg}");
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
        // suite/scalar/eql_type must match the old per-type files so test names
        // (and the snapshot) are unchanged.
        assert!(out.contains("suite = int4"));
        assert!(out.contains("scalar = i32"));
        assert!(out.contains(r#"eql_type = "eql_v2_int4""#));
        assert!(out.contains("suite = int8"));
        assert!(out.contains("scalar = i64"));
        assert!(out.contains(r#"eql_type = "eql_v2_int8""#));
    }
}
