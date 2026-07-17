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

/// The `v3_ste_vec` `$.hello` **string** leaf's `op` selector, pinned from the
/// generated fixture (same value as `v3_jsonb_tests::SEL_HELLO_OP`).
///
/// This previously named `$.number` — the fixture's INTEGER leaf — so the text
/// arms below silently exercised numeric ciphertext. Equality could not see it:
/// the fixture pairs `number = i` with `hello = "world-i"` 1:1, so both leaves
/// induce identical equality partitions, and an `=`-only suite passes against
/// either. Only ORDER separates them, which is what
/// `json_entry_text_ord_cross_type_matches_plaintext_ordering` now pins.
///
/// To re-derive rather than trust this hex: `ste_vec_query_selector(…, "$.hello")`
/// asks cipherstash-client directly (see the `proptest-e2e` suite
/// `v3_json_entry_query_operand_e2e_tests`, which needs no constant at all).
/// Creds-free, the fixture's term LENGTHS distinguish the two leaves: a string
/// `op` is `8 * (len + 1) + 1` bits, so `$.hello` is 132 hex chars for
/// `"world-1"`..`"world-9"` and 148 for `"world-10"`, while `$.number` is a
/// fixed-width 65-bit number term — 132 on every row.
const SEL_HELLO_OP: &str = "b325a0c77b130af97b805c12ff853ab3";

/// #5 — TEXT has NO equality operator, and must not grow one.
///
/// A `text` leaf's `op` term is not injective on plaintext, so `=` built on it
/// returns rows whose plaintext DIFFERS. cllw-ore's `orderize_string` NFKC-
/// decomposes and then strips every char that is not alphanumeric, whitespace, or
/// ASCII punctuation, so these distinct plaintexts share one `op` term:
///
/// ```text
///   "cafe" == "café"                          "Muller" == "Müller"
///   "hello" == "hello😎"                       "user@example.com" == "user@exämple.com"
/// ```
///
/// (Pinned upstream by cllw-ore 0.4.2's own `test_string_non_ascii_stripped`, and
/// verified against cipherstash-client 0.38.1's SteVec term path.)
///
/// Determinism is what `op` gives — equal plaintext ⇒ equal term — and that is
/// enough for ORDERING (#6 pins it) but not for equality, which also needs
/// injectivity. A scalar text COLUMN escapes this by listing `Hm` before `Ope`, so
/// `extractor_for_operator` routes `=` to the exact `hm`
/// (`every_eq_capable_text_domain_resolves_eq_through_hm`). A SteVec string LEAF
/// has no `hm` to route to — cipherstash-client maps `Value::String` to
/// `Orderable`, never `Mac` — so there is no sound text equality to offer, and the
/// codegen emits none (`ScalarKind::ope_is_injective`).
///
/// `=` is BLOCKED, not omitted. Omitting it would not make the query an error:
/// `public.eql_v3_json_entry` and `eql_v3.query_text_ord` are both domains over
/// `jsonb`, and operators resolve against the ultimate base type — so an unbound
/// `=` falls back to native `jsonb = jsonb`, comparing whole payload objects
/// (`{s,c,op}` vs `{v,i,hm,op}`), never matching, and returning ZERO ROWS with no
/// error. That swaps a false positive for a silent false negative. The blocker
/// claims the signature so the caller gets a loud "operator not supported".
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn json_entry_text_equality_is_blocked(pool: PgPool) -> Result<()> {
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

    // `=` and `<>` must RAISE for both text operands, in both directions — never
    // return rows, and never silently return none.
    for op in ["=", "<>"] {
        for operand_ty in ["eql_v3.query_text_ord", "eql_v3.query_text_ord_ope"] {
            for query in [
                format!("SELECT id FROM entry_t WHERE value {op} '{esc}'::{operand_ty}"),
                format!("SELECT id FROM entry_t WHERE '{esc}'::{operand_ty} {op} value"),
            ] {
                let err = sqlx::query(&query)
                    .fetch_all(&mut *tx)
                    .await
                    .expect_err(&format!(
                        "text `op` is not injective, so `{op}` on a json_entry leaf must \
                         RAISE rather than answer. Query: {query}"
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
