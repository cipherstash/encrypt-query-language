//! Unit edge cases for the eql_v3 scalar domains (CIP-3141): NULL propagation on
//! supported operators, blocker functions raising on unsupported operators
//! (equality, ordering, path, and containment families — the documented
//! domain-fallback footgun), the timestamptz ordering deferral, and domain
//! CHECK-constraint rejection of malformed payloads. No encryption.

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
async fn path_blocker_raises_on_eq_domain(pool: PgPool) -> Result<()> {
    // A native-jsonb PATH operator (`->`) reachable through domain fallback must
    // hit the blocker, not silently return a jsonb sub-value (the documented
    // footgun). The domain ships its own `->` operator that always raises.
    let d = int4(Variant::Eq);
    let sql = format!("SELECT ($1::jsonb::{d}) -> 'sel'::text");
    assert_raises(&pool, &sql, &[Some(WELL_FORMED)], &blocker_msg(&d, "->")).await?;
    // NULL operand: still raises (proves the blocker is not STRICT, so a NULL
    // argument cannot let PostgreSQL skip the body and fall through to NULL).
    let sql_null = format!("SELECT (NULL::{d}) -> 'sel'::text");
    assert_raises(&pool, &sql_null, &[], &blocker_msg(&d, "->")).await
}

#[sqlx::test]
async fn containment_blocker_raises_on_eq_domain(pool: PgPool) -> Result<()> {
    // A native-jsonb CONTAINMENT operator (`@>`) must likewise hit the blocker
    // on a domain that does not support it (int4_eq carries only `hm`/equality).
    let d = int4(Variant::Eq);
    let sql = format!("SELECT ($1::jsonb::{d}) @> ($1::jsonb::{d})");
    assert_raises(&pool, &sql, &[Some(WELL_FORMED)], &blocker_msg(&d, "@>")).await?;
    // NULL operand: still raises (not STRICT).
    let sql_null = format!("SELECT (NULL::{d}) @> (NULL::{d})");
    assert_raises(&pool, &sql_null, &[], &blocker_msg(&d, "@>")).await
}

#[sqlx::test]
async fn ordering_is_deferred_on_timestamptz_eq(pool: PgPool) -> Result<()> {
    // timestamptz is equality-only: ordering is deferred until a wide-ORE
    // comparator lands (CHANGELOG / #241). Lock that in at the SQL boundary — an
    // ordering operator on `timestamptz_eq` must RAISE (and be non-STRICT), not
    // silently mis-order. There are no `timestamptz_ord` / `_ord_ore` domains.
    let d = ScalarDomainSpec::new::<chrono::DateTime<chrono::Utc>>(Variant::Eq).sql_domain;
    let sql = format!("SELECT (NULL::{d}) < (NULL::{d})");
    assert_raises(&pool, &sql, &[], &blocker_msg(&d, "<")).await
}

#[sqlx::test]
async fn every_eql_v3_blocker_is_non_strict_plpgsql(pool: PgPool) -> Result<()> {
    // The footgun guard, applied to EVERY generated blocker at once.
    //
    // Codegen emits a blocker for each native-jsonb operator a domain does NOT
    // support (`->`, `->>`, `@>`, `<@`, `||`, `?`, `?|`, `?&`, `@?`, `@@`, `#>`,
    // `#>>`, `-`, `#-`, plus the unsupported comparison ops) across every
    // eql_v3 scalar domain (storage / _eq / _ord / _ord_ore / _match). Each MUST
    // be `LANGUAGE plpgsql` and MUST NOT be `STRICT`:
    //   * a `STRICT` blocker is skipped on a NULL argument, silently returning
    //     NULL instead of raising — falling through to native jsonb semantics;
    //   * a `LANGUAGE sql` blocker is inlinable and the planner can elide the
    //     call (and its RAISE) when the result is provably unused.
    // The behavioural tests above prove the raise for representative operators
    // (`<`, `->`, `@>`); this proves the structural contract for the WHOLE set,
    // and against the *installed* catalog (catching build/install drift the
    // codegen golden test cannot see). Blockers are identified by their RAISE
    // body — the `'operator % is not supported for %'` message every blocker
    // carries and nothing else does.
    let (total, strict, non_plpgsql): (i64, i64, i64) = sqlx::query_as(
        r#"
        SELECT count(*),
               count(*) FILTER (WHERE p.proisstrict),
               count(*) FILTER (WHERE l.lanname <> 'plpgsql')
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v3'
          AND p.prosrc LIKE '%is not supported for %'
        "#,
    )
    .fetch_one(&pool)
    .await?;

    anyhow::ensure!(
        total > 0,
        "found no eql_v3 blocker functions — did the extension install?"
    );
    anyhow::ensure!(
        strict == 0,
        "{strict} of {total} eql_v3 blocker(s) are STRICT — a STRICT blocker is \
         elided on a NULL argument, bypassing the not-supported RAISE"
    );
    anyhow::ensure!(
        non_plpgsql == 0,
        "{non_plpgsql} of {total} eql_v3 blocker(s) are not LANGUAGE plpgsql — a \
         LANGUAGE sql blocker is inlinable and can be elided when the result is \
         provably unused"
    );
    Ok(())
}

#[sqlx::test]
async fn check_rejects_payload_missing_envelope(pool: PgPool) -> Result<()> {
    // The storage domain's CHECK requires the EQL envelope (`v`, `i`, `c`). A
    // payload missing the top-level ciphertext `c` must be rejected at the cast.
    let d = int4(Variant::Storage);
    let no_c = r#"{"v":2,"i":{"t":"edge","c":"payload"}}"#;
    let sql = format!("SELECT $1::jsonb::{d}");
    assert_raises(&pool, &sql, &[Some(no_c)], "violates check constraint").await
}

#[sqlx::test]
async fn check_rejects_payload_missing_hm(pool: PgPool) -> Result<()> {
    // The _eq domain CHECK requires `hm`. A payload without it must be rejected
    // at the cast with a CHECK-constraint violation (not some unrelated error).
    let d = int4(Variant::Eq);
    let no_hm = r#"{"v":2,"i":{"t":"edge","c":"payload"},"c":"AAAA","ob":["00"]}"#;
    let sql = format!("SELECT $1::jsonb::{d}");
    assert_raises(&pool, &sql, &[Some(no_hm)], "violates check constraint").await
}

#[sqlx::test]
async fn check_rejects_payload_missing_ob(pool: PgPool) -> Result<()> {
    // The _ord and _ord_ore domain CHECKs both require `ob`. A payload without
    // it must be rejected at the cast on either ordered twin.
    let no_ob = r#"{"v":2,"i":{"t":"edge","c":"payload"},"c":"AAAA","hm":"deadbeef"}"#;
    for variant in [Variant::Ord, Variant::OrdOre] {
        let d = int4(variant);
        let sql = format!("SELECT $1::jsonb::{d}");
        assert_raises(&pool, &sql, &[Some(no_ob)], "violates check constraint").await?;
    }
    Ok(())
}
