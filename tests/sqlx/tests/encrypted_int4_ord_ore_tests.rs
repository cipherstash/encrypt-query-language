//! Fixture-based test suite for `eql_v2_int4_ord_ore` — the concrete
//! ordered variant (equality + ORE-block ordering).
//!
//! Consumes `tests/sqlx/migrations/009_install_encrypted_int4_fixture.sql`
//! (table `encrypted_int4_plaintext`, column `payload JSONB NOT NULL`).
//! Each row pairs a plaintext integer with its encrypted JSONB payload
//! carrying `c`, `hm`, `ob` terms.
//!
//! Value set: { -100, -1, 1, 2, 5, 10, 17, 25, 42, 50, 100, 250, 1000, 9999 }
//! 14 rows. Range pivots produce distinct cardinalities so swapped
//! operators would fail the assertions, not silently pass.
//!
//! Equality and range both route through `eql_v2.ord_term`: `col <op> $1`
//! inlines to `eql_v2.ord_term(col) <op> eql_v2.ord_term($1)`, the operator on
//! `eql_v2.ore_block_u64_8_256`. A single functional btree
//! `USING btree (eql_v2.ord_term(col))` serves all six operators — there is
//! no operator class on the domain. `ORDER BY eql_v2.ord_term(col)` sorts in
//! plaintext numeric order. Equality routes through the `ob` term
//! (lossless ORE on full-domain int4 = exact equality); there is no
//! `hm` term on the ordered variants (D#1).
//!
//! Most tests cast `payload::eql_v2_int4_ord_ore` per-query so the
//! fixture table itself stays JSONB-shaped.

use anyhow::Result;
use sqlx::PgPool;

/// Pull plaintext column out of fixture rows whose payload satisfies a
/// predicate. The predicate is the SQL fragment that goes after `WHERE`.
async fn plaintexts_matching(pool: &PgPool, predicate: &str) -> Result<Vec<i32>> {
    let sql = format!(
        "SELECT plaintext FROM encrypted_int4_plaintext WHERE {predicate} ORDER BY plaintext"
    );
    let mut rows: Vec<i32> = sqlx::query_scalar(&sql).fetch_all(pool).await?;
    rows.sort();
    Ok(rows)
}

#[sqlx::test]
async fn encrypted_int4_equality_matches_self(pool: PgPool) -> Result<()> {
    // For each fixture plaintext, looking up by `=` against that row's own
    // payload must return exactly that plaintext.
    for target in [-100, -1, 1, 42, 9999] {
        let needle: String = sqlx::query_scalar(
            "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = $1",
        )
        .bind(target)
        .fetch_one(&pool)
        .await?;

        let matched: Vec<i32> = plaintexts_matching(
            &pool,
            &format!(
                "payload::eql_v2_int4_ord_ore = '{}'::jsonb::eql_v2_int4_ord_ore",
                needle.replace('\'', "''")
            ),
        )
        .await?;
        assert_eq!(matched, vec![target], "= against payload of {target}");
    }

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_equality_cross_type_shapes(pool: PgPool) -> Result<()> {
    // = in all three signature shapes against the payload of 42.
    let needle: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&pool)
    .await?;
    let lit = needle.replace('\'', "''");

    // (domain, domain)
    let ids: Vec<i32> = plaintexts_matching(
        &pool,
        &format!("payload::eql_v2_int4_ord_ore = '{lit}'::jsonb::eql_v2_int4_ord_ore"),
    )
    .await?;
    assert_eq!(ids, vec![42], "(domain, domain) =");

    // (domain, jsonb)
    let ids: Vec<i32> = plaintexts_matching(
        &pool,
        &format!("payload::eql_v2_int4_ord_ore = '{lit}'::jsonb"),
    )
    .await?;
    assert_eq!(ids, vec![42], "(domain, jsonb) =");

    // (jsonb, domain) — ORM bind shape
    let ids: Vec<i32> = plaintexts_matching(
        &pool,
        &format!("'{lit}'::jsonb = payload::eql_v2_int4_ord_ore"),
    )
    .await?;
    assert_eq!(ids, vec![42], "(jsonb, domain) =");

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_inequality_against_42(pool: PgPool) -> Result<()> {
    let needle: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&pool)
    .await?;
    let lit = needle.replace('\'', "''");

    let ids: Vec<i32> = plaintexts_matching(
        &pool,
        &format!("payload::eql_v2_int4_ord_ore <> '{lit}'::jsonb::eql_v2_int4_ord_ore"),
    )
    .await?;
    // 14 rows, exclude 42 → 13 remaining
    let mut expected = vec![-100, -1, 1, 2, 5, 10, 17, 25, 50, 100, 250, 1000, 9999];
    expected.sort();
    assert_eq!(ids, expected, "<> against 42 should exclude only 42");

    // Reverse shape sweep
    let ids: Vec<i32> = plaintexts_matching(
        &pool,
        &format!("'{lit}'::jsonb <> payload::eql_v2_int4_ord_ore"),
    )
    .await?;
    assert_eq!(ids, expected, "reverse-shape <> against 42");

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_range_operators_match_numeric_semantics(pool: PgPool) -> Result<()> {
    // Pivot value 10. Numeric ground truth for each range operator:
    //   < 10  → { -100, -1, 1, 2, 5 }                       (5 rows)
    //   <= 10 → { -100, -1, 1, 2, 5, 10 }                   (6 rows)
    //   > 10  → { 17, 25, 42, 50, 100, 250, 1000, 9999 }    (8 rows)
    //   >= 10 → { 10, 17, 25, 42, 50, 100, 250, 1000, 9999 } (9 rows)
    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 10",
    )
    .fetch_one(&pool)
    .await?;
    let lit = pivot.replace('\'', "''");

    let cases: &[(&str, Vec<i32>)] = &[
        ("<", vec![-100, -1, 1, 2, 5]),
        ("<=", vec![-100, -1, 1, 2, 5, 10]),
        (">", vec![17, 25, 42, 50, 100, 250, 1000, 9999]),
        (">=", vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999]),
    ];

    for (op, expected) in cases {
        let mut expected_sorted = expected.clone();
        expected_sorted.sort();

        // Forward shapes — value on the LHS.
        for rhs in ["'{LIT}'::jsonb::eql_v2_int4_ord_ore", "'{LIT}'::jsonb"] {
            let rhs_sql = rhs.replace("{LIT}", &lit);
            let predicate = format!("payload::eql_v2_int4_ord_ore {op} {rhs_sql}");
            let ids = plaintexts_matching(&pool, &predicate).await?;
            assert_eq!(
                ids, expected_sorted,
                "forward {op} with rhs {rhs}: predicate={predicate}"
            );
        }

        // Reverse shape — pivot on the LHS inverts the expected set.
        // Forward `value < 10` → rows where value < 10
        // Reverse `10 < value` → rows where value > 10 → "opposite" op's set
        let reverse_expected: Vec<i32> = match *op {
            "<" => vec![17, 25, 42, 50, 100, 250, 1000, 9999], // >
            "<=" => vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999], // >=
            ">" => vec![-100, -1, 1, 2, 5],                    // <
            ">=" => vec![-100, -1, 1, 2, 5, 10],               // <=
            _ => unreachable!(),
        };
        let mut reverse_sorted = reverse_expected.clone();
        reverse_sorted.sort();
        let predicate = format!("'{lit}'::jsonb {op} payload::eql_v2_int4_ord_ore");
        let ids = plaintexts_matching(&pool, &predicate).await?;
        assert_eq!(
            ids, reverse_sorted,
            "reverse {op} (pivot {op} value): predicate={predicate}"
        );
    }

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ore_ordering_matches_numeric_ordering(pool: PgPool) -> Result<()> {
    // Critical invariant: ORE bytes from Proxy must preserve numeric order.
    // Pulling all 14 rows ordered by eql_v2.ord_term — the uniform ordered-int4
    // index/ORDER BY extractor — must yield the plaintext sequence in
    // ascending numeric order. A bug in Proxy's ORE-block encoding (sign
    // handling, byte-order, padding) would fail this without throwing.
    //
    // ORDER BY eql_v2.ord_term(payload::eql_v2_int4_ord_ore) pins the sort to
    // the ORE-block term; sorting the domain column directly would follow
    // native jsonb comparison, not ORE order.
    let ordered: Vec<i32> = sqlx::query_scalar(
        r#"
        SELECT plaintext
        FROM encrypted_int4_plaintext
        ORDER BY eql_v2.ord_term(payload::eql_v2_int4_ord_ore)
        "#,
    )
    .fetch_all(&pool)
    .await?;

    let expected = vec![-100, -1, 1, 2, 5, 10, 17, 25, 42, 50, 100, 250, 1000, 9999];
    assert_eq!(
        ordered, expected,
        "eql_v2.ord_term ordering must match numeric ordering of plaintext"
    );

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ord_distinctness_sweep(pool: PgPool) -> Result<()> {
    // Pairwise: no two distinct integer plaintexts share an ORE term.
    // Equality routes through eql_v2.ord_term (the `ob` term), not HMAC —
    // 14 distinct ints → 14 distinct ORE terms → no `=` collisions.
    let collisions: i64 = sqlx::query_scalar(
        r#"
        SELECT count(*)
        FROM encrypted_int4_plaintext a
        JOIN encrypted_int4_plaintext b ON a.id < b.id
        WHERE a.payload::eql_v2_int4_ord_ore = b.payload::eql_v2_int4_ord_ore
        "#,
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        collisions, 0,
        "no two distinct integer plaintexts may share an ORE term"
    );

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ord_ore_functional_index_serves_range_and_equality(
    pool: PgPool,
) -> Result<()> {
    // Range + equality on eql_v2_int4_ord_ore are served by one
    // functional btree USING btree (eql_v2.ord_term(col)). eql_v2.ord_term
    // returns eql_v2.ore_block_u64_8_256, which carries main's DEFAULT
    // btree operator class — no opclass annotation needed.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_ore_fi (\
             plaintext integer, \
             value eql_v2_int4_ord_ore\
         ) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_ore_fi(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_ord_ore FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX ord_ore_fi_idx ON ord_ore_fi USING btree (eql_v2.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE ord_ore_fi").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 10",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    // Engagement: =, <, <=, >, >= each engage the functional btree.
    for op in ["=", "<", "<=", ">", ">="] {
        let plan: Vec<String> = sqlx::query_scalar(&format!(
            "EXPLAIN SELECT * FROM ord_ore_fi \
             WHERE value {op} '{lit}'::jsonb::eql_v2_int4_ord_ore"
        ))
        .fetch_all(&mut *tx)
        .await?;
        let plan_text = plan.join("\n");
        assert!(
            plan_text.contains("ord_ore_fi_idx"),
            "{op} must engage the eql_v2.ord_term functional btree; plan:\n{plan_text}"
        );
    }

    // Correctness via the index: numeric ground truth against pivot 10.
    let cases: &[(&str, Vec<i32>)] = &[
        ("=", vec![10]),
        ("<", vec![-100, -1, 1, 2, 5]),
        ("<=", vec![-100, -1, 1, 2, 5, 10]),
        (">", vec![17, 25, 42, 50, 100, 250, 1000, 9999]),
        (">=", vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999]),
    ];
    for (op, expected) in cases {
        let mut ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT plaintext FROM ord_ore_fi \
             WHERE value {op} '{lit}'::jsonb::eql_v2_int4_ord_ore"
        ))
        .fetch_all(&mut *tx)
        .await?;
        ids.sort();
        let mut want = expected.clone();
        want.sort();
        assert_eq!(
            ids, want,
            "{op} via functional index must match ground truth"
        );
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ord_ore_unsupported_operators_raise(pool: PgPool) -> Result<()> {
    // The _ord_ore variant supports equality + ORE range. Every other
    // operator must raise the variant-specific blocker error rather than
    // fall through to native jsonb semantics.
    //
    // We use the fixture payload of 42 (any row would work) cast to the
    // domain to exercise the (domain, domain) shape, then sweep the other
    // two declared shapes.
    let payload: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&pool)
    .await?;
    let lit = payload.replace('\'', "''");

    let shapes: &[(&str, &str)] = &[
        (
            "$1::jsonb::eql_v2_int4_ord_ore",
            "$2::jsonb::eql_v2_int4_ord_ore",
        ),
        ("$1::jsonb::eql_v2_int4_ord_ore", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::eql_v2_int4_ord_ore"),
    ];

    for op in ["~~", "~~*", "@>", "<@"] {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query(&sql)
                .bind(&payload)
                .bind(&payload)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_ord_ore {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4_ord_ore");
            assert!(
                err.contains(&expected),
                "blocker error mismatch: {sql} -> {err}"
            );
        }
    }

    // Path operators across all three asymmetric shapes.
    for op in ["->", "->>"] {
        for sql in [
            format!(
                "SELECT '{}'::jsonb::eql_v2_int4_ord_ore {op} 'field'::text",
                lit
            ),
            format!(
                "SELECT '{}'::jsonb::eql_v2_int4_ord_ore {op} 0::integer",
                lit
            ),
            format!(
                "SELECT '{}'::jsonb {op} '{}'::jsonb::eql_v2_int4_ord_ore",
                lit, lit
            ),
        ] {
            let err = sqlx::query(&sql)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_ord_ore {op} must raise: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for eql_v2_int4_ord_ore");
            assert!(
                err.contains(&expected),
                "path-op blocker error mismatch: {sql} -> {err}"
            );
        }
    }

    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ord_ore_blocked_operators_raise_on_null_input(pool: PgPool) -> Result<()> {
    // A blocker declared STRICT lets PostgreSQL skip the body and return
    // NULL on a NULL argument, silently bypassing the
    // "operator … is not supported" exception. The blocker contract is
    // "always raises" — guard against STRICT regressing back in.
    let null: Option<&str> = None;

    let err =
        sqlx::query("SELECT $1::jsonb::eql_v2_int4_ord_ore ~~ $2::jsonb::eql_v2_int4_ord_ore")
            .bind(null)
            .bind(null)
            .fetch_one(&pool)
            .await
            .expect_err("eql_v2_int4_ord_ore ~~ must raise on NULL input")
            .to_string();
    assert!(
        err.contains("operator ~~ is not supported for eql_v2_int4_ord_ore"),
        "unexpected error for ~~ on NULL: {err}"
    );

    let err = sqlx::query("SELECT $1::jsonb -> $2::jsonb::eql_v2_int4_ord_ore")
        .bind(null)
        .bind(null)
        .fetch_one(&pool)
        .await
        .expect_err("eql_v2_int4_ord_ore -> must raise on NULL input")
        .to_string();
    assert!(
        err.contains("operator -> is not supported for eql_v2_int4_ord_ore"),
        "unexpected error for -> on NULL: {err}"
    );
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ord_ore_null_operand_yields_null(pool: PgPool) -> Result<()> {
    // STRICT comparison wrappers: a NULL operand propagates NULL
    // (standard SQL three-valued logic), not an error and not a match.
    let payload: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&pool)
    .await?;
    let null: Option<&str> = None;

    for op in ["=", "<>", "<", "<=", ">", ">="] {
        let result: Option<bool> = sqlx::query_scalar(&format!(
            "SELECT $1::jsonb::eql_v2_int4_ord_ore {op} $2::jsonb::eql_v2_int4_ord_ore"
        ))
        .bind(&payload)
        .bind(null)
        .fetch_one(&pool)
        .await?;
        assert!(
            result.is_none(),
            "{op} with a NULL operand must yield NULL, got {result:?}"
        );
    }
    Ok(())
}

#[sqlx::test]
async fn encrypted_int4_ord_ore_equality_uses_ob_not_hm(pool: PgPool) -> Result<()> {
    // D#1: ordered variants carry c + ob and drop hm. Equality routes
    // through eql_v2.ord_term (the `ob` term), never HMAC. Strip `hm` from
    // every payload: with no hm present, an accidental regression to
    // HMAC equality fails instead of silently passing on the fixture.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_ore_no_hm (\
             plaintext integer, value eql_v2_int4_ord_ore\
         ) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_ore_no_hm(plaintext, value) \
         SELECT plaintext, (payload - 'hm')::eql_v2_int4_ord_ore \
         FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    // Sanity: no row carries `hm` (jsonb_exists is the function form of
    // the `?` key-exists operator — avoids `?` in the SQLx query string).
    let with_hm: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM ord_ore_no_hm WHERE jsonb_exists(value::jsonb, 'hm')",
    )
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(with_hm, 0, "test rows must not carry hm");

    sqlx::query(
        "CREATE INDEX ord_ore_no_hm_idx ON ord_ore_no_hm USING btree (eql_v2.ord_term(value))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE ord_ore_no_hm")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT (payload - 'hm')::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    // Equality + inequality return correct rows with no hm present.
    let eq: Vec<i32> = sqlx::query_scalar(&format!(
        "SELECT plaintext FROM ord_ore_no_hm \
         WHERE value = '{lit}'::jsonb::eql_v2_int4_ord_ore"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(eq, vec![42], "= must match via ob with no hm present");

    let neq_count: i64 = sqlx::query_scalar(&format!(
        "SELECT count(*) FROM ord_ore_no_hm \
         WHERE value <> '{lit}'::jsonb::eql_v2_int4_ord_ore"
    ))
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(neq_count, 13, "<> must match the other 13 rows");

    // The functional btree still engages for equality with no hm.
    let plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM ord_ore_no_hm \
         WHERE value = '{lit}'::jsonb::eql_v2_int4_ord_ore"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert!(
        plan.join("\n").contains("ord_ore_no_hm_idx"),
        "= must engage the eql_v2.ord_term functional btree with no hm present"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn ord_ore_functional_index_serves_constant_on_left(pool: PgPool) -> Result<()> {
    // The functional btree on eql_v2.ord_term(col) must engage when the
    // literal is on the LEFT (`$1 < col`) — the commuted shape — for an
    // eql_v2_int4_ord_ore column, in both the (domain, domain) and
    // (jsonb, domain) operator forms.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_ore_cl (\
             plaintext integer, value eql_v2_int4_ord_ore\
         ) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_ore_cl(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_ord_ore FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX ord_ore_cl_idx ON ord_ore_cl USING btree (eql_v2.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE ord_ore_cl").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 10",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    // Pivot 10 on the LEFT — the expected set is the commuted operator's
    // ground truth (`10 < value` selects rows where value > 10).
    let cases: &[(&str, Vec<i32>)] = &[
        ("=", vec![10]),
        ("<", vec![17, 25, 42, 50, 100, 250, 1000, 9999]),
        ("<=", vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999]),
        (">", vec![-100, -1, 1, 2, 5]),
        (">=", vec![-100, -1, 1, 2, 5, 10]),
    ];
    for (op, expected) in cases {
        for rhs_cast in ["::eql_v2_int4_ord_ore", ""] {
            let predicate = format!("'{lit}'::jsonb{rhs_cast} {op} value");
            let plan: Vec<String> = sqlx::query_scalar(&format!(
                "EXPLAIN SELECT * FROM ord_ore_cl WHERE {predicate}"
            ))
            .fetch_all(&mut *tx)
            .await?;
            let plan_text = plan.join("\n");
            assert!(
                plan_text.contains("ord_ore_cl_idx"),
                "constant-on-left {op} must engage the functional btree; \
                 predicate={predicate}\nplan:\n{plan_text}"
            );

            let mut ids: Vec<i32> = sqlx::query_scalar(&format!(
                "SELECT plaintext FROM ord_ore_cl WHERE {predicate}"
            ))
            .fetch_all(&mut *tx)
            .await?;
            ids.sort();
            let mut want = expected.clone();
            want.sort();
            assert_eq!(
                ids, want,
                "constant-on-left {op} must match commuted ground truth; \
                 predicate={predicate}"
            );
        }
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn ord_ore_rejects_payload_missing_required_keys(pool: PgPool) -> Result<()> {
    // The eql_v2_int4_ord_ore domain CHECK requires v, i, c, ob. A
    // payload missing any required key is rejected at the cast.
    for (label, json) in [
        ("missing ob", r#"{"v":2,"i":{"t":"t","c":"c"},"c":"x"}"#),
        ("missing c", r#"{"v":2,"i":{"t":"t","c":"c"},"ob":["aa"]}"#),
    ] {
        let err = sqlx::query(&format!("SELECT '{json}'::jsonb::eql_v2_int4_ord_ore"))
            .fetch_one(&pool)
            .await
            .expect_err(&format!("eql_v2_int4_ord_ore must reject payload: {label}"))
            .to_string();
        assert!(
            err.contains("violates check constraint"),
            "{label}: expected a check-constraint violation, got: {err}"
        );
    }
    Ok(())
}
