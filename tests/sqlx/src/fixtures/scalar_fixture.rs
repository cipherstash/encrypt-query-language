//! `scalar_fixture!` — collapse a scalar fixture wrapper to one invocation.
//!
//! Every `eql_v2_<T>` scalar fixture file (`eql_v2_int2`, `eql_v2_int4`, …) is
//! the same three items differing only in the fixture name, the Rust plaintext
//! type, and the generated value list: the `spec()` builder, the `fixture-gen`
//! generator test, and a small property-test module. This macro stamps all
//! three out, so a new scalar fixture is one `use` of the value const plus one
//! `scalar_fixture!(…)`.
//!
//! The per-file `//!` module docs still belong in each fixture file — they
//! describe *that* type's value choices and are not boilerplate.

/// Stamp out the `spec()` builder, the `fixture-gen` generator test, and the
/// property-test module for a scalar fixture.
///
/// - `$name` — the fixture name (`"eql_v2_int2"`), drives every derived path.
/// - `$ty` — the Rust plaintext type (`i16`); `<$ty>::MIN`/`MAX` supply the
///   signed-extreme assertions.
/// - `$values` — the generated value const (`int2_values::VALUES`).
///
/// Indexes are fixed to `Unique` (HMAC, drives `=` / `<>`) and `Ore` (ORE
/// block terms, drives `<` `<=` `>` `>=`) with a committed `jsonb` payload —
/// the shape shared by every ordered scalar domain.
#[macro_export]
macro_rules! scalar_fixture {
    ($name:literal, $ty:ty, $values:expr $(,)?) => {
        /// The complete fixture definition. `IndexKind::Unique` drives `=` /
        /// `<>` (HMAC); `IndexKind::Ore` drives `<` `<=` `>` `>=` (ORE block
        /// terms).
        pub fn spec() -> $crate::fixtures::FixtureSpec<'static, $ty> {
            $crate::fixtures::FixtureSpec::new($name)
                .with_index($crate::fixtures::IndexKind::Unique)
                .with_index($crate::fixtures::IndexKind::Ore)
                .with_column_type("jsonb")
                .with_values($values)
        }

        /// The generator. Gated by `fixture-gen` so `cargo test` never compiles
        /// it; `#[ignore]` is a second guard. Run via
        /// `mise run fixture:generate`.
        #[cfg(feature = "fixture-gen")]
        #[tokio::test]
        #[ignore = "generator — run via `mise run fixture:generate`"]
        async fn generate() -> anyhow::Result<()> {
            spec().run().await
        }

        #[cfg(test)]
        mod tests {
            use super::*;

            #[test]
            fn spec_is_complete() {
                assert!(spec().check_complete().is_ok());
            }

            #[test]
            fn spec_includes_signed_extremes() {
                // MIN / MAX exercise ORE block-encoding sign-bit edges that a
                // smaller list would not cover.
                let spec = spec();
                let values = spec.values();
                assert!(
                    values.contains(&<$ty>::MIN),
                    "spec must include {}::MIN",
                    stringify!($ty)
                );
                assert!(
                    values.contains(&<$ty>::MAX),
                    "spec must include {}::MAX",
                    stringify!($ty)
                );
                assert!(values.contains(&0), "spec must include 0");
            }

            #[test]
            fn spec_includes_negative_values() {
                assert!(spec().values().iter().any(|&v| v < 0));
            }
        }
    };
}
