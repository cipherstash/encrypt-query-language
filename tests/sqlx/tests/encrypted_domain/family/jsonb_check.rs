//! Equivalence guards for the inline SteVec domain CHECK expressions
//! (issue #354).
//!
//! `public.jsonb_entry` carries an INLINE CHECK expression rather than
//! calling `public.eql_v3_is_valid_ste_vec_entry_payload`: domain
//! constraints cannot inline SQL functions, so the function-call form paid
//! the per-call SQL-function executor on every cast — the needle cast in
//! every field_eq query, the ENTIRE measured +19% v2→v3 regression on that
//! scenario (cipherstash/benches#23). `jsonb_entry_check_matches_validator`
//! pins the inline expression to the validator (still the source of truth
//! for direct callers) over a corpus of payload shapes; the one intentional
//! divergence is SQL NULL, which both forms accept (the validator via
//! STRICT, the inline expression via a leading `VALUE IS NULL OR`).
//!
//! `public.query_jsonb`'s CHECK CANNOT be inlined — validating sv elements
//! needs a subquery, which CHECK constraints forbid — so its validator is
//! plpgsql instead (cached plan vs the per-call SQL-function executor; the
//! issue #353 finding). `query_jsonb_check_behaviour` characterises the
//! accept/reject matrix, and `query_jsonb_validator_is_plpgsql` guards the
//! language so a revert to LANGUAGE sql fails here.

use anyhow::Result;
use sqlx::PgPool;

/// Try the domain cast for `payload`; Ok(true) = accepted, Ok(false) = CHECK
/// rejection. Any non-CHECK error propagates.
async fn cast_accepts(pool: &PgPool, domain: &str, payload: Option<&str>) -> Result<bool> {
    let sql = format!("SELECT ($1::jsonb)::{domain} IS NOT DISTINCT FROM $1::jsonb");
    match sqlx::query_scalar::<_, bool>(&sql)
        .bind(payload)
        .fetch_one(pool)
        .await
    {
        Ok(_) => Ok(true),
        Err(e) if e.to_string().contains("check constraint") => Ok(false),
        Err(e) => Err(e.into()),
    }
}

/// The validator's verdict for `payload`, with the STRICT NULL-passes rule
/// applied (SQL NULL is accepted by the domain even though the validator
/// returns NULL for it).
async fn validator_accepts(pool: &PgPool, validator: &str, payload: Option<&str>) -> Result<bool> {
    if payload.is_none() {
        return Ok(true);
    }
    let sql = format!("SELECT public.{validator}($1::jsonb)");
    Ok(sqlx::query_scalar::<_, bool>(&sql)
        .bind(payload)
        .fetch_one(pool)
        .await?)
}

async fn assert_equivalent(
    pool: &PgPool,
    domain: &str,
    validator: &str,
    candidates: &[Option<&str>],
) -> Result<()> {
    for payload in candidates {
        let cast = cast_accepts(pool, domain, *payload).await?;
        let valid = validator_accepts(pool, validator, *payload).await?;
        anyhow::ensure!(
            cast == valid,
            "{domain} inline CHECK diverges from {validator} for payload {payload:?}: \
             cast accepted = {cast}, validator = {valid}"
        );
    }
    Ok(())
}

#[sqlx::test]
async fn jsonb_entry_check_matches_validator(pool: PgPool) -> Result<()> {
    let candidates: &[Option<&str>] = &[
        // SQL NULL — accepted by both forms (STRICT / VALUE IS NULL OR).
        None,
        // Valid: hm entry, oc entry, extra fields allowed.
        Some(r#"{"s":"sel","c":"ct","hm":"h"}"#),
        Some(r#"{"s":"sel","c":"ct","oc":"o"}"#),
        Some(r#"{"s":"sel","c":"ct","hm":"h","a":true,"i":{},"v":3}"#),
        // Invalid: missing s / missing c / both terms / neither term.
        Some(r#"{"c":"ct","hm":"h"}"#),
        Some(r#"{"s":"sel","hm":"h"}"#),
        Some(r#"{"s":"sel","c":"ct","hm":"h","oc":"o"}"#),
        Some(r#"{"s":"sel","c":"ct"}"#),
        // Invalid: non-string term / non-string s / wrong jsonb types.
        Some(r#"{"s":"sel","c":"ct","hm":1}"#),
        Some(r#"{"s":1,"c":"ct","hm":"h"}"#),
        Some(r#""scalar""#),
        Some("5"),
        Some("null"),
        Some("[]"),
        Some("{}"),
    ];
    assert_equivalent(
        &pool,
        "public.jsonb_entry",
        "eql_v3_is_valid_ste_vec_entry_payload",
        candidates,
    )
    .await
}

#[sqlx::test]
async fn query_jsonb_check_behaviour(pool: PgPool) -> Result<()> {
    // (payload, expected accept) — hardcoded verdicts: the CHECK calls the
    // validator, so a validator-equivalence assertion would be tautological.
    let candidates: &[(Option<&str>, bool)] = &[
        (None, true),
        // Valid: single- and multi-entry needles; empty sv is valid.
        (Some(r#"{"sv":[{"s":"sel","hm":"h"}]}"#), true),
        (
            Some(r#"{"sv":[{"s":"a","hm":"h"},{"s":"b","oc":"o"}]}"#),
            true,
        ),
        (Some(r#"{"sv":[]}"#), true),
        // Invalid: element carries a ciphertext / both terms / neither term /
        // missing s.
        (Some(r#"{"sv":[{"s":"sel","hm":"h","c":"ct"}]}"#), false),
        (Some(r#"{"sv":[{"s":"sel","hm":"h","oc":"o"}]}"#), false),
        (Some(r#"{"sv":[{"s":"sel"}]}"#), false),
        (Some(r#"{"sv":[{"hm":"h"}]}"#), false),
        // Invalid: sv not an array / missing sv / non-object roots.
        (Some(r#"{"sv":{"s":"sel","hm":"h"}}"#), false),
        (Some("{}"), false),
        (Some(r#""scalar""#), false),
        (Some("null"), false),
        (Some("[]"), false),
    ];
    for (payload, expected) in candidates {
        let cast = cast_accepts(&pool, "public.query_jsonb", *payload).await?;
        anyhow::ensure!(
            cast == *expected,
            "public.query_jsonb cast verdict changed for {payload:?}: \
             accepted = {cast}, expected = {expected}"
        );
    }
    Ok(())
}

/// The query_jsonb validator must stay plpgsql: its only caller is the domain
/// CHECK (a context that can never inline a SQL function), so LANGUAGE sql
/// pays the per-call SQL-function executor on every containment-needle cast
/// (issues #353/#354). A revert fails here.
#[sqlx::test]
async fn query_jsonb_validator_is_plpgsql(pool: PgPool) -> Result<()> {
    let lang: String = sqlx::query_scalar(
        "SELECT l.lanname FROM pg_proc p \
         JOIN pg_language l ON l.oid = p.prolang \
         WHERE p.proname = 'eql_v3_is_valid_ste_vec_query_payload' \
           AND p.pronamespace = 'public'::regnamespace",
    )
    .fetch_one(&pool)
    .await?;
    anyhow::ensure!(
        lang == "plpgsql",
        "eql_v3_is_valid_ste_vec_query_payload must be plpgsql (got {lang})"
    );
    Ok(())
}
