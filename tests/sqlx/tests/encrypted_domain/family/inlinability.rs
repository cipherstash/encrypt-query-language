//! Global guard for the encrypted-domain inline-critical SQL surface.
//!
//! `tasks/pin_search_path.sql` runs after every build and pins a fixed
//! `search_path` on every `eql_v2` function — except the inline-critical
//! ones, which must stay unpinned so the planner can inline them and the
//! documented functional indexes (`eql_v2.eq_term(col)`,
//! `eql_v2.ord_term(col)`, …) engage.
//!
//! The encrypted-domain family is skipped by a structural rule anchored
//! on the *identity predicate*: a `LANGUAGE sql`, `IMMUTABLE` function
//! taking at least one argument typed as a jsonb-backed DOMAIN in
//! `public` named `eql_v2_*`. The identity predicate is
//! proconfig-independent — it describes what a function intrinsically
//! IS, not whether it has been pinned.
//!
//! This test is the global net for that rule. It uses the identity
//! predicate VERBATIM and appends one offender filter:
//! `proconfig IS NOT NULL` — a function matching the family shape that
//! nonetheless carries a pinned `search_path`. It asserts that offender
//! set is empty. Because the test and the pin-loop skip clause share the
//! identity predicate exactly (the guard only adds the offender filter),
//! they cannot drift apart on identity.
//!
//! A non-empty result means `pin_search_path.sql` pinned an
//! inline-critical encrypted-domain function — index engagement is
//! silently broken for that type. This is not int4-specific: a missed
//! skip for ANY encrypted-domain type — present or future — fails here,
//! so a new type's author does not have to remember to add a per-type
//! inlinability assertion.

use anyhow::Result;
use sqlx::PgPool;

#[sqlx::test]
async fn no_encrypted_domain_inline_critical_function_is_pinned(pool: PgPool) -> Result<()> {
    // The identity predicate is shared verbatim with the structural skip
    // clause in tasks/pin_search_path.sql: LANGUAGE sql, IMMUTABLE, and
    // taking at least one argument typed as a `public.eql_v2_*` domain
    // over jsonb. It is proconfig-independent. The ONLY addition here is
    // the offender filter `p.proconfig IS NOT NULL` — a function that
    // matches the identity predicate but DID get pinned. That set must be
    // empty.
    let offenders: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT p.oid::regprocedure::text AS signature,
               array_to_string(p.proconfig, ', ') AS proconfig
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v2'
          AND l.lanname = 'sql'
          AND p.provolatile = 'i'
          AND p.proconfig IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM pg_catalog.unnest(p.proargtypes::oid[]) AS arg(typ)
            JOIN pg_catalog.pg_type dt ON dt.oid = arg.typ
            JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
            JOIN pg_catalog.pg_type bt ON bt.oid = dt.typbasetype
            WHERE dt.typtype = 'd'
              AND dn.nspname = 'public'
              AND dt.typname LIKE 'eql_v2\_%'
              AND bt.typname = 'jsonb'
          )
        ORDER BY signature
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "pin_search_path.sql pinned {} inline-critical encrypted-domain \
         SQL function(s) — index engagement is silently broken. \
         Offenders (signature → proconfig):\n{}",
        offenders.len(),
        offenders
            .iter()
            .map(|(sig, cfg)| format!("  {sig} → {cfg}"))
            .collect::<Vec<_>>()
            .join("\n"),
    );
    Ok(())
}

#[sqlx::test]
async fn every_inline_critical_eligible_domain_has_inline_critical_functions(
    pool: PgPool,
) -> Result<()> {
    // Stronger than a bare `count > 0`: if a future change accidentally
    // narrows the structural predicate (e.g. hard-codes `eql_v2_int4_%`),
    // a `count > 0` assertion would still pass while int8/bool/date
    // domains silently lose inline-critical coverage. Instead, assert
    // that EVERY inline-critical-eligible domain (any `public.eql_v2_*`
    // domain over jsonb that carries a capability suffix — `_eq`, `_ord`,
    // `_ord_ore`) appears as an argument type of at least one
    // inline-critical function.
    //
    // Storage-only variants (the bare `eql_v2_<T>` domain, with no
    // capability suffix) intentionally have NO inline-critical surface
    // and are excluded from the eligibility set.
    let unbound: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT dt.typname
        FROM pg_catalog.pg_type dt
        JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
        JOIN pg_catalog.pg_type bt ON bt.oid = dt.typbasetype
        WHERE dt.typtype = 'd'
          AND dn.nspname = 'public'
          AND bt.typname = 'jsonb'
          AND dt.typname LIKE 'eql_v2\_%'
          AND (
               dt.typname LIKE '%\_eq'
            OR dt.typname LIKE '%\_ord'
            OR dt.typname LIKE '%\_ord\_ore'
          )
          AND NOT EXISTS (
            SELECT 1
            FROM pg_catalog.pg_proc p
            JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
            JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
            WHERE n.nspname = 'eql_v2'
              AND l.lanname = 'sql'
              AND p.provolatile = 'i'
              AND dt.oid = ANY(p.proargtypes::oid[])
          )
        ORDER BY dt.typname
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        unbound.is_empty(),
        "the following inline-critical-eligible domains have NO \
         inline-critical function bound — index engagement is broken \
         for them: {unbound:?}"
    );
    Ok(())
}

/// Encrypted-domain blockers must be `LANGUAGE plpgsql` and **never**
/// `STRICT`. A LANGUAGE sql blocker is inlinable (the planner can elide
/// it when the result is provably unused); a STRICT blocker returns NULL
/// on a NULL argument, silently bypassing the RAISE. Either footgun
/// re-enables an operator the storage variant exists to block.
///
/// This is a structural guard that does NOT depend on `eql_v2.lints()` —
/// a regression to the lint catalog itself cannot hide a regression to
/// the blocker surface from this test.
#[sqlx::test]
async fn encrypted_domain_blockers_are_plpgsql_and_non_strict(pool: PgPool) -> Result<()> {
    let offenders: Vec<(String, String, bool)> = sqlx::query_as(
        r#"
        SELECT p.oid::regprocedure::text AS signature,
               l.lanname,
               p.proisstrict
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v2'
          AND (p.prosrc LIKE '%encrypted_domain_unsupported_bool%'
            OR p.prosrc LIKE '%is not supported for%')
          AND EXISTS (
            SELECT 1
            FROM pg_catalog.unnest(p.proargtypes::oid[]) AS arg(typ)
            JOIN pg_catalog.pg_type dt ON dt.oid = arg.typ
            JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
            JOIN pg_catalog.pg_type bt ON bt.oid = dt.typbasetype
            WHERE dt.typtype = 'd'
              AND dn.nspname = 'public'
              AND dt.typname LIKE 'eql_v2\_%'
              AND bt.typname = 'jsonb'
          )
          AND (l.lanname <> 'plpgsql' OR p.proisstrict)
        ORDER BY signature
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "encrypted-domain blockers must be LANGUAGE plpgsql and non-STRICT. \
         Offenders (signature, language, isstrict): {offenders:#?}"
    );
    Ok(())
}

/// No `eql_v2_*` domain may be derived from another `eql_v2_*` domain —
/// operators resolve against the ultimate base type, so a derived domain
/// inherits jsonb's operator surface and not the base domain's blockers.
/// All family domains must be defined directly over jsonb.
#[sqlx::test]
async fn no_eql_v2_domain_is_derived_from_another_eql_v2_domain(pool: PgPool) -> Result<()> {
    let offenders: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT format('%I.%I', dn.nspname, dt.typname) AS derived,
               format('%I.%I', bn.nspname, bt.typname) AS base
        FROM pg_catalog.pg_type dt
        JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
        JOIN pg_catalog.pg_type bt ON bt.oid = dt.typbasetype
        JOIN pg_catalog.pg_namespace bn ON bn.oid = bt.typnamespace
        WHERE dt.typtype = 'd'
          AND dn.nspname = 'public'
          AND dt.typname LIKE 'eql_v2\_%'
          AND bt.typtype = 'd'
          AND bt.typname LIKE 'eql_v2\_%'
        ORDER BY derived
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "eql_v2_* domains must be defined directly over jsonb, not derived \
         from another eql_v2_* domain. Offenders (derived, base): {offenders:#?}"
    );
    Ok(())
}

/// No operator class may be declared `FOR TYPE` on an `eql_v2_*` domain.
/// Opclasses on domains bypass the operator-resolution that storage
/// blockers depend on. The recommended index pattern is a functional
/// index on the extractor (e.g. `eql_v2.eq_term(col)`).
#[sqlx::test]
async fn no_opclass_targets_eql_v2_domain(pool: PgPool) -> Result<()> {
    let offenders: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT format('%I.%I', cn.nspname, oc.opcname) AS opclass,
               format('%I.%I', tn.nspname, t.typname)  AS for_type
        FROM pg_catalog.pg_opclass oc
        JOIN pg_catalog.pg_type t ON t.oid = oc.opcintype
        JOIN pg_catalog.pg_namespace tn ON tn.oid = t.typnamespace
        JOIN pg_catalog.pg_namespace cn ON cn.oid = oc.opcnamespace
        WHERE t.typtype = 'd'
          AND tn.nspname = 'public'
          AND t.typname LIKE 'eql_v2\_%'
        ORDER BY opclass
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "no operator class may target an eql_v2_* domain — use a functional \
         index on the extractor instead. Offenders (opclass, for_type): {offenders:#?}"
    );
    Ok(())
}
