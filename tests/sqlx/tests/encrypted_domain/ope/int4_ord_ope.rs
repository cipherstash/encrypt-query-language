//! `eql_v3.int4_ord_ope` smoke suite: the shared `_ord_ope` tests plus the
//! deeper single-type behaviour (bytea prefix order, blockers, ORDER BY forms,
//! MIN/MAX aggregates) exercised once on the int4 reference — the ope surface
//! is byte-identical across the ordered families modulo the domain name, so
//! the per-type modules pin the shared contract and this one goes deeper.

use crate::ope_support::ope_cast;

crate::ope_ord_smoke!("int4_ord_ope");

#[sqlx::test]
async fn ord_ope_shorter_prefix_sorts_first(pool: PgPool) -> anyhow::Result<()> {
    // Native bytea semantics: a strict prefix sorts before its extension.
    let lt: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) < ({})",
        ope_cast("int4_ord_ope", "aa", "00ff"),
        ope_cast("int4_ord_ope", "aa", "00ff01")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(lt, "prefix must sort before its extension");
    Ok(())
}

#[sqlx::test]
async fn ord_ope_blocks_unsupported_operators(pool: PgPool) -> anyhow::Result<()> {
    let err = sqlx::query(&format!(
        "SELECT ({}) @> ({})",
        ope_cast("int4_ord_ope", "aa", "00"),
        ope_cast("int4_ord_ope", "aa", "00")
    ))
    .execute(&pool)
    .await
    .unwrap_err();
    assert!(
        format!("{err}").contains("not supported"),
        "@> must be blocked on int4_ord_ope, got: {err}"
    );
    Ok(())
}

#[sqlx::test]
async fn ord_ope_order_by_sorts_by_decoded_bytes(pool: PgPool) -> anyhow::Result<()> {
    // The supported ORDER BY form is the functional-index expression (the
    // extractor, whose eql_v3.ope_cllw return type carries the DEFAULT btree
    // opclass). `ORDER BY col USING <` must REJECT: the design forbids
    // opclasses on the domains themselves (see the matrix's order_by_using
    // rejection category).
    sqlx::query("CREATE TABLE ope_smoke (id int, payload eql_v3.int4_ord_ope)")
        .execute(&pool)
        .await?;
    // Insert out of byte order: 0xff (3rd), 0x00ff (1st), 0x0100 (2nd).
    for (id, op) in [(1, "ff"), (2, "00ff"), (3, "0100")] {
        sqlx::query(&format!(
            "INSERT INTO ope_smoke VALUES ({id}, ({}))",
            ope_cast("int4_ord_ope", "aa", op)
        ))
        .execute(&pool)
        .await?;
    }

    let by_extractor: Vec<i32> =
        sqlx::query_scalar("SELECT id FROM ope_smoke ORDER BY eql_v3.ord_ope_term(payload)")
            .fetch_all(&pool)
            .await?;
    assert_eq!(
        by_extractor,
        [2, 3, 1],
        "extractor ORDER BY must sort by decoded bytes"
    );

    let err = sqlx::query("SELECT id FROM ope_smoke ORDER BY payload USING <")
        .fetch_all(&pool)
        .await
        .unwrap_err();
    assert!(
        format!("{err}").contains("is not a valid ordering operator"),
        "ORDER BY USING < must reject (no opclass on the domain), got: {err}"
    );
    Ok(())
}

#[sqlx::test]
async fn ord_ope_min_max_aggregates(pool: PgPool) -> anyhow::Result<()> {
    sqlx::query("CREATE TABLE ope_agg (payload eql_v3.int4_ord_ope)")
        .execute(&pool)
        .await?;
    for op in ["0a", "00", "ff"] {
        sqlx::query(&format!(
            "INSERT INTO ope_agg VALUES (({}))",
            ope_cast("int4_ord_ope", "aa", op)
        ))
        .execute(&pool)
        .await?;
    }
    let min_op: String =
        sqlx::query_scalar("SELECT (eql_v3.min(payload))::jsonb ->> 'op' FROM ope_agg")
            .fetch_one(&pool)
            .await?;
    assert_eq!(min_op, "00");
    let max_op: String =
        sqlx::query_scalar("SELECT (eql_v3.max(payload))::jsonb ->> 'op' FROM ope_agg")
            .fetch_one(&pool)
            .await?;
    assert_eq!(max_op, "ff");
    Ok(())
}
