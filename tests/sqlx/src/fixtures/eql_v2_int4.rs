//! The `eql_v2_int4` fixture — the framework's reference example and proof.
//!
//! 14 integers spanning a negative boundary and small/medium/large/extreme
//! magnitudes. The generated `tests/sqlx/fixtures/eql_v2_int4.sql` is a plain
//! `jsonb`-payload table with no EQL dependency; #225 layers the `eql_v2_int4`
//! domain on top by casting `payload` per query.

use super::spec::FixtureSpec;

/// 14 values: a negative boundary plus small/medium/large/extreme magnitudes,
/// chosen so range pivots produce distinct cardinalities.
const VALUES: &[i32] = &[-100, -1, 1, 2, 5, 10, 17, 25, 42, 50, 100, 250, 1000, 9999];

/// The complete fixture definition. `.with_index("unique")` drives `=` / `<>`
/// (HMAC); `.with_index("ore")` drives `<` `<=` `>` `>=` (ORE block terms).
pub fn spec() -> FixtureSpec<'static, i32> {
    FixtureSpec::new("eql_v2_int4")
        .with_index("unique")
        .with_index("ore")
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
    fn spec_has_14_values() {
        assert_eq!(spec().values().len(), 14);
    }

    #[test]
    fn spec_includes_negative_values() {
        assert!(spec().values().iter().any(|&v| v < 0));
    }
}
