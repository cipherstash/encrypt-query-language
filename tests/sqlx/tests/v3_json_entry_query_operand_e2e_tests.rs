#![cfg(feature = "proptest-e2e")]
//! CIP-3526 — end-to-end conformance for the `json_entry` ↔ `query_<T>_ord`
//! cross-type operators, with the query operand encrypted FRESH through
//! cipherstash-client rather than reconstructed from the stored document.
//!
//! ## Why this suite exists
//!
//! `v3_json_entry_cross_type_tests` builds its operand by lifting the `op` term
//! out of a fixture row and re-wrapping it. That proves the SQL compares terms,
//! but the operand is not one any client ever produced — the answer is extracted
//! from the data it is then checked against, so no client-side encryption bug can
//! fail it. Here the operand is derived INDEPENDENTLY: a plaintext goes through
//! ZeroKMS at test time and never touches the stored rows. Two independent
//! encryptions of the same plaintext must produce byte-equal terms that the
//! operator equates — that is the actual runtime contract.
//!
//! ## What scopes a query
//!
//! `col -> '<selector>' <op> $1` resolves the FIELD via the `->` extraction —
//! it selects the one `sv` entry whose `s` matches, returning that leaf. The
//! comparison is then a pure term comparison. So a query operand carries no
//! field context and needs none: an `op` term encodes the plaintext and the
//! column only (cipherstash-client derives the OPE key from the index key +
//! SteVec prefix; the selector is mixed into `hm` terms exclusively). Field
//! scoping lives in the extractor, type scoping in the term's tag bit, column
//! scoping in the key. Nothing is left for the term to carry.
//!
//! Both coordinates therefore come from the client: `ste_vec_query_selector`
//! for the `->` argument, `ste_vec_query_term` for the operand. Nothing is
//! pinned as a constant, so this suite cannot drift onto the wrong field the way
//! a hard-coded selector can.

use anyhow::Result;
use serde_json::{json, Value};
use sqlx::PgPool;

use eql_tests::fixtures::cipherstash::{
    encrypt_store, ste_vec_query_selector, ste_vec_query_term, PAYLOAD_COLUMN,
};
use eql_tests::fixtures::index_kind::IndexKind;
use eql_tests::scalar_domains::F8;

/// The identifier the `v3_ste_vec` fixture rows were encrypted under
/// (`FixtureSpec::working_table` → `_fixture_<name>`). The index key comes from
/// the keyset, not the identifier, so this does not affect term derivation — it
/// only keeps the operand's `i` honest about the column it targets.
const FIXTURE_TABLE: &str = "_fixture_v3_ste_vec";

/// Build a v3 term-only query operand: `{v, i, op}`, plus an inert `hm` when the
/// target domain's CHECK demands one.
///
/// `query_text_ord`/`_ord_ope` require BOTH `hm` and `op` because they also serve
/// scalar text columns, whose equality routes through `hm`. For a JSON leaf the
/// `hm` is pure shape — `ord_term` reads only `op` — but it must be present and
/// real. `query_integer_ord` is `op`-only and passes `None`.
fn v3_operand(op_hex: &str, hm_hex: Option<&str>) -> String {
    let mut obj = serde_json::Map::new();
    obj.insert("v".into(), json!(3));
    obj.insert("i".into(), json!({"t": FIXTURE_TABLE, "c": PAYLOAD_COLUMN}));
    obj.insert("op".into(), json!(op_hex));
    if let Some(hm) = hm_hex {
        obj.insert("hm".into(), json!(hm));
    }
    Value::Object(obj).to_string()
}

/// Assert a freshly-derived term is a plausible non-empty hex string, so a
/// silently-empty term cannot make every comparison vacuously false.
fn assert_hex_term(term: &str, what: &str) {
    assert!(
        !term.is_empty()
            && term.len().is_multiple_of(2)
            && term.bytes().all(|b| b.is_ascii_hexdigit()),
        "{what} must be a non-empty even-length hex string; got {term:?}"
    );
}

/// The selector must actually resolve against every stored row — if `->` returns
/// NULL the comparisons below are all NULL and every assertion passes vacuously.
/// This is what fails loudly if the derived selector and the fixture's stored
/// selectors ever diverge (a keyset change, a `documents()` reshape).
async fn assert_selector_resolves(pool: &PgPool, selector: &str, path: &str) -> Result<()> {
    let resolved: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM fixtures.v3_ste_vec \
         WHERE (payload -> $1::text) IS NOT NULL",
    )
    .bind(selector)
    .fetch_one(pool)
    .await?;
    let total: i64 = sqlx::query_scalar("SELECT count(*) FROM fixtures.v3_ste_vec")
        .fetch_one(pool)
        .await?;
    assert_eq!(
        resolved, total,
        "the client-derived selector for {path} ({selector}) must resolve on all {total} \
         fixture rows; it resolved on {resolved}. The derived selector and the fixture's \
         stored selectors have diverged — same keyset and SteVec prefix?"
    );
    Ok(())
}

/// Run an operator against the fresh operand and return the matching ids.
async fn matching_ids(
    pool: &PgPool,
    selector: &str,
    operand: &str,
    op: &str,
    operand_ty: &str,
) -> Result<Vec<i64>> {
    let ids: Vec<i64> = sqlx::query_scalar(&format!(
        "SELECT id FROM fixtures.v3_ste_vec \
         WHERE (payload -> $1::text)::public.eql_v3_json_entry {op} $2::jsonb::{operand_ty} \
         ORDER BY id"
    ))
    .bind(selector)
    .bind(operand)
    .fetch_all(pool)
    .await?;
    Ok(ids)
}

/// Plaintext oracle over the fixture's own `plaintext` jsonb column.
async fn oracle_ids(pool: &PgPool, predicate: &str) -> Result<Vec<i64>> {
    let ids: Vec<i64> = sqlx::query_scalar(&format!(
        "SELECT id FROM fixtures.v3_ste_vec WHERE {predicate} ORDER BY id"
    ))
    .fetch_all(pool)
    .await?;
    Ok(ids)
}

/// #1 — NUMERIC leaf (`$.number`, values 1..=10). A fresh operand for the
/// plaintext `2` must equate with the stored `$.number` leaf of row 2 (`=`
/// matching exactly that row is the two-independent-encryptions proof) and order
/// correctly against every other row (`>`), both against the plaintext oracle.
///
/// The operand MUST be encrypted as a **float**, not an integer, because a JSON
/// numeric leaf is encoded through f64. `OrderableTerm::try_from(&Plaintext)`
/// treats the two incompatibly:
///
/// ```text
/// Plaintext::Int(Some(n))   => Number(*n as u64)                              // raw cast
/// Plaintext::Float(Some(f)) => Number(orderable_to_u64(f.to_orderable_bytes())) // twiddled
/// ```
///
/// So `Int(2)` yields `Number(2)` while the stored JSON `2` yields
/// `Number(orderable_to_u64(2.0f64))` — different bits, no match, ZERO ROWS and
/// no error. That is the real silent-mismatch failure mode on this surface: it
/// is a plaintext-TYPE mismatch, not a field-context one. Encrypting the operand
/// as `F8` is what makes it comparable, and the `=` arm below is what would
/// catch a regression to the integer path.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn fresh_numeric_operand_matches_plaintext_oracle(pool: PgPool) -> Result<()> {
    let selector = ste_vec_query_selector(FIXTURE_TABLE, PAYLOAD_COLUMN, "$.number").await?;
    assert_selector_resolves(&pool, &selector, "$.number").await?;

    let term = ste_vec_query_term(FIXTURE_TABLE, PAYLOAD_COLUMN, &F8(2.0)).await?;
    assert_hex_term(&term, "the fresh $.number=2 operand term");
    let operand = v3_operand(&term, None);

    // Guard the guard: the domain CHECK must accept the operand. A rejected cast
    // would error, but an operand that silently failed to carry `op` would make
    // every comparison NULL and every assertion below vacuous.
    let accepted: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.query_integer_ord) IS NOT NULL AND ($1::jsonb ? 'op')",
    )
    .bind(&operand)
    .fetch_one(&pool)
    .await?;
    assert!(
        accepted,
        "operand must pass the query_integer_ord CHECK and carry `op`: {operand}"
    );

    // `=` — the independence proof. The fresh term must byte-equal the stored
    // leaf's term for row 2 and no other.
    let eq = matching_ids(&pool, &selector, &operand, "=", "eql_v3.query_integer_ord").await?;
    let eq_oracle = oracle_ids(&pool, "(plaintext ->> 'number')::int = 2").await?;
    assert_eq!(
        eq_oracle,
        vec![2],
        "fixture precondition: exactly row 2 has $.number = 2"
    );
    assert_eq!(
        eq, eq_oracle,
        "a FRESHLY encrypted operand for `2` must equate with the independently \
         encrypted stored $.number leaf of row 2, and only that row"
    );

    // `<>` — the negative half: exactly the complement, not merely "some rows".
    let neq = matching_ids(&pool, &selector, &operand, "<>", "eql_v3.query_integer_ord").await?;
    let neq_oracle = oracle_ids(&pool, "(plaintext ->> 'number')::int <> 2").await?;
    assert_eq!(
        neq, neq_oracle,
        "`<>` against the fresh operand must match exactly the plaintext-differing rows"
    );

    // `>` — one range operator, full match set against the oracle.
    let gt = matching_ids(&pool, &selector, &operand, ">", "eql_v3.query_integer_ord").await?;
    let gt_oracle = oracle_ids(&pool, "(plaintext ->> 'number')::int > 2").await?;
    assert!(
        !gt_oracle.is_empty() && gt_oracle.len() < 10,
        "oracle must be a proper non-empty subset to be load-bearing; got {gt_oracle:?}"
    );
    assert_eq!(
        gt, gt_oracle,
        "`>` against the fresh operand must match exactly the rows whose $.number \
         sorts after 2"
    );

    Ok(())
}

/// #2 — TEXT leaf (`$.hello`, `"world-1"`..`"world-10"`). Same contract for a
/// string leaf, whose term is a variable-width CLLW-OPE encoding of
/// `orderize_string` rather than a fixed 64-bit number.
///
/// **Ordering only.** A text leaf has no equality operator, because `orderize_string`
/// is not injective — it NFKC-decomposes then strips every char that is not
/// alphanumeric / whitespace / ASCII punctuation, so `"café"` and `"cafe"` share
/// one `op` term and an `=` on it would be a false positive. `ord_term` is
/// deterministic, which is all ORDERING needs. See
/// `v3_json_entry_cross_type_tests::json_entry_text_has_no_equality_operator`,
/// which pins the absence, and `ScalarKind::ope_is_injective`, which owns the rule.
///
/// The `>` arm is deliberately pivoted on `"world-2"`, where STRING order and
/// NUMERIC order disagree: `"world-10"` sorts BELOW `"world-2"` as a string,
/// while `10` sorts above `2` as a number. So this arm pins that the surface is
/// really comparing text — an operand or leaf that was secretly numeric would
/// include row 10 and fail.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn fresh_text_operand_matches_plaintext_oracle(pool: PgPool) -> Result<()> {
    let selector = ste_vec_query_selector(FIXTURE_TABLE, PAYLOAD_COLUMN, "$.hello").await?;
    assert_selector_resolves(&pool, &selector, "$.hello").await?;

    let needle = "world-2".to_owned();
    let term = ste_vec_query_term(FIXTURE_TABLE, PAYLOAD_COLUMN, &needle).await?;
    assert_hex_term(&term, "the fresh $.hello=\"world-2\" operand term");

    // `query_text_ord`'s CHECK requires an `hm` alongside `op`. `ord_term` never
    // reads it for a JSON leaf, but it must be present and REAL (per CLAUDE.md:
    // real crypto, never synthetic blobs). Encrypt the same plaintext as a scalar
    // text value to obtain a genuine `hm` — freshly derived like everything else
    // here, and inert by construction.
    let inert = encrypt_store(
        "qtest",
        PAYLOAD_COLUMN,
        &[needle.clone()],
        &[IndexKind::Unique],
    )
    .await?;
    let hm = inert
        .first()
        .and_then(|p| p.get("hm"))
        .and_then(Value::as_str)
        .expect("a unique-indexed text payload must carry a string `hm` term")
        .to_owned();
    assert_hex_term(&hm, "the inert hm shape term");
    let operand = v3_operand(&term, Some(&hm));

    let accepted: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.query_text_ord) IS NOT NULL \
         AND ($1::jsonb ? 'op') AND ($1::jsonb ? 'hm')",
    )
    .bind(&operand)
    .fetch_one(&pool)
    .await?;
    assert!(
        accepted,
        "operand must pass the query_text_ord CHECK carrying `op` + `hm`: {operand}"
    );

    // `>` — string order, where row 10 discriminates text from numeric. This is
    // ALSO the independence proof for a string leaf: a freshly encrypted operand
    // for "world-2" must order against the independently encrypted stored $.hello
    // leaves, which only holds if two independent encryptions of one plaintext
    // produce corresponding terms.
    let gt = matching_ids(&pool, &selector, &operand, ">", "eql_v3.query_text_ord").await?;
    let gt_oracle = oracle_ids(&pool, "plaintext ->> 'hello' > 'world-2'").await?;
    assert!(
        !gt_oracle.contains(&10),
        "fixture precondition: \"world-10\" must sort BELOW \"world-2\" as a string, so the \
         oracle excludes row 10 — that divergence from numeric order is what gives this arm \
         its discriminating power. Got {gt_oracle:?}"
    );
    assert!(
        !gt_oracle.is_empty(),
        "oracle must be non-empty to be load-bearing; got {gt_oracle:?}"
    );
    assert_eq!(
        gt, gt_oracle,
        "`>` against the fresh text operand must follow CLLW-OPE string order and match \
         exactly the rows whose $.hello sorts after \"world-2\" (row 10 excluded)"
    );

    Ok(())
}
