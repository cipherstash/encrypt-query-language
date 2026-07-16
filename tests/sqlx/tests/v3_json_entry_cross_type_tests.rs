//! CIP-3526 — cross-type comparison operators binding a `public.eql_v3_json_entry`
//! leaf to the per-type query operands `eql_v3.query_<T>_ord` (the OPE-backed
//! default ordering operand) and `eql_v3.query_<T>_ord_ope` (its explicit twin).
//!
//! Equality on encrypted JSON scalar fields is served by these `_ord` operands,
//! NOT by `query_<T>_eq`: a SteVec scalar (number/string) leaf carries only the
//! deterministic order-preserving `op` term, never a per-value `hm` (the
//! cipherstash-client emits `hm` only for bool/null/object/array leaves, and that
//! `hm` is a value-independent structural term). So `=`/`<>` on a `[Ope]`-family
//! `_ord` operand route through `ord_term` → `ope_cllw` (byte-equality on `op`,
//! which is injective on plaintext), exactly like the range operators. The
//! `query_<T>_eq` operand is deliberately not bound to json_entry — it would be
//! dead surface (see v3_jsonb_operator_surface_tests.rs).
//!
//! Proves: (1) every generated cross operator is backed by a public `eql_v3.*`
//! wrapper (callable by name on operator-free platforms); (2) a functional index
//! on `eql_v3.ord_term(...)` engages for both range AND equality queries in
//! operator form; (3) operator form ≡ function form; (4) `=` matches exactly the
//! rows whose plaintext equals the operand's, and `<>` the complement — real
//! op-based equality against real ciphertext.

use anyhow::Result;
use sqlx::PgPool;

use eql_tests::fixtures::v3_doc_integer::SELECTOR;

/// #1 — Structural: every generated cross operator is backed by a PUBLIC
/// `eql_v3.*` wrapper (callable by name on operator-free platforms). Creds-free.
#[sqlx::test]
async fn json_entry_cross_operators_are_public_and_present(pool: PgPool) -> Result<()> {
    // Expected (op, lhs, rhs) shapes for integer (representative [Ope] family):
    // all six operators bind both `_ord` and its `_ord_ope` twin, plus the
    // (query, json_entry) commutator. `=`/`<>` are present — they route through
    // ord_term (op equality), not the dropped `_eq`/hm path.
    let expected: &[(&str, &str, &str)] = &[
        ("=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("<>", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        (">", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        (">=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("<", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("<=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("=", "eql_v3.query_integer_ord", "public.eql_v3_json_entry"),
        (">", "eql_v3.query_integer_ord", "public.eql_v3_json_entry"),
        // _ord_ope — the explicit OPE twin.
        ("=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
        (">", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
        ("<=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
    ];
    // Build the schema-qualified type names from pg_namespace/pg_type joins
    // rather than `::regtype::text`, which drops the schema prefix for any type
    // in the session search_path (both `public` and `eql_v3` are, in the test DB).
    let rows: Vec<(String, String, String, String)> = sqlx::query_as(
        r#"
        SELECT o.oprname::text,
               ln.nspname || '.' || lt.typname AS lhs,
               rn.nspname || '.' || rt.typname AS rhs,
               format('%s.%s', pn.nspname, p.proname)
        FROM pg_operator o
        JOIN pg_proc p ON p.oid = o.oprcode
        JOIN pg_namespace pn ON pn.oid = p.pronamespace
        JOIN pg_type lt ON lt.oid = o.oprleft
        JOIN pg_namespace ln ON ln.oid = lt.typnamespace
        JOIN pg_type rt ON rt.oid = o.oprright
        JOIN pg_namespace rn ON rn.oid = rt.typnamespace
        WHERE 'public.eql_v3_json_entry'::regtype IN (o.oprleft, o.oprright)
          AND ((ln.nspname = 'eql_v3' AND lt.typname LIKE 'query%')
               OR (rn.nspname = 'eql_v3' AND rt.typname LIKE 'query%'))
        "#,
    )
    .fetch_all(&pool)
    .await?;
    for (op, l, r) in expected {
        let hit = rows.iter().find(|(n, ll, rr, _)| n == op && ll == l && rr == r);
        let (_, _, _, backing) =
            hit.unwrap_or_else(|| panic!("missing cross operator {op}({l},{r})"));
        assert!(
            backing.starts_with("eql_v3."),
            "cross operator {op}({l},{r}) must bind a public eql_v3 wrapper, got {backing}"
        );
    }
    // Negative: NO `query_<T>_eq` operand is bound to json_entry (dead surface).
    assert!(
        !rows
            .iter()
            .any(|(_, l, r, _)| l.ends_with("_eq") || r.ends_with("_eq")),
        "no query_<T>_eq operand may bind json_entry; found: {:?}",
        rows.iter()
            .filter(|(_, l, r, _)| l.ends_with("_eq") || r.ends_with("_eq"))
            .collect::<Vec<_>>()
    );
    Ok(())
}

/// Build a field-context `_ord`/`_ord_ope` operand from the given fixture row's
/// `$.field` `op` leaf: extract the entry's CLLW-OPE (`op`) term and wrap it
/// term-only (`{v, i, op}`, no `c`). `op` carries the field's selector context,
/// so `ord_term(operand)` is comparable to every leaf's `ord_term`.
async fn field_context_ord_operand(tx: &mut sqlx::PgConnection, id: i64) -> Result<String> {
    let operand: String = sqlx::query_scalar(&format!(
        "SELECT jsonb_build_object('v', '3', 'i', (payload::jsonb -> 'i'), 'op', \
                (payload -> '{SELECTOR}'::text)::jsonb -> 'op')::text \
         FROM fixtures.v3_doc_integer WHERE id = {id}"
    ))
    .fetch_one(&mut *tx)
    .await?;
    Ok(operand)
}

/// Extract every row's `$.field` entry into a temp table (id, plaintext, value)
/// and return a functional btree name on `ord_term(value)`.
async fn build_entry_table(tx: &mut sqlx::PgConnection) -> Result<()> {
    sqlx::query(
        "CREATE TEMP TABLE entry_x (id bigint, plaintext integer, value public.eql_v3_json_entry) \
         ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(&format!(
        "INSERT INTO entry_x(id, plaintext, value) \
         SELECT id, plaintext, (payload -> '{SELECTOR}'::text)::public.eql_v3_json_entry \
         FROM fixtures.v3_doc_integer"
    ))
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX entry_x_idx ON entry_x USING btree (eql_v3.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE entry_x").execute(&mut *tx).await?;
    Ok(())
}

/// #2 — ACCEPTANCE: selector-with-constraint queries in operator form against a
/// `query_integer_ord` / `_ord_ope` operand engage the ord_term functional btree
/// — an index scan, not a seq scan. Covers the range operators AND `=` (equality
/// via op also engages the btree). The operand is built in FIELD CONTEXT from a
/// fixture leaf's own `op` term, so it is real ciphertext.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_doc_integer")))]
async fn json_entry_ord_cross_type_engages_index(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    let operand = field_context_ord_operand(&mut tx, 1).await?;
    build_entry_table(&mut tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    // Both `_ord` and its explicit `_ord_ope` twin engage the same ord_term btree
    // (identical `[Term::Ope]` terms). `=` engages it too (equality is a btree
    // point lookup on the op term); `<>` is deliberately excluded — an inequality
    // predicate is not index-accelerated.
    for operand_ty in ["eql_v3.query_integer_ord", "eql_v3.query_integer_ord_ope"] {
        for op in ["=", ">", ">=", "<", "<="] {
            let q = format!(
                "SELECT * FROM entry_x WHERE value {op} '{}'::{operand_ty}",
                operand.replace('\'', "''")
            );
            eql_tests::matrix::assert_index_scan_uses(
                &mut *tx,
                &q,
                "entry_x_idx",
                &format!("cross-type `value {op} {operand_ty}` must engage the ord_term btree"),
            )
            .await?;
        }
    }
    tx.commit().await?;
    Ok(())
}

/// #3 — operator form ≡ function form (real ciphertext). For every operator,
/// `count(*) WHERE value <op> operand` equals `count(*) WHERE eql_v3.<fn>(value,
/// operand)`. Pins that each operator is a true alias of the function form the
/// adapter falls back to on operator-free platforms.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_doc_integer")))]
async fn json_entry_ord_cross_type_operator_equals_function(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    let operand = field_context_ord_operand(&mut tx, 1).await?;
    build_entry_table(&mut tx).await?;

    let esc = operand.replace('\'', "''");
    for (op, func) in [
        ("=", "eq"),
        ("<>", "neq"),
        (">", "gt"),
        (">=", "gte"),
        ("<", "lt"),
        ("<=", "lte"),
    ] {
        for operand_ty in ["eql_v3.query_integer_ord", "eql_v3.query_integer_ord_ope"] {
            let via_op: i64 = sqlx::query_scalar(&format!(
                "SELECT count(*) FROM entry_x WHERE value {op} '{esc}'::{operand_ty}"
            ))
            .fetch_one(&mut *tx)
            .await?;
            let via_fn: i64 = sqlx::query_scalar(&format!(
                "SELECT count(*) FROM entry_x \
                 WHERE eql_v3.{func}(value, '{esc}'::{operand_ty})"
            ))
            .fetch_one(&mut *tx)
            .await?;
            assert_eq!(
                via_op, via_fn,
                "operator `value {op} {operand_ty}` must equal function eql_v3.{func}(value, operand)"
            );
        }
    }
    tx.commit().await?;
    Ok(())
}

/// #4 — CORRECTNESS: op-based equality matches plaintext equality. An operand
/// built in field context from row R's `op` leaf makes `value = operand` select
/// exactly the rows whose plaintext equals row R's (the deterministic CLLW-OPE
/// `op` is injective on plaintext at a fixed selector), and `<>` selects the
/// complement. This is the real end-to-end equality promise (`col -> '$.f' = $1`)
/// against real ciphertext — not a self-needle: it asserts the FULL match set
/// against the plaintext oracle, positive and negative.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_doc_integer")))]
async fn json_entry_eq_cross_type_matches_plaintext_equality(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    let operand = field_context_ord_operand(&mut tx, 1).await?;
    build_entry_table(&mut tx).await?;
    let esc = operand.replace('\'', "''");

    // Oracle: the ids whose plaintext equals row 1's plaintext (robust to any
    // duplicate fixture values), and its complement.
    let expected_eq: Vec<i64> = sqlx::query_scalar(
        "SELECT id FROM entry_x WHERE plaintext = (SELECT plaintext FROM entry_x WHERE id = 1) \
         ORDER BY id",
    )
    .fetch_all(&mut *tx)
    .await?;
    let expected_neq: Vec<i64> = sqlx::query_scalar(
        "SELECT id FROM entry_x WHERE plaintext <> (SELECT plaintext FROM entry_x WHERE id = 1) \
         ORDER BY id",
    )
    .fetch_all(&mut *tx)
    .await?;
    // Sanity: the fixture is non-degenerate (some rows match, some don't).
    assert!(
        expected_eq.contains(&1) && !expected_neq.is_empty(),
        "fixture must have row 1 plus at least one differing row"
    );

    for operand_ty in ["eql_v3.query_integer_ord", "eql_v3.query_integer_ord_ope"] {
        let matched_eq: Vec<i64> = sqlx::query_scalar(&format!(
            "SELECT id FROM entry_x WHERE value = '{esc}'::{operand_ty} ORDER BY id"
        ))
        .fetch_all(&mut *tx)
        .await?;
        assert_eq!(
            matched_eq, expected_eq,
            "`value = {operand_ty}` must match exactly the plaintext-equal rows"
        );

        let matched_neq: Vec<i64> = sqlx::query_scalar(&format!(
            "SELECT id FROM entry_x WHERE value <> '{esc}'::{operand_ty} ORDER BY id"
        ))
        .fetch_all(&mut *tx)
        .await?;
        assert_eq!(
            matched_neq, expected_neq,
            "`value <> {operand_ty}` must match exactly the plaintext-differing rows"
        );
    }
    tx.commit().await?;
    Ok(())
}
