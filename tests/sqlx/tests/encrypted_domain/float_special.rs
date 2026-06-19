//! Float edge-case behavioural regression suite (CIP — float4/float8).
//!
//! Captures the NaN / `-0.0` / `+0.0` / `±Inf` behaviour that the shared
//! all-pairs oracle deliberately excludes from its fixtures (NaN is unordered
//! and unspecified in the encoder; `-0.0` canonicalizes to `+0.0`). It encrypts
//! the special values FRESH through cipherstash at test time, so NaN never
//! enters the `float8` fixture table.
//!
//! IMPORTANT: the NaN eq/order outcomes asserted here are an **artifact of the
//! canonical NaN bit pattern + deterministic index terms (hm/ore are pure
//! functions of plaintext+key)**, NOT a supported guarantee, and they diverge
//! from IEEE (`NaN != NaN`). They are discovered-and-locked on first run.
//!
//! The `-0.0`/`+0.0` equality below pins the `orderable-bytes` ORE path, which
//! canonicalizes `-0.0 -> +0.0` before encoding. A dormant alternative encoder
//! (`cllw-ore`) instead distinguishes them; if float ORE is ever routed through
//! that path this test flips from "equal" to "`-0.0 < +0.0`" — it is the canary,
//! so keep this comment pointing at the orderable-bytes canonicalization.

use anyhow::Result;
use eql_tests::fixtures::cipherstash::{column_config_for, encrypt_store};
use eql_tests::fixtures::eql_plaintext::EqlPlaintext;
use eql_tests::fixtures::index_kind::IndexKind;
use eql_tests::property::{connect_pool, ensure_eql_installed};
use eql_tests::scalar_domains::F8;
use sqlx::PgPool;

/// Encrypt one batch of f64 special values into payload JSON strings, one
/// ZeroKMS round trip. Mirrors `e2e_oracle::encrypt_rows` but returns only the
/// payloads (these tests key on position, not plaintext). `encrypt_store`
/// encrypts through cipherstash-client directly — it needs no `PgPool`.
async fn encrypt_specials(values: &[F8]) -> Result<Vec<String>> {
    let config = column_config_for(
        &[IndexKind::Unique, IndexKind::Ore],
        <F8 as EqlPlaintext>::CAST,
    )?;
    let payloads = encrypt_store("float_special", "payload", values, &config).await?;
    Ok(payloads.into_iter().map(|p| p.to_string()).collect())
}

/// Cast a payload literal to `eql_v3.float8` and read it back, proving the domain
/// CHECK accepts the encrypted special value.
async fn cast_passes_check(pool: &PgPool, payload: &str) -> Result<()> {
    let sql = "SELECT ($1::jsonb::eql_v3.float8) IS NOT NULL";
    let ok: bool = sqlx::query_scalar(sql)
        .bind(payload)
        .fetch_one(pool)
        .await?;
    anyhow::ensure!(ok, "payload failed the eql_v3.float8 CHECK: {payload}");
    Ok(())
}

/// Compare two payloads under an operator on the `_ord` domain, returning the
/// boolean result. Used to pin the discovered NaN/±0/±Inf outcomes.
async fn ord_cmp(pool: &PgPool, a: &str, op: &str, b: &str) -> Result<bool> {
    let d = "eql_v3.float8_ord";
    let sql = format!("SELECT ($1::jsonb::{d} {op} $2::jsonb::{d})");
    Ok(sqlx::query_scalar(&sql)
        .bind(a)
        .bind(b)
        .fetch_one(pool)
        .await?)
}

/// Equality under the `_eq` domain (HMAC).
async fn eq_cmp(pool: &PgPool, a: &str, b: &str) -> Result<bool> {
    let d = "eql_v3.float8_eq";
    let sql = format!("SELECT ($1::jsonb::{d} = $2::jsonb::{d})");
    Ok(sqlx::query_scalar(&sql)
        .bind(a)
        .bind(b)
        .fetch_one(pool)
        .await?)
}

async fn setup() -> Result<PgPool> {
    let pool = connect_pool().await?;
    ensure_eql_installed(&pool, &crate::property::migrator()).await?;
    Ok(pool)
}

#[tokio::test]
async fn nan_encrypts_and_passes_check() -> Result<()> {
    // Encrypting f64::NAN succeeds (no panic) and yields a structurally valid
    // eql_v3.float8 payload. This is the one universal NaN guarantee.
    let pool = setup().await?;
    let payloads = encrypt_specials(&[F8(f64::NAN)]).await?;
    assert_eq!(payloads.len(), 1);
    cast_passes_check(&pool, &payloads[0]).await?;
    Ok(())
}

#[tokio::test]
async fn two_encryptions_of_same_nan_bits_compare_equal() -> Result<()> {
    // ARTIFACT, NOT A GUARANTEE: index terms are deterministic functions of
    // plaintext+key, so two encryptions of the SAME canonical NaN bit pattern
    // produce the same hm/ore terms and compare equal under `=` — diverging from
    // IEEE (NaN != NaN). Locked on first run; if the encoder's canonical NaN
    // handling changes, this fails loudly and the comment must be revisited.
    let pool = setup().await?;
    let p = encrypt_specials(&[F8(f64::NAN), F8(f64::NAN)]).await?;
    let equal = eq_cmp(&pool, &p[0], &p[1]).await?;
    assert!(
        equal,
        "two encryptions of canonical NaN compare equal (artifact of deterministic terms)"
    );
    Ok(())
}

#[tokio::test]
async fn negative_zero_and_positive_zero_compare_equal_and_share_ore() -> Result<()> {
    // The encoder canonicalizes -0.0 -> +0.0 (byte-equal), matching IEEE
    // (-0.0 == 0.0). So they compare equal under `=` and are not `<` either way.
    let pool = setup().await?;
    let p = encrypt_specials(&[F8(-0.0), F8(0.0)]).await?;
    assert!(eq_cmp(&pool, &p[0], &p[1]).await?, "-0.0 == +0.0");
    assert!(!ord_cmp(&pool, &p[0], "<", &p[1]).await?, "-0.0 not < +0.0");
    assert!(!ord_cmp(&pool, &p[1], "<", &p[0]).await?, "+0.0 not < -0.0");
    Ok(())
}

#[tokio::test]
async fn infinities_order_correctly() -> Result<()> {
    // Redundant spot-check of the boundary ordering: -Inf < 0 < +Inf through the
    // encrypted _ord domain (no decryption).
    let pool = setup().await?;
    let p = encrypt_specials(&[F8(f64::NEG_INFINITY), F8(0.0), F8(f64::INFINITY)]).await?;
    assert!(ord_cmp(&pool, &p[0], "<", &p[1]).await?, "-Inf < 0");
    assert!(ord_cmp(&pool, &p[1], "<", &p[2]).await?, "0 < +Inf");
    assert!(ord_cmp(&pool, &p[0], "<", &p[2]).await?, "-Inf < +Inf");
    Ok(())
}
