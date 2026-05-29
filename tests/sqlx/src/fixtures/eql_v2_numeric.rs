//! The `eql_v2_numeric` fixture — the ordered `numeric` scalar.
//!
//! 14 decimals spanning the `Decimal` signed extremes (`MIN`/`MAX`), zero,
//! negatives, fractional/high-scale values, and ordinary magnitudes. The
//! generated `tests/sqlx/fixtures/eql_v2_numeric.sql` is a plain
//! `jsonb`-payload table with no EQL dependency; the `eql_v2_numeric` domain
//! layers on top by casting `payload` per query, exactly as `eql_v2_int4`
//! does.

use rust_decimal::Decimal;

use super::index_kind::IndexKind;
use super::spec::FixtureSpec;

/// 14 values: the `Decimal` signed extremes (`MIN`, `MAX`), zero, negatives,
/// fractional/high-scale values, and ordinary magnitudes. Must stay in
/// agreement with `Decimal::FIXTURE_VALUES` in `scalar_domains.rs` — the
/// matrix derives its comparison pivots (`MIN`, `MAX`, zero) from the type
/// and fetches each pivot's ciphertext from this fixture, so the rows must
/// be present. `Decimal::from_parts(lo, mid, hi, negative, scale)` is a
/// `const fn`, so fractional values are buildable in this `const` array
/// without `rust_decimal_macros`. Every value is distinct under
/// `Decimal::cmp`, giving range pivots and ordering tests meaningful,
/// non-colliding boundary coverage.
const VALUES: &[Decimal] = &[
    Decimal::MIN,                                // signed extreme (negative)
    Decimal::from_parts(100, 0, 0, true, 0),     // -100
    Decimal::NEGATIVE_ONE,                       // -1
    Decimal::from_parts(5, 0, 0, true, 1),       // -0.5  (negative fractional)
    Decimal::ZERO,                               // 0     (= Default; pivot)
    Decimal::from_parts(1, 0, 0, false, 3),      // 0.001 (small, high scale)
    Decimal::ONE,                                // 1
    Decimal::from_parts(15, 0, 0, false, 1),     // 1.5  (fractional)
    Decimal::TWO,                                // 2
    Decimal::from_parts(314159, 0, 0, false, 5), // 3.14159 (high scale)
    Decimal::TEN,                                // 10
    Decimal::ONE_HUNDRED,                        // 100
    Decimal::ONE_THOUSAND,                       // 1000
    Decimal::MAX,                                // signed extreme (positive)
];

/// The complete fixture definition. `IndexKind::Unique` drives `=` / `<>`
/// (HMAC); `IndexKind::Ore` drives `<` `<=` `>` `>=` (ORE block terms).
pub fn spec() -> FixtureSpec<'static, Decimal> {
    FixtureSpec::new("eql_v2_numeric")
        .with_index(IndexKind::Unique)
        .with_index(IndexKind::Ore)
        .with_column_type("jsonb")
        .with_values(VALUES)
}

/// The generator. Gated by `fixture-gen` so `cargo test` never compiles it;
/// `#[ignore]` is a second guard. Run via `mise run fixture:generate eql_v2_numeric`.
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
    fn spec_values_match_the_constant() {
        // Derived from the constant so adding fixture rows doesn't
        // silently break this assertion.
        assert_eq!(spec().values().len(), VALUES.len());
    }

    #[test]
    fn spec_includes_signed_extremes() {
        // Decimal::MIN / MAX exercise ORE block-encoding sign-bit edges at
        // the full Decimal range; zero is a required comparison pivot.
        let spec = spec();
        let values = spec.values();
        assert!(
            values.contains(&Decimal::MIN),
            "spec must include Decimal::MIN"
        );
        assert!(
            values.contains(&Decimal::MAX),
            "spec must include Decimal::MAX"
        );
        assert!(values.contains(&Decimal::ZERO), "spec must include 0");
    }

    #[test]
    fn spec_includes_negative_values() {
        assert!(spec().values().iter().any(|v| v.is_sign_negative()));
    }

    #[test]
    fn spec_includes_a_fractional_value() {
        // High-scale coverage: at least one value with a non-zero scale.
        assert!(spec().values().iter().any(|v| v.scale() > 0));
    }
}
