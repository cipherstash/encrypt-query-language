//! Synthetic test suite for `eql_v2_int4_eq` — HMAC equality only.
//!
//! `=` engages the functional btree on
//! `((eql_v2.hmac_256(col::jsonb)))` (EXPLAIN assertion).
//! `<>` is supported semantically but is seq-scan (btree only
//! supports equality, by design). All other operators raise.

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
async fn eq_engages_hmac_btree_for_equality(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_eq_table(&mut tx, &["aaa", "bbb", "ccc"]).await?;

    sqlx::query(
        "CREATE INDEX typed_int4_eq_hmac_idx \
         ON typed_int4_eq ((eql_v2.hmac_256(value::jsonb)))",
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
        plan_text.contains("typed_int4_eq_hmac_idx"),
        "= must engage the hmac btree; got plan:\n{plan_text}"
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
async fn eq_hmac_index_recipe_requires_jsonb_cast(pool: PgPool) -> Result<()> {
    // The documented _eq index recipe is
    //   USING btree ((eql_v2.hmac_256(col::jsonb)))
    // The ::jsonb cast is REQUIRED, not redundant. `eql_v2.hmac_256` is
    // both a function and an index-term type, and an eql_v2_int4_eq
    // column has no exact hmac_256 overload — so the bare form
    // `eql_v2.hmac_256(col)` parses as a cast to the hmac_256 type
    // (col::eql_v2.hmac_256), building an index the `=` predicate never
    // matches. This test pins both halves of that contract so the
    // docs/reference + v2.4.md U-001 recipe stays honest.
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

    // Footgun half: the bare eql_v2.hmac_256(value) form is a cast to the
    // hmac_256 type, not a function call — the index it builds cannot
    // serve the = predicate.
    sqlx::query("CREATE INDEX eq_idx_bare ON eq_idx USING btree (eql_v2.hmac_256(value))")
        .execute(&mut *tx)
        .await?;
    let bare_plan: Vec<String> = sqlx::query_scalar(&format!("EXPLAIN {eq_query}"))
        .fetch_all(&mut *tx)
        .await?;
    assert!(
        !bare_plan.join("\n").contains("eq_idx_bare"),
        "bare eql_v2.hmac_256(col) is a cast, not a call — must NOT serve = ; plan:\n{}",
        bare_plan.join("\n")
    );

    // Recipe half: the explicit ::jsonb cast resolves the
    // hmac_256(jsonb) function, and = engages the index.
    sqlx::query("CREATE INDEX eq_idx_hmac ON eq_idx USING btree ((eql_v2.hmac_256(value::jsonb)))")
        .execute(&mut *tx)
        .await?;
    let plan: Vec<String> = sqlx::query_scalar(&format!("EXPLAIN {eq_query}"))
        .fetch_all(&mut *tx)
        .await?;
    assert!(
        plan.join("\n").contains("eq_idx_hmac"),
        "the documented eql_v2.hmac_256(col::jsonb) recipe must engage for = ; plan:\n{}",
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
        "= via the hmac index must return the matching row"
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
