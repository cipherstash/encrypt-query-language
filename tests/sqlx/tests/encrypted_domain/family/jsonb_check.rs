//! Equivalence guards for the inline SteVec domain CHECK expressions
//! (issue #354).
//!
//! `public.eql_v3_json_entry` carries an INLINE CHECK expression rather than
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
//! `eql_v3.query_json`'s CHECK CANNOT be inlined — validating sv elements
//! needs a subquery, which CHECK constraints forbid — so its validator is
//! plpgsql instead (cached plan vs the per-call SQL-function executor; the
//! issue #353 finding). `query_json_check_behaviour` characterises the
//! accept/reject matrix, and `query_json_validator_is_plpgsql` guards the
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
        // Valid: hm entry, op entry, extra fields allowed.
        Some(r#"{"s":"sel","c":"ct","hm":"h"}"#),
        Some(r#"{"s":"sel","c":"ct","op":"o"}"#),
        Some(r#"{"s":"sel","c":"ct","hm":"h","a":true,"i":{},"v":3}"#),
        // Invalid: missing s / missing c / both terms / neither term.
        Some(r#"{"c":"ct","hm":"h"}"#),
        Some(r#"{"s":"sel","hm":"h"}"#),
        Some(r#"{"s":"sel","c":"ct","hm":"h","op":"o"}"#),
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
        "public.eql_v3_json_entry",
        "eql_v3_is_valid_ste_vec_entry_payload",
        candidates,
    )
    .await
}

#[sqlx::test]
async fn query_json_check_behaviour(pool: PgPool) -> Result<()> {
    // (payload, expected accept) — hardcoded verdicts: the CHECK calls the
    // validator, so a validator-equivalence assertion would be tautological.
    let candidates: &[(Option<&str>, bool)] = &[
        (None, true),
        // Valid: single- and multi-entry needles; empty sv is valid.
        (Some(r#"{"sv":[{"s":"sel","hm":"h"}]}"#), true),
        (
            Some(r#"{"sv":[{"s":"a","hm":"h"},{"s":"b","op":"o"}]}"#),
            true,
        ),
        (Some(r#"{"sv":[]}"#), true),
        // Invalid: element carries a ciphertext / both terms / neither term /
        // missing s.
        (Some(r#"{"sv":[{"s":"sel","hm":"h","c":"ct"}]}"#), false),
        (Some(r#"{"sv":[{"s":"sel","hm":"h","op":"o"}]}"#), false),
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
        let cast = cast_accepts(&pool, "eql_v3.query_json", *payload).await?;
        anyhow::ensure!(
            cast == *expected,
            "eql_v3.query_json cast verdict changed for {payload:?}: \
             accepted = {cast}, expected = {expected}"
        );
    }
    Ok(())
}

/// Cast `payload` to the bare storage domain and observe whether its CHECK
/// accepts. Deliberately NOT the shared `cast_accepts` helper: that uses
/// `IS NOT DISTINCT FROM` (i.e. `=`), and `=` is a BLOCKED operator on the
/// storage domain (every comparison raises). `IS NOT NULL` needs no operator on
/// the domain, so it isolates the CHECK verdict. SQL NULL casts to NULL and
/// evaluates no CHECK, so it is accepted (Ok, no error).
async fn storage_cast_accepts(pool: &PgPool, payload: Option<&str>) -> Result<bool> {
    let sql = "SELECT ($1::jsonb)::public.eql_v3_json IS NOT NULL";
    match sqlx::query_scalar::<_, bool>(sql)
        .bind(payload)
        .fetch_one(pool)
        .await
    {
        Ok(_) => Ok(true),
        Err(e) if e.to_string().contains("check constraint") => Ok(false),
        Err(e) => Err(e.into()),
    }
}

/// The bare storage domain `public.eql_v3_json` (ciphertext-only encrypted
/// JSON) accepts only a well-formed `{v,i,c}` envelope at `v == '3'`, and in
/// particular REJECTS a SteVec document payload (`{v,i,sv}` with no root `c`) —
/// the structural distinction from the searchable `public.eql_v3_json_search`.
#[sqlx::test]
async fn json_storage_check_accepts_envelope_rejects_malformed(pool: PgPool) -> Result<()> {
    let candidates: &[(Option<&str>, bool)] = &[
        // SQL NULL — a domain accepts NULL (no CHECK is evaluated).
        (None, true),
        // Valid: the minimal `{v,i,c}` envelope; extra keys allowed.
        (Some(r#"{"v":"3","i":{},"c":"ct"}"#), true),
        (
            Some(r#"{"v":"3","i":{"t":"tbl","c":"col"},"c":"ct","extra":1}"#),
            true,
        ),
        // Invalid: a SteVec document (`sv`, no root `c`) — belongs to
        // public.eql_v3_json_search, not the ciphertext-only storage domain.
        (
            Some(r#"{"v":"3","i":{},"sv":[{"s":"sel","hm":"h"}]}"#),
            false,
        ),
        // Invalid: missing c / missing v / missing i / wrong version.
        (Some(r#"{"v":"3","i":{}}"#), false),
        (Some(r#"{"i":{},"c":"ct"}"#), false),
        (Some(r#"{"v":"3","c":"ct"}"#), false),
        (Some(r#"{"v":"2","i":{},"c":"ct"}"#), false),
        // Invalid: non-object roots.
        (Some(r#""scalar""#), false),
        (Some("5"), false),
        (Some("null"), false),
        (Some("[]"), false),
    ];
    for (payload, expected) in candidates {
        let cast = storage_cast_accepts(&pool, *payload).await?;
        anyhow::ensure!(
            cast == *expected,
            "public.eql_v3_json cast verdict for {payload:?}: accepted = {cast}, \
             expected = {expected}"
        );
    }
    Ok(())
}

/// The comparison/containment native jsonb operators are BLOCKED on
/// `public.eql_v3_json`: a value typed as the storage domain can never fall
/// through to plaintext-jsonb equality/containment. Each raises
/// `... is not supported ...` (a LANGUAGE plpgsql blocker the planner cannot
/// elide). NB: the pure path/existence operators (`->`, `->>`, `?`) resolve to
/// native jsonb on ANY jsonb-backed storage domain (`eql_v3_integer` included) —
/// a pre-existing PostgreSQL operator-resolution quirk, not specific to `json`
/// — so they are deliberately not asserted here.
#[sqlx::test]
async fn json_storage_blocks_native_comparison_operators(pool: PgPool) -> Result<()> {
    let envelope = r#"{"v":"3","i":{},"c":"ct"}"#;
    let ops: &[&str] = &[
        "col = '{}'::jsonb",
        "col @> '{}'::jsonb",
        "col <@ '{}'::jsonb",
        "col #> '{k}'::text[]",
        "col || '{}'::jsonb",
    ];
    for frag in ops {
        let sql = format!("SELECT {frag} FROM (SELECT $1::public.eql_v3_json AS col) t");
        let err = sqlx::query_scalar::<_, serde_json::Value>(&sql)
            .bind(envelope)
            .fetch_one(&pool)
            .await
            .expect_err(&format!(
                "native jsonb operator in `{frag}` must be blocked"
            ));
        anyhow::ensure!(
            err.to_string().contains("is not supported"),
            "expected a 'not supported' blocker error for `{frag}`, got: {err}"
        );
    }
    Ok(())
}

/// KNOWN LIMITATION (characterization test — pins current behaviour, there is no
/// fix). The pure path/existence native jsonb operators `->`, `->>`, and `?` are
/// NOT blocked on `public.eql_v3_json`: they resolve to the native `jsonb`
/// operator and return a plaintext result (`NULL` / `false`) instead of raising
/// the blocker. This is a PostgreSQL operator-resolution quirk affecting EVERY
/// jsonb-backed storage domain (`eql_v3_integer`, `eql_v3_boolean`, … — not
/// specific to `json`): for these operators the planner binds the base-type
/// `jsonb` operator rather than the domain-specific blocker. The
/// comparison/containment operators (`=`, `@>`, `<@`, `#>`, `||`) DO engage the
/// blocker — see `json_storage_blocks_native_comparison_operators`.
///
/// The encrypted ciphertext lives in `c`, so `->'c'` / `->>'c'` merely echo the
/// already-opaque ciphertext string and `?` tests key presence in the envelope —
/// none of which leaks plaintext. This test exists so that if a future
/// PostgreSQL version (or an EQL change) starts routing these through the
/// blocker, the change is noticed here rather than silently altering behaviour.
#[sqlx::test]
async fn json_storage_path_operators_fall_through_to_native_known_limitation(
    pool: PgPool,
) -> Result<()> {
    let envelope = r#"{"v":"3","i":{},"c":"ct"}"#;
    let of = |frag: &str| format!("SELECT {frag} FROM (SELECT $1::public.eql_v3_json AS col) t");

    // `->` / `->>` return native jsonb: NULL for an absent key, and `-> 'c'`
    // echoes the (already-opaque) ciphertext string — no plaintext leak. None raise.
    let jsonb_cases: &[(&str, serde_json::Value)] = &[
        ("col -> 'missing'", serde_json::Value::Null),
        ("col ->> 'missing'", serde_json::Value::Null),
        ("col -> 'c'", serde_json::json!("ct")),
    ];
    for (frag, expected) in jsonb_cases {
        let got: Option<serde_json::Value> = sqlx::query_scalar(&of(frag))
            .bind(envelope)
            .fetch_one(&pool)
            .await
            .unwrap_or_else(|e| panic!("`{frag}` unexpectedly raised (limitation changed?): {e}"));
        let got = got.unwrap_or(serde_json::Value::Null);
        anyhow::ensure!(
            &got == expected,
            "path operator `{frag}` returned {got:?}, expected native {expected:?}"
        );
    }

    // `?` tests envelope key presence and returns a native boolean (does not raise).
    let key_cases: &[(&str, bool)] = &[("col ? 'c'", true), ("col ? 'absent'", false)];
    for (frag, expected) in key_cases {
        let got: bool = sqlx::query_scalar(&of(frag))
            .bind(envelope)
            .fetch_one(&pool)
            .await
            .unwrap_or_else(|e| panic!("`{frag}` unexpectedly raised (limitation changed?): {e}"));
        anyhow::ensure!(
            got == *expected,
            "existence operator `{frag}` returned {got}, expected native {expected}"
        );
    }
    Ok(())
}

/// The query_json validator must stay plpgsql: its only caller is the domain
/// CHECK (a context that can never inline a SQL function), so LANGUAGE sql
/// pays the per-call SQL-function executor on every containment-needle cast
/// (issues #353/#354). A revert fails here.
#[sqlx::test]
async fn query_json_validator_is_plpgsql(pool: PgPool) -> Result<()> {
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
