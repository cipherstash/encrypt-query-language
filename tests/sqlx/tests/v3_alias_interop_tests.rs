//! Native-spelling alias interop: an alias domain (e.g. `public.int4`) is a full
//! standalone encrypted type, and it interoperates with its canonical twin
//! (`public.integer`) in BOTH directions via generated cross-name operators —
//! never silently degrading to native jsonb comparison. See
//! docs/superpowers/specs/2026-07-07-encrypted-domain-aliases-design.md.

use anyhow::Result;
use sqlx::PgPool;
use sqlx::Row;

/// The alias domains exist and their CHECK is byte-identical to the canonical
/// (modulo the type-name substring — the generated CHECK body carries no type
/// name, so the two are identical in practice).
#[sqlx::test]
async fn alias_domains_exist_with_identical_check(pool: PgPool) -> Result<()> {
    for (canonical, alias) in [("integer", "int4"), ("bigint", "int8")] {
        for suffix in ["", "_eq", "_ord", "_ord_ore", "_ord_ope"] {
            let cdom = format!("{canonical}{suffix}");
            let adom = format!("{alias}{suffix}");
            let row = sqlx::query(
                r#"
                SELECT
                  (SELECT pg_get_constraintdef(c.oid)
                     FROM pg_constraint c JOIN pg_type t ON t.oid = c.contypid
                     JOIN pg_namespace n ON n.oid = t.typnamespace
                    WHERE n.nspname='public' AND t.typname=$1 LIMIT 1) AS canon_check,
                  (SELECT pg_get_constraintdef(c.oid)
                     FROM pg_constraint c JOIN pg_type t ON t.oid = c.contypid
                     JOIN pg_namespace n ON n.oid = t.typnamespace
                    WHERE n.nspname='public' AND t.typname=$2 LIMIT 1) AS alias_check
                "#,
            )
            .bind(&cdom)
            .bind(&adom)
            .fetch_one(&pool)
            .await?;
            let canon: Option<String> = row.get("canon_check");
            let alias_c: Option<String> = row.get("alias_check");
            assert!(alias_c.is_some(), "alias domain public.{adom} missing");
            // Same CHECK modulo the type name substring.
            assert_eq!(
                canon.map(|s| s.replace(canonical, "T")),
                alias_c.map(|s| s.replace(alias, "T")),
                "CHECK mismatch for {adom} vs {cdom}"
            );
        }
    }
    Ok(())
}

/// [fix R5] Every SUPPORTED cross op is backed by the PUBLIC wrapper (eql_v3),
/// and every UNSUPPORTED cross op is backed by an INTERNAL blocker
/// (eql_v3_internal) — both directions, across roles. This is the per-role
/// supported/blocker split the feature introduces; the existing
/// `v3_operator_equivalents_tests` gate filters on operand schema `eql_v3` and
/// alias/canonical domains live in `public`, so it does NOT cover these.
#[sqlx::test]
async fn cross_name_operators_split_public_wrapper_vs_internal_blocker(pool: PgPool) -> Result<()> {
    // (op, left_domain, right_domain, expected backing schema)
    let cases: &[(&str, &str, &str, &str)] = &[
        // _eq role: = and <> supported (public); < is a blocker (internal).
        ("=", "int4_eq", "integer_eq", "eql_v3"),
        ("=", "integer_eq", "int4_eq", "eql_v3"),
        ("<>", "int4_eq", "integer_eq", "eql_v3"),
        ("<", "int4_eq", "integer_eq", "eql_v3_internal"),
        // _ord role: < <= > >= supported (public), both directions.
        ("<", "int4_ord", "integer_ord", "eql_v3"),
        ("<", "integer_ord", "int4_ord", "eql_v3"),
        (">=", "int4_ord", "integer_ord", "eql_v3"),
    ];
    for (op, lt, rt, schema) in cases {
        let n: i64 = sqlx::query_scalar(
            r#"
            SELECT count(*)
            FROM pg_operator o
            JOIN pg_proc p ON p.oid = o.oprcode
            JOIN pg_namespace pn ON pn.oid = p.pronamespace
            JOIN pg_type lt ON lt.oid = o.oprleft
            JOIN pg_type rt ON rt.oid = o.oprright
            WHERE o.oprname = $1 AND pn.nspname = $2
              AND lt.typname = $3 AND rt.typname = $4
            "#,
        )
        .bind(op)
        .bind(schema)
        .bind(lt)
        .bind(rt)
        .fetch_one(&pool)
        .await?;
        assert_eq!(n, 1, "cross op {op} {lt}->{rt} not backed by {schema}");
    }
    Ok(())
}

/// Behavioural [fix R2]: comparing an int4-typed value to an integer-typed value
/// routes through the hmac wrapper, NOT native jsonb. Two encryptions of the SAME
/// plaintext (same `hm`, different `c`) must compare EQUAL — native jsonb `=`
/// would say not-equal (distinct `c`). This is the core silent-jsonb regression
/// guard (spec §2.3). Uses the `eql_v3_integer_doubles` fixture (equal-plaintext /
/// distinct-ciphertext rows); the `eql_v3_integer` matrix fixture has unique
/// plaintexts by construction and cannot exercise this.
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v3_integer_doubles")))]
async fn cross_name_equality_uses_hmac_not_jsonb(pool: PgPool) -> Result<()> {
    // Two rows: same decrypted plaintext, DIFFERENT payload (distinct c).
    let row = sqlx::query(
        r#"
        SELECT a.payload AS pa, b.payload AS pb
        FROM fixtures.eql_v3_integer_doubles a
        JOIN fixtures.eql_v3_integer_doubles b
          ON a.plaintext = b.plaintext AND a.payload <> b.payload
        LIMIT 1
        "#,
    )
    .fetch_one(&pool)
    .await?;
    let pa: serde_json::Value = row.get("pa");
    let pb: serde_json::Value = row.get("pb");

    // Bind A as int4_eq, B as integer_eq — cross-name equality.
    let equal: bool =
        sqlx::query_scalar(r#"SELECT ($1::jsonb::public.int4_eq) = ($2::jsonb::public.integer_eq)"#)
            .bind(&pa)
            .bind(&pb)
            .fetch_one(&pool)
            .await?;
    assert!(
        equal,
        "cross-name equality must route hmac (equal), not jsonb (distinct c)"
    );

    // And the reverse direction must route hmac too.
    let equal_rev: bool =
        sqlx::query_scalar(r#"SELECT ($1::jsonb::public.integer_eq) = ($2::jsonb::public.int4_eq)"#)
            .bind(&pa)
            .bind(&pb)
            .fetch_one(&pool)
            .await?;
    assert!(equal_rev, "reverse cross-name equality must also route hmac");
    Ok(())
}

/// An unsupported cross-name operator raises (the internal blocker), never
/// returns a native jsonb result. The payload is CHECK-valid (`v`,`i`,`c`,`hm`
/// present, `v`='3') so the cast succeeds and the failure is the OPERATOR
/// blocker, not a domain CHECK violation.
#[sqlx::test]
async fn unsupported_cross_name_op_raises(pool: PgPool) -> Result<()> {
    let err = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT ('{"v":3,"i":{},"c":"x","hm":"a"}'::jsonb::public.int4_eq)
             < ('{"v":3,"i":{},"c":"y","hm":"a"}'::jsonb::public.integer_eq)
        "#,
    )
    .fetch_one(&pool)
    .await
    .unwrap_err();
    let msg = err.to_string();
    assert!(
        msg.contains("not supported"),
        "expected blocker RAISE, got: {msg}"
    );
    Ok(())
}
