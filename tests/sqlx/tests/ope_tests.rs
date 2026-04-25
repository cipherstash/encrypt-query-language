//! OPE (CLWW Order-Preserving Encryption) tests
//!
//! Exercises the `ope_cllw_u64_65` and `ope_cllw_var_8` support wired into
//! `eql_v2_encrypted`. Unlike the ORE CLLW variants, OPE ciphertexts compare
//! under standard lexicographic `bytea` ordering — these tests verify that
//! property end-to-end through the SEM extraction, `compare_*` helpers, and
//! the generic `eql_v2.compare` dispatch.
//!
//! Fixture data for OPE is constructed inline as hand-crafted JSONB payloads
//! (there is no Rust-side fixture generator yet; the ORE fixture tables are
//! built from `ore_rs`, not `cllw_ore::encrypt_ope`).

use anyhow::Result;
use eql_tests::QueryAssertion;
use sqlx::PgPool;

/// Build a 65-byte OPE fixed ciphertext from a single "signal" byte at index 8
/// (the first plaintext body byte). All other bytes are zero. Larger signal →
/// larger ciphertext under lex compare.
fn opf_payload(signal: u8) -> String {
    let mut bytes = vec![0u8; 65];
    bytes[8] = signal;
    format!(
        r#"{{"v":2,"i":{{"t":"t","c":"c"}},"opf":"{}"}}"#,
        hex::encode(&bytes)
    )
}

fn opv_payload(bytes: &[u8]) -> String {
    format!(
        r#"{{"v":2,"i":{{"t":"t","c":"c"}},"opv":"{}"}}"#,
        hex::encode(bytes)
    )
}

#[sqlx::test]
async fn opf_extracts_to_65_bytes(pool: PgPool) -> Result<()> {
    let sql = format!(
        "SELECT length((eql_v2.ope_cllw_u64_65('{}'::jsonb)).bytes)",
        opf_payload(1)
    );
    QueryAssertion::new(&pool, &sql).returns_int_value(65).await;
    Ok(())
}

#[sqlx::test]
async fn has_opf_true_when_field_present(pool: PgPool) -> Result<()> {
    let sql = format!(
        "SELECT eql_v2.has_ope_cllw_u64_65('{}'::jsonb)",
        opf_payload(1)
    );
    QueryAssertion::new(&pool, &sql).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn has_opf_false_when_field_absent(pool: PgPool) -> Result<()> {
    // Same shape but 'opf' replaced with 'ob' — should not trigger ope detection.
    let sql = r#"SELECT eql_v2.has_ope_cllw_u64_65('{"v":2,"i":{"t":"t","c":"c"},"ob":["00"]}'::jsonb)"#;
    QueryAssertion::new(&pool, sql).returns_bool_value(false).await;
    Ok(())
}

#[sqlx::test]
async fn compare_opf_three_way(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let cmp = |l: &str, r: &str| {
        format!(
            "SELECT eql_v2.compare_ope_cllw_u64_65(eql_v2.to_encrypted('{}'::jsonb), eql_v2.to_encrypted('{}'::jsonb))",
            l, r
        )
    };

    QueryAssertion::new(&pool, &cmp(&a, &b)).returns_int_value(-1).await;
    QueryAssertion::new(&pool, &cmp(&b, &a)).returns_int_value(1).await;
    QueryAssertion::new(&pool, &cmp(&a, &a)).returns_int_value(0).await;
    Ok(())
}

#[sqlx::test]
async fn generic_compare_dispatches_to_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let sql = format!(
        "SELECT eql_v2.compare(eql_v2.to_encrypted('{}'::jsonb), eql_v2.to_encrypted('{}'::jsonb))",
        a, b
    );
    QueryAssertion::new(&pool, &sql).returns_int_value(-1).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_lt_operator_uses_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let sql = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) < eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &sql).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_gt_operator_uses_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let sql = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) > eql_v2.to_encrypted('{}'::jsonb)",
        b, a
    );
    QueryAssertion::new(&pool, &sql).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn compare_opv_short_prefix_sorts_less(pool: PgPool) -> Result<()> {
    // Shorter ciphertext that is a lex prefix of the longer one.
    let short = opv_payload(&[0xaa, 0x11, 0x11, 0x11, 0x11]);
    let long = opv_payload(&[0xaa, 0x11, 0x11, 0x11, 0x11, 0x00]);

    let sql = format!(
        "SELECT eql_v2.compare_ope_cllw_var_8(eql_v2.to_encrypted('{}'::jsonb), eql_v2.to_encrypted('{}'::jsonb))",
        short, long
    );
    QueryAssertion::new(&pool, &sql).returns_int_value(-1).await;
    Ok(())
}

#[sqlx::test]
async fn compare_opv_three_way_same_length(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11, 0x11]);
    let b = opv_payload(&[0xbb, 0x11, 0x11]);

    let cmp = |l: &str, r: &str| {
        format!(
            "SELECT eql_v2.compare_ope_cllw_var_8(eql_v2.to_encrypted('{}'::jsonb), eql_v2.to_encrypted('{}'::jsonb))",
            l, r
        )
    };

    QueryAssertion::new(&pool, &cmp(&a, &b)).returns_int_value(-1).await;
    QueryAssertion::new(&pool, &cmp(&b, &a)).returns_int_value(1).await;
    QueryAssertion::new(&pool, &cmp(&a, &a)).returns_int_value(0).await;
    Ok(())
}

#[sqlx::test]
async fn generic_compare_dispatches_to_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let sql = format!(
        "SELECT eql_v2.compare(eql_v2.to_encrypted('{}'::jsonb), eql_v2.to_encrypted('{}'::jsonb))",
        a, b
    );
    QueryAssertion::new(&pool, &sql).returns_int_value(-1).await;
    Ok(())
}

#[sqlx::test]
async fn config_check_accepts_ope_index(pool: PgPool) -> Result<()> {
    let sql = r#"SELECT eql_v2.config_check_indexes('{"v":1,"tables":{"t":{"c":{"cast_as":"int","indexes":{"ope":{}}}}}}'::jsonb)"#;
    QueryAssertion::new(&pool, sql).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn config_check_rejects_unknown_index(pool: PgPool) -> Result<()> {
    let sql = r#"SELECT eql_v2.config_check_indexes('{"v":1,"tables":{"t":{"c":{"cast_as":"int","indexes":{"bogus":{}}}}}}'::jsonb)"#;
    // Should raise; use sqlx directly to assert the error message mentions `ope`.
    let err = sqlx::query(sql)
        .fetch_one(&pool)
        .await
        .expect_err("expected check_indexes to reject unknown index");
    let msg = err.to_string();
    assert!(
        msg.contains("match, ore, ope, unique, ste_vec"),
        "expected error to list valid indexes including 'ope'; got: {msg}"
    );
    Ok(())
}
