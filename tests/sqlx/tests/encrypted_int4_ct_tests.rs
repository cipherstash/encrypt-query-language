//! Synthetic test suite for `eql_v2_int4_ct` — the storage-only variant.
//!
//! Every operator is a blocker that raises
//! `operator X is not supported for eql_v2_int4_ct`. No fixture data is
//! needed; operator-on-literals is sufficient.

use anyhow::Result;
use sqlx::PgPool;

const SAMPLE_PAYLOAD: &str = r#"{"v":2,"i":{"t":"t","c":"c"},"c":"sample"}"#;

#[sqlx::test]
async fn ct_all_symmetric_operators_raise(pool: PgPool) -> Result<()> {
    let shapes: &[(&str, &str)] = &[
        ("$1::jsonb::eql_v2_int4_ct", "$2::jsonb::eql_v2_int4_ct"),
        ("$1::jsonb::eql_v2_int4_ct", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::eql_v2_int4_ct"),
    ];

    for op in ["=", "<>", "<", "<=", ">", ">=", "~~", "~~*", "@>", "<@"] {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query(&sql)
                .bind(SAMPLE_PAYLOAD)
                .bind(SAMPLE_PAYLOAD)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_ct {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4_ct");
            assert!(
                err.contains(&expected),
                "unexpected error for {sql}: got {err}, want {expected}"
            );
        }
    }
    Ok(())
}

#[sqlx::test]
async fn ct_path_operators_raise(pool: PgPool) -> Result<()> {
    for op in ["->", "->>"] {
        for sql in [
            format!("SELECT $1::jsonb::eql_v2_int4_ct {op} 'field'::text"),
            format!("SELECT $1::jsonb::eql_v2_int4_ct {op} 0::integer"),
            format!("SELECT $1::jsonb {op} $2::jsonb::eql_v2_int4_ct"),
        ] {
            let err = sqlx::query(&sql)
                .bind(SAMPLE_PAYLOAD)
                .bind(SAMPLE_PAYLOAD)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_ct {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4_ct");
            assert!(err.contains(&expected), "unexpected error for {sql}: {err}");
        }
    }
    Ok(())
}
