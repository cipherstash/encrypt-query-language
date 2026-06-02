//! Catalog-driven "generate every encrypted fixture" entry point.
//!
//! Replaces the Python-era `fixture:generate <name>` per-type scripts and the
//! `fixture:generate:all` TOML-glob loop (which spawned a separate `cargo test`
//! per type). This runs ALL scalar fixture generators in ONE process, iterating
//! `eql_scalars::CATALOG` for the authoritative token set.
//!
//! The encrypted-fixture logic itself is unchanged — each type's
//! `fixtures::eql_v2_<T>::spec().run()` still produces
//! `tests/sqlx/fixtures/eql_v2_<T>.sql` exactly as before.
//!
//! Gated behind `fixture-gen` (needs a live Postgres + CS_* creds). Run via:
//!   mise run fixture:generate:all
#![cfg(feature = "fixture-gen")]

use eql_scalars::CATALOG;
use eql_tests::fixtures;

/// Map a catalog token to its fixture generator and run it. A token present in
/// the catalog but missing here is a wiring gap — fail loudly so a new scalar
/// type cannot silently skip fixture generation.
async fn generate_for_token(token: &str) -> anyhow::Result<()> {
    match token {
        "int2" => fixtures::eql_v2_int2::spec().run().await,
        "int4" => fixtures::eql_v2_int4::spec().run().await,
        other => anyhow::bail!(
            "no fixture generator wired for catalog token '{other}'. \
             Add an arm to generate_for_token in tests/sqlx/tests/generate_all_fixtures.rs \
             (and the eql_v2_{other} fixture module). See the encrypted-domain spec §9."
        ),
    }
}

#[tokio::test]
#[ignore = "generator — run via `mise run fixture:generate:all`"]
async fn generate_all() -> anyhow::Result<()> {
    let mut generated = 0usize;
    for spec in CATALOG {
        eprintln!("Generating fixture eql_v2_{}...", spec.token);
        generate_for_token(spec.token).await?;
        generated += 1;
    }
    assert!(generated > 0, "CATALOG is empty — nothing to generate");
    eprintln!("Regenerated {generated} scalar fixture(s).");
    Ok(())
}
