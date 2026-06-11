//! Global guard for the encrypted-domain inline-critical SQL surface.
//!
//! `tasks/pin_search_path.sql` runs after every build and pins a fixed
//! `search_path` on every `eql_v2`/`eql_v3` function — except the
//! inline-critical ones, which must stay unpinned so the planner can
//! inline them and the documented functional indexes (`eql_v3.eq_term(col)`,
//! `eql_v3.ord_term(col)`, …) engage.
//!
//! The encrypted-domain family is skipped by a structural rule anchored
//! on the *identity predicate*: a `LANGUAGE sql`, `IMMUTABLE` function
//! taking at least one argument typed as a jsonb-backed DOMAIN of the
//! encrypted-domain families — a domain in the `eql_v3` schema (e.g.
//! `eql_v3.int4_eq`) or the legacy `public.eql_v2_*` form. The identity
//! predicate is proconfig-independent — it describes what a function
//! intrinsically IS, not whether it has been pinned.
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
    // taking at least one argument typed as an encrypted-domain-family
    // domain over jsonb (an `eql_v3.*` domain or the legacy
    // `public.eql_v2_*` form). It is proconfig-independent. The ONLY
    // addition here is the offender filter `p.proconfig IS NOT NULL` — a
    // function that matches the identity predicate but DID get pinned.
    // That set must be empty.
    let offenders: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT p.oid::regprocedure::text AS signature,
               array_to_string(p.proconfig, ', ') AS proconfig
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        WHERE n.nspname IN ('eql_v2', 'eql_v3')
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
              AND bt.typname = 'jsonb'
              AND (
                   dn.nspname = 'eql_v3'
                OR (dn.nspname = 'public' AND dt.typname LIKE 'eql_v2\_%')
              )
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

/// Direct guard for the self-contained eql_v3 SEM index-term functions. Unlike
/// the structural guard above (which covers jsonb-domain-arg functions), these
/// take a composite (ore_block_u64_8_256) or raw jsonb (hmac_256, bloom_filter,
/// the ore_cllw/has_ore_cllw extractors, the two per-encrypted-value
/// `jsonb_array_to_*` helpers) arg, so they are NOT caught by the structural
/// pin-skip and need explicit inline_critical allowlisting. If
/// pin_search_path.sql pins any of them, v3 functional-index inlining silently
/// regresses to Seq Scan — this test fails instead.
///
/// `jsonb_array_to_bytea_array(jsonb)` and
/// `jsonb_array_to_ore_block_u64_8_256(jsonb)` are included here: both take a
/// bare `jsonb` arg (not a jsonb-backed encrypted DOMAIN), so the structural
/// skip in tasks/pin_search_path.sql does not recognise them — they are kept
/// unpinned by the `eql-inline-critical` COMMENT marker instead. This test
/// asserts the unpinned + inlinable-SQL state directly; the companion
/// `eql_v3_sem_inline_critical_functions_carry_marker` test below asserts the
/// marker itself, so an edit that drops the marker (or a pin_search_path.sql
/// refactor that stops honouring it) fails CI even though both checks live in
/// separate tests.
#[sqlx::test]
async fn eql_v3_sem_inline_critical_functions_are_unpinned(pool: PgPool) -> Result<()> {
    let rows: Vec<(String,)> = sqlx::query_as(
        r#"
        SELECT p.proname || '(' || pg_catalog.pg_get_function_arguments(p.oid) || ')'
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'eql_v3'
          AND (
            (p.pronargs = 2 AND p.proname IN (
              'ore_block_u64_8_256_eq','ore_block_u64_8_256_neq',
              'ore_block_u64_8_256_lt','ore_block_u64_8_256_lte',
              'ore_block_u64_8_256_gt','ore_block_u64_8_256_gte'))
            OR (p.pronargs = 1 AND p.proname IN (
              'hmac_256',
              'bloom_filter',
              'ore_cllw',
              'has_ore_cllw',
              'jsonb_array_to_bytea_array',
              'jsonb_array_to_ore_block_u64_8_256')
                AND p.proargtypes[0] = 'jsonb'::regtype)
          )
          AND (
            -- offender: pinned search_path, or not inlinable SQL/IMMUTABLE
            EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig,'{}'::text[])) c WHERE c LIKE 'search_path=%')
            OR p.provolatile <> 'i'
            OR p.prolang <> (SELECT l.oid FROM pg_catalog.pg_language l WHERE l.lanname = 'sql')
          )
        ORDER BY 1
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        rows.is_empty(),
        "eql_v3 SEM inline-critical functions must stay unpinned + inlinable SQL; offenders: {:?}",
        rows.iter().map(|r| &r.0).collect::<Vec<_>>()
    );
    Ok(())
}

/// Companion guard for the two bare-`jsonb` per-encrypted-value helpers
/// (`jsonb_array_to_bytea_array`, `jsonb_array_to_ore_block_u64_8_256`). The
/// unpinned state asserted above is only DURABLE because each helper carries an
/// `eql-inline-critical` COMMENT marker that `tasks/pin_search_path.sql` honours
/// (it skips pinning functions whose `pg_description` matches
/// `'eql-inline-critical%'`). Neither helper is caught by the structural
/// jsonb-domain skip, so the marker is the ONLY thing keeping them unpinned —
/// an edit that removes the marker, or a pin_search_path.sql refactor that drops
/// the marker handling, would silently re-pin them and break inlining. This test
/// asserts the marker is present (and the helpers are SQL/IMMUTABLE) so that
/// failure surfaces here.
#[sqlx::test]
async fn eql_v3_sem_inline_critical_helpers_carry_marker(pool: PgPool) -> Result<()> {
    // Each expected helper must appear with a present inline-critical marker
    // and be inlinable SQL/IMMUTABLE. Any helper that is missing, unmarked, or
    // not inlinable SQL/IMMUTABLE is an offender.
    let offenders: Vec<(String, Option<String>, String, String)> = sqlx::query_as(
        r#"
        WITH expected(proname) AS (
          VALUES ('jsonb_array_to_bytea_array'),
                 ('jsonb_array_to_ore_block_u64_8_256')
        )
        SELECT e.proname AS proname,
               d.description AS marker,
               l.lanname AS prolang,
               p.provolatile::text AS provolatile
        FROM expected e
        LEFT JOIN pg_catalog.pg_proc p
          ON p.proname = e.proname
         AND p.pronamespace = 'eql_v3'::regnamespace
         AND p.pronargs = 1
         AND p.proargtypes[0] = 'jsonb'::regtype
        LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang
        LEFT JOIN pg_catalog.pg_description d
          ON d.objoid = p.oid AND d.classoid = 'pg_proc'::regclass
        WHERE p.oid IS NULL
           OR d.description IS NULL
           OR d.description NOT LIKE 'eql-inline-critical%'
           OR l.lanname IS DISTINCT FROM 'sql'
           OR p.provolatile IS DISTINCT FROM 'i'
        ORDER BY e.proname
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "eql_v3 SEM bare-jsonb helpers must carry an `eql-inline-critical` COMMENT \
         marker and be inlinable SQL/IMMUTABLE — the marker is what keeps \
         pin_search_path.sql from pinning them. Offenders \
         (proname, marker, prolang, provolatile): {offenders:#?}"
    );
    Ok(())
}

#[sqlx::test]
async fn every_inline_critical_eligible_domain_has_inline_critical_functions(
    pool: PgPool,
) -> Result<()> {
    // Stronger than a bare `count > 0`: if a future change accidentally
    // narrows the structural predicate (e.g. hard-codes `int4_%`), a
    // `count > 0` assertion would still pass while int8/bool/date
    // domains silently lose inline-critical coverage. Instead, assert
    // that EVERY inline-critical-eligible domain (any encrypted-domain
    // family domain over jsonb — `eql_v3.*` or legacy `public.eql_v2_*` —
    // that carries a capability suffix — `_eq`, `_ord`, `_ord_ore`)
    // appears as an argument type of at least one inline-critical
    // function.
    //
    // Storage-only variants (the bare `eql_v3.<T>` / `eql_v2_<T>` domain,
    // with no capability suffix) intentionally have NO inline-critical
    // surface and are excluded from the eligibility set.
    let unbound: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT dt.typname
        FROM pg_catalog.pg_type dt
        JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
        JOIN pg_catalog.pg_type bt ON bt.oid = dt.typbasetype
        WHERE dt.typtype = 'd'
          AND bt.typname = 'jsonb'
          AND (
               dn.nspname = 'eql_v3'
            OR (dn.nspname = 'public' AND dt.typname LIKE 'eql_v2\_%')
          )
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
            WHERE n.nspname IN ('eql_v2', 'eql_v3')
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
        WHERE n.nspname IN ('eql_v2', 'eql_v3')
          AND (p.prosrc LIKE '%encrypted_domain_unsupported_bool%'
            OR p.prosrc LIKE '%is not supported for%')
          AND EXISTS (
            SELECT 1
            FROM pg_catalog.unnest(p.proargtypes::oid[]) AS arg(typ)
            JOIN pg_catalog.pg_type dt ON dt.oid = arg.typ
            JOIN pg_catalog.pg_namespace dn ON dn.oid = dt.typnamespace
            JOIN pg_catalog.pg_type bt ON bt.oid = dt.typbasetype
            WHERE dt.typtype = 'd'
              AND bt.typname = 'jsonb'
              AND (
                   dn.nspname = 'eql_v3'
                OR (dn.nspname = 'public' AND dt.typname LIKE 'eql_v2\_%')
              )
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

/// No encrypted-domain family domain may be derived from another family
/// domain — operators resolve against the ultimate base type, so a derived
/// domain inherits jsonb's operator surface and not the base domain's
/// blockers. All family domains must be defined directly over jsonb.
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
          AND (
               dn.nspname = 'eql_v3'
            OR (dn.nspname = 'public' AND dt.typname LIKE 'eql_v2\_%')
          )
          AND bt.typtype = 'd'
          AND (
               bn.nspname = 'eql_v3'
            OR (bn.nspname = 'public' AND bt.typname LIKE 'eql_v2\_%')
          )
        ORDER BY derived
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "encrypted-domain family domains must be defined directly over jsonb, \
         not derived from another family domain. Offenders (derived, base): {offenders:#?}"
    );
    Ok(())
}

/// No operator class may be declared `FOR TYPE` on an encrypted-domain
/// family domain. Opclasses on domains bypass the operator-resolution that
/// storage blockers depend on. The recommended index pattern is a functional
/// index on the extractor (e.g. `eql_v3.eq_term(col)`).
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
          AND (
               tn.nspname = 'eql_v3'
            OR (tn.nspname = 'public' AND t.typname LIKE 'eql_v2\_%')
          )
        ORDER BY opclass
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "no operator class may target an encrypted-domain family domain — use a \
         functional index on the extractor instead. Offenders (opclass, for_type): {offenders:#?}"
    );
    Ok(())
}
