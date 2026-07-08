//! Comprehensive cross-name routing matrix: for EVERY aliased scalar family, an
//! alias-typed value and its canonical twin compare correctly through the
//! generated cross-name operators — equality routes HMAC, ordering routes ORE /
//! OPE — and NEVER silently degrade to native jsonb (which compares raw
//! ciphertext and would get equality/ordering wrong).
//!
//! Driven by real encrypted `fixtures.eql_v3_<T>_doubles` rows (each plaintext
//! encrypted twice → equal-plaintext / distinct-ciphertext pairs), the same
//! oracle source as `cross_ciphertext.rs`. For each family it exercises, over
//! all row pairs and in BOTH operand directions:
//!   - `_eq` cross-name `=` / `<>` (HMAC path — the silent-jsonb equality guard),
//!   - `_ord` / `_ord_ore` / `_ord_ope` cross-name `<` `<=` `>` `>=` (ORE / OPE
//!     ordering path — the silent-jsonb ordering guard).
//!
//! The alias name for each family is read from `eql_domains::CATALOG`, so a new
//! alias is picked up automatically. Lives under `encrypted_domain::property`,
//! NOT `scalars::`, so it stays out of the pinned matrix-inventory baseline.

use super::fixture_oracle::load_doubles_rows;
use anyhow::{Context, Result};
use eql_domains::CATALOG;
use eql_tests::scalar_domains::{ScalarType, F4, F8};
use sqlx::PgPool;

/// `'<json>'::jsonb::<domain>` — cast a payload literal into an encrypted domain.
fn cast(json: &str, domain: &str) -> String {
    format!("'{}'::jsonb::{}", json.replace('\'', "''"), domain)
}

/// Schema-qualified domain name, e.g. `dom("int4", "_eq") == "public.int4_eq"`.
fn dom(name: &str, suffix: &str) -> String {
    format!("public.{name}{suffix}")
}

/// Cross-name equality oracle: side A cast to `a_domain`, side B to `b_domain`
/// (two DIFFERENT-named encrypted domains). Over every ordered row pair,
/// `=` / `<>` must agree with the plaintext oracle — proving the comparison
/// binds the generated cross-name HMAC wrapper, not native jsonb.
async fn assert_cross_eq<T: ScalarType>(
    pool: &PgPool,
    rows: &[eql_tests::property::Row<T>],
    a_domain: &str,
    b_domain: &str,
) -> Result<()> {
    for a in rows {
        for b in rows {
            let want = a.plaintext == b.plaintext;
            let (l, r) = (cast(&a.payload_json, a_domain), cast(&b.payload_json, b_domain));
            let sql = format!("SELECT ({l}) = ({r}), ({l}) <> ({r})");
            let (eq, neq): (Option<bool>, Option<bool>) = sqlx::query_as(&sql)
                .fetch_one(pool)
                .await
                .with_context(|| format!("cross-eq query: {sql}"))?;
            anyhow::ensure!(
                eq == Some(want),
                "cross `=` {a_domain} vs {b_domain}: {:?}=={:?} is {want}, got {eq:?}",
                a.plaintext,
                b.plaintext
            );
            anyhow::ensure!(
                neq == Some(!want),
                "cross `<>` {a_domain} vs {b_domain}: {:?}!={:?} is {}, got {neq:?}",
                a.plaintext,
                b.plaintext,
                !want
            );
        }
    }
    Ok(())
}

/// Cross-name ordering oracle over `< <= > >=` between two DIFFERENT-named
/// encrypted domains. Over every ordered row pair, each operator must agree with
/// the plaintext comparison — proving the ORE/OPE cross-name wrapper is bound,
/// not native jsonb byte comparison.
async fn assert_cross_ord<T: ScalarType>(
    pool: &PgPool,
    rows: &[eql_tests::property::Row<T>],
    a_domain: &str,
    b_domain: &str,
) -> Result<()> {
    for a in rows {
        for b in rows {
            let (l, r) = (cast(&a.payload_json, a_domain), cast(&b.payload_json, b_domain));
            let sql =
                format!("SELECT ({l}) < ({r}), ({l}) <= ({r}), ({l}) > ({r}), ({l}) >= ({r})");
            let (lt, lte, gt, gte): (Option<bool>, Option<bool>, Option<bool>, Option<bool>) =
                sqlx::query_as(&sql)
                    .fetch_one(pool)
                    .await
                    .with_context(|| format!("cross-ord query: {sql}"))?;
            let (pa, pb) = (&a.plaintext, &b.plaintext);
            anyhow::ensure!(lt == Some(pa < pb), "cross `<` {a_domain} vs {b_domain}: {pa:?}<{pb:?}");
            anyhow::ensure!(
                lte == Some(pa <= pb),
                "cross `<=` {a_domain} vs {b_domain}: {pa:?}<={pb:?}"
            );
            anyhow::ensure!(gt == Some(pa > pb), "cross `>` {a_domain} vs {b_domain}: {pa:?}>{pb:?}");
            anyhow::ensure!(
                gte == Some(pa >= pb),
                "cross `>=` {a_domain} vs {b_domain}: {pa:?}>={pb:?}"
            );
        }
    }
    Ok(())
}

/// The full cross-name matrix for one aliased ordered-scalar family `T`: for
/// every alias `T` declares, and in BOTH operand directions (alias→canonical and
/// canonical→alias), exercise cross-name `=`/`<>` on `_eq` and cross-name
/// `<`/`<=`/`>`/`>=` on `_ord`, `_ord_ore`, and `_ord_ope`.
async fn assert_cross_name_matrix<T: ScalarType>(pool: &PgPool) -> Result<()> {
    let rows = load_doubles_rows::<T>(pool).await?;
    let canonical = T::PG_TYPE;
    let fam = CATALOG
        .iter()
        .find(|f| f.name == canonical)
        .unwrap_or_else(|| panic!("no catalog family for {canonical}"));
    anyhow::ensure!(
        !fam.aliases.is_empty(),
        "{canonical} declares no alias — this test must only run on aliased families"
    );
    // Self-guard (I1): the eq oracle is only meaningful if an equal-plaintext /
    // distinct-ciphertext pair actually exists — otherwise `=` TRUE could never
    // fire and the HMAC-vs-jsonb distinction would be untested.
    anyhow::ensure!(
        rows.iter().enumerate().any(|(i, a)| rows
            .iter()
            .skip(i + 1)
            .any(|b| a.plaintext == b.plaintext && a.payload_json != b.payload_json)),
        "{canonical} doubles fixture lacks an equal-plaintext/distinct-ciphertext pair; \
         regenerate via mise run test:sqlx:prep"
    );

    for &alias in fam.aliases {
        for (left, right) in [(alias, canonical), (canonical, alias)] {
            assert_cross_eq::<T>(pool, &rows, &dom(left, "_eq"), &dom(right, "_eq"))
                .await
                .with_context(|| format!("cross-name eq {left} <-> {right}"))?;
            for suffix in ["_ord", "_ord_ore", "_ord_ope"] {
                assert_cross_ord::<T>(pool, &rows, &dom(left, suffix), &dom(right, suffix))
                    .await
                    .with_context(|| format!("cross-name ord {left}{suffix} <-> {right}{suffix}"))?;
            }
        }
    }
    Ok(())
}

/// One `#[sqlx::test]` per aliased family (its own migrated scratch DB), like the
/// rest of the fixture suite. Every ordered scalar family that declares an alias
/// is covered: smallint/int2, integer/int4, bigint/int8, real/float4,
/// double/float8, numeric/decimal.
macro_rules! cross_name_matrix_test {
    ($name:ident, $ty:ty) => {
        #[sqlx::test]
        async fn $name(pool: PgPool) -> Result<()> {
            assert_cross_name_matrix::<$ty>(&pool).await
        }
    };
}

cross_name_matrix_test!(cross_name_smallint_int2, i16);
cross_name_matrix_test!(cross_name_integer_int4, i32);
cross_name_matrix_test!(cross_name_bigint_int8, i64);
cross_name_matrix_test!(cross_name_real_float4, F4);
cross_name_matrix_test!(cross_name_double_float8, F8);
cross_name_matrix_test!(cross_name_numeric_decimal, rust_decimal::Decimal);
