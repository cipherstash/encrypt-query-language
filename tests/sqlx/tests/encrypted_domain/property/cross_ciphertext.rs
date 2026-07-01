//! fixture-suite (CIP-3141) cross-ciphertext equality test.
//!
//! Proves "two independent encryptions of one value compare equal" using the
//! generated `fixtures.eql_v3_<T>_doubles` tables — each plaintext encrypted
//! twice, so the table carries equal-plaintext / distinct-ciphertext rows. No
//! fresh encryption, no creds: it reads the already-encrypted doubles, so it
//! runs in the credential-free `mise run test:sqlx` path. Distinct from the
//! matrix (which reads the curated `fixtures.eql_v3_<T>`) and from the e2e suite
//! (which re-encrypts fresh duplicates each run).
//!
//! Each type asserts, on its doubles rows:
//!  1. a distinct-ciphertext pair exists (an equal-plaintext pair whose
//!     `payload_json` differs) — so the equality assertions below are non-trivial;
//!  2. `=` TRUE / `<>` FALSE across every pair through the `_eq` (hm/HMAC) domain
//!     (`assert_eq_oracle`);
//!  3. the ordering operators agree with the plaintext oracle on both ordered
//!     twins (`assert_ord_oracle`), PLUS `=` TRUE / `<>` FALSE on an equal pair
//!     through `_ord` and `_ord_ore` — the ORE (`ob`) equality path, which routes
//!     `=` through `compare_ore_block_256_terms(...) = 0` (GUARANTEED equal for
//!     two independent encryptions of one value; see the ORE finding in the plan).
//!
//! `#[sqlx::test]` per type (its own migrated scratch DB), like the rest of the
//! fixture suite.

use super::fixture_oracle::load_doubles_rows;
use anyhow::Result;
use eql_tests::property::{assert_eq_oracle, assert_ord_oracle, Row};
use eql_tests::scalar_domains::{ScalarDomainSpec, ScalarType, Variant};
use sqlx::PgPool;

/// Find two rows with equal plaintext but DIFFERENT ciphertext, or fail. The
/// doubles fixture encrypts each plaintext independently, so an equal-plaintext
/// pair is expected to differ in ciphertext; a failure here means the fixture
/// was not regenerated.
fn first_distinct_ciphertext_pair<T: ScalarType>(rows: &[Row<T>]) -> Result<(&Row<T>, &Row<T>)> {
    for i in 0..rows.len() {
        for j in (i + 1)..rows.len() {
            if rows[i].plaintext == rows[j].plaintext
                && rows[i].payload_json != rows[j].payload_json
            {
                return Ok((&rows[i], &rows[j]));
            }
        }
    }
    anyhow::bail!(
        "doubles fixture for {} has no equal-plaintext/distinct-ciphertext pair; \
         regenerate via mise run test:sqlx:prep",
        T::PG_TYPE
    )
}

/// Assert `=` TRUE / `<>` FALSE for one equal-plaintext distinct-ciphertext pair
/// on `variant`'s domain. Used for the ORE path (`Ord` / `OrdOre`), which routes
/// `=` through `compare_ore_block_256_terms(...) = 0` — the assertion the
/// plaintext ordering oracle does not itself make on the ordered twins.
async fn assert_pair_eq_on<T: ScalarType>(
    pool: &PgPool,
    variant: Variant,
    a: &Row<T>,
    b: &Row<T>,
) -> Result<()> {
    let domain = ScalarDomainSpec::new::<T>(variant).sql_domain;
    // `'<json>'::jsonb::<domain>` for each side; escape single quotes the same
    // way property.rs's `cast` does.
    let a_cast = format!("'{}'::jsonb::{domain}", a.payload_json.replace('\'', "''"));
    let b_cast = format!("'{}'::jsonb::{domain}", b.payload_json.replace('\'', "''"));
    let sql = format!("SELECT ({a_cast}) = ({b_cast}), ({a_cast}) <> ({b_cast})");
    let (eq, neq): (Option<bool>, Option<bool>) = sqlx::query_as(&sql).fetch_one(pool).await?;
    anyhow::ensure!(
        eq == Some(true),
        "cross-ciphertext `=` on {domain} must be TRUE for equal plaintext, got {eq:?}"
    );
    anyhow::ensure!(
        neq == Some(false),
        "cross-ciphertext `<>` on {domain} must be FALSE for equal plaintext, got {neq:?}"
    );
    Ok(())
}

/// The full cross-ciphertext check for an ordered scalar `T`.
async fn assert_cross_ciphertext<T: ScalarType>(pool: &PgPool) -> Result<()> {
    let rows = load_doubles_rows::<T>(pool).await?;

    // (1) the doubles really are distinct ciphertext.
    let (a, b) = first_distinct_ciphertext_pair::<T>(&rows)?;

    // (2) hm/HMAC equality path across all pairs.
    assert_eq_oracle::<T>(pool, &rows).await?;

    // (3) ordering oracle on both ordered twins, plus the explicit ORE-path
    //     equality on the distinct-ciphertext pair.
    assert_ord_oracle::<T>(pool, Variant::Ord, &rows).await?;
    assert_ord_oracle::<T>(pool, Variant::OrdOre, &rows).await?;
    assert_pair_eq_on::<T>(pool, Variant::Ord, a, b).await?;
    assert_pair_eq_on::<T>(pool, Variant::OrdOre, a, b).await?;
    Ok(())
}

macro_rules! cross_ciphertext_test {
    ($name:ident, $ty:ty) => {
        #[sqlx::test]
        async fn $name(pool: PgPool) -> Result<()> {
            assert_cross_ciphertext::<$ty>(&pool).await
        }
    };
}

cross_ciphertext_test!(cross_ciphertext_int2, i16);
cross_ciphertext_test!(cross_ciphertext_int4, i32);
cross_ciphertext_test!(cross_ciphertext_int8, i64);
cross_ciphertext_test!(cross_ciphertext_date, chrono::NaiveDate);
cross_ciphertext_test!(cross_ciphertext_timestamp, chrono::DateTime<chrono::Utc>);
cross_ciphertext_test!(cross_ciphertext_numeric, rust_decimal::Decimal);
cross_ciphertext_test!(cross_ciphertext_text, String);
