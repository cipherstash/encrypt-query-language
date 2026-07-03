//! Float edge-case behavioural regression suite (CIP — real/double).
//!
//! Captures the NaN / `-0.0` / `+0.0` / `±Inf` behaviour that the shared
//! all-pairs oracle deliberately excludes from its fixtures (NaN is unordered
//! and unspecified in the encoder; `-0.0` canonicalizes to `+0.0`). It encrypts
//! the special values FRESH through cipherstash at test time, so NaN never
//! enters the `double` fixture table.
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
use eql_tests::fixtures::cipherstash::encrypt_store;
use eql_tests::fixtures::index_kind::IndexKind;
use eql_tests::property::{connect_pool, ensure_eql_installed};
use eql_tests::scalar_domains::F8;
use sqlx::PgPool;

/// Encrypt one batch of f64 special values into payload JSON strings, one
/// ZeroKMS round trip. Mirrors `e2e_oracle::encrypt_rows` but returns only the
/// payloads (these tests key on position, not plaintext). `encrypt_store`
/// encrypts through cipherstash-client directly — it needs no `PgPool` — and
/// returns v3-envelope payloads (converted via eql_bindings::from_v2), so
/// the casts below satisfy the `v = '3'` domain CHECKs.
async fn encrypt_specials(values: &[F8]) -> Result<Vec<String>> {
    let payloads = encrypt_store(
        "float_special",
        "payload",
        values,
        &[IndexKind::Unique, IndexKind::Ore],
    )
    .await?;
    Ok(payloads.into_iter().map(|p| p.to_string()).collect())
}

/// Cast a payload literal to `eql_v3.double` and read it back, proving the domain
/// CHECK accepts the encrypted special value.
async fn cast_passes_check(pool: &PgPool, payload: &str) -> Result<()> {
    let sql = "SELECT ($1::jsonb::eql_v3.double) IS NOT NULL";
    let ok: bool = sqlx::query_scalar(sql)
        .bind(payload)
        .fetch_one(pool)
        .await?;
    anyhow::ensure!(ok, "payload failed the eql_v3.double CHECK: {payload}");
    Ok(())
}

/// Compare two payloads under an operator on the `_ord` domain, returning the
/// boolean result. Used to pin the discovered NaN/±0/±Inf outcomes.
async fn ord_cmp(pool: &PgPool, a: &str, op: &str, b: &str) -> Result<bool> {
    let d = "eql_v3.double_ord";
    let sql = format!("SELECT ($1::jsonb::{d} {op} $2::jsonb::{d})");
    Ok(sqlx::query_scalar(&sql)
        .bind(a)
        .bind(b)
        .fetch_one(pool)
        .await?)
}

/// Equality under the `_eq` domain (HMAC).
async fn eq_cmp(pool: &PgPool, a: &str, b: &str) -> Result<bool> {
    let d = "eql_v3.double_eq";
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
    // eql_v3.double payload. This is the one universal NaN guarantee.
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

#[tokio::test]
async fn nan_order_position_is_deterministic_and_total() -> Result<()> {
    // TRIPWIRE for encoder drift — NOT a direction guarantee.
    //
    // NaN is "unordered and unspecified" by design, so we deliberately do NOT
    // pin WHERE NaN sorts relative to finite / ±Inf values (that position is an
    // encoder artifact and may change). But the Block-ORE index the `_ord`
    // domain rides on requires a *total, deterministic* order: the same
    // plaintext must always land at the same position, and every pair must
    // resolve to exactly one of `<` / `=` / `>`. If a future encoder change
    // makes NaN's position non-deterministic (same bits, different sort slot ->
    // btree corruption) or non-total (a comparison that follows IEEE and returns
    // false both ways), this fails loudly. The NaN==NaN equality artifact is
    // locked separately in `two_encryptions_of_same_nan_bits_compare_equal`;
    // this guards the ORDER side of the same deterministic-terms property.
    let pool = setup().await?;
    // Two independent encryptions of canonical NaN, plus a spread of references.
    let p = encrypt_specials(&[
        F8(f64::NAN),          // 0: NaN (encryption A)
        F8(f64::NAN),          // 1: NaN (encryption B)
        F8(f64::NEG_INFINITY), // 2
        F8(0.0),               // 3
        F8(f64::INFINITY),     // 4
    ])
    .await?;
    let (nan_a, nan_b) = (&p[0], &p[1]);

    for (label, r) in [("-Inf", &p[2]), ("0", &p[3]), ("+Inf", &p[4])] {
        let lt = ord_cmp(&pool, nan_a, "<", r).await?;
        let eq = ord_cmp(&pool, nan_a, "=", r).await?;
        let gt = ord_cmp(&pool, nan_a, ">", r).await?;
        // Totality: exactly one of < = > holds (NaN is NOT IEEE-incomparable here).
        assert_eq!(
            [lt, eq, gt].iter().filter(|b| **b).count(),
            1,
            "NaN vs {label} is not a total order: (<, =, >) = ({lt}, {eq}, {gt})"
        );
        // Determinism: a second independent NaN encryption lands identically.
        let (lt_b, eq_b, gt_b) = (
            ord_cmp(&pool, nan_b, "<", r).await?,
            ord_cmp(&pool, nan_b, "=", r).await?,
            ord_cmp(&pool, nan_b, ">", r).await?,
        );
        assert_eq!(
            (lt, eq, gt),
            (lt_b, eq_b, gt_b),
            "NaN's order position vs {label} is not stable across re-encryption \
             (deterministic index terms broken)"
        );
    }
    Ok(())
}
