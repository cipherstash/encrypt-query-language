//! Literal-payload smoke tests for the generated `public.eql_v3_text_match` surface:
//! `@>` / `<@` containment engages (supported wrappers), `=` raises (blocker),
//! `~~`/`~~*` are absent (no pattern-match), and the domain CHECK requires `bf`.
//! Uses hand-written jsonb payloads carrying `bf` — no encryption/fixtures
//! needed. The fixture-backed containment behaviour lives in `text_match.rs`.
use sqlx::PgPool;

/// Build a literal `public.eql_v3_text_match` cast expression carrying bloom array
/// `bf` (e.g. `"[1,2,3]"` or `"[]"`). Lets these tests state set-containment
/// semantics directly on `bf` arrays — deterministic, with no encryption and no
/// bloom false positives to reason about.
fn match_cast(bf: &str) -> String {
    format!("'{{\"v\":\"3\",\"i\":{{}},\"c\":\"x\",\"bf\":{bf}}}'::jsonb::public.eql_v3_text_match")
}

#[sqlx::test]
async fn text_match_at_contains_engages(pool: PgPool) -> anyhow::Result<()> {
    // self-containment: a filter contains a subset of itself
    let hit: bool = sqlx::query_scalar(
        "SELECT ('{\"v\":\"3\",\"i\":{},\"c\":\"x\",\"bf\":[1,2,3]}'::jsonb::public.eql_v3_text_match)
              @> ('{\"v\":\"3\",\"i\":{},\"c\":\"x\",\"bf\":[2]}'::jsonb::public.eql_v3_text_match)",
    )
    .fetch_one(&pool)
    .await?;
    assert!(hit, "[1,2,3] @> [2] must hold");
    Ok(())
}

#[sqlx::test]
async fn text_match_eq_is_blocked(pool: PgPool) -> anyhow::Result<()> {
    let err = sqlx::query(
        "SELECT ('{\"v\":\"3\",\"i\":{},\"c\":\"x\",\"bf\":[1]}'::jsonb::public.eql_v3_text_match)
              =  ('{\"v\":\"3\",\"i\":{},\"c\":\"x\",\"bf\":[1]}'::jsonb::public.eql_v3_text_match)",
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
        "'{\"v\":\"3\",\"i\":{},\"c\":\"x\",\"bf\":[1,2,3]}'::jsonb::public.eql_v3_text_match";
    const EMPTY: &str =
        "'{\"v\":\"3\",\"i\":{},\"c\":\"x\",\"bf\":[]}'::jsonb::public.eql_v3_text_match";

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

#[sqlx::test]
async fn match_null_propagates(pool: PgPool) -> anyhow::Result<()> {
    // `eql_v3.contains` / `eql_v3.contained_by` are STRICT, so a NULL operand
    // yields NULL (three-valued logic) rather than false or an error.
    const BF: &str = r#"{"v":"3","i":{},"c":"x","bf":[1,2,3]}"#;
    for op in ["@>", "<@"] {
        let sql =
            format!("SELECT ($1::jsonb::public.eql_v3_text_match) {op} ($2::jsonb::public.eql_v3_text_match)");
        eql_tests::assert_null(&pool, &sql, &[None, Some(BF)]).await?;
        eql_tests::assert_null(&pool, &sql, &[Some(BF), None]).await?;
    }
    Ok(())
}

#[sqlx::test]
async fn text_match_contained_by_engages(pool: PgPool) -> anyhow::Result<()> {
    // `<@` is the COMMUTATOR of `@>` and otherwise unexercised on literals.
    let hit: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) <@ ({})",
        match_cast("[2]"),
        match_cast("[1,2,3]")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(hit, "[2] <@ [1,2,3] must hold");
    Ok(())
}

#[sqlx::test]
async fn empty_bloom_contained_by_semantics(pool: PgPool) -> anyhow::Result<()> {
    // `<@` mirror of the `@>` empty-set test: the empty filter is contained by
    // everything; a non-empty filter is not contained by the empty filter.
    let empty_in_everything: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) <@ ({})",
        match_cast("[]"),
        match_cast("[1,2,3]")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(
        empty_in_everything,
        "the empty filter must be contained by every filter"
    );

    let nonempty_not_in_empty: bool = sqlx::query_scalar(&format!(
        "SELECT ({}) <@ ({})",
        match_cast("[1,2,3]"),
        match_cast("[]")
    ))
    .fetch_one(&pool)
    .await?;
    assert!(
        !nonempty_not_in_empty,
        "a non-empty filter must not be contained by the empty filter"
    );
    Ok(())
}

#[sqlx::test]
async fn text_match_containment_requires_all_elements(pool: PgPool) -> anyhow::Result<()> {
    // `@>` is set containment: the haystack bloom must include *every* element of
    // the needle bloom. This is what makes it unlike SQL `LIKE` — there is no
    // wildcard or anchoring, only "are all of these ngrams present". Asserted on
    // literal `bf` arrays so it is deterministic (no bloom false positives).
    let cases = [
        ("[1,2,3]", "[1,2]", true),  // proper subset
        ("[1,2,3]", "[3,4]", false), // partial overlap — 4 is absent
        ("[1,2]", "[3]", false),     // disjoint
    ];
    for (hay, needle, expected) in cases {
        let sql = format!("SELECT ({}) @> ({})", match_cast(hay), match_cast(needle));
        let hit: bool = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
        assert_eq!(
            hit, expected,
            "bf {hay} @> bf {needle} should be {expected}"
        );
    }
    Ok(())
}

#[sqlx::test]
async fn text_match_like_ilike_absent(pool: PgPool) -> anyhow::Result<()> {
    // The bloom containment surface replaces deprecated `LIKE`/`ILIKE`, but it is
    // NOT a pattern-match operator. `~~`/`~~*` are deliberately not declared on
    // public.eql_v3_text_match, so they resolve to PostgreSQL's "operator does not
    // exist" rather than an EQL blocker. Pin that they stay absent on the very
    // domain a `LIKE` user would reach for.
    const BF: &str = r#"{"v":"3","i":{},"c":"x","bf":[1]}"#;
    for op in ["~~", "~~*"] {
        let sql = format!(
            "SELECT $1::jsonb::public.eql_v3_text_match {op} $2::jsonb::public.eql_v3_text_match"
        );
        eql_tests::assert_raises(
            &pool,
            &sql,
            &[Some(BF), Some(BF)],
            "operator does not exist",
        )
        .await?;
    }
    Ok(())
}

#[sqlx::test]
async fn text_match_payload_check_rejects_missing_bf(pool: PgPool) -> anyhow::Result<()> {
    // The generated public.eql_v3_text_match domain CHECK requires the `bf` key
    // (src/v3/scalars/text/text_types.sql). A well-formed envelope lacking `bf`
    // must be rejected at the cast, so a match query can never silently run
    // against a payload that carries no bloom term.
    const NO_BF: &str = r#"{"v":"3","i":{},"c":"x"}"#;
    eql_tests::assert_raises(
        &pool,
        "SELECT $1::jsonb::public.eql_v3_text_match",
        &[Some(NO_BF)],
        "violates check constraint",
    )
    .await?;
    Ok(())
}
