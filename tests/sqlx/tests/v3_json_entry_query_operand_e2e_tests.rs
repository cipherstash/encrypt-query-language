#![cfg(feature = "proptest-e2e")]
//! CIP-3551 — end-to-end conformance for exact field EQUALITY on encrypted JSON,
//! with the query needle encrypted FRESH through cipherstash-client rather than
//! reconstructed from the stored document.
//!
//! ## Why this suite exists
//!
//! `v3_jsonb_tests` proves value-selector containment by lifting a selector out of
//! a fixture row and searching for it — the answer is extracted from the data it is
//! then checked against, so no client-side encryption bug can fail it. Here the
//! needle is derived INDEPENDENTLY: a `(path, value)` goes through ZeroKMS at test
//! time and never touches the stored rows. Two independent encryptions of the same
//! `(path, value)` must produce byte-equal VALUE SELECTORS that containment equates
//! — the actual runtime equality contract (CIP-3551).
//!
//! ## What scopes a query
//!
//! Exact field EQUALITY is document containment: `col @> $1::eql_v3.query_json`,
//! where the needle carries a VALUE selector `SEL(tag ‖ path ‖ canonical(value))`
//! whose presence in the stored document is the exact match — path AND value baked
//! into one selector, injective (so `"café"` ≠ `"cafe"`, `2^53` ≠ `2^53+1`). The
//! client derives it via `ste_vec_query_value_selector`; nothing is pinned as a
//! constant, so the suite cannot drift onto the wrong field/value.
//!
//! RANGE independence (`col -> 'sel' > $1::query_<T>_ord`) is NOT proven here yet:
//! the current client cannot assemble a bare-`op` range operand into a v3 query
//! payload (`QueryOp::SteVecTerm` → `index term has no EQL v3 query-operand
//! representation` — v3 jsonb queries are the containment needle or the selector).
//! Range CORRECTNESS is covered against stored fixtures in
//! `v3_json_entry_cross_type_tests`; the fresh-crypto range-independence arm returns
//! when the client exposes a v3 range op.

use anyhow::Result;
use serde_json::json;
use sqlx::PgPool;

use eql_tests::fixtures::cipherstash::{ste_vec_query_value_selector, PAYLOAD_COLUMN};

/// The identifier the `v3_ste_vec` fixture rows were encrypted under
/// (`FixtureSpec::working_table` → `_fixture_<name>`). A value selector is a
/// deterministic MAC of (keyset, column, path, canonical(value)); the identifier's
/// table/column keep the needle honest about the column it targets.
const FIXTURE_TABLE: &str = "_fixture_v3_ste_vec";

/// Assert a freshly-derived selector is a plausible non-empty hex string, so a
/// silently-empty selector cannot make containment vacuously match nothing.
fn assert_hex_selector(sel: &str, what: &str) {
    assert!(
        !sel.is_empty()
            && sel.len().is_multiple_of(2)
            && sel.bytes().all(|b| b.is_ascii_hexdigit()),
        "{what} must be a non-empty even-length hex string; got {sel:?}"
    );
}

/// Rows whose stored document CONTAINS the given value selector — the exact
/// field-equality path (`col @> $1::eql_v3.query_json`, presence = exact match).
/// The needle is a single-element containment query `{"sv":[{"s":"<selector>"}]}`.
async fn contains_ids(pool: &PgPool, value_selector: &str) -> Result<Vec<i64>> {
    let needle = json!({ "sv": [{ "s": value_selector }] }).to_string();
    let ids: Vec<i64> = sqlx::query_scalar(
        "SELECT id FROM fixtures.v3_ste_vec \
         WHERE payload @> $1::jsonb::eql_v3.query_json ORDER BY id",
    )
    .bind(&needle)
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

/// #1 — NUMERIC leaf (`$.number`, values 1..=10). A FRESH value selector for
/// `$.number = 2` must be contained in exactly row 2's independently-encrypted
/// document, and no other — the two-independent-encryptions proof for EQUALITY.
///
/// Numbers canonicalise (jsonb numeric equality), so `json!(2)` matches the stored
/// `2` without the float-vs-int hazard the `op` term has — the value selector keys
/// on `canonical(value)`, not on an orderable f64 encoding.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn fresh_numeric_value_selector_equality(pool: PgPool) -> Result<()> {
    let eq_oracle = oracle_ids(&pool, "(plaintext ->> 'number')::int = 2").await?;
    assert_eq!(
        eq_oracle,
        vec![2],
        "fixture precondition: exactly row 2 has $.number = 2"
    );

    let vsel =
        ste_vec_query_value_selector(FIXTURE_TABLE, PAYLOAD_COLUMN, "$.number", &json!(2)).await?;
    assert_hex_selector(&vsel, "the fresh $.number=2 value selector");
    let contained = contains_ids(&pool, &vsel).await?;
    assert_eq!(
        contained, eq_oracle,
        "a FRESHLY derived value selector for `$.number = 2` must be contained in exactly \
         row 2's independently-encrypted document, and no other"
    );

    // Negative: a value NOT in the fixture matches nothing — so the positive above
    // is a real, injective match, not a vacuous always-contain.
    let vsel_absent =
        ste_vec_query_value_selector(FIXTURE_TABLE, PAYLOAD_COLUMN, "$.number", &json!(999))
            .await?;
    let absent = contains_ids(&pool, &vsel_absent).await?;
    assert!(
        absent.is_empty(),
        "a value selector for an absent value (`$.number = 999`) must match no rows; got {absent:?}"
    );
    Ok(())
}

/// #2 — TEXT leaf (`$.hello`, `"world-1"`..`"world-10"`). Exact TEXT equality — the
/// headline CIP-3551 capability the collating `op` term could not provide
/// (`"café"` == `"cafe"` under `op`, but the value selector is injective). A FRESH
/// value selector for `$.hello = "world-2"` must be contained in exactly row 2.
#[sqlx::test(fixtures(path = "../fixtures", scripts("v3_ste_vec")))]
async fn fresh_text_value_selector_equality(pool: PgPool) -> Result<()> {
    let eq_oracle = oracle_ids(&pool, "plaintext ->> 'hello' = 'world-2'").await?;
    assert_eq!(
        eq_oracle,
        vec![2],
        "fixture precondition: exactly row 2 has $.hello = \"world-2\""
    );

    let vsel =
        ste_vec_query_value_selector(FIXTURE_TABLE, PAYLOAD_COLUMN, "$.hello", &json!("world-2"))
            .await?;
    assert_hex_selector(&vsel, "the fresh $.hello=\"world-2\" value selector");
    let contained = contains_ids(&pool, &vsel).await?;
    assert_eq!(
        contained, eq_oracle,
        "a FRESHLY derived value selector for `$.hello = \"world-2\"` must be contained in \
         exactly row 2 — exact text equality the collating `op` term cannot provide"
    );

    // Negative: a string NOT in the fixture matches nothing.
    let vsel_absent = ste_vec_query_value_selector(
        FIXTURE_TABLE,
        PAYLOAD_COLUMN,
        "$.hello",
        &json!("world-999"),
    )
    .await?;
    let absent = contains_ids(&pool, &vsel_absent).await?;
    assert!(
        absent.is_empty(),
        "a value selector for an absent value (`$.hello = \"world-999\"`) must match no rows; got {absent:?}"
    );
    Ok(())
}
