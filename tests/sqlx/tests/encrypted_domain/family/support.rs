//! Self-checks for the type-generic matrix substrate
//! (`tests/sqlx/src/scalar_domains.rs`). Each test pins one piece of the
//! `ScalarType` / `Variant` / assertion-helper API that the matrix
//! depends on.

use anyhow::Result;
use eql_tests::{
    assert_null, assert_raises, assert_scalar_plaintexts, blocker_msg, fetch_fixture_payload,
    sql_string_literal, ScalarDomainSpec, ScalarType, Variant, PLACEHOLDER_PAYLOAD,
};
use sqlx::PgPool;

#[test]
fn variant_derives_consistent_sql_domain_and_capabilities() {
    let storage = ScalarDomainSpec::new::<i32>(Variant::Storage);
    assert_eq!(storage.sql_domain, "eql_v2_int4");
    assert!(!storage.supports_eq());
    assert!(!storage.supports_ord());
    assert_eq!(storage.extractor_fn(), None);
    assert_eq!(Variant::Storage.required_term(), None);

    let eq = ScalarDomainSpec::new::<i32>(Variant::Eq);
    assert_eq!(eq.sql_domain, "eql_v2_int4_eq");
    assert!(eq.supports_eq());
    assert!(!eq.supports_ord());
    assert_eq!(eq.extractor_fn(), Some("eql_v2.eq_term"));
    assert_eq!(Variant::Eq.required_term(), Some("hm"));

    let ord = ScalarDomainSpec::new::<i32>(Variant::Ord);
    assert_eq!(ord.sql_domain, "eql_v2_int4_ord");
    assert!(ord.supports_ord());
    assert_eq!(ord.extractor_fn(), Some("eql_v2.ord_term"));
    assert_eq!(Variant::Ord.required_term(), Some("ob"));

    let ord_ore = ScalarDomainSpec::new::<i32>(Variant::OrdOre);
    assert_eq!(ord_ore.sql_domain, "eql_v2_int4_ord_ore");
    assert!(ord_ore.supports_ord());
    assert_eq!(ord_ore.extractor_fn(), Some("eql_v2.ord_term"));
}

#[test]
fn expected_forward_default_is_numeric_ground_truth() {
    // Pinned against the full 17-row fixture (extremes + zero + the
    // original 14). The output is sorted-ascending by `expected_forward`,
    // so a regression in the default impl's filter or sort shows up
    // here.
    assert_eq!(<i32 as ScalarType>::expected_forward("=", 10), vec![10]);
    assert_eq!(
        <i32 as ScalarType>::expected_forward("<", 10),
        vec![i32::MIN, -100, -1, 0, 1, 2, 5]
    );
    assert_eq!(
        <i32 as ScalarType>::expected_forward("<=", 10),
        vec![i32::MIN, -100, -1, 0, 1, 2, 5, 10]
    );
    assert_eq!(
        <i32 as ScalarType>::expected_forward(">", 10),
        vec![17, 25, 42, 50, 100, 250, 1000, 9999, i32::MAX]
    );
    assert_eq!(
        <i32 as ScalarType>::expected_forward(">=", 10),
        vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999, i32::MAX]
    );
    assert_eq!(
        <i32 as ScalarType>::expected_forward("<>", 42),
        vec![
            i32::MIN, -100, -1, 0, 1, 2, 5, 10, 17, 25, 50, 100, 250, 1000, 9999, i32::MAX
        ]
    );
}

#[test]
fn sql_string_literal_escapes_single_quotes() {
    assert_eq!(sql_string_literal("abc'def"), "'abc''def'");
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_int4")))]
async fn fetch_fixture_payload_returns_keyed_row(pool: PgPool) -> Result<()> {
    // Parse the payload as JSON rather than substring-matching — whitespace
    // and key ordering in the serialised form are not contract.
    let payload = fetch_fixture_payload::<i32>(&pool, 42).await?;
    let value: serde_json::Value = serde_json::from_str(&payload)?;
    assert_eq!(value["v"], serde_json::json!(2), "payload must carry v=2");
    assert!(value.get("c").is_some(), "payload must carry a c field");
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_int4")))]
async fn assert_scalar_plaintexts_reports_sql_context(pool: PgPool) -> Result<()> {
    let lit = sql_string_literal(&fetch_fixture_payload::<i32>(&pool, 42).await?);
    let predicate = format!("payload::eql_v2_int4_ord_ore = {lit}::jsonb::eql_v2_int4_ord_ore");
    assert_scalar_plaintexts::<i32>(&pool, "eql_v2_int4_ord_ore", "=", &predicate, &[42]).await?;
    Ok(())
}

#[sqlx::test]
async fn placeholder_payload_satisfies_every_variant_check(pool: PgPool) -> Result<()> {
    // The whole point of PLACEHOLDER_PAYLOAD: one sentinel that casts
    // successfully to every domain in the family. If a variant CHECK
    // tightens, this test fails and PLACEHOLDER_PAYLOAD needs updating.
    //
    // Iterates `Variant::ALL` against `<T as ScalarType>::PG_TYPE`
    // rather than hardcoding domain names — when `int8` (or any future
    // scalar) lands, this test picks it up automatically by extending
    // the type list below.
    for variant in Variant::ALL {
        let spec = ScalarDomainSpec::new::<i32>(*variant);
        let sql = format!("SELECT $1::jsonb::{}", spec.sql_domain);
        sqlx::query(&sql)
            .bind(PLACEHOLDER_PAYLOAD)
            .fetch_one(&pool)
            .await
            .map_err(|e| {
                anyhow::anyhow!(
                    "PLACEHOLDER_PAYLOAD must cast to {}: {e}",
                    spec.sql_domain
                )
            })?;
    }
    Ok(())
}

#[sqlx::test]
async fn assert_raises_two_bind_blocker(pool: PgPool) -> Result<()> {
    let msg = blocker_msg("eql_v2_int4", "=");
    assert_raises(
        &pool,
        "SELECT $1::jsonb::eql_v2_int4 = $2::jsonb::eql_v2_int4",
        &[Some(PLACEHOLDER_PAYLOAD), Some(PLACEHOLDER_PAYLOAD)],
        &msg,
    )
    .await
}

#[sqlx::test]
async fn assert_raises_one_bind_path_blocker(pool: PgPool) -> Result<()> {
    let msg = blocker_msg("eql_v2_int4", "->");
    assert_raises(
        &pool,
        "SELECT $1::jsonb::eql_v2_int4 -> 'field'::text",
        &[Some(PLACEHOLDER_PAYLOAD)],
        &msg,
    )
    .await
}

#[sqlx::test]
async fn assert_raises_native_operator_absent(pool: PgPool) -> Result<()> {
    // ~~ (LIKE) isn't declared on int4 — error message is PG's native
    // "operator does not exist", not an EQL blocker message.
    assert_raises(
        &pool,
        "SELECT $1::jsonb::eql_v2_int4 ~~ $2::jsonb::eql_v2_int4",
        &[Some(PLACEHOLDER_PAYLOAD), Some(PLACEHOLDER_PAYLOAD)],
        "operator does not exist",
    )
    .await
}

#[sqlx::test]
async fn omitted_native_jsonb_operators_raise_eql_blockers(pool: PgPool) -> Result<()> {
    let cases: &[(&str, &[Option<&str>], &str)] = &[
        (
            "SELECT $1::jsonb::eql_v2_int4 ? 'c'::text",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "?",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 ?| ARRAY['c']",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "?|",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 ?& ARRAY['c']",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "?&",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 #> ARRAY['i']",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "#>",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 #>> ARRAY['i', 'c']",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "#>>",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 @? '$.c'::jsonpath",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "@?",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 @@ '$.c == \"placeholder\"'::jsonpath",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "@@",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 - 'c'::text",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "-",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 - 0",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "-",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 - ARRAY['c']",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "-",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 #- ARRAY['i']",
            &[Some(PLACEHOLDER_PAYLOAD)],
            "#-",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 || $2::jsonb",
            &[Some(PLACEHOLDER_PAYLOAD), Some(PLACEHOLDER_PAYLOAD)],
            "||",
        ),
        (
            "SELECT $1::jsonb || $2::jsonb::eql_v2_int4",
            &[Some(PLACEHOLDER_PAYLOAD), Some(PLACEHOLDER_PAYLOAD)],
            "||",
        ),
        (
            "SELECT $1::jsonb::eql_v2_int4 || $2::jsonb::eql_v2_int4",
            &[Some(PLACEHOLDER_PAYLOAD), Some(PLACEHOLDER_PAYLOAD)],
            "||",
        ),
    ];

    for (sql, binds, op) in cases {
        assert_raises(&pool, sql, binds, &blocker_msg("eql_v2_int4", op)).await?;
    }
    Ok(())
}

#[sqlx::test]
async fn assert_raises_engages_on_all_null(pool: PgPool) -> Result<()> {
    // Non-STRICT blocker proof — must raise even with NULL on both sides.
    let msg = blocker_msg("eql_v2_int4", "=");
    assert_raises(
        &pool,
        "SELECT $1::jsonb::eql_v2_int4 = $2::jsonb::eql_v2_int4",
        &[None, None],
        &msg,
    )
    .await
}

#[sqlx::test]
async fn assert_null_propagates_through_supported_op(pool: PgPool) -> Result<()> {
    // STRICT supported op with one NULL operand yields NULL.
    assert_null(
        &pool,
        "SELECT $1::jsonb::eql_v2_int4_eq = $2::jsonb::eql_v2_int4_eq",
        &[Some(PLACEHOLDER_PAYLOAD), None],
    )
    .await
}

#[sqlx::test]
async fn neq_propagates_null_under_three_valued_logic(pool: PgPool) -> Result<()> {
    // `<>` with a NULL operand must yield NULL (not true, not false).
    // Three-valued logic is easy to get wrong in domain wrappers; a
    // STRICT supported `<>` returns NULL on either NULL side.
    for binds in [
        &[Some(PLACEHOLDER_PAYLOAD), None][..],
        &[None, Some(PLACEHOLDER_PAYLOAD)][..],
        &[None, None][..],
    ] {
        assert_null(
            &pool,
            "SELECT $1::jsonb::eql_v2_int4_eq <> $2::jsonb::eql_v2_int4_eq",
            binds,
        )
        .await?;
    }
    Ok(())
}

#[sqlx::test]
async fn no_cross_variant_equality_operator_is_declared(pool: PgPool) -> Result<()> {
    // The family deliberately does NOT define operators that mix two
    // different capability variants — `eql_v2_int4_eq = eql_v2_int4_ord`
    // would resolve against jsonb (the ultimate base type) and silently
    // bypass the per-variant blockers. If someone accidentally adds such
    // an operator, this test fails.
    //
    // The check is structural (`pg_operator`) rather than dynamic
    // ("invoke and see it raise") so a future PG version with stricter
    // operator resolution doesn't mask the regression.
    let cross_variant: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT format('%s(%s, %s)',
                      o.oprname, lt.typname, rt.typname)
        FROM pg_catalog.pg_operator o
        JOIN pg_catalog.pg_type lt ON lt.oid = o.oprleft
        JOIN pg_catalog.pg_type rt ON rt.oid = o.oprright
        WHERE lt.typname LIKE 'eql_v2\_%'
          AND rt.typname LIKE 'eql_v2\_%'
          AND lt.typname <> rt.typname
        ORDER BY 1
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        cross_variant.is_empty(),
        "no operator should mix two different eql_v2_* domain types, but found: {cross_variant:#?}"
    );
    Ok(())
}
