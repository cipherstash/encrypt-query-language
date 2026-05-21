//! End-to-end test suite for `eql_v2_int4_ord` — the recommended
//! ordered domain name.
//!
//! eql_v2_int4_ord is a concrete ordered domain with its own operators
//! (D-E fallback): the §8 verification spike showed a domain-over-domain
//! alias does not transparently inherit the operator surface. This suite
//! asserts eql_v2_int4_ord behaves correctly on a real column typed
//! eql_v2_int4_ord — operator routing to EQL ORE semantics, blocked
//! operators raising rather than falling through to native jsonb, and
//! functional-index engagement. eql_v2_int4_ord_ore (the scheme-explicit
//! domain) carries the identical operator surface.

use std::path::PathBuf;

use anyhow::Result;
use sqlx::PgPool;

#[sqlx::test]
async fn ord_six_operators_resolve_to_ore_semantics(pool: PgPool) -> Result<()> {
    // On a column typed eql_v2_int4_ord, every operator must resolve to
    // EQL ORE semantics (numeric ground truth), not native jsonb
    // comparison. Pivot is the payload of plaintext 10.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_t (plaintext integer, value eql_v2_int4_ord) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_t(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_ord FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 10",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    let cases: &[(&str, Vec<i32>)] = &[
        ("=", vec![10]),
        (
            "<>",
            vec![-100, -1, 1, 2, 5, 17, 25, 42, 50, 100, 250, 1000, 9999],
        ),
        ("<", vec![-100, -1, 1, 2, 5]),
        ("<=", vec![-100, -1, 1, 2, 5, 10]),
        (">", vec![17, 25, 42, 50, 100, 250, 1000, 9999]),
        (">=", vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999]),
    ];
    for (op, expected) in cases {
        let mut ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT plaintext FROM ord_t \
             WHERE value {op} '{lit}'::jsonb::eql_v2_int4_ord"
        ))
        .fetch_all(&mut *tx)
        .await?;
        ids.sort();
        let mut want = expected.clone();
        want.sort();
        assert_eq!(
            ids, want,
            "{op} on eql_v2_int4_ord must match ORE ground truth"
        );
    }

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn ord_blocked_operators_raise(pool: PgPool) -> Result<()> {
    // Blocked operators on eql_v2_int4_ord must raise, never fall through
    // to native jsonb @>/<@/->/->>. The error names the concrete domain
    // the blocker is defined on; assert only "is not supported" + the
    // operator symbol so the test is robust to the exact type name.
    let payload: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&pool)
    .await?;

    let shapes: &[(&str, &str)] = &[
        ("$1::jsonb::eql_v2_int4_ord", "$2::jsonb::eql_v2_int4_ord"),
        ("$1::jsonb::eql_v2_int4_ord", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::eql_v2_int4_ord"),
    ];
    for op in ["@>", "<@"] {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query(&sql)
                .bind(&payload)
                .bind(&payload)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_ord {op} must raise: {sql}"))
                .to_string();
            assert!(
                err.contains("is not supported") && err.contains(op),
                "blocked {op} must raise 'not supported': {sql} -> {err}"
            );
        }
    }

    let lit = payload.replace('\'', "''");
    for op in ["->", "->>"] {
        for sql in [
            format!("SELECT '{lit}'::jsonb::eql_v2_int4_ord {op} 'field'::text"),
            format!("SELECT '{lit}'::jsonb::eql_v2_int4_ord {op} 0::integer"),
            format!("SELECT '{lit}'::jsonb {op} '{lit}'::jsonb::eql_v2_int4_ord"),
        ] {
            let err = sqlx::query(&sql)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("eql_v2_int4_ord {op} must raise: {sql}"))
                .to_string();
            assert!(
                err.contains("is not supported") && err.contains(op),
                "blocked {op} must raise 'not supported': {sql} -> {err}"
            );
        }
    }
    Ok(())
}

#[sqlx::test]
async fn ord_functional_index_serves_range_and_equality(pool: PgPool) -> Result<()> {
    // Range + equality on eql_v2_int4_ord are served by one functional
    // btree USING btree (eql_v2.ord_term(col)).
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_fi (plaintext integer, value eql_v2_int4_ord) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_fi(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_ord FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX ord_fi_idx ON ord_fi USING btree (eql_v2.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE ord_fi").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 10",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    for op in ["=", "<", "<=", ">", ">="] {
        let plan: Vec<String> = sqlx::query_scalar(&format!(
            "EXPLAIN SELECT * FROM ord_fi WHERE value {op} '{lit}'::jsonb::eql_v2_int4_ord"
        ))
        .fetch_all(&mut *tx)
        .await?;
        let plan_text = plan.join("\n");
        assert!(
            plan_text.contains("ord_fi_idx"),
            "{op} must engage the eql_v2.ord_term functional btree; plan:\n{plan_text}"
        );
    }

    let cases: &[(&str, Vec<i32>)] = &[
        ("=", vec![10]),
        ("<", vec![-100, -1, 1, 2, 5]),
        ("<=", vec![-100, -1, 1, 2, 5, 10]),
        (">", vec![17, 25, 42, 50, 100, 250, 1000, 9999]),
        (">=", vec![10, 17, 25, 42, 50, 100, 250, 1000, 9999]),
    ];
    for (op, expected) in cases {
        let mut ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT plaintext FROM ord_fi WHERE value {op} '{lit}'::jsonb::eql_v2_int4_ord"
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
async fn ord_order_by_preserves_numeric_order(pool: PgPool) -> Result<()> {
    // ORDER BY eql_v2.ord_term(col) sorts an eql_v2_int4_ord column in
    // plaintext numeric order.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_sort (plaintext integer, value eql_v2_int4_ord) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_sort(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_ord FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    let ordered: Vec<i32> =
        sqlx::query_scalar("SELECT plaintext FROM ord_sort ORDER BY eql_v2.ord_term(value)")
            .fetch_all(&mut *tx)
            .await?;
    assert_eq!(
        ordered,
        vec![-100, -1, 1, 2, 5, 10, 17, 25, 42, 50, 100, 250, 1000, 9999],
        "ORDER BY eql_v2.ord_term(value) must yield plaintext numeric order"
    );
    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn ord_null_operand_yields_null(pool: PgPool) -> Result<()> {
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
            "SELECT $1::jsonb::eql_v2_int4_ord {op} $2::jsonb::eql_v2_int4_ord"
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
async fn ord_equality_independent_of_hm(pool: PgPool) -> Result<()> {
    // D#1: ordered variants carry c + ob and drop hm. Equality on
    // eql_v2_int4_ord routes through eql_v2.ord_term (the `ob` term), never
    // HMAC. Strip `hm` so an accidental regression to HMAC equality
    // fails instead of passing on the hm-carrying fixture.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_no_hm (plaintext integer, value eql_v2_int4_ord) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_no_hm(plaintext, value) \
         SELECT plaintext, (payload - 'hm')::eql_v2_int4_ord FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    // Sanity: no row carries `hm` (jsonb_exists is the function form of
    // the `?` key-exists operator — avoids `?` in the SQLx query string).
    let with_hm: i64 =
        sqlx::query_scalar("SELECT count(*) FROM ord_no_hm WHERE jsonb_exists(value::jsonb, 'hm')")
            .fetch_one(&mut *tx)
            .await?;
    assert_eq!(with_hm, 0, "test rows must not carry hm");

    sqlx::query("CREATE INDEX ord_no_hm_idx ON ord_no_hm USING btree (eql_v2.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE ord_no_hm").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let pivot: String = sqlx::query_scalar(
        "SELECT (payload - 'hm')::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&mut *tx)
    .await?;
    let lit = pivot.replace('\'', "''");

    let eq: Vec<i32> = sqlx::query_scalar(&format!(
        "SELECT plaintext FROM ord_no_hm WHERE value = '{lit}'::jsonb::eql_v2_int4_ord"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(eq, vec![42], "= must match via ob with no hm present");

    let neq_count: i64 = sqlx::query_scalar(&format!(
        "SELECT count(*) FROM ord_no_hm WHERE value <> '{lit}'::jsonb::eql_v2_int4_ord"
    ))
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(neq_count, 13, "<> must match the other 13 rows");

    let plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM ord_no_hm WHERE value = '{lit}'::jsonb::eql_v2_int4_ord"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert!(
        plan.join("\n").contains("ord_no_hm_idx"),
        "= must engage the eql_v2.ord_term functional btree with no hm present"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn ord_ore_wrappers_are_inlinable(pool: PgPool) -> Result<()> {
    // The comparison wrappers on eql_v2_int4_ord_ore and eql_v2_int4_ord
    // must be LANGUAGE sql, IMMUTABLE, and carry no pinned search_path,
    // so the planner inlines `col < $1` to
    // `eql_v2.ord_term(col) < eql_v2.ord_term($1)` and the functional btree on
    // eql_v2.ord_term(col) engages. A pinned proconfig or a plpgsql body
    // would break the inline chain.
    let rows: Vec<(String, String, String, Option<Vec<String>>)> = sqlx::query_as(
        r#"
        SELECT p.proname,
               l.lanname,
               p.provolatile::text,
               p.proconfig
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        JOIN pg_catalog.pg_type lt ON lt.oid = p.proargtypes[0]
        JOIN pg_catalog.pg_type rt ON rt.oid = p.proargtypes[1]
        WHERE n.nspname = 'eql_v2'
          AND p.proname IN ('eq', 'neq', 'lt', 'lte', 'gt', 'gte')
          AND (lt.typname IN ('eql_v2_int4_ord', 'eql_v2_int4_ord_ore')
            OR rt.typname IN ('eql_v2_int4_ord', 'eql_v2_int4_ord_ore'))
        "#,
    )
    .fetch_all(&pool)
    .await?;

    // 6 converged comparison wrappers (eq/neq/lt/lte/gt/gte) × 2 ordered
    // domains (_ord_ore and the concrete _ord) × 3 arg-shapes = 36 rows.
    assert_eq!(
        rows.len(),
        36,
        "expected 36 ordered comparison wrapper overloads"
    );
    for (name, lang, volatile, config) in &rows {
        assert_eq!(lang, "sql", "{name} must be LANGUAGE sql to inline");
        assert_eq!(volatile, "i", "{name} must be IMMUTABLE");
        assert!(
            config.is_none(),
            "{name} must have no pinned search_path (proconfig)"
        );
    }

    // eql_v2.ord_term must be IMMUTABLE (functional-index requirement) in
    // every spike outcome. The spike (Task 2) fixed its LANGUAGE as sql,
    // so a LANGUAGE sql eql_v2.ord_term must additionally have no proconfig
    // (it must inline); a LANGUAGE plpgsql ord is exempt from that check.
    let ord: Vec<(String, String, Option<Vec<String>>)> = sqlx::query_as(
        r#"
        SELECT l.lanname, p.provolatile::text, p.proconfig
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_catalog.pg_language  l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v2' AND p.proname = 'ord_term'
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(!ord.is_empty(), "eql_v2.ord_term must exist");
    for (lang, volatile, config) in &ord {
        assert_eq!(volatile, "i", "eql_v2.ord_term must be IMMUTABLE");
        if lang == "sql" {
            assert!(
                config.is_none(),
                "a LANGUAGE sql eql_v2.ord_term must have no pinned search_path so it inlines"
            );
        }
    }
    Ok(())
}

/// Structural-sync guard for the two ordered int4 domain file pairs.
///
/// The `_ord_ore` variant (scheme-explicit) and the `_ord` variant (the
/// D-E fallback concrete domain) are deliberate twins: the same
/// `eql_v2.ord_term` extractor, the 18 comparison wrappers, the blockers, and
/// the operator declarations, differing only by the
/// `eql_v2_int4_ord_ore` <-> `eql_v2_int4_ord` type-name swap. A full
/// de-duplication refactor is out of scope for this branch, so this test
/// pins the invariant cheaply: after normalising both type names to a
/// common token, the executable body of each file (from the first
/// declaration onward — the file-header doc comments are intentionally
/// different and excluded) must be byte-identical between the twins. An
/// edit to one file that is not mirrored into the other fails here.
///
/// The split keeps comparison/path functions and operator declarations
/// in separate `_functions.sql` / `_operators.sql` files, so both pairs
/// are checked: `int4_ord_functions.sql` <-> `int4_ord_ore_functions.sql`
/// and `int4_ord_operators.sql` <-> `int4_ord_ore_operators.sql`.
///
/// This is a source-only test; it does not touch the database.
#[test]
fn ordered_int4_domain_files_stay_in_sync() {
    fn body(rel: &str, marker: &str) -> String {
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../src/encrypted_domain/int4")
            .join(rel);
        let text = std::fs::read_to_string(&path)
            .unwrap_or_else(|e| panic!("failed to read {}: {}", path.display(), e));
        // The header doc-comments differ by design; compare only the
        // executable body, which starts at the given marker.
        let start = text
            .find(marker)
            .unwrap_or_else(|| panic!("{} is missing the marker {:?}", path.display(), marker));
        // Normalise the two domain type names to one token. Replace the
        // longer name first so `eql_v2_int4_ord` does not partially match
        // inside `eql_v2_int4_ord_ore`.
        text[start..]
            .replace("eql_v2_int4_ord_ore", "ORDTYPE")
            .replace("eql_v2_int4_ord", "ORDTYPE")
    }

    // Functions: executable body starts at the eql_v2.ord_term extractor.
    assert_eq!(
        body(
            "int4_ord_ore_functions.sql",
            "--! @brief Index/ORDER BY extractor"
        ),
        body(
            "int4_ord_functions.sql",
            "--! @brief Index/ORDER BY extractor"
        ),
        "int4_ord_ore_functions.sql and int4_ord_functions.sql have \
         drifted apart. They must stay mechanical twins (type-name swap \
         only) below the file header; mirror every change into both files."
    );

    // Operators: executable body starts at the operator declarations.
    assert_eq!(
        body("int4_ord_ore_operators.sql", "-- Operator declarations"),
        body("int4_ord_operators.sql", "-- Operator declarations"),
        "int4_ord_ore_operators.sql and int4_ord_operators.sql have \
         drifted apart. They must stay mechanical twins (type-name swap \
         only) below the file header; mirror every change into both files."
    );
}

#[sqlx::test]
async fn ord_functional_index_serves_constant_on_left(pool: PgPool) -> Result<()> {
    // The functional btree on eql_v2.ord_term(col) must engage when the
    // literal is on the LEFT (`$1 < col`) — the commuted shape — for
    // both the (domain, domain) and (jsonb, domain) operator forms.
    // `$1 < col` resolves through COMMUTATOR to `col > $1` for index
    // matching.
    let mut tx = pool.begin().await?;
    sqlx::query(
        "CREATE TEMP TABLE ord_cl (plaintext integer, value eql_v2_int4_ord) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_cl(plaintext, value) \
         SELECT plaintext, payload::eql_v2_int4_ord FROM encrypted_int4_plaintext",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX ord_cl_idx ON ord_cl USING btree (eql_v2.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE ord_cl").execute(&mut *tx).await?;
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
        for rhs_cast in ["::eql_v2_int4_ord", ""] {
            let predicate = format!("'{lit}'::jsonb{rhs_cast} {op} value");
            let plan: Vec<String> =
                sqlx::query_scalar(&format!("EXPLAIN SELECT * FROM ord_cl WHERE {predicate}"))
                    .fetch_all(&mut *tx)
                    .await?;
            let plan_text = plan.join("\n");
            assert!(
                plan_text.contains("ord_cl_idx"),
                "constant-on-left {op} must engage the functional btree; \
                 predicate={predicate}\nplan:\n{plan_text}"
            );

            let mut ids: Vec<i32> =
                sqlx::query_scalar(&format!("SELECT plaintext FROM ord_cl WHERE {predicate}"))
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
async fn ord_operators_declare_planner_metadata(pool: PgPool) -> Result<()> {
    // The real comparison operators on the ordered int4 domains
    // (eql_v2_int4_ord and eql_v2_int4_ord_ore) must declare COMMUTATOR,
    // NEGATOR, and selectivity estimators (RESTRICT / JOIN) on all three
    // arg-shapes, so the planner can normalise and cost commuted and
    // negated predicates.
    let rows: Vec<(String, String, String, bool, bool, bool, bool)> = sqlx::query_as(
        r#"
        SELECT o.oprname,
               lt.typname AS lhs,
               rt.typname AS rhs,
               o.oprcom <> 0       AS has_commutator,
               o.oprnegate <> 0    AS has_negator,
               o.oprrest::oid <> 0 AS has_restrict,
               o.oprjoin::oid <> 0 AS has_join
        FROM pg_catalog.pg_operator o
        JOIN pg_catalog.pg_type lt ON lt.oid = o.oprleft
        JOIN pg_catalog.pg_type rt ON rt.oid = o.oprright
        WHERE o.oprname IN ('=', '<>', '<', '<=', '>', '>=')
          AND (lt.typname IN ('eql_v2_int4_ord', 'eql_v2_int4_ord_ore')
            OR rt.typname IN ('eql_v2_int4_ord', 'eql_v2_int4_ord_ore'))
        "#,
    )
    .fetch_all(&pool)
    .await?;

    // 6 operators x 3 arg-shapes x 2 ordered domains = 36 rows.
    assert_eq!(
        rows.len(),
        36,
        "expected 6 operators x 3 arg-shapes x 2 ordered domains"
    );
    for (op, lhs, rhs, has_com, has_neg, has_rest, has_join) in &rows {
        assert!(
            has_com,
            "operator {op}({lhs},{rhs}) must declare COMMUTATOR"
        );
        assert!(has_neg, "operator {op}({lhs},{rhs}) must declare NEGATOR");
        assert!(has_rest, "operator {op}({lhs},{rhs}) must declare RESTRICT");
        assert!(has_join, "operator {op}({lhs},{rhs}) must declare JOIN");
    }
    Ok(())
}

#[sqlx::test]
async fn ord_functional_index_preferred_at_scale(pool: PgPool) -> Result<()> {
    // The other EXPLAIN tests force `enable_seqscan = off`, proving the
    // index is *usable*. This test proves the planner *prefers* it: at
    // ~5000 rows with a highly selective `=` predicate, the functional
    // btree must be chosen with seqscan left enabled.
    let mut tx = pool.begin().await?;
    sqlx::query("CREATE TEMP TABLE ord_scale (value eql_v2_int4_ord) ON COMMIT DROP")
        .execute(&mut *tx)
        .await?;

    let filler: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 5",
    )
    .fetch_one(&mut *tx)
    .await?;
    let pivot: String = sqlx::query_scalar(
        "SELECT payload::text FROM encrypted_int4_plaintext WHERE plaintext = 42",
    )
    .fetch_one(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO ord_scale(value) \
         SELECT $1::jsonb::eql_v2_int4_ord FROM generate_series(1, 5000)",
    )
    .bind(&filler)
    .execute(&mut *tx)
    .await?;
    sqlx::query("INSERT INTO ord_scale(value) VALUES ($1::jsonb::eql_v2_int4_ord)")
        .bind(&pivot)
        .execute(&mut *tx)
        .await?;
    sqlx::query("CREATE INDEX ord_scale_idx ON ord_scale USING btree (eql_v2.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE ord_scale").execute(&mut *tx).await?;

    let lit = pivot.replace('\'', "''");
    let plan: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM ord_scale WHERE value = '{lit}'::jsonb::eql_v2_int4_ord"
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan_text = plan.join("\n");
    assert!(
        plan_text.contains("ord_scale_idx"),
        "with seqscan enabled the planner must prefer the eql_v2.ord_term \
         btree for a selective = ; plan:\n{plan_text}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn ord_rejects_payload_missing_required_keys(pool: PgPool) -> Result<()> {
    // The eql_v2_int4_ord domain CHECK requires v, i, c, ob. A payload
    // missing any required key is rejected at the cast.
    for (label, json) in [
        ("missing ob", r#"{"v":2,"i":{"t":"t","c":"c"},"c":"x"}"#),
        ("missing c", r#"{"v":2,"i":{"t":"t","c":"c"},"ob":["aa"]}"#),
    ] {
        let err = sqlx::query(&format!("SELECT '{json}'::jsonb::eql_v2_int4_ord"))
            .fetch_one(&pool)
            .await
            .expect_err(&format!("eql_v2_int4_ord must reject payload: {label}"))
            .to_string();
        assert!(
            err.contains("violates check constraint"),
            "{label}: expected a check-constraint violation, got: {err}"
        );
    }
    Ok(())
}
