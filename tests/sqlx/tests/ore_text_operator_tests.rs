//! ORE text operator tests
//!
//! Tests equality, comparison, function, JSONB, and edge-case operators with text ORE encryption.
//! Uses ore_text table from migrations/006_install_ore_text_data.sql (ids 1-100)
//! Words are lexicographically sorted: id=1 is 'aardvark', id=100 is 'zinc'.
//!
//! Pivot point: id=56 ('horizon') — 55 rows below, 44 rows above.

use anyhow::Result;
use eql_tests::{get_ore_text_encrypted, get_ore_text_encrypted_as_jsonb, QueryAssertion};
use sqlx::PgPool;

// ============================================================================
// Equality and inequality operators
// ============================================================================

// ore_text_equality_operator_finds_match,
// ore_text_inequality_operator_finds_non_matches removed:
// post-discipline `=` and `<>` require hmac at the root. The ore_text
// fixture carries only ORE terms.

// ============================================================================
// Comparison operators
// ============================================================================

#[sqlx::test]
async fn ore_text_less_than(pool: PgPool) -> Result<()> {
    // Test: e < e with text ORE
    // 55 words before 'horizon' (ids 1-55)

    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(55).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_less_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e <= e with text ORE
    // 56 words at or before 'horizon' (ids 1-56)

    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(56).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_greater_than(pool: PgPool) -> Result<()> {
    // Test: e > e with text ORE
    // 44 words after 'horizon' (ids 57-100)

    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e > '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(44).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_greater_than_or_equal(pool: PgPool) -> Result<()> {
    // Test: e >= e with text ORE
    // 45 words at or after 'horizon' (ids 56-100)

    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e >= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(45).await;

    Ok(())
}

// ============================================================================
// Function variants (eql_v2.eq, neq, lt, lte, gt, gte)
// ============================================================================

#[sqlx::test]
async fn ore_text_eq_function(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE eql_v2.eq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(1).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_neq_function(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE eql_v2.neq(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(99).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_lt_function(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE eql_v2.lt(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(55).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_lte_function(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE eql_v2.lte(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(56).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_gt_function(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE eql_v2.gt(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(44).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_gte_function(pool: PgPool) -> Result<()> {
    let encrypted = get_ore_text_encrypted(&pool, 56).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE eql_v2.gte(e, '{}'::eql_v2_encrypted)",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(45).await;

    Ok(())
}

// ============================================================================
// JSONB variants: e op jsonb
// ============================================================================

#[sqlx::test]
async fn ore_text_less_than_encrypted_lt_jsonb(pool: PgPool) -> Result<()> {
    // Test: e < jsonb with text ORE

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE e < '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(55).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_greater_than_encrypted_gt_jsonb(pool: PgPool) -> Result<()> {
    // Test: e > jsonb with text ORE

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE e > '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(44).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_lte_encrypted_lte_jsonb(pool: PgPool) -> Result<()> {
    // Test: e <= jsonb with text ORE

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE e <= '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(56).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_gte_encrypted_gte_jsonb(pool: PgPool) -> Result<()> {
    // Test: e >= jsonb with text ORE

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE e >= '{}'::jsonb", json_value);

    QueryAssertion::new(&pool, &sql).count(45).await;

    Ok(())
}

// ============================================================================
// JSONB variants: e = jsonb, e <> jsonb
// ============================================================================

// ore_text_equality_encrypted_eq_jsonb,
// ore_text_inequality_encrypted_neq_jsonb removed: post-discipline `=`
// and `<>` (cross-type encrypted/jsonb) require hmac at the root.

// ============================================================================
// JSONB variants: jsonb = e, jsonb <> e (reverse direction)
// ============================================================================

// ore_text_equality_jsonb_eq_encrypted,
// ore_text_inequality_jsonb_neq_encrypted removed: post-discipline `=`
// and `<>` (reverse-direction jsonb/encrypted) require hmac at the root.

// ============================================================================
// JSONB variants: jsonb op e (reverse comparison direction)
// ============================================================================

#[sqlx::test]
async fn ore_text_less_than_jsonb_lt_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb < e (reverse direction)
    // jsonb(56) < e means e > 56, so 44 records (ids 57-100)

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE '{}'::jsonb < e", json_value);

    QueryAssertion::new(&pool, &sql).count(44).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_greater_than_jsonb_gt_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb > e (reverse direction)
    // jsonb(56) > e means e < 56, so 55 records (ids 1-55)

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE '{}'::jsonb > e", json_value);

    QueryAssertion::new(&pool, &sql).count(55).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_lte_jsonb_lte_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb <= e (reverse direction)
    // jsonb(56) <= e means e >= 56, so 45 records (ids 56-100)

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE '{}'::jsonb <= e", json_value);

    QueryAssertion::new(&pool, &sql).count(45).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_gte_jsonb_gte_encrypted(pool: PgPool) -> Result<()> {
    // Test: jsonb >= e (reverse direction)
    // jsonb(56) >= e means e <= 56, so 56 records (ids 1-56)

    let json_value = get_ore_text_encrypted_as_jsonb(&pool, 56).await?;

    let sql = format!("SELECT id FROM ore_text WHERE '{}'::jsonb >= e", json_value);

    QueryAssertion::new(&pool, &sql).count(56).await;

    Ok(())
}

// ============================================================================
// Lexicographic edge cases
// ============================================================================

#[sqlx::test]
async fn ore_text_prefix_less_than(pool: PgPool) -> Result<()> {
    // Prefix ordering: app(6) < apple(7) < application(8)
    // e < apple(7) should return 6 rows (ids 1-6), confirming app(6) < apple(7)

    let encrypted = get_ore_text_encrypted(&pool, 7).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(6).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_prefix_greater_than(pool: PgPool) -> Result<()> {
    // e > apple(7) should return 93 rows (ids 8-100), confirming application(8) > apple(7)

    let encrypted = get_ore_text_encrypted(&pool, 7).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e > '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(93).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_prefix_between(pool: PgPool) -> Result<()> {
    // e >= app(6) AND e <= application(8) should return 3 rows (ids 6, 7, 8)

    let lower = get_ore_text_encrypted(&pool, 6).await?;
    let upper = get_ore_text_encrypted(&pool, 8).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e >= '{}'::eql_v2_encrypted AND e <= '{}'::eql_v2_encrypted",
        lower, upper
    );

    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_similar_starts_less_than(pool: PgPool) -> Result<()> {
    // Similar starts: car(22) < card(23) < care(24)
    // e < card(23) should return 22 rows (ids 1-22), confirming car(22) < card(23)

    let encrypted = get_ore_text_encrypted(&pool, 23).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(22).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_similar_starts_between(pool: PgPool) -> Result<()> {
    // e >= car(22) AND e <= care(24) should return 3 rows (ids 22, 23, 24)

    let lower = get_ore_text_encrypted(&pool, 22).await?;
    let upper = get_ore_text_encrypted(&pool, 24).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e >= '{}'::eql_v2_encrypted AND e <= '{}'::eql_v2_encrypted",
        lower, upper
    );

    QueryAssertion::new(&pool, &sql).count(3).await;

    Ok(())
}

// ============================================================================
// Boundary tests
// ============================================================================

#[sqlx::test]
async fn ore_text_less_than_first_word(pool: PgPool) -> Result<()> {
    // e < aardvark(1) should return 0 rows — nothing is before the first word

    let encrypted = get_ore_text_encrypted(&pool, 1).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e < '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_greater_than_last_word(pool: PgPool) -> Result<()> {
    // e > zinc(100) should return 0 rows — nothing is after the last word

    let encrypted = get_ore_text_encrypted(&pool, 100).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e > '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(0).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_gte_first_word(pool: PgPool) -> Result<()> {
    // e >= aardvark(1) should return all 100 rows

    let encrypted = get_ore_text_encrypted(&pool, 1).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e >= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(100).await;

    Ok(())
}

#[sqlx::test]
async fn ore_text_lte_last_word(pool: PgPool) -> Result<()> {
    // e <= zinc(100) should return all 100 rows

    let encrypted = get_ore_text_encrypted(&pool, 100).await?;

    let sql = format!(
        "SELECT id FROM ore_text WHERE e <= '{}'::eql_v2_encrypted",
        encrypted
    );

    QueryAssertion::new(&pool, &sql).count(100).await;

    Ok(())
}
