//! Cross-name routing property: for every equal-plaintext / distinct-ciphertext
//! pair, an int4-typed value and an integer-typed value compare EQUAL under the
//! generated cross-name `=` (hmac routing), and a distinct-plaintext pair
//! compares NOT equal — proving cross-name `=` never binds native jsonb (which
//! would compare the raw ciphertext `c` and get equality wrong). Reuses the
//! `eql_v3_integer_doubles` oracle rows from `cross_ciphertext.rs`.
//!
//! Lives under `encrypted_domain::property`, NOT `scalars::`, so it does not feed
//! the pinned matrix-inventory baseline (see property/mod.rs).

use super::fixture_oracle::load_doubles_rows;
use anyhow::Result;
use sqlx::PgPool;

/// Assert cross-name `=` / `<>` between two DIFFERENT-named encrypted domains
/// (`a_domain` / `b_domain`) agrees with the plaintext oracle for one pair: `=`
/// is `expect_eq`, `<>` is its negation. The operands cast raw jsonb payloads
/// into the two domains, so the operator resolved is the generated cross-name
/// one — never native jsonb.
async fn assert_cross_name_pair(
    pool: &PgPool,
    a_domain: &str,
    b_domain: &str,
    a_payload: &str,
    b_payload: &str,
    expect_eq: bool,
) -> Result<()> {
    let a_cast = format!("'{}'::jsonb::{a_domain}", a_payload.replace('\'', "''"));
    let b_cast = format!("'{}'::jsonb::{b_domain}", b_payload.replace('\'', "''"));
    let sql = format!("SELECT ({a_cast}) = ({b_cast}), ({a_cast}) <> ({b_cast})");
    let (eq, neq): (Option<bool>, Option<bool>) = sqlx::query_as(&sql).fetch_one(pool).await?;
    anyhow::ensure!(
        eq == Some(expect_eq),
        "cross-name `=` {a_domain} vs {b_domain}: expected {expect_eq}, got {eq:?}"
    );
    anyhow::ensure!(
        neq == Some(!expect_eq),
        "cross-name `<>` {a_domain} vs {b_domain}: expected {}, got {neq:?}",
        !expect_eq
    );
    Ok(())
}

/// Over every (i, j) pair of `eql_v3_integer_doubles` rows, cross-name `=` between
/// `public.int4_eq` and `public.integer_eq` must agree with the plaintext oracle,
/// in BOTH operand directions (int4->integer and integer->int4). The full i×j
/// grid covers equal-plaintext/distinct-ciphertext pairs (the silent-jsonb guard)
/// as well as distinct-plaintext pairs (must be NOT equal).
#[sqlx::test]
async fn cross_name_equality_routes_hmac_over_all_doubles_pairs(pool: PgPool) -> Result<()> {
    let rows = load_doubles_rows::<i32>(&pool).await?;
    anyhow::ensure!(
        rows.len() >= 2,
        "doubles fixture must carry at least two rows; regenerate via mise run test:sqlx:prep"
    );
    for i in 0..rows.len() {
        for j in 0..rows.len() {
            let expect_eq = rows[i].plaintext == rows[j].plaintext;
            // int4 (A) vs integer (B) — the cross-name operator, one direction.
            assert_cross_name_pair(
                &pool,
                "public.int4_eq",
                "public.integer_eq",
                &rows[i].payload_json,
                &rows[j].payload_json,
                expect_eq,
            )
            .await?;
            // integer (A) vs int4 (B) — the other operand direction (a distinct
            // CREATE OPERATOR / backing wrapper).
            assert_cross_name_pair(
                &pool,
                "public.integer_eq",
                "public.int4_eq",
                &rows[i].payload_json,
                &rows[j].payload_json,
                expect_eq,
            )
            .await?;
        }
    }
    Ok(())
}
