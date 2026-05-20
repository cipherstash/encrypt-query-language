//! Smoke + drift-detection suite for the default `eql_v2_int4` variant.
//!
//! `eql_v2_int4` is a line-for-line duplicate of `_ord_ore` with a
//! different domain identifier. The INLINEABLE_DOMAIN_FUNCTIONS test
//! detects structural drift (SQL + IMMUTABLE + no proconfig);
//! `default_matches_ord_ore_explain` here detects behavioural drift
//! by comparing the normalised EXPLAIN output for parallel queries
//! word-for-word.

use anyhow::Result;
use sqlx::PgPool;

const SAMPLE: &str = r#"{"v":2,"i":{"t":"t","c":"c"},"c":"x","hm":"aa","ob":["bb"]}"#;

/// Normalise an EXPLAIN plan string so two variants' plans can be
/// compared structurally. Strips the cost / row segment (which fluctuates
/// with stats), then collapses table/index/variant identifiers that are
/// expected to differ between the two variants.
fn normalise_plan(plan: &[String], table: &str, idx: &str, variant: &str) -> Vec<String> {
    plan.iter()
        .map(|line| {
            // The cost segment is always shaped `(cost=N..M rows=N width=N)`
            // at the end of a node line. Drop it entirely.
            let no_cost = if let Some(start) = line.rfind("  (cost=") {
                line[..start].to_string()
            } else if let Some(start) = line.rfind("(cost=") {
                line[..start].trim_end().to_string()
            } else {
                line.clone()
            };
            let s = no_cost.replace(idx, "{IDX}");
            let s = s.replace(table, "{TABLE}");
            // Variant is replaced last because `eql_v2_int4_ord_ore`
            // contains `eql_v2_int4` as a prefix — replacing the default
            // identifier first would also chew the _ord_ore name.
            s.replace(variant, "{VARIANT}")
        })
        .collect()
}

#[sqlx::test]
async fn default_accepts_payload_and_supports_equality(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE t_default (id integer GENERATED ALWAYS AS IDENTITY, value eql_v2_int4) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("INSERT INTO t_default(value) VALUES ($1::jsonb::eql_v2_int4)")
        .bind(SAMPLE)
        .execute(&mut *tx)
        .await?;

    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM t_default WHERE value = $1::jsonb::eql_v2_int4")
            .bind(SAMPLE)
            .fetch_one(&mut *tx)
            .await?;
    assert_eq!(count, 1);

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn default_matches_ord_ore_explain(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query("CREATE TEMP TABLE t_default (id integer GENERATED ALWAYS AS IDENTITY, value eql_v2_int4) ON COMMIT DROP")
        .execute(&mut *tx).await?;
    sqlx::query("CREATE TEMP TABLE t_ore (id integer GENERATED ALWAYS AS IDENTITY, value eql_v2_int4_ord_ore) ON COMMIT DROP")
        .execute(&mut *tx).await?;
    sqlx::query("INSERT INTO t_default(value) VALUES ($1::jsonb::eql_v2_int4)")
        .bind(SAMPLE)
        .execute(&mut *tx)
        .await?;
    sqlx::query("INSERT INTO t_ore(value) VALUES ($1::jsonb::eql_v2_int4_ord_ore)")
        .bind(SAMPLE)
        .execute(&mut *tx)
        .await?;

    sqlx::query("CREATE INDEX t_default_hmac_idx ON t_default ((eql_v2.hmac_256(value::jsonb)))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("CREATE INDEX t_ore_hmac_idx ON t_ore ((eql_v2.hmac_256(value::jsonb)))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE t_default").execute(&mut *tx).await?;
    sqlx::query("ANALYZE t_ore").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let default_plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM t_default WHERE value = '{}'::jsonb::eql_v2_int4",
        SAMPLE.replace('\'', "''")
    ))
    .fetch_all(&mut *tx)
    .await?;
    let ore_plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM t_ore WHERE value = '{}'::jsonb::eql_v2_int4_ord_ore",
        SAMPLE.replace('\'', "''")
    ))
    .fetch_all(&mut *tx)
    .await?;

    // Both plans should still pick the hmac functional btree.
    assert!(
        default_plan.iter().any(|r| r.contains("Index Scan")),
        "default plan must use Index Scan: {default_plan:?}"
    );
    assert!(
        ore_plan.iter().any(|r| r.contains("Index Scan")),
        "ord_ore plan must use Index Scan: {ore_plan:?}"
    );

    // Strict drift check: after normalising away the table/index/variant
    // identifiers and the per-stats cost numbers, the two plans must be
    // byte-identical. A divergence in operator routing, inlined function,
    // or indexed expression that *also* still produces an Index Scan
    // would show up here.
    let normalised_default = normalise_plan(
        &default_plan,
        "t_default",
        "t_default_hmac_idx",
        "eql_v2_int4",
    );
    let normalised_ore =
        normalise_plan(&ore_plan, "t_ore", "t_ore_hmac_idx", "eql_v2_int4_ord_ore");
    assert_eq!(
        normalised_default, normalised_ore,
        "default and _ord_ore EXPLAIN plans diverge structurally; \
         default:\n{normalised_default:#?}\n_ord_ore:\n{normalised_ore:#?}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn default_unsupported_operators_raise(pool: PgPool) -> Result<()> {
    // Default variant must reject the same operators _ord_ore rejects.
    // Without this sweep, the default's blocker coverage rides entirely
    // on "structural duplicate" trust — this catches re-routed blockers
    // (e.g. a future refactor that accidentally points one of these to
    // the encrypted base operator).
    let shapes: &[(&str, &str)] = &[
        ("$1::jsonb::eql_v2_int4", "$2::jsonb::eql_v2_int4"),
        ("$1::jsonb::eql_v2_int4", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::eql_v2_int4"),
    ];

    for op in ["~~", "~~*", "@>", "<@"] {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query(&sql)
                .bind(SAMPLE)
                .bind(SAMPLE)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4 {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4");
            assert!(
                err.contains(&expected),
                "blocker error mismatch: {sql} -> {err}"
            );
        }
    }

    for op in ["->", "->>"] {
        for sql in [
            format!("SELECT $1::jsonb::eql_v2_int4 {op} 'field'::text"),
            format!("SELECT $1::jsonb::eql_v2_int4 {op} 0::integer"),
            format!("SELECT $1::jsonb {op} $1::jsonb::eql_v2_int4"),
        ] {
            let err = sqlx::query(&sql)
                .bind(SAMPLE)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4 {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4");
            assert!(
                err.contains(&expected),
                "path-op blocker error mismatch: {sql} -> {err}"
            );
        }
    }

    Ok(())
}

#[sqlx::test]
async fn default_opclass_indexes_range(pool: PgPool) -> Result<()> {
    // The default eql_v2_int4 variant mirrors _ord_ore: range queries
    // are served by its btree operator class
    // (eql_v2.eql_v2_int4_operator_class), which must be named
    // explicitly in CREATE INDEX (a bare USING btree (col) resolves to
    // jsonb_ops via the domain's base type).
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE int4_oc (\
             plaintext integer, \
             value eql_v2_int4\
         ) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO int4_oc(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4 FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "CREATE INDEX int4_oc_idx ON int4_oc \
         USING btree (value eql_v2.eql_v2_int4_operator_class)",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE int4_oc").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 10",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    for op in ["<", "<=", ">", ">="] {
        let plan: Vec<String> = sqlx::query_scalar(&format!(
            "EXPLAIN SELECT * FROM int4_oc WHERE value {op} '{lit}'::jsonb::eql_v2_int4"
        ))
        .fetch_all(&mut *tx)
        .await?;
        let plan_text = plan.join("\n");
        assert!(
            plan_text.contains("int4_oc_idx"),
            "{op} must engage the eql_v2_int4 opclass btree index; plan:\n{plan_text}"
        );
    }

    // Correctness: < 10 returns the five fixture values below 10.
    let mut ids: Vec<i32> = sqlx::query_scalar(&format!(
        "SELECT plaintext FROM int4_oc WHERE value < '{lit}'::jsonb::eql_v2_int4"
    ))
    .fetch_all(&mut *tx)
    .await?;
    ids.sort();
    assert_eq!(ids, vec![-100, -1, 1, 2, 5], "< 10 via opclass index");

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn default_blocked_operators_raise_on_null_input(pool: PgPool) -> Result<()> {
    // A blocker declared STRICT lets PostgreSQL skip the body and return
    // NULL on a NULL argument, silently bypassing the
    // "operator … is not supported" exception. The blocker contract is
    // "always raises" — guard against STRICT regressing back in.
    let null: Option<&str> = None;

    let err = sqlx::query("SELECT $1::jsonb::eql_v2_int4 ~~ $2::jsonb::eql_v2_int4")
        .bind(null)
        .bind(null)
        .fetch_one(&pool)
        .await
        .expect_err("eql_v2_int4 ~~ must raise on NULL input")
        .to_string();
    assert!(
        err.contains("operator ~~ is not supported for eql_v2_int4"),
        "unexpected error for ~~ on NULL: {err}"
    );

    let err = sqlx::query("SELECT $1::jsonb -> $2::jsonb::eql_v2_int4")
        .bind(null)
        .bind(null)
        .fetch_one(&pool)
        .await
        .expect_err("eql_v2_int4 -> must raise on NULL input")
        .to_string();
    assert!(
        err.contains("operator -> is not supported for eql_v2_int4"),
        "unexpected error for -> on NULL: {err}"
    );
    Ok(())
}
