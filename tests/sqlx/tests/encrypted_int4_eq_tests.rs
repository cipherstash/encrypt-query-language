//! Synthetic test suite for `eql_v2_int4_eq` — HMAC equality only.
//!
//! `=` engages the functional btree on
//! `((eql_v2.hmac_256(col::jsonb)))` (EXPLAIN assertion).
//! `<>` is supported semantically but is seq-scan (btree only
//! supports equality, by design). All other operators raise.

use anyhow::Result;
use sqlx::PgPool;

fn payload(hm: &str) -> String {
    format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"int_col"}},"c":"ct-{hm}","hm":"{hm}"}}"#
    )
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
        sqlx::query(
            "INSERT INTO typed_int4_eq(value) VALUES ($1::jsonb::eql_v2_int4_eq)",
        )
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
    sqlx::query("ANALYZE typed_int4_eq").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off").execute(&mut *tx).await?;

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
        format!("SELECT count(*) FROM typed_int4_eq WHERE value = '{}'::jsonb::eql_v2_int4_eq", needle),
        format!("SELECT count(*) FROM typed_int4_eq WHERE value = '{}'::jsonb", needle),
        format!("SELECT count(*) FROM typed_int4_eq WHERE '{}'::jsonb = value", needle),
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
            format!("SELECT $1::jsonb {op} $2::jsonb::eql_v2_int4_eq"),
        ] {
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
    Ok(())
}
