//! Direct behavioural tests for the self-contained `eql_v3` searchable-
//! encrypted-metadata (SEM) index-term functions (`eql_v3.hmac_256`,
//! `eql_v3.ore_block_u64_8_256` and their comparators).
//!
//! These functions are a HAND-PORT of the `eql_v2` originals (`src/v3/sem/`).
//! The scalar matrix already exercises the happy path of the *array* comparator
//! end-to-end against real ciphertext fixtures (ordering, equality, min/max,
//! injectivity, index engagement). This file covers the branches the matrix
//! structurally cannot reach, and which are otherwise tested only on the
//! `eql_v2` copies (in `tests/index_compare_tests.rs`):
//!
//! - T1: differential v2↔v3 parity on real `ob` fixtures (the strongest guard
//!   against a faithful-port slip — see below).
//! - T2: the `'Ciphertexts are different lengths'` RAISE (all real fixtures are
//!   equal length, so the matrix never hits it).
//! - T3: NULL-term ordering inside `compare_ore_block_u64_8_256_term` — the
//!   `STRICT` comparison wrappers short-circuit before these branches run.
//! - T4: array-level NULL + empty/cardinality base cases of the recursion.
//! - T5: presence checks (`has_*`) and the missing-`ob` RAISE.
//!
//! All migrations (`001`–`007`) auto-apply to every `#[sqlx::test]` pool, so the
//! real `ore` table (ids 1–1000) and both schemas are available with no setup.

use std::collections::HashSet;

use anyhow::Result;
use eql_tests::assert_raises;
use sqlx::PgPool;

/// A single term built directly from hex — no encryption needed for the
/// structural/edge-case tests.
fn term(hex: &str) -> String {
    format!("ROW(decode('{hex}', 'hex'))::eql_v3.ore_block_u64_8_256_term")
}

/// T1 — Differential parity: the same real `ob` payload must compare identically
/// through the `eql_v2` and `eql_v3` array comparators. `eql_v2` is the trusted
/// oracle; `eql_v3` is the byte-port. Both sides route through the SAME path
/// (jsonb extractor → composite → `compare_ore_block_u64_8_256_terms`) so the
/// schema prefix is the only variable — any divergence is a genuine port bug.
/// v3 has no encrypted-arg `compare` overload, hence the extractor routing.
#[sqlx::test]
async fn ore_v2_v3_comparator_parity_on_real_fixtures(pool: PgPool) -> Result<()> {
    // Pairs spanning equal and unequal ids. Plaintext order of the fixtures is
    // undocumented, so we assert v2≡v3 agreement (not a specific sign).
    let pairs = [
        (1i64, 1i64),
        (1, 2),
        (2, 1),
        (1, 500),
        (500, 1),
        (42, 42),
        (10, 900),
        (900, 10),
    ];

    let sql = r#"
        WITH a AS (SELECT e::jsonb AS j FROM ore WHERE id = $1),
             b AS (SELECT e::jsonb AS j FROM ore WHERE id = $2)
        SELECT
          eql_v2.compare_ore_block_u64_8_256_terms(
            eql_v2.ore_block_u64_8_256(a.j), eql_v2.ore_block_u64_8_256(b.j)) AS v2,
          eql_v3.compare_ore_block_u64_8_256_terms(
            eql_v3.ore_block_u64_8_256(a.j), eql_v3.ore_block_u64_8_256(b.j)) AS v3
        FROM a, b
    "#;

    let mut v3_signs: HashSet<i32> = HashSet::new();
    for (x, y) in pairs {
        let (v2, v3): (i32, i32) = sqlx::query_as(sql).bind(x).bind(y).fetch_one(&pool).await?;
        assert_eq!(
            v2, v3,
            "eql_v2 and eql_v3 ORE comparators disagree on ids ({x},{y}): v2={v2} v3={v3}"
        );
        v3_signs.insert(v3);
    }

    // Non-triviality: the sample must have actually exercised lt, eq, and gt —
    // otherwise the parity check could pass on a degenerate all-equal path.
    assert!(
        v3_signs.contains(&0),
        "sample must include an equal pair (0)"
    );
    assert!(
        v3_signs.contains(&-1),
        "sample must include a less-than pair (-1)"
    );
    assert!(
        v3_signs.contains(&1),
        "sample must include a greater-than pair (1)"
    );
    Ok(())
}

/// T2 — The term comparator must reject ciphertexts of different lengths. This
/// guard is unreachable via the matrix (every real fixture is equal length).
#[sqlx::test]
async fn ore_term_comparator_rejects_different_length_ciphertexts(pool: PgPool) -> Result<()> {
    let sql = format!(
        "SELECT eql_v3.compare_ore_block_u64_8_256_term({}, {})",
        term("aabbccdd"),   // 4 bytes
        term("aabbccddee"), // 5 bytes
    );
    assert_raises(&pool, &sql, &[], "Ciphertexts are different lengths").await?;
    Ok(())
}

/// T3 — NULL-term ordering inside `compare_ore_block_u64_8_256_term`. The
/// function is intentionally NOT `STRICT`, so these defensive branches are
/// reachable by a direct call (the `STRICT` comparison wrappers never reach
/// them). Pins: `(NULL, t) = -1`, `(t, NULL) = 1`, `(NULL, NULL) = 0`.
#[sqlx::test]
async fn ore_term_comparator_null_ordering(pool: PgPool) -> Result<()> {
    let t = term("aabb");
    let n = "NULL::eql_v3.ore_block_u64_8_256_term";

    let cases = [
        (
            format!("SELECT eql_v3.compare_ore_block_u64_8_256_term({n}, {t})"),
            -1,
        ),
        (
            format!("SELECT eql_v3.compare_ore_block_u64_8_256_term({t}, {n})"),
            1,
        ),
        (
            format!("SELECT eql_v3.compare_ore_block_u64_8_256_term({n}, {n})"),
            0,
        ),
    ];

    for (sql, expected) in cases {
        let got: i32 = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert_eq!(got, expected, "null-term ordering: {sql}");
    }
    Ok(())
}

/// T4 — Array-level NULL and empty/cardinality base cases of the recursive
/// `compare_ore_block_u64_8_256_terms(term[], term[])`. NULL array → NULL;
/// both empty → 0; empty vs non-empty → -1; non-empty vs empty → 1.
#[sqlx::test]
async fn ore_terms_array_null_and_empty_base_cases(pool: PgPool) -> Result<()> {
    let t = format!("ARRAY[{}]", term("aabb"));
    let empty = "ARRAY[]::eql_v3.ore_block_u64_8_256_term[]";
    let null_arr = "NULL::eql_v3.ore_block_u64_8_256_term[]";

    // NULL array operand → NULL result (the array overload returns NULL; it is
    // not STRICT). Typed as Option<i32>; the shared `assert_null` helper only
    // types Option<bool>, so query directly here.
    for sql in [
        format!("SELECT eql_v3.compare_ore_block_u64_8_256_terms({null_arr}, {t})"),
        format!("SELECT eql_v3.compare_ore_block_u64_8_256_terms({t}, {null_arr})"),
    ] {
        let got: Option<i32> = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert!(got.is_none(), "NULL array operand must yield NULL: {sql}");
    }

    let cases = [
        (
            format!("SELECT eql_v3.compare_ore_block_u64_8_256_terms({empty}, {empty})"),
            0,
        ),
        (
            format!("SELECT eql_v3.compare_ore_block_u64_8_256_terms({empty}, {t})"),
            -1,
        ),
        (
            format!("SELECT eql_v3.compare_ore_block_u64_8_256_terms({t}, {empty})"),
            1,
        ),
    ];
    for (sql, expected) in cases {
        let got: i32 = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert_eq!(got, expected, "array base case: {sql}");
    }
    Ok(())
}

/// T5 — SEM presence checks (`has_ore_block_u64_8_256`, `has_hmac_256`), the
/// extractor's missing-`ob` RAISE, and its NULL-jsonb short-circuit.
#[sqlx::test]
async fn sem_presence_checks_and_missing_ob_behaviour(pool: PgPool) -> Result<()> {
    let bool_cases = [
        (
            r#"SELECT eql_v3.has_ore_block_u64_8_256('{"ob":["aa"]}'::jsonb)"#,
            true,
        ),
        (
            r#"SELECT eql_v3.has_ore_block_u64_8_256('{}'::jsonb)"#,
            false,
        ),
        // json-null `ob` → `->>` yields NULL → absent.
        (
            r#"SELECT eql_v3.has_ore_block_u64_8_256('{"ob":null}'::jsonb)"#,
            false,
        ),
        (r#"SELECT eql_v3.has_hmac_256('{"hm":"abc"}'::jsonb)"#, true),
        (r#"SELECT eql_v3.has_hmac_256('{}'::jsonb)"#, false),
    ];
    for (sql, expected) in bool_cases {
        let got: bool = sqlx::query_scalar(sql).fetch_one(&pool).await?;
        assert_eq!(got, expected, "presence check: {sql}");
    }

    // Missing `ob` → RAISE.
    assert_raises(
        &pool,
        r#"SELECT eql_v3.ore_block_u64_8_256('{"foo":1}'::jsonb)"#,
        &[],
        "Expected an ore index (ob) value",
    )
    .await?;

    // NULL jsonb → NULL composite (STRICT short-circuit), NOT a raise.
    let is_null: bool =
        sqlx::query_scalar("SELECT eql_v3.ore_block_u64_8_256(NULL::jsonb) IS NULL")
            .fetch_one(&pool)
            .await?;
    assert!(
        is_null,
        "NULL jsonb must extract to a NULL composite, not raise"
    );
    Ok(())
}
