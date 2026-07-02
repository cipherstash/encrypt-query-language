//! Literal-payload smoke tests for the generated `eql_v3.*_ord_ope` surface:
//! the CLLW-OPE term (`op`) is a hex-encoded ciphertext that is
//! order-preserving under native bytea comparison, so ordering assertions can
//! be stated directly on hand-built hex strings — deterministic, no
//! encryption/fixtures needed (the pinned cipherstash-client does not emit
//! `op` yet, so there is no generated fixture to lean on). Covers: the
//! comparison wrappers route through `eql_v3.ord_ope_term` / native bytea
//! order, text `=` routes through `hm` (not `op`), blockers still raise, the
//! domain CHECK requires `op`, and ORDER BY (extractor + USING) sorts by
//! decoded bytes.
use sqlx::PgPool;

/// Build a literal `eql_v3.int4_ord_ope` cast expression carrying the CLLW-OPE
/// hex term `op`.
fn int4_ope_cast(op_hex: &str) -> String {
    format!("'{{\"v\":3,\"i\":{{}},\"c\":\"x\",\"op\":\"{op_hex}\"}}'::jsonb::eql_v3.int4_ord_ope")
}

/// Build a literal `eql_v3.text_ord_ope` cast expression carrying both the
/// exact-equality term `hm` and the CLLW-OPE hex term `op`.
fn text_ope_cast(hm: &str, op_hex: &str) -> String {
    format!(
        "'{{\"v\":3,\"i\":{{}},\"c\":\"x\",\"hm\":\"{hm}\",\"op\":\"{op_hex}\"}}'::jsonb::eql_v3.text_ord_ope"
    )
}

#[sqlx::test]
async fn ord_ope_orders_by_decoded_bytes(pool: PgPool) -> anyhow::Result<()> {
    // Native bytea order over the decoded hex: 0x00ff < 0x0100 (a hex-STRING
    // comparison would also say so; 0x02 < 0x0100 would not — assert both, so
    // the test fails if comparison ever degrades to text order over the hex).
    for (lo, hi) in [("00ff", "0100"), ("00", "0100"), ("0a", "ff")] {
        let lt: bool = sqlx::query_scalar(&format!(
            "SELECT ({}) < ({})",
            int4_ope_cast(lo),
            int4_ope_cast(hi)
        ))
        .fetch_one(&pool)
        .await?;
        assert!(lt, "op {lo} must sort before op {hi}");

        let gt: bool = sqlx::query_scalar(&format!(
            "SELECT ({}) > ({})",
            int4_ope_cast(hi),
            int4_ope_cast(lo)
        ))
        .fetch_one(&pool)
        .await?;
        assert!(gt, "op {hi} must sort after op {lo}");
    }
    Ok(())
}

#[sqlx::test]
async fn ord_ope_shorter_prefix_sorts_first(pool: PgPool) -> anyhow::Result<()> {
    // Native bytea semantics: a strict prefix sorts before its extension.
    let lt: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) < ({})",
        int4_ope_cast("00ff"),
        int4_ope_cast("00ff01")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(lt, "prefix must sort before its extension");
    Ok(())
}

#[sqlx::test]
async fn ord_ope_equality_is_bytewise(pool: PgPool) -> anyhow::Result<()> {
    let eq: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) = ({})",
        int4_ope_cast("00ffab"),
        int4_ope_cast("00ffab")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(eq, "identical op terms must compare equal");

    let neq: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) <> ({})",
        int4_ope_cast("00ffab"),
        int4_ope_cast("00ffac")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(neq, "different op terms must compare not-equal");
    Ok(())
}

#[sqlx::test]
async fn text_ord_ope_equality_routes_through_hm(pool: PgPool) -> anyhow::Result<()> {
    // text leads with Hm, so `=` resolves through eq_term/hm — two payloads
    // with the SAME hm but DIFFERENT op are equal, and vice versa.
    let same_hm: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) = ({})",
        text_ope_cast("deadbeef", "00"),
        text_ope_cast("deadbeef", "ff")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(same_hm, "text `=` must route through hm, not op");

    let diff_hm: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) = ({})",
        text_ope_cast("deadbeef", "00"),
        text_ope_cast("feedface", "00")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(!diff_hm, "different hm must not compare equal");

    // Ordering still routes through op.
    let lt: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) < ({})",
        text_ope_cast("feedface", "00"),
        text_ope_cast("deadbeef", "ff")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(lt, "text `<` must route through op");
    Ok(())
}

#[sqlx::test]
async fn ord_ope_blocks_unsupported_operators(pool: PgPool) -> anyhow::Result<()> {
    let err = sqlx::query(&format!(
        "SELECT ({}) @> ({})",
        int4_ope_cast("00"),
        int4_ope_cast("00")
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
async fn ord_ope_check_requires_op(pool: PgPool) -> anyhow::Result<()> {
    // The domain CHECK requires the `op` key; an envelope-only payload fails
    // at the cast boundary.
    let err = sqlx::query("SELECT '{\"v\":3,\"i\":{},\"c\":\"x\"}'::jsonb::eql_v3.int4_ord_ope")
        .execute(&pool)
        .await
        .unwrap_err();
    assert!(
        format!("{err}").contains("check constraint"),
        "missing op must violate the domain CHECK, got: {err}"
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
            int4_ope_cast(op)
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
            int4_ope_cast(op)
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
