//! Synthetic test suite for `eql_v2_int4_eq` — HMAC equality only.
//!
//! `=` engages a functional index on `eql_v2.eq_term(col)` — hash or
//! btree (EXPLAIN assertion). `<>` is supported semantically but is
//! seq-scan (no index serves inequality). All other operators raise.

use anyhow::Result;
use sqlx::PgPool;

fn payload(hm: &str) -> String {
    format!(r#"{{"v":2,"i":{{"t":"typed","c":"int_col"}},"c":"ct-{hm}","hm":"{hm}"}}"#)
}

async fn setup_eq_table(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    hmacs: &[&str],
) -> Result<()> {
    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_int4_eq (
            id integer GENERATED ALWAYS AS IDENTITY,
            value eql_v2_int4_eq
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut **tx)
    .await?;

    for hm in hmacs {
        sqlx::query("INSERT INTO typed_int4_eq(value) VALUES ($1::jsonb::eql_v2_int4_eq)")
            .bind(payload(hm))
            .execute(&mut **tx)
            .await?;
    }
    Ok(())
}

#[sqlx::test]
async fn eq_engages_btree_for_equality(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_eq_table(&mut tx, &["aaa", "bbb", "ccc"]).await?;

    sqlx::query(
        "CREATE INDEX typed_int4_eq_btree_idx \
         ON typed_int4_eq USING btree (eql_v2.eq_term(value))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_int4_eq")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let needle = payload("bbb");
    let plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM typed_int4_eq WHERE value = '{}'::jsonb::eql_v2_int4_eq",
        needle
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan_text = plan.join("\n");
    assert!(
        plan_text.contains("typed_int4_eq_btree_idx"),
        "= must engage the eql_v2.eq_term btree index; got plan:\n{plan_text}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn eq_neq_returns_correct_rows(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_eq_table(&mut tx, &["aaa", "bbb", "ccc"]).await?;

    let count: i64 = sqlx::query_scalar(&format!(
        "SELECT count(*) FROM typed_int4_eq WHERE value = '{}'::jsonb::eql_v2_int4_eq",
        payload("bbb")
    ))
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(count, 1, "= must match exactly one row");

    let count: i64 = sqlx::query_scalar(&format!(
        "SELECT count(*) FROM typed_int4_eq WHERE value <> '{}'::jsonb::eql_v2_int4_eq",
        payload("bbb")
    ))
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(count, 2, "<> must match the other two rows");

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn eq_cross_type_shapes_for_equality(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_eq_table(&mut tx, &["aaa", "bbb"]).await?;
    let needle = payload("bbb");

    for sql in [
        format!(
            "SELECT count(*) FROM typed_int4_eq WHERE value = '{}'::jsonb::eql_v2_int4_eq",
            needle
        ),
        format!(
            "SELECT count(*) FROM typed_int4_eq WHERE value = '{}'::jsonb",
            needle
        ),
        format!(
            "SELECT count(*) FROM typed_int4_eq WHERE '{}'::jsonb = value",
            needle
        ),
    ] {
        let count: i64 = sqlx::query_scalar(&sql).fetch_one(&mut *tx).await?;
        assert_eq!(count, 1, "= shape must match one row; sql: {sql}");
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn eq_unsupported_operators_raise(pool: PgPool) -> Result<()> {
    let sample = payload("aaa");
    let shapes: &[(&str, &str)] = &[
        ("$1::jsonb::eql_v2_int4_eq", "$2::jsonb::eql_v2_int4_eq"),
        ("$1::jsonb::eql_v2_int4_eq", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::eql_v2_int4_eq"),
    ];
    for op in ["<", "<=", ">", ">=", "~~", "~~*", "@>", "<@"] {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query(&sql)
                .bind(&sample)
                .bind(&sample)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_eq {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4_eq");
            assert!(err.contains(&expected), "unexpected: {sql} → {err}");
        }
    }

    for op in ["->", "->>"] {
        for sql in [
            format!("SELECT $1::jsonb::eql_v2_int4_eq {op} 'field'::text"),
            format!("SELECT $1::jsonb::eql_v2_int4_eq {op} 0::integer"),
            format!("SELECT $1::jsonb {op} $1::jsonb::eql_v2_int4_eq"),
        ] {
            let err = sqlx::query(&sql)
                .bind(&sample)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_eq {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4_eq");
            assert!(err.contains(&expected), "unexpected: {sql} → {err}");
        }
    }
    Ok(())
}

#[sqlx::test]
async fn eq_blocked_operators_raise_on_null_input(pool: PgPool) -> Result<()> {
    // A blocker declared STRICT lets PostgreSQL skip the body and return
    // NULL on a NULL argument, silently bypassing the
    // "operator … is not supported" exception. The blocker contract is
    // "always raises" — guard against STRICT regressing back in.
    let null: Option<&str> = None;

    let err = sqlx::query("SELECT $1::jsonb::eql_v2_int4_eq < $2::jsonb::eql_v2_int4_eq")
        .bind(null)
        .bind(null)
        .fetch_one(&pool)
        .await
        .expect_err("eql_v2_int4_eq < must raise on NULL input")
        .to_string();
    assert!(
        err.contains("operator < is not supported for eql_v2_int4_eq"),
        "unexpected error for < on NULL: {err}"
    );

    let err = sqlx::query("SELECT $1::jsonb -> $2::jsonb::eql_v2_int4_eq")
        .bind(null)
        .bind(null)
        .fetch_one(&pool)
        .await
        .expect_err("eql_v2_int4_eq -> must raise on NULL input")
        .to_string();
    assert!(
        err.contains("operator -> is not supported for eql_v2_int4_eq"),
        "unexpected error for -> on NULL: {err}"
    );
    Ok(())
}

#[sqlx::test]
async fn eq_engages_hash_for_equality(pool: PgPool) -> Result<()> {
    // `eql_v2.eq_term(col)` extracts the HMAC equality term — a domain
    // over `text`, which carries a default hash operator class. A hash
    // functional index on it engages `=` (btree does too — see
    // eq_engages_btree_for_equality). No `::jsonb` cast: `eql_v2.eq_term`
    // is a plain function name with no colliding type.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE eq_idx (plaintext integer, value eql_v2_int4_eq) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO eq_idx(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_eq FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX eq_idx_hash ON eq_idx USING hash (eql_v2.eq_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE eq_idx").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");
    let eq_query = format!("SELECT * FROM eq_idx WHERE value = '{lit}'::jsonb::eql_v2_int4_eq");

    let plan: Vec<String> = sqlx::query_scalar(&format!("EXPLAIN {eq_query}"))
        .fetch_all(&mut *tx)
        .await?;
    assert!(
        plan.join("\n").contains("eq_idx_hash"),
        "the eql_v2.eq_term hash recipe must engage for = ; plan:\n{}",
        plan.join("\n")
    );

    let ids: Vec<i32> = sqlx::query_scalar(&format!(
        "SELECT plaintext FROM eq_idx WHERE value = '{lit}'::jsonb::eql_v2_int4_eq"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(
        ids,
        vec![42],
        "= via the eq_term hash index must return the matching row"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn eq_null_operand_yields_null(pool: PgPool) -> Result<()> {
    // STRICT equality wrappers: a NULL operand propagates NULL.
    let null: Option<&str> = None;
    let sample = r#"{"v":2,"i":{"t":"t","c":"c"},"c":"x","hm":"aa"}"#;
    for op in ["=", "<>"] {
        let result: Option<bool> = sqlx::query_scalar(&format!(
            "SELECT $1::jsonb::eql_v2_int4_eq {op} $2::jsonb::eql_v2_int4_eq"
        ))
        .bind(sample)
        .bind(null)
        .fetch_one(&pool)
        .await?;
        assert!(result.is_none(), "{op} with NULL operand must yield NULL");
    }
    Ok(())
}

#[sqlx::test]
async fn eq_engages_btree_constant_on_left(pool: PgPool) -> Result<()> {
    // The functional btree must engage when the literal is on the LEFT
    // (`$1 = col`) as well as the right — the commuted shape ORMs and
    // PostgREST emit. `=` is its own commutator.
    let mut tx = pool.begin().await?;
    setup_eq_table(&mut tx, &["aaa", "bbb", "ccc"]).await?;

    sqlx::query(
        "CREATE INDEX typed_int4_eq_cl_idx \
         ON typed_int4_eq USING btree (eql_v2.eq_term(value))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_int4_eq")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let needle = payload("bbb");
    for sql in [
        format!(
            "EXPLAIN SELECT * FROM typed_int4_eq \
             WHERE '{needle}'::jsonb::eql_v2_int4_eq = value"
        ),
        format!("EXPLAIN SELECT * FROM typed_int4_eq WHERE '{needle}'::jsonb = value"),
    ] {
        let plan: Vec<String> = sqlx::query_scalar(&sql).fetch_all(&mut *tx).await?;
        let plan_text = plan.join("\n");
        assert!(
            plan_text.contains("typed_int4_eq_cl_idx"),
            "constant-on-left = must engage the eql_v2.eq_term btree; \
             sql: {sql}\nplan:\n{plan_text}"
        );
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn eq_operators_declare_planner_metadata(pool: PgPool) -> Result<()> {
    // The real = / <> operators on eql_v2_int4_eq must declare
    // COMMUTATOR, NEGATOR, and selectivity estimators (RESTRICT / JOIN)
    // on all three arg-shapes, so the planner can normalise and cost
    // commuted and negated predicates.
    let rows: Vec<(String, String, String, bool, bool, bool, bool)> = sqlx::query_as(
        r#"
        SELECT o.oprname,
               lt.typname AS lhs,
               rt.typname AS rhs,
               o.oprcom <> 0       AS has_commutator,
               o.oprnegate <> 0    AS has_negator,
               o.oprrest::oid <> 0 AS has_restrict,
               o.oprjoin::oid <> 0 AS has_join
        FROM pg_catalog.pg_operator o
        JOIN pg_catalog.pg_type lt ON lt.oid = o.oprleft
        JOIN pg_catalog.pg_type rt ON rt.oid = o.oprright
        WHERE o.oprname IN ('=', '<>')
          AND (lt.typname = 'eql_v2_int4_eq' OR rt.typname = 'eql_v2_int4_eq')
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert_eq!(
        rows.len(),
        6,
        "expected = and <> x 3 arg-shapes on eql_v2_int4_eq"
    );
    for (op, lhs, rhs, has_com, has_neg, has_rest, has_join) in &rows {
        assert!(
            has_com,
            "operator {op}({lhs},{rhs}) must declare COMMUTATOR"
        );
        assert!(has_neg, "operator {op}({lhs},{rhs}) must declare NEGATOR");
        assert!(has_rest, "operator {op}({lhs},{rhs}) must declare RESTRICT");
        assert!(has_join, "operator {op}({lhs},{rhs}) must declare JOIN");
    }
    Ok(())
}

#[sqlx::test]
async fn eq_wrappers_are_inlinable(pool: PgPool) -> Result<()> {
    // The = / <> wrappers on eql_v2_int4_eq must be LANGUAGE sql,
    // IMMUTABLE, and carry no pinned search_path, so the planner inlines
    // `col = $1` to `eql_v2.eq_term(col) = eql_v2.eq_term($1)` and the
    // functional index on eql_v2.eq_term(col) engages. A pinned
    // proconfig or a plpgsql body would break the inline chain.
    let rows: Vec<(String, String, String, Option<Vec<String>>)> = sqlx::query_as(
        r#"
        SELECT p.proname, l.lanname, p.provolatile::text, p.proconfig
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        JOIN pg_catalog.pg_type lt ON lt.oid = p.proargtypes[0]
        JOIN pg_catalog.pg_type rt ON rt.oid = p.proargtypes[1]
        WHERE n.nspname = 'eql_v2'
          AND p.proname IN ('eq', 'neq')
          AND (lt.typname = 'eql_v2_int4_eq' OR rt.typname = 'eql_v2_int4_eq')
        "#,
    )
    .fetch_all(&pool)
    .await?;

    // 2 wrapper names x 3 arg-shapes = 6 rows.
    assert_eq!(rows.len(), 6, "expected 6 equality wrapper overloads");
    for (name, lang, volatile, config) in &rows {
        assert_eq!(lang, "sql", "{name} must be LANGUAGE sql to inline");
        assert_eq!(volatile, "i", "{name} must be IMMUTABLE");
        assert!(
            config.is_none(),
            "{name} must have no pinned search_path (proconfig)"
        );
    }

    // The eql_v2.eq_term index extractor must be IMMUTABLE — a
    // functional index expression requires it.
    let eq_term: Vec<(String, String, Option<Vec<String>>)> = sqlx::query_as(
        r#"
        SELECT l.lanname, p.provolatile::text, p.proconfig
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v2' AND p.proname = 'eq_term'
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(!eq_term.is_empty(), "eql_v2.eq_term must exist");
    for (lang, volatile, config) in &eq_term {
        assert_eq!(volatile, "i", "eql_v2.eq_term must be IMMUTABLE");
        if lang == "sql" {
            assert!(
                config.is_none(),
                "a LANGUAGE sql eql_v2.eq_term must have no pinned search_path"
            );
        }
    }
    Ok(())
}

#[sqlx::test]
async fn eq_btree_index_preferred_at_scale(pool: PgPool) -> Result<()> {
    // The other EXPLAIN tests force `enable_seqscan = off`, proving the
    // index is *usable*. This test proves the planner *prefers* it: at
    // ~5000 rows with a highly selective `=` predicate, the functional
    // btree must be chosen with seqscan left enabled.
    let mut tx = pool.begin().await?;
    sqlx::query("CREATE TEMP TABLE eq_scale (value eql_v2_int4_eq) ON COMMIT DROP")
        .execute(&mut *tx)
        .await?;

    let filler = payload("filler");
    let pivot = payload("pivot");
    sqlx::query(
        "INSERT INTO eq_scale(value) \
         SELECT $1::jsonb::eql_v2_int4_eq FROM generate_series(1, 5000)",
    )
    .bind(&filler)
    .execute(&mut *tx)
    .await?;
    sqlx::query("INSERT INTO eq_scale(value) VALUES ($1::jsonb::eql_v2_int4_eq)")
        .bind(&pivot)
        .execute(&mut *tx)
        .await?;
    sqlx::query("CREATE INDEX eq_scale_idx ON eq_scale USING btree (eql_v2.eq_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE eq_scale").execute(&mut *tx).await?;

    let plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM eq_scale WHERE value = '{pivot}'::jsonb::eql_v2_int4_eq"
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan_text = plan.join("\n");
    assert!(
        plan_text.contains("eq_scale_idx"),
        "with seqscan enabled the planner must prefer the eql_v2.eq_term \
         btree for a selective = ; plan:\n{plan_text}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn eq_rejects_payload_missing_required_keys(pool: PgPool) -> Result<()> {
    // The eql_v2_int4_eq domain CHECK requires v, i, c, hm. A payload
    // missing any required key is rejected at the cast.
    for (label, json) in [
        ("missing hm", r#"{"v":2,"i":{"t":"t","c":"c"},"c":"x"}"#),
        ("missing c", r#"{"v":2,"i":{"t":"t","c":"c"},"hm":"aa"}"#),
    ] {
        let err = sqlx::query(&format!("SELECT '{json}'::jsonb::eql_v2_int4_eq"))
            .fetch_one(&pool)
            .await
            .expect_err(&format!("eql_v2_int4_eq must reject payload: {label}"))
            .to_string();
        assert!(
            err.contains("violates check constraint"),
            "{label}: expected a check-constraint violation, got: {err}"
        );
    }
    Ok(())
}
