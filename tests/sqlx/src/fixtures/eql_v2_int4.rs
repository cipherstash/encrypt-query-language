//! The `eql_v2_int4` fixture — the framework's reference example and proof.
//!
//! 17 integers spanning a negative boundary, the i32 signed extremes
//! (`MIN`/`MAX`), zero, and small/medium/large magnitudes. The generated
//! `tests/sqlx/fixtures/eql_v2_int4.sql` is a plain `jsonb`-payload table with
//! no EQL dependency; #225 layers the `eql_v2_int4` domain on top by casting
//! `payload` per query.

use super::index_kind::IndexKind;
use super::int4_values::VALUES;
use super::spec::FixtureSpec;

/// The complete fixture definition. `IndexKind::Unique` drives `=` / `<>`
/// (HMAC); `IndexKind::Ore` drives `<` `<=` `>` `>=` (ORE block terms).
pub fn spec() -> FixtureSpec<'static, i32> {
    FixtureSpec::new("eql_v2_int4")
        .with_index(IndexKind::Unique)
        .with_index(IndexKind::Ore)
        .with_column_type("jsonb")
        .with_values(VALUES)
}

/// The generator. Gated by `fixture-gen` so `cargo test` never compiles it;
/// `#[ignore]` is a second guard. Run via `mise run fixture:generate eql_v2_int4`.
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
        // i32::MIN / MAX exercise ORE block-encoding sign-bit edges
        // that the smaller earlier list did not cover.
        let spec = spec();
        let values = spec.values();
        assert!(values.contains(&i32::MIN), "spec must include i32::MIN");
        assert!(values.contains(&i32::MAX), "spec must include i32::MAX");
        assert!(values.contains(&0), "spec must include 0");
    }

    #[test]
    fn spec_includes_negative_values() {
        assert!(spec().values().iter().any(|&v| v < 0));
    }
}
