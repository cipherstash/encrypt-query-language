//! Literal-payload smoke tests for the generated `eql_v3.text_match` surface:
//! `@>` containment engages (supported wrapper) and `=` raises (blocker).
//! Uses hand-written jsonb payloads carrying `bf` — no encryption/fixtures
//! needed. The fixture-backed containment behaviour lives in `text_match.rs`.
use sqlx::PgPool;

#[sqlx::test]
async fn text_match_at_contains_engages(pool: PgPool) -> anyhow::Result<()> {
    // self-containment: a filter contains a subset of itself
    let hit: bool = sqlx::query_scalar(
        "SELECT ('{\"v\":\"2\",\"i\":{},\"c\":\"x\",\"bf\":[1,2,3]}'::jsonb::eql_v3.text_match)
              @> ('{\"v\":\"2\",\"i\":{},\"c\":\"x\",\"bf\":[2]}'::jsonb::eql_v3.text_match)",
    )
    .fetch_one(&pool)
    .await?;
    assert!(hit, "[1,2,3] @> [2] must hold");
    Ok(())
}

#[sqlx::test]
async fn text_match_eq_is_blocked(pool: PgPool) -> anyhow::Result<()> {
    let err = sqlx::query(
        "SELECT ('{\"v\":\"2\",\"i\":{},\"c\":\"x\",\"bf\":[1]}'::jsonb::eql_v3.text_match)
              =  ('{\"v\":\"2\",\"i\":{},\"c\":\"x\",\"bf\":[1]}'::jsonb::eql_v3.text_match)",
    )
    .execute(&pool)
    .await
    .unwrap_err();
    assert!(
        format!("{err}").contains("not supported"),
        "= must be blocked on text_match"
    );
    Ok(())
}

#[sqlx::test]
async fn empty_bloom_has_empty_set_semantics(pool: PgPool) -> anyhow::Result<()> {
    // A value too short to tokenize (e.g. the empty string) yields an empty
    // bloom filter (`bf: []`). Containment then follows empty-set semantics:
    // everything contains the empty set; the empty set contains nothing. Uses
    // literal payloads so the assertion is deterministic and independent of how
    // the encryptor renders a `bf` for a degenerate plaintext.
    const NON_EMPTY: &str =
        "'{\"v\":\"2\",\"i\":{},\"c\":\"x\",\"bf\":[1,2,3]}'::jsonb::eql_v3.text_match";
    const EMPTY: &str = "'{\"v\":\"2\",\"i\":{},\"c\":\"x\",\"bf\":[]}'::jsonb::eql_v3.text_match";

    let everything_contains_empty: bool =
        sqlx::query_scalar(&format!("SELECT ({NON_EMPTY}) @> ({EMPTY})"))
            .fetch_one(&pool)
            .await?;
    assert!(
        everything_contains_empty,
        "every filter must contain the empty filter"
    );

    let empty_contains_nothing: bool =
        sqlx::query_scalar(&format!("SELECT ({EMPTY}) @> ({NON_EMPTY})"))
            .fetch_one(&pool)
            .await?;
    assert!(
        !empty_contains_nothing,
        "empty filter must not contain a non-empty one"
    );
    Ok(())
}
