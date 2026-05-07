//! OPE (CLLW Order-Preserving Encryption) tests
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
use sqlx::{PgPool, Row};

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
    QueryAssertion::new(&pool, &sql)
        .returns_bool_value(true)
        .await;
    Ok(())
}

#[sqlx::test]
async fn has_opf_false_when_field_absent(pool: PgPool) -> Result<()> {
    // Same shape but 'opf' replaced with 'ob' — should not trigger ope detection.
    let sql =
        r#"SELECT eql_v2.has_ope_cllw_u64_65('{"v":2,"i":{"t":"t","c":"c"},"ob":["00"]}'::jsonb)"#;
    QueryAssertion::new(&pool, sql)
        .returns_bool_value(false)
        .await;
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

    QueryAssertion::new(&pool, cmp(&a, &b))
        .returns_int_value(-1)
        .await;
    QueryAssertion::new(&pool, cmp(&b, &a))
        .returns_int_value(1)
        .await;
    QueryAssertion::new(&pool, cmp(&a, &a))
        .returns_int_value(0)
        .await;
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
    QueryAssertion::new(&pool, &sql)
        .returns_bool_value(true)
        .await;
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
    QueryAssertion::new(&pool, &sql)
        .returns_bool_value(true)
        .await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_lte_operator_uses_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let lt = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <= eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &lt).returns_bool_value(true).await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <= eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_gte_operator_uses_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let gt = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) >= eql_v2.to_encrypted('{}'::jsonb)",
        b, a
    );
    QueryAssertion::new(&pool, &gt).returns_bool_value(true).await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) >= eql_v2.to_encrypted('{}'::jsonb)",
        b, b
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_eq_operator_uses_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) = eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(true).await;

    let neq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) = eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &neq).returns_bool_value(false).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_neq_operator_uses_opf(pool: PgPool) -> Result<()> {
    let a = opf_payload(1);
    let b = opf_payload(2);

    let neq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <> eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &neq).returns_bool_value(true).await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <> eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(false).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_lt_operator_uses_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let sql = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) < eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &sql)
        .returns_bool_value(true)
        .await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_gt_operator_uses_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let sql = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) > eql_v2.to_encrypted('{}'::jsonb)",
        b, a
    );
    QueryAssertion::new(&pool, &sql)
        .returns_bool_value(true)
        .await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_lte_operator_uses_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let lt = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <= eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &lt).returns_bool_value(true).await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <= eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_gte_operator_uses_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let gt = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) >= eql_v2.to_encrypted('{}'::jsonb)",
        b, a
    );
    QueryAssertion::new(&pool, &gt).returns_bool_value(true).await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) >= eql_v2.to_encrypted('{}'::jsonb)",
        b, b
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(true).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_eq_operator_uses_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) = eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(true).await;

    let neq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) = eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &neq).returns_bool_value(false).await;
    Ok(())
}

#[sqlx::test]
async fn encrypted_neq_operator_uses_opv(pool: PgPool) -> Result<()> {
    let a = opv_payload(&[0xaa, 0x11]);
    let b = opv_payload(&[0xbb, 0x11]);

    let neq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <> eql_v2.to_encrypted('{}'::jsonb)",
        a, b
    );
    QueryAssertion::new(&pool, &neq).returns_bool_value(true).await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <> eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq).returns_bool_value(false).await;
    Ok(())
}

/// Build the raw 65-byte OPE fixed ciphertext as a hex string (no JSONB
/// wrapper). Mirrors `opf_payload`'s body: a single signal byte at index 8,
/// all other bytes zero. Larger signal → larger ciphertext under lex compare.
fn opf_hex(signal: u8) -> String {
    let mut bytes = vec![0u8; 65];
    bytes[8] = signal;
    hex::encode(&bytes)
}

#[sqlx::test]
async fn ore_wins_over_opf_when_both_present(pool: PgPool) -> Result<()> {
    // When a row carries both ORE (`ob`) and OPE (`opf`) terms with conflicting
    // orderings, eql_v2.compare must dispatch to the ORE branch (it appears
    // earlier in the priority chain) — locking in the precedence contract.
    //
    // Build a value with ORE rank 1 + opf=high(99) and another with ORE rank 2
    // + opf=low(1). ORE-only ordering says (rank 1) < (rank 2). OPE-only
    // ordering would say opf=99 > opf=1. compare() must follow ORE → -1.
    let opf_high = opf_hex(99);
    let opf_low = opf_hex(1);

    // Fixture rows in `ore` have id=N and an `ob` term that orders by N.
    let a_sql = format!(
        "(create_encrypted_ore_json(1)::jsonb || jsonb_build_object('opf', '{}'))::eql_v2_encrypted",
        opf_high
    );
    let b_sql = format!(
        "(create_encrypted_ore_json(2)::jsonb || jsonb_build_object('opf', '{}'))::eql_v2_encrypted",
        opf_low
    );

    let cmp = format!("SELECT eql_v2.compare({}, {})", a_sql, b_sql);
    QueryAssertion::new(&pool, &cmp).returns_int_value(-1).await;
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

    QueryAssertion::new(&pool, cmp(&a, &b))
        .returns_int_value(-1)
        .await;
    QueryAssertion::new(&pool, cmp(&b, &a))
        .returns_int_value(1)
        .await;
    QueryAssertion::new(&pool, cmp(&a, &a))
        .returns_int_value(0)
        .await;
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
    QueryAssertion::new(&pool, sql)
        .returns_bool_value(true)
        .await;
    Ok(())
}

#[sqlx::test]
async fn order_by_ope_extracts_opf_bytes(pool: PgPool) -> Result<()> {
    let payload = opf_payload(7);
    let sql = format!(
        "SELECT length(eql_v2.order_by_ope(eql_v2.to_encrypted('{}'::jsonb)))",
        payload
    );
    QueryAssertion::new(&pool, &sql).returns_int_value(65).await;
    Ok(())
}

#[sqlx::test]
async fn order_by_ope_extracts_opv_bytes(pool: PgPool) -> Result<()> {
    let payload = opv_payload(&[0xaa, 0x11, 0x22, 0x33]);
    let sql = format!(
        "SELECT length(eql_v2.order_by_ope(eql_v2.to_encrypted('{}'::jsonb)))",
        payload
    );
    QueryAssertion::new(&pool, &sql).returns_int_value(4).await;
    Ok(())
}

#[sqlx::test]
async fn sort_compare_orders_opf_lexicographically(pool: PgPool) -> Result<()> {
    let payloads = [opf_payload(3), opf_payload(1), opf_payload(2)];
    let sql = format!(
        "SELECT id FROM eql_v2.sort_compare(
            ARRAY[1::bigint, 2::bigint, 3::bigint],
            ARRAY[
                eql_v2.to_encrypted('{}'::jsonb),
                eql_v2.to_encrypted('{}'::jsonb),
                eql_v2.to_encrypted('{}'::jsonb)
            ]::eql_v2_encrypted[],
            'ASC'
        )",
        payloads[0], payloads[1], payloads[2]
    );

    let rows = sqlx::query(&sql).fetch_all(&pool).await?;
    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        ids,
        vec![2, 3, 1],
        "opf ASC should be id=2 (1) < 3 (2) < 1 (3)"
    );
    Ok(())
}

#[sqlx::test]
async fn sort_compare_uses_ope_fast_path(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE encrypted_ope(
            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
    )
    .execute(&mut *tx)
    .await?;

    for signal in [3u8, 1, 2] {
        let sql = format!(
            "INSERT INTO encrypted_ope(e) VALUES (eql_v2.to_encrypted('{}'::jsonb))",
            opf_payload(signal)
        );
        sqlx::query(&sql).execute(&mut *tx).await?;
    }

    sqlx::query(
        "SELECT pg_stat_reset_single_function_counters(p.oid)
         FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'eql_v2'
           AND p.proname IN ('ope_cllw_u64_65', 'ope_cllw_var_8', 'order_by')",
    )
    .execute(&mut *tx)
    .await?;

    let rows = sqlx::query(
        "SELECT id FROM eql_v2.sort_compare(
            (SELECT array_agg(id ORDER BY id) FROM encrypted_ope),
            (SELECT array_agg(e ORDER BY id) FROM encrypted_ope),
            'ASC'
        )",
    )
    .fetch_all(&mut *tx)
    .await?;
    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    assert_eq!(
        ids,
        vec![2, 3, 1],
        "OPE ASC should be id=2 (1) < 3 (2) < 1 (3)"
    );

    // sort_compare extracts the OPE key per subtype directly. Verify the opf
    // extractor is invoked (the precise count varies because the encrypted
    // overload delegates to the jsonb overload, but it must be called at all)
    // and the var_8 extractor is never invoked because the homogeneity check
    // gives up after the first row.
    let opf_calls: i64 = sqlx::query_scalar(
        "SELECT coalesce(sum(calls), 0)::bigint
         FROM pg_stat_xact_user_functions
         WHERE schemaname = 'eql_v2' AND funcname = 'ope_cllw_u64_65'",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert!(
        opf_calls >= 3,
        "sort_compare should extract opf key for every row (got {opf_calls} calls)"
    );

    let opv_calls: i64 = sqlx::query_scalar(
        "SELECT coalesce(sum(calls), 0)::bigint
         FROM pg_stat_xact_user_functions
         WHERE schemaname = 'eql_v2' AND funcname = 'ope_cllw_var_8'",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(
        opv_calls, 0,
        "sort_compare on opf-only data must not invoke the opv extractor"
    );

    let ore_calls: i64 = sqlx::query_scalar(
        "SELECT coalesce(sum(calls), 0)::bigint
         FROM pg_stat_xact_user_functions
         WHERE schemaname = 'eql_v2' AND funcname = 'order_by'",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(
        ore_calls, 0,
        "sort_compare on OPE-only data must not call the ORE order_by extractor"
    );

    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn sort_compare_mixed_ope_subtypes_falls_back_to_compare(pool: PgPool) -> Result<()> {
    // Mixing `opf` and `opv` payloads in the same batch must not take the OPE
    // bytea fast path: those ciphertexts are not comparable across subtypes.
    // sort_compare should fall back to eql_v2.compare() (which itself rejects
    // mixed subtypes and uses literal JSONB ordering) and still return all
    // rows without error.
    let mut tx = pool.begin().await?;

    sqlx::query(
        "SELECT pg_stat_reset_single_function_counters(p.oid)
         FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'eql_v2'
           AND p.proname = '_compare_ope_key'",
    )
    .execute(&mut *tx)
    .await?;

    let opf = opf_payload(5);
    let opv = opv_payload(&[0xaa, 0x11]);

    let sql = format!(
        "SELECT id FROM eql_v2.sort_compare(
            ARRAY[1::bigint, 2::bigint, 3::bigint],
            ARRAY[
                eql_v2.to_encrypted('{}'::jsonb),
                eql_v2.to_encrypted('{}'::jsonb),
                eql_v2.to_encrypted('{}'::jsonb)
            ]::eql_v2_encrypted[],
            'ASC'
        )",
        opf, opv, opf
    );
    let rows = sqlx::query(&sql).fetch_all(&mut *tx).await?;
    assert_eq!(
        rows.len(),
        3,
        "mixed OPE batch should still sort and return all rows"
    );

    // _compare_ope_key is only invoked by the sort path when strategy='ope'.
    // A mixed-subtype batch must select the compare-fallback strategy, so this
    // helper must never run.
    let ope_compare_calls: i64 = sqlx::query_scalar(
        "SELECT coalesce(sum(calls), 0)::bigint
         FROM pg_stat_xact_user_functions
         WHERE schemaname = 'eql_v2' AND funcname = '_compare_ope_key'",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(
        ope_compare_calls, 0,
        "mixed-subtype batches must not take the OPE bytea fast path"
    );

    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn order_by_compare_mixed_ope_subtypes_falls_back(pool: PgPool) -> Result<()> {
    // Same homogeneity contract for the dynamic-SQL entrypoint: a query that
    // returns mixed `opf` and `opv` rows must not lex-compare the bytea
    // ciphertexts (different subtypes are not order-comparable).
    let mut tx = pool.begin().await?;

    sqlx::query(
        "CREATE TABLE encrypted_ope_mixed(
            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
    )
    .execute(&mut *tx)
    .await?;

    let payloads = [opf_payload(5), opv_payload(&[0xaa, 0x11]), opf_payload(2)];
    for payload in &payloads {
        let sql = format!(
            "INSERT INTO encrypted_ope_mixed(e) VALUES (eql_v2.to_encrypted('{}'::jsonb))",
            payload
        );
        sqlx::query(&sql).execute(&mut *tx).await?;
    }

    sqlx::query(
        "SELECT pg_stat_reset_single_function_counters(p.oid)
         FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'eql_v2'
           AND p.proname = '_compare_ope_key'",
    )
    .execute(&mut *tx)
    .await?;

    let rows = sqlx::query(
        "SELECT id FROM eql_v2.order_by_compare(
            'SELECT id, e FROM encrypted_ope_mixed', 'ASC'
        )",
    )
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(
        rows.len(),
        3,
        "order_by_compare should return every row even on mixed-subtype input"
    );

    let ope_compare_calls: i64 = sqlx::query_scalar(
        "SELECT coalesce(sum(calls), 0)::bigint
         FROM pg_stat_xact_user_functions
         WHERE schemaname = 'eql_v2' AND funcname = '_compare_ope_key'",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(
        ope_compare_calls, 0,
        "order_by_compare must not select the OPE bytea fast path on mixed-subtype input"
    );

    tx.rollback().await?;
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
        msg.contains("ope") && msg.contains("bogus"),
        "expected error to mention the offending 'bogus' index and list 'ope' as valid; got: {msg}"
    );
    Ok(())
}
