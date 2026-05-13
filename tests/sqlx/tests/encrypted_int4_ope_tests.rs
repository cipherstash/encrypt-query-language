//! OPE-direct demonstration suite for the `encrypted_int4` domain.
//!
//! This file exists alongside `encrypted_int4_fixture_tests.rs` (which is
//! currently quarantined because real CipherStash Proxy emits ORE blocks
//! `ob` for int columns, not OPE bytes `opf`). The prototype's range-op
//! wrappers target the in-flight OPE-direct emission. This suite proves
//! the inlineable-wrapper + functional-index architecture works today
//! using hand-crafted `opf` payloads — the same pattern as
//! `tests/sqlx/tests/ope_tests.rs:20-27`.
//!
//! Pattern:
//!   - `opf_payload(signal: u8)` builds a 65-byte buffer with the signal
//!     at index 8; lexicographic bytea comparison preserves signal order.
//!   - Each test sets up its own temp table, inserts synthetic rows,
//!     creates the functional indexes, and asserts BOTH correctness
//!     (row sets) and index engagement (EXPLAIN plan).

use anyhow::Result;
use sqlx::PgPool;

/// 65-byte OPE-shaped fixed ciphertext with `signal` at the first body
/// byte (index 8). Larger signal → larger ciphertext under lex bytea
/// compare. Mirrors `tests/sqlx/tests/ope_tests.rs::opf_payload`.
fn opf_payload(signal: u8) -> String {
    let mut bytes = vec![0u8; 65];
    bytes[8] = signal;
    format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"int_col"}},"c":"ct-{}","hm":"hm-{:02x}","opf":"{}"}}"#,
        signal,
        signal,
        hex::encode(&bytes)
    )
}

async fn setup_ope_table(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    signals: &[u8],
) -> Result<()> {
    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_int4_ope (
            id integer GENERATED ALWAYS AS IDENTITY,
            signal smallint NOT NULL,
            value encrypted_int4
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut **tx)
    .await?;

    for signal in signals {
        sqlx::query(
            "INSERT INTO typed_int4_ope (signal, value) \
             VALUES ($1::smallint, $2::jsonb::encrypted_int4)",
        )
        .bind(*signal as i16)
        .bind(opf_payload(*signal))
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_eq_engages_hmac_idx(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_ope_table(&mut tx, &[0x01, 0x05, 0x0a, 0x14, 0x32]).await?;

    sqlx::query(
        "CREATE INDEX typed_int4_ope_hmac_idx \
         ON typed_int4_ope ((eql_v2.hmac_256(value::jsonb)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_int4_ope")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let needle = opf_payload(0x0a);

    // Domain-on-both-sides correctness.
    let signal: i16 = sqlx::query_scalar(
        "SELECT signal FROM typed_int4_ope \
         WHERE value = $1::jsonb::encrypted_int4",
    )
    .bind(&needle)
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(signal, 0x0a, "= against opf(0x0a) returns signal 0x0a");

    // EXPLAIN — the hmac functional index must engage for cross-type =.
    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM typed_int4_ope WHERE value = '{}'::jsonb",
        needle
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_int4_ope_hmac_idx"),
        "= must engage hmac functional index; plan:\n{plan}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ope_idx_engages_for_range(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_ope_table(&mut tx, &[0x01, 0x05, 0x0a, 0x14, 0x32]).await?;

    sqlx::query(
        "CREATE INDEX typed_int4_ope_key_idx \
         ON typed_int4_ope ((eql_v2.encrypted_int4_ope_key(value::jsonb)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_int4_ope")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot = opf_payload(0x0a);

    for op in ["<", "<=", ">", ">="] {
        let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
            "EXPLAIN SELECT * FROM typed_int4_ope WHERE value {op} '{}'::jsonb",
            pivot
        ))
        .fetch_all(&mut *tx)
        .await?;
        let plan = plan_rows.join("\n");
        assert!(
            plan.contains("typed_int4_ope_key_idx"),
            "{op} must engage OPE functional index (domain, jsonb shape); plan:\n{plan}"
        );

        // (jsonb, domain) — ORM bind shape. The wrapper inlines through
        // the (jsonb, encrypted_int4) overload of encrypted_int4_ope_key.
        let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
            "EXPLAIN SELECT * FROM typed_int4_ope WHERE '{}'::jsonb {op} value",
            pivot
        ))
        .fetch_all(&mut *tx)
        .await?;
        let plan = plan_rows.join("\n");
        assert!(
            plan.contains("typed_int4_ope_key_idx"),
            "{op} must engage OPE functional index (jsonb, domain shape); plan:\n{plan}"
        );
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_range_semantics(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    let signals = [0x01u8, 0x05, 0x0a, 0x14, 0x32];
    setup_ope_table(&mut tx, &signals).await?;

    let pivot = opf_payload(0x0a);

    // Forward shape (value op pivot)
    //   <  pivot → {0x01, 0x05}
    //   <= pivot → {0x01, 0x05, 0x0a}
    //   >  pivot → {0x14, 0x32}
    //   >= pivot → {0x0a, 0x14, 0x32}
    let cases: &[(&str, Vec<i16>)] = &[
        ("<", vec![0x01, 0x05]),
        ("<=", vec![0x01, 0x05, 0x0a]),
        (">", vec![0x14, 0x32]),
        (">=", vec![0x0a, 0x14, 0x32]),
    ];

    for (op, expected) in cases {
        // (domain, domain)
        let mut ids: Vec<i16> = sqlx::query_scalar(&format!(
            "SELECT signal FROM typed_int4_ope \
             WHERE value {op} '{}'::jsonb::encrypted_int4 \
             ORDER BY signal",
            pivot
        ))
        .fetch_all(&mut *tx)
        .await?;
        ids.sort();
        let mut want = expected.clone();
        want.sort();
        assert_eq!(ids, want, "(domain, domain) {op}");

        // (domain, jsonb) — RHS is plain jsonb, no domain cast
        let mut ids: Vec<i16> = sqlx::query_scalar(&format!(
            "SELECT signal FROM typed_int4_ope \
             WHERE value {op} '{}'::jsonb \
             ORDER BY signal",
            pivot
        ))
        .fetch_all(&mut *tx)
        .await?;
        ids.sort();
        assert_eq!(ids, want, "(domain, jsonb) {op}");

        // (jsonb, domain) — inverse shape. value op pivot ↔ pivot inverse_op value
        // For symmetric ops `<` and `>=`, the reverse-LHS form swaps to the
        // complementary set on the same dataset.
        let reverse_expected: Vec<i16> = match *op {
            "<" => vec![0x14, 0x32],        // pivot < value → value > pivot
            "<=" => vec![0x0a, 0x14, 0x32], // pivot <= value → value >= pivot
            ">" => vec![0x01, 0x05],        // pivot > value → value < pivot
            ">=" => vec![0x01, 0x05, 0x0a], // pivot >= value → value <= pivot
            _ => unreachable!(),
        };
        let mut reverse_want = reverse_expected.clone();
        reverse_want.sort();
        let mut ids: Vec<i16> = sqlx::query_scalar(&format!(
            "SELECT signal FROM typed_int4_ope \
             WHERE '{}'::jsonb {op} value \
             ORDER BY signal",
            pivot
        ))
        .fetch_all(&mut *tx)
        .await?;
        ids.sort();
        assert_eq!(ids, reverse_want, "(jsonb, domain) reverse {op}");
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ordering_matches_signal_byte(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    // Deliberately insert in non-sorted order to prove the ORDER BY
    // sorts by OPE-key bytes, not by insertion order.
    let signals = [0x32u8, 0x01, 0x14, 0x05, 0x0a];
    setup_ope_table(&mut tx, &signals).await?;

    let ordered: Vec<i16> = sqlx::query_scalar(
        "SELECT signal \
         FROM typed_int4_ope \
         ORDER BY eql_v2.encrypted_int4_ope_key(value)",
    )
    .fetch_all(&mut *tx)
    .await?;

    assert_eq!(
        ordered,
        vec![0x01, 0x05, 0x0a, 0x14, 0x32],
        "OPE-key ordering must match ascending signal-byte order"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_equality_cross_type_shapes(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    setup_ope_table(&mut tx, &[0x01, 0x05, 0x0a, 0x14, 0x32]).await?;

    let needle = opf_payload(0x14);

    // = in all three shapes
    for sql in [
        format!(
            "SELECT signal FROM typed_int4_ope \
             WHERE value = '{}'::jsonb::encrypted_int4",
            needle
        ),
        format!(
            "SELECT signal FROM typed_int4_ope \
             WHERE value = '{}'::jsonb",
            needle
        ),
        format!(
            "SELECT signal FROM typed_int4_ope \
             WHERE '{}'::jsonb = value",
            needle
        ),
    ] {
        let signal: i16 = sqlx::query_scalar(&sql).fetch_one(&mut *tx).await?;
        assert_eq!(signal, 0x14, "= must match signal 0x14; query: {sql}");
    }

    // <> in all three shapes — 5 rows, exclude the 0x14 row → 4 remaining
    let other = opf_payload(0x14);
    for sql in [
        format!(
            "SELECT count(*) FROM typed_int4_ope \
             WHERE value <> '{}'::jsonb::encrypted_int4",
            other
        ),
        format!(
            "SELECT count(*) FROM typed_int4_ope \
             WHERE value <> '{}'::jsonb",
            other
        ),
        format!(
            "SELECT count(*) FROM typed_int4_ope \
             WHERE '{}'::jsonb <> value",
            other
        ),
    ] {
        let count: i64 = sqlx::query_scalar(&sql).fetch_one(&mut *tx).await?;
        assert_eq!(
            count, 4,
            "<> must exclude only the matching row; query: {sql}"
        );
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_hmac_distinctness_sweep(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    // Each opf_payload(signal) bakes the signal into hm as a hex byte,
    // so distinct signals → distinct HMAC strings. Verify pairwise that
    // no two rows share an HMAC.
    setup_ope_table(&mut tx, &[0x01, 0x05, 0x0a, 0x14, 0x32]).await?;

    let collisions: i64 = sqlx::query_scalar(
        "SELECT count(*) \
         FROM typed_int4_ope a \
         JOIN typed_int4_ope b ON a.id < b.id \
         WHERE a.value = b.value",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(
        collisions, 0,
        "no two distinct signals may share an HMAC term"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_blocker_operators_still_raise(pool: PgPool) -> Result<()> {
    // Sanity: replacing the range ops must not accidentally re-route the
    // blocker operators. ~~, ~~*, @>, <@, ->, ->> must still raise the
    // shared "operator … is not supported" exception.
    let a = opf_payload(0x01);
    let b = opf_payload(0x02);

    for op in ["~~", "~~*", "@>", "<@"] {
        let sql = format!(
            "SELECT '{}'::jsonb::encrypted_int4 {op} '{}'::jsonb::encrypted_int4",
            a, b
        );
        let err = sqlx::query_scalar::<_, bool>(&sql)
            .fetch_one(&pool)
            .await
            .expect_err(&format!("encrypted_int4 {op} should be blocked"))
            .to_string();
        let expected = format!("operator {op} is not supported for encrypted_int4");
        assert!(
            err.contains(&expected),
            "blocker error mismatch for {op}: {err}"
        );
    }

    Ok(())
}
