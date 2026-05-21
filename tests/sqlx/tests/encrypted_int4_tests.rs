//! Synthetic test suite for `eql_v2_int4` — the storage-only variant.
//!
//! Every operator is a blocker that raises
//! `operator X is not supported for eql_v2_int4`. No fixture data is
//! needed; operator-on-literals is sufficient.

use anyhow::Result;
use sqlx::PgPool;

const SAMPLE_PAYLOAD: &str = r#"{"v":2,"i":{"t":"t","c":"c"},"c":"sample"}"#;

#[sqlx::test]
async fn all_symmetric_operators_raise(pool: PgPool) -> Result<()> {
    let shapes: &[(&str, &str)] = &[
        ("$1::jsonb::eql_v2_int4", "$2::jsonb::eql_v2_int4"),
        ("$1::jsonb::eql_v2_int4", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::eql_v2_int4"),
    ];

    for op in ["=", "<>", "<", "<=", ">", ">=", "@>", "<@"] {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query(&sql)
                .bind(SAMPLE_PAYLOAD)
                .bind(SAMPLE_PAYLOAD)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4 {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4");
            assert!(
                err.contains(&expected),
                "unexpected error for {sql}: got {err}, want {expected}"
            );
        }
    }
    Ok(())
}

#[sqlx::test]
async fn path_operators_raise(pool: PgPool) -> Result<()> {
    for op in ["->", "->>"] {
        for sql in [
            format!("SELECT $1::jsonb::eql_v2_int4 {op} 'field'::text"),
            format!("SELECT $1::jsonb::eql_v2_int4 {op} 0::integer"),
            format!("SELECT $1::jsonb {op} $1::jsonb::eql_v2_int4"),
        ] {
            let err = sqlx::query(&sql)
                .bind(SAMPLE_PAYLOAD)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4 {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4");
            assert!(err.contains(&expected), "unexpected error for {sql}: {err}");
        }
    }
    Ok(())
}

#[sqlx::test]
async fn like_operators_are_not_declared(pool: PgPool) -> Result<()> {
    // EQL no longer declares ~~ / ~~* (LIKE / ILIKE) on the int4 domains —
    // int4 has no pattern-match capability. With the operators removed,
    // `col ~~ x` raises PostgreSQL's native "operator does not exist"
    // rather than an EQL blocker message. Pin that they stay gone.
    for op in ["~~", "~~*"] {
        let sql = format!("SELECT $1::jsonb::eql_v2_int4 {op} $2::jsonb::eql_v2_int4");
        let err = sqlx::query(&sql)
            .bind(SAMPLE_PAYLOAD)
            .bind(SAMPLE_PAYLOAD)
            .fetch_one(&pool)
            .await
            .expect_err(&format!("eql_v2_int4 {op} must not resolve: {sql}"))
            .to_string();
        assert!(
            err.contains("operator does not exist"),
            "expected native 'operator does not exist' for {op}: {err}"
        );
    }
    Ok(())
}

#[sqlx::test]
async fn blockers_raise_on_typed_column(pool: PgPool) -> Result<()> {
    // The other tests exercise blockers on cast literals
    // ($1::jsonb::eql_v2_int4). This pins that the blockers also engage
    // when the operand is a genuine eql_v2_int4-typed table column, the
    // shape a real caller writes (`WHERE col = col`).
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_int4 (
            id integer GENERATED ALWAYS AS IDENTITY,
            value eql_v2_int4
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("INSERT INTO typed_int4(value) VALUES ($1::jsonb::eql_v2_int4)")
        .bind(SAMPLE_PAYLOAD)
        .execute(&mut *tx)
        .await?;

    for op in ["=", "<>", "<", "<=", ">", ">=", "@>", "<@"] {
        // A raised blocker aborts the transaction; wrap each probe in a
        // savepoint so the next operator can be checked after rollback.
        sqlx::query("SAVEPOINT op_probe").execute(&mut *tx).await?;
        let sql = format!("SELECT * FROM typed_int4 WHERE value {op} value");
        let err = sqlx::query(&sql)
            .fetch_all(&mut *tx)
            .await
            .expect_err(&format!("eql_v2_int4 column {op} must raise: {sql}"))
            .to_string();
        let expected = format!("operator {op} is not supported for eql_v2_int4");
        assert!(
            err.contains(&expected),
            "unexpected error for {sql}: got {err}, want {expected}"
        );
        sqlx::query("ROLLBACK TO SAVEPOINT op_probe")
            .execute(&mut *tx)
            .await?;
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn blocked_operators_raise_on_null_input(pool: PgPool) -> Result<()> {
    // A blocker declared STRICT lets PostgreSQL skip the body and return
    // NULL on a NULL argument, silently bypassing the
    // "operator … is not supported" exception. The blocker contract is
    // "always raises" — guard against STRICT regressing back in.
    let null: Option<&str> = None;

    let err = sqlx::query("SELECT $1::jsonb::eql_v2_int4 = $2::jsonb::eql_v2_int4")
        .bind(null)
        .bind(null)
        .fetch_one(&pool)
        .await
        .expect_err("eql_v2_int4 = must raise on NULL input")
        .to_string();
    assert!(
        err.contains("operator = is not supported for eql_v2_int4"),
        "unexpected error for = on NULL: {err}"
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

#[sqlx::test]
async fn int4_rejects_invalid_payloads(pool: PgPool) -> Result<()> {
    // The eql_v2_int4 domain CHECK requires a jsonb object carrying the
    // EQL envelope (v, i) and the ciphertext (c). A payload missing a
    // required key, or a non-object, is rejected at the cast.
    for (label, json) in [
        ("missing c", r#"{"v":2,"i":{"t":"t","c":"c"}}"#),
        ("missing v", r#"{"i":{"t":"t","c":"c"},"c":"x"}"#),
        ("missing i", r#"{"v":2,"c":"x"}"#),
        ("not an object", r#"["v","i","c"]"#),
    ] {
        let err = sqlx::query(&format!("SELECT '{json}'::jsonb::eql_v2_int4"))
            .fetch_one(&pool)
            .await
            .expect_err(&format!("eql_v2_int4 must reject payload: {label}"))
            .to_string();
        assert!(
            err.contains("violates check constraint"),
            "{label}: expected a check-constraint violation, got: {err}"
        );
    }
    Ok(())
}
