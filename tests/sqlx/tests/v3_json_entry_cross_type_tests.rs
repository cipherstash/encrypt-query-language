//! CIP-3526 — cross-type comparison operators binding a `public.eql_v3_json_entry`
//! leaf to the per-type query operands `eql_v3.query_<T>_eq` (equality),
//! `eql_v3.query_<T>_ord` (the OPE-backed default ordering operand), and
//! `eql_v3.query_<T>_ord_ope` (its explicit twin). Proves: (1) every generated
//! cross operator is backed by a public `eql_v3.*` wrapper (callable by name on
//! operator-free platforms); (2) a functional index on `eql_v3.ord_term(...)`
//! engages for a selector-with-constraint ordering query in operator form (the
//! acceptance criterion); (3) the operator form is a true alias of the function
//! form the adapter falls back to.
//!
//! Equality (`= query_<T>_eq`) coverage: the operator WIRING is proven end-to-end
//! by test (1) (the `(json_entry, query_integer_eq)` operators exist and bind the
//! public `eql_v3.eq`/`eql_v3.neq` wrappers) and by the SQL-level equivalence
//! suite. A per-VALUE positive/negative equality match would need a fixture whose
//! `$.field` carries a per-value equality (`hm`) term; the existing SteVec
//! fixtures index `$.field` for ORDERING (ORE), so their `hm` sv entry is a
//! constant structural/selector term, not a per-value HMAC. The equality path
//! shares the exact wrapper/operator machinery as ordering (which IS exercised
//! end-to-end below), differing only in the extractor (`eq_term` vs `ord_term`).

use anyhow::Result;
use sqlx::PgPool;

use eql_tests::fixtures::v3_doc_integer::SELECTOR;

/// #1 — Structural: every generated cross operator is backed by a PUBLIC
/// `eql_v3.*` wrapper (callable by name on operator-free platforms). Creds-free.
#[sqlx::test]
async fn json_entry_cross_operators_are_public_and_present(pool: PgPool) -> Result<()> {
    // Expected (op, lhs, rhs) shapes for integer (representative family).
    let expected: &[(&str, &str, &str)] = &[
        ("=", "public.eql_v3_json_entry", "eql_v3.query_integer_eq"),
        ("=", "eql_v3.query_integer_eq", "public.eql_v3_json_entry"),
        ("<>", "public.eql_v3_json_entry", "eql_v3.query_integer_eq"),
        // _ord — the OPE-backed default ordering operand (OQ1).
        (">", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        (">=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("<", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("<=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        ("=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord"),
        (">", "eql_v3.query_integer_ord", "public.eql_v3_json_entry"),
        // _ord_ope — the explicit OPE twin.
        (">", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
        (">=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
        ("<", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
        ("<=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
        ("=", "public.eql_v3_json_entry", "eql_v3.query_integer_ord_ope"),
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
    Ok(())
}

/// Build a field-context `_ord`/`_ord_ope` operand from row 1's `$.field` `op`
/// leaf: extract the entry's ORE (`op`) term and wrap it term-only (`{v, i, op}`,
/// no `c`). `op` carries the field's selector context, so `ord_term(operand)` is
/// comparable to every leaf's `ord_term`.
async fn field_context_ord_operand(tx: &mut sqlx::PgConnection) -> Result<String> {
    let operand: String = sqlx::query_scalar(&format!(
        "SELECT jsonb_build_object('v', '3', 'i', (payload::jsonb -> 'i'), 'op', \
                (payload -> '{SELECTOR}'::text)::jsonb -> 'op')::text \
         FROM fixtures.v3_doc_integer WHERE id = 1"
    ))
    .fetch_one(&mut *tx)
    .await?;
    Ok(operand)
}

/// #2 — ACCEPTANCE: a selector-with-constraint ordering query in operator form
/// against a `query_integer_ord` / `query_integer_ord_ope` operand engages the
/// ord_term functional btree over the extracted entry — an index scan, not a seq
/// scan. The operand is built in FIELD CONTEXT from a fixture leaf's own `op`
/// term (the load-bearing runtime assumption), so it is real ciphertext.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_doc_integer")))]
async fn json_entry_ord_cross_type_engages_index(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    let operand = field_context_ord_operand(&mut tx).await?;

    // Table of extracted entries + a functional btree on ord_term(value).
    sqlx::query("CREATE TEMP TABLE entry_ord (value public.eql_v3_json_entry) ON COMMIT DROP")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "INSERT INTO entry_ord(value) \
         SELECT (payload -> '{SELECTOR}'::text)::public.eql_v3_json_entry \
         FROM fixtures.v3_doc_integer"
    ))
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX entry_ord_idx ON entry_ord USING btree (eql_v3.ord_term(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE entry_ord").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    // Both the default `_ord` operand and its explicit `_ord_ope` twin engage the
    // same ord_term btree (identical `[Term::Ope]` terms → same extractor).
    for operand_ty in ["eql_v3.query_integer_ord", "eql_v3.query_integer_ord_ope"] {
        for op in [">", ">=", "<", "<="] {
            let q = format!(
                "SELECT * FROM entry_ord WHERE value {op} '{}'::{operand_ty}",
                operand.replace('\'', "''")
            );
            eql_tests::matrix::assert_index_scan_uses(
                &mut *tx,
                &q,
                "entry_ord_idx",
                &format!("cross-type `value {op} {operand_ty}` must engage the ord_term btree"),
            )
            .await?;
        }
    }
    tx.commit().await?;
    Ok(())
}

/// #3 — ord operator form ≡ function form (real ciphertext). For each ordering
/// operator, `count(*) WHERE value <op> operand` equals `count(*) WHERE
/// eql_v3.<fn>(value, operand)`. Pins that the operator is a true alias of the
/// function form the adapter falls back to on operator-free platforms.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_doc_integer")))]
async fn json_entry_ord_cross_type_operator_equals_function(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    let operand = field_context_ord_operand(&mut tx).await?;

    sqlx::query("CREATE TEMP TABLE entry_ord (value public.eql_v3_json_entry) ON COMMIT DROP")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "INSERT INTO entry_ord(value) \
         SELECT (payload -> '{SELECTOR}'::text)::public.eql_v3_json_entry \
         FROM fixtures.v3_doc_integer"
    ))
    .execute(&mut *tx)
    .await?;

    let esc = operand.replace('\'', "''");
    for (op, func) in [(">", "gt"), (">=", "gte"), ("<", "lt"), ("<=", "lte")] {
        for operand_ty in ["eql_v3.query_integer_ord", "eql_v3.query_integer_ord_ope"] {
            let via_op: i64 = sqlx::query_scalar(&format!(
                "SELECT count(*) FROM entry_ord WHERE value {op} '{esc}'::{operand_ty}"
            ))
            .fetch_one(&mut *tx)
            .await?;
            let via_fn: i64 = sqlx::query_scalar(&format!(
                "SELECT count(*) FROM entry_ord \
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
