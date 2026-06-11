//! Unit edge cases for the eql_v3 int4 domains (CIP-3141): NULL propagation on
//! supported operators, blocker functions raising on unsupported operators, and
//! domain CHECK-constraint rejection of malformed payloads. No encryption.

use anyhow::Result;
use eql_tests::scalar_domains::{
    assert_null, assert_raises, blocker_msg, ScalarDomainSpec, Variant,
};
use sqlx::PgPool;

/// A well-formed int4 storage/eq payload literal — has v/i/c + hm + ob, so it
/// casts into any int4 domain. Hand-written (no encryption needed); the term
/// VALUES are placeholders, which is fine for NULL/blocker/CHECK shape tests.
const WELL_FORMED: &str =
    r#"{"v":2,"i":{"t":"edge","c":"payload"},"c":"AAAA","hm":"deadbeef","ob":["00"]}"#;

fn int4(variant: Variant) -> String {
    ScalarDomainSpec::new::<i32>(variant).sql_domain
}

#[sqlx::test]
async fn eq_propagates_null(pool: PgPool) -> Result<()> {
    let d = int4(Variant::Eq);
    // A supported operator with a NULL operand must yield NULL, not raise.
    let sql = format!("SELECT ($1::jsonb::{d}) = (NULL::{d})");
    assert_null(&pool, &sql, &[Some(WELL_FORMED)]).await
}

#[sqlx::test]
async fn lt_blocker_raises_on_eq_domain(pool: PgPool) -> Result<()> {
    // `<` is not supported on the equality-only domain; the blocker must RAISE,
    // and must NOT be elided even on a NULL operand (blockers are never STRICT).
    let d = int4(Variant::Eq);
    let sql = format!("SELECT ($1::jsonb::{d}) < ($1::jsonb::{d})");
    assert_raises(&pool, &sql, &[Some(WELL_FORMED)], &blocker_msg(&d, "<")).await?;
    // NULL operand: still raises (proves the blocker is not STRICT).
    let sql_null = format!("SELECT (NULL::{d}) < (NULL::{d})");
    assert_raises(&pool, &sql_null, &[], &blocker_msg(&d, "<")).await
}

#[sqlx::test]
async fn check_rejects_payload_missing_hm(pool: PgPool) -> Result<()> {
    // The _eq domain CHECK requires `hm`. A payload without it must be rejected
    // at the cast.
    let d = int4(Variant::Eq);
    let no_hm = r#"{"v":2,"i":{"t":"edge","c":"payload"},"c":"AAAA","ob":["00"]}"#;
    let sql = format!("SELECT $1::jsonb::{d}");
    // The CHECK violation surfaces as a domain/constraint error; assert it raises.
    let result = sqlx::query(&sql).bind(no_hm).fetch_one(&pool).await;
    anyhow::ensure!(
        result.is_err(),
        "payload missing hm must be rejected by {d} CHECK"
    );
    Ok(())
}

#[sqlx::test]
async fn check_rejects_payload_missing_ob(pool: PgPool) -> Result<()> {
    // The _ord domain CHECK requires `ob`.
    let d = int4(Variant::Ord);
    let no_ob = r#"{"v":2,"i":{"t":"edge","c":"payload"},"c":"AAAA","hm":"deadbeef"}"#;
    let sql = format!("SELECT $1::jsonb::{d}");
    let result = sqlx::query(&sql).bind(no_ob).fetch_one(&pool).await;
    anyhow::ensure!(
        result.is_err(),
        "payload missing ob must be rejected by {d} CHECK"
    );
    Ok(())
}
