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
    QueryAssertion::new(&pool, &lt)
        .returns_bool_value(true)
        .await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <= eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq)
        .returns_bool_value(true)
        .await;
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
    QueryAssertion::new(&pool, &gt)
        .returns_bool_value(true)
        .await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) >= eql_v2.to_encrypted('{}'::jsonb)",
        b, b
    );
    QueryAssertion::new(&pool, &eq)
        .returns_bool_value(true)
        .await;
    Ok(())
}

// encrypted_eq_operator_uses_opf and encrypted_neq_operator_uses_opf
// removed: post-discipline, `=` and `<>` on `eql_v2_encrypted` require
// hmac at the root. OPE-only payloads do not carry hmac and intentionally
// cannot be compared via `=` / `<>` — they support only range operators.

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
    QueryAssertion::new(&pool, &lt)
        .returns_bool_value(true)
        .await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) <= eql_v2.to_encrypted('{}'::jsonb)",
        a, a
    );
    QueryAssertion::new(&pool, &eq)
        .returns_bool_value(true)
        .await;
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
    QueryAssertion::new(&pool, &gt)
        .returns_bool_value(true)
        .await;

    let eq = format!(
        "SELECT eql_v2.to_encrypted('{}'::jsonb) >= eql_v2.to_encrypted('{}'::jsonb)",
        b, b
    );
    QueryAssertion::new(&pool, &eq)
        .returns_bool_value(true)
        .await;
    Ok(())
}

// encrypted_eq_operator_uses_opv and encrypted_neq_operator_uses_opv
// removed for the same reason as the *_opf counterparts above.

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

// ========== NULL-handling parity with ORE ==========
//
// ORE has explicit coverage for several NULL scenarios that the OPE surface
// must also satisfy:
//   1. NULL index term in payload (`{"opf": null}` / `{"opv": null}`) — the
//      generic `eql_v2.compare` dispatcher must skip the OPE branch and fall
//      through to the next available term (mirrors `compare_hmac_with_null_ore_index`).
//   2. NULL operands at the comparator level — the `compare_ope_cllw_*`
//      helpers are STRICT, so a NULL operand short-circuits to NULL.
//   3. NULL rows mixed with encrypted rows in ORDER BY / sort_compare /
//      MIN / MAX must respect SQL NULL semantics.

#[sqlx::test]
async fn has_opf_false_when_field_is_json_null(pool: PgPool) -> Result<()> {
    // `{"opf": null}` must not trigger OPE detection — same contract as
    // `{"ob": null}` for ORE (see compare_hmac_with_null_ore_index).
    let sql =
        r#"SELECT eql_v2.has_ope_cllw_u64_65('{"v":2,"i":{"t":"t","c":"c"},"opf":null}'::jsonb)"#;
    QueryAssertion::new(&pool, sql)
        .returns_bool_value(false)
        .await;
    Ok(())
}

#[sqlx::test]
async fn has_opv_false_when_field_is_json_null(pool: PgPool) -> Result<()> {
    let sql =
        r#"SELECT eql_v2.has_ope_cllw_var_8('{"v":2,"i":{"t":"t","c":"c"},"opv":null}'::jsonb)"#;
    QueryAssertion::new(&pool, sql)
        .returns_bool_value(false)
        .await;
    Ok(())
}

#[sqlx::test]
async fn compare_dispatches_through_null_opf_to_hmac(pool: PgPool) -> Result<()> {
    // Mirror of `compare_hmac_with_null_ore_index`: when `opf` is JSON null,
    // the dispatcher must skip the OPE branch and use the HMAC term instead.
    // Without this, two records with `{"opf": null}` would compare equal via
    // the OPE branch (both extract to NULL bytes → equal), masking the HMAC
    // ordering.
    let a = "('{\"opf\": null}'::jsonb || create_encrypted_json(1, 'hm')::jsonb)::eql_v2_encrypted";
    let b = "('{\"opf\": null}'::jsonb || create_encrypted_json(2, 'hm')::jsonb)::eql_v2_encrypted";
    let c = "('{\"opf\": null}'::jsonb || create_encrypted_json(3, 'hm')::jsonb)::eql_v2_encrypted";

    for (l, r, expected, label) in [
        (a, a, 0, "compare(a, a)"),
        (a, b, -1, "compare(a, b)"),
        (a, c, -1, "compare(a, c)"),
        (b, b, 0, "compare(b, b)"),
        (b, a, 1, "compare(b, a)"),
        (b, c, -1, "compare(b, c)"),
        (c, c, 0, "compare(c, c)"),
        (c, b, 1, "compare(c, b)"),
        (c, a, 1, "compare(c, a)"),
    ] {
        let sql = format!("SELECT eql_v2.compare({}, {})", l, r);
        let got: i32 = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert_eq!(got, expected, "{label} should equal {expected}");
    }
    Ok(())
}

#[sqlx::test]
async fn compare_dispatches_through_null_opv_to_hmac(pool: PgPool) -> Result<()> {
    // Same as the opf variant but for the variable-width term. Establishes
    // that {"opv": null} also short-circuits the OPE branch.
    let a = "('{\"opv\": null}'::jsonb || create_encrypted_json(1, 'hm')::jsonb)::eql_v2_encrypted";
    let b = "('{\"opv\": null}'::jsonb || create_encrypted_json(2, 'hm')::jsonb)::eql_v2_encrypted";

    let lt: i32 = sqlx::query_scalar(&format!("SELECT eql_v2.compare({}, {})", a, b))
        .fetch_one(&pool)
        .await?;
    assert_eq!(lt, -1, "compare(a, b) should equal -1");

    let gt: i32 = sqlx::query_scalar(&format!("SELECT eql_v2.compare({}, {})", b, a))
        .fetch_one(&pool)
        .await?;
    assert_eq!(gt, 1, "compare(b, a) should equal 1");
    Ok(())
}

#[sqlx::test]
async fn compare_ope_cllw_u64_65_strict_returns_null_for_null_operand(pool: PgPool) -> Result<()> {
    // The comparator is declared STRICT; the runtime returns NULL before the
    // body runs. Codifying this so a future change that drops STRICT won't
    // silently change semantics on the sort fast path.
    let payload = opf_payload(1);
    let lhs_null = format!(
        "SELECT eql_v2.compare_ope_cllw_u64_65(NULL, eql_v2.to_encrypted('{}'::jsonb))",
        payload
    );
    let result: Option<i32> = sqlx::query_scalar(&lhs_null).fetch_one(&pool).await?;
    assert!(result.is_none(), "compare(NULL, x) should return NULL");

    let rhs_null = format!(
        "SELECT eql_v2.compare_ope_cllw_u64_65(eql_v2.to_encrypted('{}'::jsonb), NULL)",
        payload
    );
    let result: Option<i32> = sqlx::query_scalar(&rhs_null).fetch_one(&pool).await?;
    assert!(result.is_none(), "compare(x, NULL) should return NULL");
    Ok(())
}

#[sqlx::test]
async fn compare_ope_cllw_var_8_strict_returns_null_for_null_operand(pool: PgPool) -> Result<()> {
    let payload = opv_payload(&[0xaa, 0x11]);
    let lhs_null = format!(
        "SELECT eql_v2.compare_ope_cllw_var_8(NULL, eql_v2.to_encrypted('{}'::jsonb))",
        payload
    );
    let result: Option<i32> = sqlx::query_scalar(&lhs_null).fetch_one(&pool).await?;
    assert!(result.is_none(), "compare(NULL, x) should return NULL");

    let rhs_null = format!(
        "SELECT eql_v2.compare_ope_cllw_var_8(eql_v2.to_encrypted('{}'::jsonb), NULL)",
        payload
    );
    let result: Option<i32> = sqlx::query_scalar(&rhs_null).fetch_one(&pool).await?;
    assert!(result.is_none(), "compare(x, NULL) should return NULL");
    Ok(())
}

// ========== ORDER BY NULLS FIRST/LAST with opf-encoded data ==========
//
// Fixture layout (all four tests use the same shape):
//   id=1: NULL
//   id=2: opf payload with signal byte = 42  (largest non-NULL)
//   id=3: opf payload with signal byte = 3   (smallest non-NULL)
//   id=4: NULL
//
// Mirrors `order_by_null_data.sql` for the ORE side.

async fn install_opf_null_fixture(tx: &mut sqlx::Transaction<'_, sqlx::Postgres>) -> Result<()> {
    sqlx::query(
        "CREATE TABLE encrypted_opf_nulls(
            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query("INSERT INTO encrypted_opf_nulls(e) VALUES (NULL)")
        .execute(&mut **tx)
        .await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted_opf_nulls(e) VALUES (eql_v2.to_encrypted('{}'::jsonb))",
        opf_payload(42)
    ))
    .execute(&mut **tx)
    .await?;
    sqlx::query(&format!(
        "INSERT INTO encrypted_opf_nulls(e) VALUES (eql_v2.to_encrypted('{}'::jsonb))",
        opf_payload(3)
    ))
    .execute(&mut **tx)
    .await?;
    sqlx::query("INSERT INTO encrypted_opf_nulls(e) VALUES (NULL)")
        .execute(&mut **tx)
        .await?;
    Ok(())
}

#[sqlx::test]
async fn order_by_asc_nulls_first_with_opf(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let row = sqlx::query("SELECT id FROM encrypted_opf_nulls ORDER BY e ASC NULLS FIRST, id")
        .fetch_one(&mut *tx)
        .await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 1,
        "ASC NULLS FIRST + tiebreak by id should put id=1 first"
    );
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn order_by_asc_nulls_last_with_opf(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let row = sqlx::query("SELECT id FROM encrypted_opf_nulls ORDER BY e ASC NULLS LAST")
        .fetch_one(&mut *tx)
        .await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 3,
        "ASC NULLS LAST should return smallest non-NULL (id=3, opf signal=3) first"
    );
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn order_by_desc_nulls_first_with_opf(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let row = sqlx::query("SELECT id FROM encrypted_opf_nulls ORDER BY e DESC NULLS FIRST, id")
        .fetch_one(&mut *tx)
        .await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 1,
        "DESC NULLS FIRST + tiebreak by id should put id=1 first"
    );
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn order_by_desc_nulls_last_with_opf(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let row = sqlx::query("SELECT id FROM encrypted_opf_nulls ORDER BY e DESC NULLS LAST")
        .fetch_one(&mut *tx)
        .await?;
    let first_id: i64 = row.try_get(0)?;
    assert_eq!(
        first_id, 2,
        "DESC NULLS LAST should return largest non-NULL (id=2, opf signal=42) first"
    );
    tx.rollback().await?;
    Ok(())
}

// ========== sort_compare with NULL operands ==========

#[sqlx::test]
async fn sort_compare_asc_puts_nulls_first_with_opf(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let rows = sqlx::query(
        "SELECT id FROM eql_v2.sort_compare(
            (SELECT array_agg(id ORDER BY id) FROM encrypted_opf_nulls),
            (SELECT array_agg(e ORDER BY id) FROM encrypted_opf_nulls),
            'ASC'
        )",
    )
    .fetch_all(&mut *tx)
    .await?;
    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    let mut null_ids = ids[..2].to_vec();
    null_ids.sort_unstable();

    assert_eq!(rows.len(), 4, "should return all 4 rows");
    assert_eq!(null_ids, vec![1i64, 4], "NULL rows should sort first");
    assert_eq!(
        ids[2], 3,
        "smallest non-NULL (signal=3) should follow NULLs"
    );
    assert_eq!(ids[3], 2, "largest non-NULL (signal=42) should sort last");
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn sort_compare_desc_puts_nulls_last_with_opf(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let rows = sqlx::query(
        "SELECT id FROM eql_v2.sort_compare(
            (SELECT array_agg(id ORDER BY id) FROM encrypted_opf_nulls),
            (SELECT array_agg(e ORDER BY id) FROM encrypted_opf_nulls),
            'DESC'
        )",
    )
    .fetch_all(&mut *tx)
    .await?;
    let ids: Vec<i64> = rows.iter().map(|r| r.try_get(0).unwrap()).collect();
    let mut null_ids = ids[2..].to_vec();
    null_ids.sort_unstable();

    assert_eq!(rows.len(), 4, "should return all 4 rows");
    assert_eq!(ids[0], 2, "largest non-NULL (signal=42) should sort first");
    assert_eq!(ids[1], 3, "smaller non-NULL (signal=3) should sort second");
    assert_eq!(null_ids, vec![1i64, 4], "NULL rows should sort last");
    tx.rollback().await?;
    Ok(())
}

// ========== MIN / MAX aggregates over OPE-encoded values ==========
//
// `eql_v2.min` / `eql_v2.max` use `<` / `>`, which dispatch through
// `eql_v2.compare`, so OPE-encoded values must aggregate correctly without
// any aggregate-side changes.

#[sqlx::test]
async fn eql_v2_min_with_opf_finds_minimum(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    // Smallest non-NULL signal=3 lives at id=3.
    let actual: String = sqlx::query_scalar("SELECT eql_v2.min(e)::text FROM encrypted_opf_nulls")
        .fetch_one(&mut *tx)
        .await?;
    let expected: String =
        sqlx::query_scalar("SELECT e::text FROM encrypted_opf_nulls WHERE id = 3")
            .fetch_one(&mut *tx)
            .await?;

    assert_eq!(
        actual, expected,
        "eql_v2.min should return the opf row with the smallest signal byte"
    );
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn eql_v2_max_with_opf_finds_maximum(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    // Largest non-NULL signal=42 lives at id=2.
    let actual: String = sqlx::query_scalar("SELECT eql_v2.max(e)::text FROM encrypted_opf_nulls")
        .fetch_one(&mut *tx)
        .await?;
    let expected: String =
        sqlx::query_scalar("SELECT e::text FROM encrypted_opf_nulls WHERE id = 2")
            .fetch_one(&mut *tx)
            .await?;

    assert_eq!(
        actual, expected,
        "eql_v2.max should return the opf row with the largest signal byte"
    );
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn eql_v2_min_with_opf_null_only_returns_null(pool: PgPool) -> Result<()> {
    // Mirrors `eql_v2_min_with_null_values` for ORE: aggregate over a NULL-only
    // selection must return NULL (the STRICT state-transition function never
    // runs).
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let result: Option<String> =
        sqlx::query_scalar("SELECT eql_v2.min(e)::text FROM encrypted_opf_nulls WHERE e IS NULL")
            .fetch_one(&mut *tx)
            .await?;
    assert!(result.is_none(), "eql_v2.min over NULL-only should be NULL");
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn eql_v2_max_with_opf_null_only_returns_null(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    install_opf_null_fixture(&mut tx).await?;

    let result: Option<String> =
        sqlx::query_scalar("SELECT eql_v2.max(e)::text FROM encrypted_opf_nulls WHERE e IS NULL")
            .fetch_one(&mut *tx)
            .await?;
    assert!(result.is_none(), "eql_v2.max over NULL-only should be NULL");
    tx.rollback().await?;
    Ok(())
}

// ========== BETWEEN with OPE-encoded data ==========
//
// BETWEEN expands to `lo <= x AND x <= hi`, so this exercises both `<=`
// and `>=` dispatching through compare.

#[sqlx::test]
async fn between_with_opf_inclusive_bounds(pool: PgPool) -> Result<()> {
    // signals 1 < 3 < 5 < 7 < 9; BETWEEN 3 AND 7 should include 3, 5, 7.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TABLE encrypted_opf_between(
            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
    )
    .execute(&mut *tx)
    .await?;
    for signal in [1u8, 3, 5, 7, 9] {
        sqlx::query(&format!(
            "INSERT INTO encrypted_opf_between(e) VALUES (eql_v2.to_encrypted('{}'::jsonb))",
            opf_payload(signal)
        ))
        .execute(&mut *tx)
        .await?;
    }

    let lo = opf_payload(3);
    let hi = opf_payload(7);
    let sql = format!(
        "SELECT count(*)::bigint FROM encrypted_opf_between
         WHERE e BETWEEN eql_v2.to_encrypted('{}'::jsonb) AND eql_v2.to_encrypted('{}'::jsonb)",
        lo, hi
    );
    let count: i64 = sqlx::query_scalar(&sql).fetch_one(&mut *tx).await?;
    assert_eq!(count, 3, "BETWEEN 3 AND 7 should match signals 3, 5, 7");
    tx.rollback().await?;
    Ok(())
}

#[sqlx::test]
async fn between_with_opv_inclusive_bounds(pool: PgPool) -> Result<()> {
    // Variable-width OPE: two-byte ciphertexts compared by bytea lex order.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TABLE encrypted_opv_between(
            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            e eql_v2_encrypted
        )",
    )
    .execute(&mut *tx)
    .await?;
    for first_byte in [0x10u8, 0x30, 0x50, 0x70, 0x90] {
        sqlx::query(&format!(
            "INSERT INTO encrypted_opv_between(e) VALUES (eql_v2.to_encrypted('{}'::jsonb))",
            opv_payload(&[first_byte, 0x00])
        ))
        .execute(&mut *tx)
        .await?;
    }

    let lo = opv_payload(&[0x30, 0x00]);
    let hi = opv_payload(&[0x70, 0x00]);
    let sql = format!(
        "SELECT count(*)::bigint FROM encrypted_opv_between
         WHERE e BETWEEN eql_v2.to_encrypted('{}'::jsonb) AND eql_v2.to_encrypted('{}'::jsonb)",
        lo, hi
    );
    let count: i64 = sqlx::query_scalar(&sql).fetch_one(&mut *tx).await?;
    assert_eq!(
        count, 3,
        "BETWEEN 0x30 AND 0x70 should match 0x30, 0x50, 0x70"
    );
    tx.rollback().await?;
    Ok(())
}
