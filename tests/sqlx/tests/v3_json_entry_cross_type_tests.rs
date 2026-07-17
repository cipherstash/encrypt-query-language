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
        (
            "=",
            "public.eql_v3_json_entry",
            "eql_v3.query_integer_ord_ope",
        ),
        (
            ">",
            "public.eql_v3_json_entry",
            "eql_v3.query_integer_ord_ope",
        ),
        (
            "<=",
            "public.eql_v3_json_entry",
            "eql_v3.query_integer_ord_ope",
        ),
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
        let hit = rows
            .iter()
            .find(|(n, ll, rr, _)| n == op && ll == l && rr == r);
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

/// The id of the row holding the MEDIAN plaintext — the pivot that gives every
/// comparison operator a non-degenerate split (rows exist strictly below AND
/// strictly above). Row 1 must never be used as a range pivot: it holds the
/// fixture's minimum (`i32::MIN`), so `<` selects nothing and any
/// oracle-agreement assertion on it is vacuously 0 == 0.
async fn median_pivot_id(tx: &mut sqlx::PgConnection) -> Result<i64> {
    let id: i64 = sqlx::query_scalar(
        "SELECT id FROM entry_x ORDER BY plaintext \
         LIMIT 1 OFFSET (SELECT count(*) / 2 FROM entry_x)",
    )
    .fetch_one(&mut *tx)
    .await?;
    // Guard: the median must actually split the fixture (strictly-below and
    // strictly-above rows both exist), or every range assertion downstream
    // silently loses its power.
    let (below, above): (i64, i64) = sqlx::query_as(
        "SELECT count(*) FILTER (WHERE plaintext < p), count(*) FILTER (WHERE plaintext > p) \
         FROM entry_x, (SELECT plaintext AS p FROM entry_x WHERE id = $1) pivot",
    )
    .bind(id)
    .fetch_one(&mut *tx)
    .await?;
    anyhow::ensure!(
        below > 0 && above > 0,
        "median pivot (id {id}) must have rows strictly below and above; \
         got {below} below / {above} above — fixture too degenerate for range oracles"
    );
    Ok(id)
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
    build_entry_table(&mut tx).await?;
    // Pivot on the MEDIAN row, not row 1: row 1 is the fixture's minimum
    // (i32::MIN), which makes the `<` comparison vacuous — both sides count an
    // empty set and 0 == 0 proves nothing. A mid-range pivot gives every
    // operator a non-degenerate split to agree on.
    let pivot_id = median_pivot_id(&mut tx).await?;
    let operand = field_context_ord_operand(&mut tx, pivot_id).await?;

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
            // Guard the guard: with a median pivot every operator selects a
            // non-empty set, so the agreement above is never 0 == 0.
            assert!(
                via_op > 0,
                "`value {op} {operand_ty}` must select at least one row at the \
                 median pivot — an empty agreement proves nothing"
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

/// #4b — CORRECTNESS: every RANGE operator matches plaintext ordering. This is
/// the feature's headline promise (`col -> '$.age' > $1`) stated directly: for
/// `<` `<=` `>` `>=`, the operator's match set equals the plaintext oracle's,
/// per operand type. #2 (index engagement) and #3 (operator ≡ function) cannot
/// see a wrong result set — an index engages for wrong rows just as happily, and
/// operator/function agree when both are identically wrong. Only an oracle
/// comparison pins the ORDER itself.
///
/// Pivots on the median row so both sides of every comparison are non-empty
/// proper subsets (see `median_pivot_id` — row 1 is the fixture minimum and
/// would make `<` vacuous).
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_doc_integer")))]
async fn json_entry_range_cross_type_matches_plaintext_ordering(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;
    build_entry_table(&mut tx).await?;
    let pivot_id = median_pivot_id(&mut tx).await?;
    let operand = field_context_ord_operand(&mut tx, pivot_id).await?;
    let esc = operand.replace('\'', "''");

    let total: i64 = sqlx::query_scalar("SELECT count(*) FROM entry_x")
        .fetch_one(&mut *tx)
        .await?;

    for cmp in ["<", "<=", ">", ">="] {
        let oracle: Vec<i64> = sqlx::query_scalar(&format!(
            "SELECT id FROM entry_x \
             WHERE plaintext {cmp} (SELECT plaintext FROM entry_x WHERE id = $1) \
             ORDER BY id"
        ))
        .bind(pivot_id)
        .fetch_all(&mut *tx)
        .await?;
        // Guard the guard: a proper non-empty subset, or the equality below
        // could hold for a uniformly-true/false comparison.
        assert!(
            !oracle.is_empty() && (oracle.len() as i64) < total,
            "`plaintext {cmp} pivot` oracle must be a proper non-empty subset \
             to be load-bearing; got {} of {total}",
            oracle.len()
        );

        for operand_ty in ["eql_v3.query_integer_ord", "eql_v3.query_integer_ord_ope"] {
            let matched: Vec<i64> = sqlx::query_scalar(&format!(
                "SELECT id FROM entry_x WHERE value {cmp} '{esc}'::{operand_ty} ORDER BY id"
            ))
            .fetch_all(&mut *tx)
            .await?;
            assert_eq!(
                matched, oracle,
                "`value {cmp} {operand_ty}` must match exactly the rows whose plaintext \
                 sorts {cmp} the pivot's — CLLW-OPE order must agree with integer order"
            );
        }
    }
    tx.commit().await?;
    Ok(())
}

/// The `v3_ste_vec` `$.hello` **string** leaf's `op` selector, imported from
/// the ONE shared copy (see its doc for the `$.number` mis-pin history and how
/// to re-derive the hex creds-free). Ordering arms below are exactly what makes
/// a wrong pin visible — `"world-10"` sorts between `"world-1"` and `"world-2"`
/// as a string but last as a number.
use eql_tests::fixtures::v3_ste_vec::SEL_HELLO_OP;

/// #5 — The families whose leaf encoding is LOSSY have NO equality operator, and
/// must not grow one.
///
/// A JSON leaf is encoded as an f64 (numbers) or a collated string (text), and
/// neither preserves every type's values. Where it does not, `=` returns rows whose
/// plaintext DIFFERS — reachable by ordinary use, not by client error:
///
/// ```text
///   text     "cafe" == "café"     "hello" == "hello😎"     (orderize_string collates)
///   bigint   9007199254740992 == 9007199254740993          (as_f64 rounds above 2^53)
///   numeric  more precision than an f64 carries
/// ```
///
/// (Pinned upstream by cllw-ore 0.4.2's `test_string_non_ascii_stripped`; the
/// bigint collision is verified e2e against cipherstash-client 0.38.1, whose
/// `impl From<&Value> for StePlaintextTerm` routes every numeric leaf through
/// `as_f64()` BEFORE `orderable_to_u64`.)
///
/// Determinism is what `op` gives — equal plaintext ⇒ equal term — and that is
/// enough for ORDERING (#6 pins it) but not for equality, which also needs
/// injectivity. A scalar COLUMN escapes this by listing `Hm` before `Ope`, so
/// `extractor_for_operator` routes `=` to the exact `hm`
/// (`every_eq_capable_text_domain_resolves_eq_through_hm`). A SteVec LEAF has no
/// `hm` to route to — cipherstash-client maps `Value::Number`/`Value::String` to
/// `Orderable`, never `Mac` — so there is no sound equality to offer for these
/// families, and the codegen emits none
/// (`ScalarKind::json_leaf_equality_is_exact`).
///
/// `integer`/`smallint`/`real`/`double` KEEP `=` and are pinned here too — the
/// gate must not over-broaden. See #4, which asserts integer `=` against the
/// plaintext oracle. (`date`/`timestamp` are not in the kept list: they fail the
/// upstream PARTICIPATION gate — JSON has no temporal type, so their operands
/// bind nothing and every operator on them is blocked; see #7.)
///
/// `=` is BLOCKED, not omitted. Omitting it would not make the query an error:
/// `public.eql_v3_json_entry` and `eql_v3.query_text_ord` are both domains over
/// `jsonb`, and operators resolve against the ultimate base type — so an unbound
/// `=` falls back to native `jsonb = jsonb`, comparing whole payload objects
/// (`{s,c,op}` vs `{v,i,hm,op}`), never matching, and returning ZERO ROWS with no
/// error. That swaps a false positive for a silent false negative. The blocker
/// claims the signature so the caller gets a loud "operator not supported".
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn json_entry_lossy_family_equality_is_blocked(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;

    let operand: String = sqlx::query_scalar(&format!(
        "SELECT jsonb_build_object('v', '3', 'i', (payload::jsonb -> 'i'), \
                'hm', (SELECT e -> 'hm' FROM jsonb_array_elements(payload::jsonb -> 'sv') e \
                       WHERE e ? 'hm' LIMIT 1), \
                'op', (payload -> '{SEL_HELLO_OP}'::text)::jsonb -> 'op')::text \
         FROM fixtures.v3_ste_vec WHERE id = 1"
    ))
    .fetch_one(&mut *tx)
    .await?;
    let esc = operand.replace('\'', "''");

    sqlx::query(
        "CREATE TEMP TABLE entry_t (id bigint, value public.eql_v3_json_entry) ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(&format!(
        "INSERT INTO entry_t(id, value) \
         SELECT id, (payload -> '{SEL_HELLO_OP}'::text)::public.eql_v3_json_entry \
         FROM fixtures.v3_ste_vec"
    ))
    .execute(&mut *tx)
    .await?;

    // `=` and `<>` must RAISE for every lossy family's operands, in both
    // directions — never return rows, and never silently return none. The operand
    // payload is a text one; the CHECKs of the numeric operands accept `{v,i,op}`,
    // and what is under test is OPERATOR RESOLUTION, not the term bytes: a blocker
    // raises before it ever reads them.
    for op in ["=", "<>"] {
        for operand_ty in [
            "eql_v3.query_text_ord",
            "eql_v3.query_text_ord_ope",
            "eql_v3.query_bigint_ord",
            "eql_v3.query_bigint_ord_ope",
            "eql_v3.query_numeric_ord",
            "eql_v3.query_numeric_ord_ope",
        ] {
            for query in [
                format!("SELECT id FROM entry_t WHERE value {op} '{esc}'::{operand_ty}"),
                format!("SELECT id FROM entry_t WHERE '{esc}'::{operand_ty} {op} value"),
            ] {
                let err = sqlx::query(&query)
                    .fetch_all(&mut *tx)
                    .await
                    .expect_err(&format!(
                        "{operand_ty}'s leaf encoding is lossy, so `{op}` on a json_entry \
                         leaf must RAISE rather than answer. Query: {query}"
                    ));
                let msg = err.to_string();
                assert!(
                    msg.contains("is not supported for"),
                    "expected the `operator not supported` blocker for `{op}`, got: {msg}"
                );
                // The failed statement poisons the transaction; restart it.
                tx.rollback().await?;
                tx = pool.begin().await?;
                sqlx::query(
                    "CREATE TEMP TABLE entry_t (id bigint, value public.eql_v3_json_entry) \
                     ON COMMIT DROP",
                )
                .execute(&mut *tx)
                .await?;
                sqlx::query(&format!(
                    "INSERT INTO entry_t(id, value) \
                     SELECT id, (payload -> '{SEL_HELLO_OP}'::text)::public.eql_v3_json_entry \
                     FROM fixtures.v3_ste_vec"
                ))
                .execute(&mut *tx)
                .await?;
            }
        }
    }

    // Guard the guard: ORDERING on the very same operand DOES resolve, so the
    // assertions above prove equality is absent — not that the operand, the cast,
    // or the temp table is broken.
    let ordered: Vec<i64> = sqlx::query_scalar(&format!(
        "SELECT id FROM entry_t WHERE value > '{esc}'::eql_v3.query_text_ord ORDER BY id"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert!(
        !ordered.is_empty(),
        "text ordering must still resolve and match rows — otherwise this test \
         proves nothing about equality specifically"
    );

    // The other half of the gate: the families whose leaf encoding IS lossless keep
    // `=`, backed by the PUBLIC wrapper. Without this, blocking everything would
    // pass the assertions above — over-broadening is as much a defect as
    // under-blocking, it just fails silently as a missing feature.
    // (date/timestamp are NOT here: JSON has no temporal type, so they fail the
    // participation gate and every operator on their operands is blocked — #7.)
    for operand_ty in [
        "eql_v3.query_integer_ord",
        "eql_v3.query_smallint_ord",
        "eql_v3.query_real_ord",
        "eql_v3.query_double_ord",
    ] {
        let backing: String = sqlx::query_scalar(
            "SELECT n.nspname || '.' || p.proname \
             FROM pg_operator o \
             JOIN pg_proc p ON p.oid = o.oprcode \
             JOIN pg_namespace n ON n.oid = p.pronamespace \
             WHERE o.oprname = '=' \
               AND o.oprleft = 'public.eql_v3_json_entry'::regtype \
               AND o.oprright = $1::regtype",
        )
        .bind(operand_ty)
        .fetch_one(&mut *tx)
        .await?;
        assert_eq!(
            backing, "eql_v3.eq",
            "{operand_ty}'s leaf encoding is lossless, so `=` must stay bound to the \
             public wrapper — not blocked"
        );
    }

    tx.commit().await?;
    Ok(())
}

/// #6 — TEXT ordering end-to-end: `>` against `eql_v3.query_text_ord` matches
/// exactly the rows whose `$.hello` plaintext sorts after the operand's, per the
/// CLLW-OPE order over `orderize_string`.
///
/// This arm is what keeps #5 honest, and it exists because #5 alone could not.
/// `SEL_HELLO_OP` was pinned at `$.number` — the INTEGER leaf — and #5 passed
/// anyway for two compounding reasons: the fixture pairs `number = i` with
/// `hello = "world-i"` 1:1, so both leaves induce the SAME equality partition;
/// and #5 only exercises `=`/`<>`, the one comparison that cannot distinguish
/// them. Order can: `"world-10"` sorts BETWEEN `"world-1"` and `"world-2"` as a
/// string, while `10` sorts last as a number. So a text arm reading a numeric
/// leaf disagrees with the string oracle on exactly row 10, and fails here.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn json_entry_text_ord_cross_type_matches_plaintext_ordering(pool: PgPool) -> Result<()> {
    let mut tx = pool.begin().await?;

    // Pivot on row 2 ("world-2"), where string and numeric order disagree. Row 1
    // ("world-1") would NOT discriminate — it is the minimum under both orders.
    let operand: String = sqlx::query_scalar(&format!(
        "SELECT jsonb_build_object('v', '3', 'i', (payload::jsonb -> 'i'), \
                'hm', (SELECT e -> 'hm' FROM jsonb_array_elements(payload::jsonb -> 'sv') e \
                       WHERE e ? 'hm' LIMIT 1), \
                'op', (payload -> '{SEL_HELLO_OP}'::text)::jsonb -> 'op')::text \
         FROM fixtures.v3_ste_vec WHERE id = 2"
    ))
    .fetch_one(&mut *tx)
    .await?;
    assert!(
        !operand.contains("\"hm\": null") && !operand.contains("\"op\": null"),
        "operand must carry real hm/op terms from the fixture, got: {operand}"
    );

    sqlx::query(
        "CREATE TEMP TABLE entry_t (id bigint, hello text, value public.eql_v3_json_entry) \
         ON COMMIT DROP",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query(&format!(
        "INSERT INTO entry_t(id, hello, value) \
         SELECT id, plaintext ->> 'hello', \
                (payload -> '{SEL_HELLO_OP}'::text)::public.eql_v3_json_entry \
         FROM fixtures.v3_ste_vec"
    ))
    .execute(&mut *tx)
    .await?;

    let expected_gt: Vec<i64> = sqlx::query_scalar(
        "SELECT id FROM entry_t WHERE hello > (SELECT hello FROM entry_t WHERE id = 2) ORDER BY id",
    )
    .fetch_all(&mut *tx)
    .await?;
    let total: i64 = sqlx::query_scalar("SELECT count(*) FROM entry_t")
        .fetch_one(&mut *tx)
        .await?;
    // Guard the guard: a proper non-empty subset, else the comparison could be
    // uniformly true or false and still "pass".
    assert!(
        !expected_gt.is_empty() && (expected_gt.len() as i64) < total,
        "oracle must be a proper non-empty subset for the ordering to be load-bearing, \
         got {expected_gt:?} of {total}"
    );
    // FIXTURE invariant, not a selector check: this oracle is plain SQL text
    // comparison over `hello`, so it cannot see which leaf SEL_HELLO_OP names.
    // What it pins is that the fixture still DISCRIMINATES string order from
    // numeric order — zero-padding `documents()` to `"world-01"`..`"world-10"`
    // would align the two orders and silently strip this arm of the power to
    // catch a numeric leaf, without failing anything.
    assert!(
        !expected_gt.contains(&10),
        "fixture must keep string and numeric order divergent at the row-2 pivot: \
         \"world-10\" < \"world-2\" as a string while 10 > 2 as a number. Got id 10 in \
         {expected_gt:?} — the $.hello values no longer discriminate, and the assertion \
         below would pass against a numeric leaf."
    );

    let esc = operand.replace('\'', "''");
    let matched_gt: Vec<i64> = sqlx::query_scalar(&format!(
        "SELECT id FROM entry_t WHERE value > '{esc}'::eql_v3.query_text_ord ORDER BY id"
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(
        matched_gt, expected_gt,
        "text `value > query_text_ord` must follow CLLW-OPE string order and match exactly \
         the rows whose $.hello sorts after the operand (row 10 excluded). A mismatch on \
         id 10 means SEL_HELLO_OP is reading a numeric leaf, not $.hello."
    );

    tx.commit().await?;
    Ok(())
}

/// #7 — UNSERVED Ope-carrying operands are BLOCKED, not silently flattened.
///
/// Two operand groups carry the `op` term this seam serves yet must not bind it:
///
/// - **`query_date_ord` / `query_timestamp_ord` (+ `_ope` twins)** — JSON has no
///   date/timestamp type (coderdan, PR #410): those values are marshaled into
///   ISO-8601 STRINGS, so a "date leaf" IS a text leaf and the TEXT surface owns
///   it (ordering via `query_text_ord`; equality via `@>` containment).
///   cipherstash-client agrees mechanically — it refuses to build a SteVec query
///   term from a temporal plaintext (`OrderableTerm::try_from(&Plaintext)` is
///   `Err` for `NaiveDate`/`Timestamp`), so no real operand could ever reach the
///   comparison. It is also the collated-equality back door: a date leaf and a
///   text leaf are byte-identically encoded, so an unblocked `= query_date_ord`
///   would be exactly the text `=` that #5 blocks, reached by a different cast.
/// - **`query_text_search`** — SteVec has no match/bloom capability, so `search`
///   offers nothing over `_ord` while its CHECK demands a `bf` the seam never
///   reads (coderdan, PR #410).
///
/// Neither can be merely OMITTED: both sides are domains over `jsonb`, so an
/// unclaimed pair resolves to native `jsonb <op> jsonb` — whole-envelope
/// comparison, zero rows, no error. Every operator on every pair must RAISE, in
/// both directions. Loads the `eql_v3_text` scalar fixture alongside the SteVec
/// document one so the `query_text_search` operand can be assembled from REAL
/// terms (`{v,i,hm,op,bf}` — its CHECK demands all four; the SteVec fixture
/// carries no `bf`).
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec", "eql_v3_text")))]
async fn json_entry_unserved_operand_operators_raise(pool: PgPool) -> Result<()> {
    // A temporal operand payload never exists in the wild (the client refuses to
    // mint one), so what is under test is OPERATOR RESOLUTION — the blocker
    // raises before reading any term. The ste_vec text-leaf operand `{v,i,hm,op}`
    // satisfies the `{v,i,op}` CHECK of `query_{date,timestamp}_ord{,_ope}`.
    let temporal_operand: String = sqlx::query_scalar(&format!(
        "SELECT jsonb_build_object('v', '3', 'i', (payload::jsonb -> 'i'), \
                'hm', (SELECT e -> 'hm' FROM jsonb_array_elements(payload::jsonb -> 'sv') e \
                       WHERE e ? 'hm' LIMIT 1), \
                'op', (payload -> '{SEL_HELLO_OP}'::text)::jsonb -> 'op')::text \
         FROM fixtures.v3_ste_vec WHERE id = 1"
    ))
    .fetch_one(&pool)
    .await?;
    // The search operand needs `{v,i,hm,op,bf}` — all REAL terms, taken from a
    // scalar text fixture payload (Unique+Ore+Match+Ope indexes ⇒ hm/op/bf all
    // present). Inert by construction: the blocker never reads them.
    let search_operand: String = sqlx::query_scalar(
        "SELECT jsonb_build_object('v', '3', 'i', (payload::jsonb -> 'i'), \
                'hm', (payload::jsonb -> 'hm'), 'op', (payload::jsonb -> 'op'), \
                'bf', (payload::jsonb -> 'bf'))::text \
         FROM fixtures.eql_v3_text LIMIT 1",
    )
    .fetch_one(&pool)
    .await?;

    let pairs: &[(&str, &str)] = &[
        ("eql_v3.query_date_ord", temporal_operand.as_str()),
        ("eql_v3.query_date_ord_ope", temporal_operand.as_str()),
        ("eql_v3.query_timestamp_ord", temporal_operand.as_str()),
        ("eql_v3.query_timestamp_ord_ope", temporal_operand.as_str()),
        ("eql_v3.query_text_search", search_operand.as_str()),
    ];

    for (operand_ty, operand) in pairs {
        let esc = operand.replace('\'', "''");
        // Guard the guard: the operand must pass the domain CHECK — a cast
        // failure would ALSO error and make the raise assertions below vacuous.
        let accepted: bool = sqlx::query_scalar(&format!(
            "SELECT ('{esc}'::jsonb::{operand_ty}) IS NOT NULL"
        ))
        .fetch_one(&pool)
        .await?;
        assert!(
            accepted,
            "{operand_ty}: the operand must pass the domain CHECK so the errors \
             below can only come from the blocker: {operand}"
        );

        for op in ["=", "<>", "<", "<=", ">", ">="] {
            for query in [
                format!(
                    "SELECT id FROM fixtures.v3_ste_vec \
                     WHERE (payload -> '{SEL_HELLO_OP}'::text)::public.eql_v3_json_entry \
                           {op} '{esc}'::{operand_ty}"
                ),
                format!(
                    "SELECT id FROM fixtures.v3_ste_vec \
                     WHERE '{esc}'::{operand_ty} {op} \
                           (payload -> '{SEL_HELLO_OP}'::text)::public.eql_v3_json_entry"
                ),
            ] {
                let err = sqlx::query(&query)
                    .fetch_all(&pool)
                    .await
                    .expect_err(&format!(
                        "json_entry {op} {operand_ty} must RAISE (blocked pair), not answer. \
                     Silently returning rows means the operator flattened to native \
                     jsonb {op} jsonb. Query: {query}"
                    ));
                let msg = err.to_string();
                assert!(
                    msg.contains("is not supported for"),
                    "expected the `operator not supported` blocker for \
                     json_entry {op} {operand_ty}, got: {msg}"
                );
            }
        }
    }
    Ok(())
}
