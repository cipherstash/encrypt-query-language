//! Behaviour matrix for SteVec jsonb-entry comparisons, reusing the scalar
//! matrix generators via `jsonb_entry_matrix!`. Covers the positive behaviours
//! (correctness / ordering / NULL / ORDER BY / COUNT / index engagement, plus
//! entry-specific fixture-shape and ORE-CLLW injectivity tests) that the
//! hand-written `v3_jsonb_tests` suite does not. Document-specific behaviours
//! (containment / path query / array ops / the operator-surface guard) remain
//! in `v3_jsonb_tests` / `v3_jsonb_operator_surface_tests`.
//!
//! The view type (`JsonbEntryInt4`) is deliberately NOT a `eql_scalars::CATALOG`
//! scalar, so this suite is hand-written rather than emitted by the
//! `scalar_types!` list — and its test names live under `jsonb_entry::…`,
//! validated by `test:matrix:inventory:jsonb_entry` (NOT the scalar inventory).

use eql_tests::fixtures::v3_doc_int4::SELECTOR;
use eql_tests::jsonb_entry::JsonbEntryInt4;
use eql_tests::scalar_domains::ScalarType;

eql_tests::jsonb_entry_matrix! {
    suite = jsonb_entry_int4,
    scalar = eql_tests::jsonb_entry::JsonbEntryInt4,
    eql_type = "v3_doc_int4",
}

// ----------------------------------------------------------------------------
// Entry-specific structural invariant. Pins that the pinned SELECTOR extracts a
// real, `oc`-carrying entry from every fixture row — a wrong selector would make
// every matrix comparison vacuous via NULL extraction rather than failing.
// ----------------------------------------------------------------------------
#[sqlx::test(fixtures(path = "../../fixtures", scripts("v3_doc_int4")))]
async fn jsonb_entry_int4_fixture_shape(pool: sqlx::PgPool) -> anyhow::Result<()> {
    let n = <JsonbEntryInt4 as ScalarType>::fixture_values().len() as i64;

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM fixtures.v3_doc_int4")
        .fetch_one(&pool)
        .await?;
    anyhow::ensure!(
        count == n,
        "row count must match fixture_values().len(): want {n}, got {count}",
    );

    // ids sequential from 1 (the split generator inserts in INT4_VALUES order).
    let ids: Vec<i64> = sqlx::query_scalar("SELECT id FROM fixtures.v3_doc_int4 ORDER BY id")
        .fetch_all(&pool)
        .await?;
    anyhow::ensure!(
        ids == (1..=n).collect::<Vec<i64>>(),
        "ids must be sequential from 1: got {ids:?}",
    );

    // Every row's entry at the selector is non-NULL — guards against a wrong
    // SELECTOR silently hollowing out the matrix.
    let null_entries: i64 = sqlx::query_scalar(&format!(
        "SELECT COUNT(*) FROM fixtures.v3_doc_int4 WHERE (payload -> '{SELECTOR}'::text) IS NULL",
    ))
    .fetch_one(&pool)
    .await?;
    anyhow::ensure!(
        null_entries == 0,
        "{null_entries} rows have a NULL entry at SELECTOR — wrong selector for $.field?",
    );

    // Every extracted entry is a valid ste_vec_entry payload AND carries `oc`
    // (the ordered term the matrix's ore_cllw paths require).
    let invalid: i64 = sqlx::query_scalar(&format!(
        "SELECT COUNT(*) FROM fixtures.v3_doc_int4 \
         WHERE NOT eql_v3.is_valid_ste_vec_entry_payload((payload -> '{SELECTOR}'::text)::jsonb) \
            OR NOT eql_v3.has_ore_cllw((payload -> '{SELECTOR}'::text)::eql_v3.ste_vec_entry)",
    ))
    .fetch_one(&pool)
    .await?;
    anyhow::ensure!(
        invalid == 0,
        "{invalid} rows have an invalid or oc-less entry at SELECTOR",
    );

    // Distinct oc terms == row count (distinct plaintexts → distinct ORE-CLLW
    // leaves), so the correctness/ordering oracle has real discrimination.
    let distinct_oc: i64 = sqlx::query_scalar(&format!(
        "SELECT COUNT(DISTINCT ((payload -> '{SELECTOR}'::text)::jsonb ->> 'oc')) \
         FROM fixtures.v3_doc_int4",
    ))
    .fetch_one(&pool)
    .await?;
    anyhow::ensure!(
        distinct_oc == n,
        "{n} distinct plaintexts must yield {n} distinct oc terms; got {distinct_oc}",
    );

    Ok(())
}

// ----------------------------------------------------------------------------
// ORE-CLLW injectivity. Distinct plaintexts must produce distinct ore_cllw
// terms. Compares `eql_v3.ore_cllw(...)` outputs directly — NOT entry `=`, which
// tests `eq_term`, not ORE.
// ----------------------------------------------------------------------------
#[sqlx::test(fixtures(path = "../../fixtures", scripts("v3_doc_int4")))]
async fn jsonb_entry_int4_ore_cllw_injectivity(pool: sqlx::PgPool) -> anyhow::Result<()> {
    let collisions: i64 = sqlx::query_scalar(&format!(
        "SELECT COUNT(*) \
         FROM fixtures.v3_doc_int4 a \
         JOIN fixtures.v3_doc_int4 b ON a.id < b.id \
         WHERE a.plaintext <> b.plaintext \
           AND eql_v3.ore_cllw((a.payload -> '{SELECTOR}'::text)::eql_v3.ste_vec_entry) \
             = eql_v3.ore_cllw((b.payload -> '{SELECTOR}'::text)::eql_v3.ste_vec_entry)",
    ))
    .fetch_one(&pool)
    .await?;
    anyhow::ensure!(
        collisions == 0,
        "no two distinct plaintexts may share an ORE-CLLW term ($.field); got {collisions} collisions",
    );
    Ok(())
}

// ----------------------------------------------------------------------------
// Index engagement — hand-written (not via the shared `__scalar_matrix_index`
// driver, which sweeps a bare-jsonb RHS that flattens to native `jsonb < jsonb`
// for entries). Builds the ore_cllw functional btree and asserts each ORDERING
// op (which inlines to `ore_cllw(value) <op> ore_cllw(const)`) engages it, using
// the domain-cast RHS (`'<lit>'::eql_v3.ste_vec_entry`) so the entry operator
// resolves rather than native jsonb.
//
// VALIDITY ONLY: forces `enable_seqscan = off` on the ~17-row fixture, so a
// green assertion proves the index is USABLE, not that the planner would PREFER
// it at scale (mirrors the scalar index-engagement caveat). Equality is
// excluded: entry `=` reduces through `eql_v3.eq_term`, not `ore_cllw`, so the
// ore_cllw btree cannot serve it.
// ----------------------------------------------------------------------------
#[sqlx::test(fixtures(path = "../../fixtures", scripts("v3_doc_int4")))]
async fn jsonb_entry_int4_index_engages(pool: sqlx::PgPool) -> anyhow::Result<()> {
    let sel = SELECTOR;
    let pivot = <JsonbEntryInt4 as ScalarType>::fixture_values()[0];
    let payload =
        eql_tests::scalar_domains::fetch_fixture_payload::<JsonbEntryInt4>(&pool, pivot).await?;
    let lit = payload.replace('\'', "''");

    let mut tx = pool.begin().await?;
    sqlx::query("CREATE TEMP TABLE entry_idx (value eql_v3.ste_vec_entry) ON COMMIT DROP")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "INSERT INTO entry_idx(value) \
         SELECT (payload -> '{sel}'::text)::eql_v3.ste_vec_entry FROM fixtures.v3_doc_int4",
    ))
    .execute(&mut *tx)
    .await?;
    sqlx::query("CREATE INDEX entry_idx_ore ON entry_idx USING btree (eql_v3.ore_cllw(value))")
        .execute(&mut *tx)
        .await?;
    sqlx::query("ANALYZE entry_idx").execute(&mut *tx).await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    for op in ["<", "<=", ">", ">="] {
        let query = format!(
            "SELECT * FROM entry_idx WHERE value {op} '{lit}'::eql_v3.ste_vec_entry",
        );
        eql_tests::matrix::assert_index_scan_uses(
            &mut *tx,
            &query,
            "entry_idx_ore",
            &format!("entry op {op} (domain-cast RHS) must engage the ore_cllw functional btree"),
        )
        .await?;
    }

    tx.commit().await?;
    Ok(())
}
