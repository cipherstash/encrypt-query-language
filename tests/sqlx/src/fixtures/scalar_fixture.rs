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
/// The leading **kind** discriminator (`int` / `temporal`) selects which
/// property asserts are stamped — the rest of the expansion is identical:
///
/// - `int` — signed-extreme asserts (`<$ty>::MIN`/`MAX`, `contains(&0)`,
///   `any(|v| v < 0)`). These typecheck only for integer plaintexts.
/// - `temporal` — a pivot-presence assert (`min_pivot`/`max_pivot`/zero from the
///   `ScalarType` impl all appear in the values). `<$ty>::MIN` / `< 0` don't
///   exist for a `chrono::NaiveDate`, so the integer asserts can't be reused.
///
/// - `$name` — the fixture name (`"eql_v2_int2"`), drives every derived path.
/// - `$ty` — the Rust plaintext type (`i16` / `chrono::NaiveDate`).
/// - `$values` — the value source: the catalog const (`eql_scalars::INT2_VALUES`)
///   for integers, or the harness accessor (`date_values()`) for temporal.
///
/// Indexes are fixed to `Unique` (HMAC, drives `=` / `<>`) and `Ore` (ORE
/// block terms, drives `<` `<=` `>` `>=`) with a committed `jsonb` payload —
/// the shape shared by every ordered scalar domain.
#[macro_export]
macro_rules! scalar_fixture {
    // Integer scalars: signed-extreme property asserts.
    (int, $name:literal, $ty:ty, $values:expr $(,)?) => {
        $crate::scalar_fixture!(@common $name, $ty, $values);

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

    // Temporal scalars: pivot-presence property assert (no signed extremes).
    (temporal, $name:literal, $ty:ty, $values:expr $(,)?) => {
        $crate::scalar_fixture!(@common $name, $ty, $values);

        #[cfg(test)]
        mod tests {
            use super::*;
            use $crate::scalar_domains::ScalarType;

            #[test]
            fn spec_is_complete() {
                assert!(spec().check_complete().is_ok());
            }

            #[test]
            fn spec_includes_pivots() {
                // The three matrix pivots (min/max/zero) must be present in the
                // fixture — `fetch_fixture_payload` fetches each at test time.
                let spec = spec();
                let values = spec.values();
                let min = <$ty as ScalarType>::min_pivot();
                let max = <$ty as ScalarType>::max_pivot();
                let zero: $ty = ::core::default::Default::default();
                assert!(values.contains(&min), "spec must include min_pivot {min:?}");
                assert!(values.contains(&max), "spec must include max_pivot {max:?}");
                assert!(values.contains(&zero), "spec must include zero pivot {zero:?}");
            }
        }
    };

    // Shared expansion: the `spec()` builder + the gated generator test.
    (@common $name:literal, $ty:ty, $values:expr) => {
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
    };
}
