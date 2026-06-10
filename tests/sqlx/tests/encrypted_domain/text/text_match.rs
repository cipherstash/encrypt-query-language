//! Match-containment coverage for `eql_v3.text_match` — separate from the
//! ordered matrix because `@>` is asymmetric/probabilistic, not a total order.
//! Asserts against the generated `eql_v2_text` fixtures (which carry `bf`).
use sqlx::PgPool;

const TABLE: &str = "fixtures.eql_v2_text";

async fn payload_for(pool: &PgPool, plaintext: &str) -> anyhow::Result<serde_json::Value> {
    Ok(sqlx::query_scalar::<_, serde_json::Value>(&format!(
        "SELECT payload::jsonb FROM {TABLE} WHERE plaintext = $1"
    ))
    .bind(plaintext)
    .fetch_one(pool)
    .await?)
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn value_matches_itself(pool: PgPool) -> anyhow::Result<()> {
    let p = payload_for(&pool, "aardvark").await?;
    let hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.text_match) @> ($1::jsonb::eql_v3.text_match)",
    )
    .bind(&p)
    .fetch_one(&pool)
    .await?;
    assert!(hit, "a value's bloom filter must contain itself");
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn haystack_contains_substring_needle(pool: PgPool) -> anyhow::Result<()> {
    let hay = payload_for(&pool, "aardvark").await?;
    let needle = payload_for(&pool, "aard").await?;
    let hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.text_match) @> ($2::jsonb::eql_v3.text_match)",
    )
    .bind(&hay)
    .bind(&needle)
    .fetch_one(&pool)
    .await?;
    assert!(hit, "'aardvark' bloom must contain 'aard' (shared ngrams)");
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn disjoint_value_does_not_match(pool: PgPool) -> anyhow::Result<()> {
    // A bloom filter is probabilistic and admits false positives, so a true
    // negative is only deterministic for inputs that share no n-grams. "aard"
    // (3-grams `aar`, `ard`) and "zzzz" (`zzz`) are chosen ngram-disjoint in
    // TEXT_FIXTURES (crates/eql-scalars/src/lib.rs) precisely for this assertion;
    // keep them disjoint if the fixture list changes.
    let hay = payload_for(&pool, "aard").await?;
    let needle = payload_for(&pool, "zzzz").await?;
    let hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.text_match) @> ($2::jsonb::eql_v3.text_match)",
    )
    .bind(&hay)
    .bind(&needle)
    .fetch_one(&pool)
    .await?;
    assert!(
        !hit,
        "'aard' must not contain disjoint 'zzzz' (no shared ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn match_uses_functional_index(pool: PgPool) -> anyhow::Result<()> {
    // Explicit extractor form `match_term(col) @> match_term(needle)`. Forces
    // `enable_seqscan = off` so this is an index-VALIDITY proof on the small
    // fixture (not a cost-preference one), and uses the node-type-aware
    // `assert_index_scan_uses` rather than a plan substring match.
    let mut tx = pool.begin().await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "CREATE INDEX text_match_idx ON {TABLE} USING gin (eql_v3.match_term(payload::eql_v3.text_match))"
    ))
    .execute(&mut *tx)
    .await?;

    // Needle embedded via an uncorrelated subquery so the helper receives a
    // hardcoded query (it interpolates directly and takes no binds).
    let query = format!(
        "SELECT 1 FROM {TABLE} \
         WHERE eql_v3.match_term(payload::eql_v3.text_match) \
           @> eql_v3.match_term((SELECT payload::jsonb FROM {TABLE} WHERE plaintext = 'aard')::eql_v3.text_match)"
    );
    eql_tests::matrix::assert_index_scan_uses(
        &mut *tx,
        &query,
        "text_match_idx",
        "explicit match_term(col) @> match_term(needle) must engage the functional GIN index",
    )
    .await?;
    Ok(())
}

/// Companion to `match_uses_functional_index` proving the **bare operator** form
/// `WHERE col @> needle` (not the explicit `match_term(col) @> match_term(needle)`)
/// reaches the GIN index — i.e. the generated `@>` wrapper inlines through
/// `match_term` to the native array-containment the index supports. Forces
/// `enable_seqscan = off` so this is an index-**validity** proof on the small
/// fixture, not a cost-preference one, and uses the node-type-aware
/// `assert_index_scan_uses` rather than a plan substring match.
#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn bare_operator_uses_functional_index(pool: PgPool) -> anyhow::Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "CREATE INDEX text_match_idx ON {TABLE} USING gin (eql_v3.match_term(payload::eql_v3.text_match))"
    ))
    .execute(&mut *tx)
    .await?;

    // The needle is embedded via an uncorrelated subquery so the helper receives
    // a hardcoded query string (it interpolates directly and takes no binds).
    let query = format!(
        "SELECT 1 FROM {TABLE} \
         WHERE (payload::eql_v3.text_match) \
           @> ((SELECT payload::jsonb FROM {TABLE} WHERE plaintext = 'aard')::eql_v3.text_match)"
    );
    eql_tests::matrix::assert_index_scan_uses(
        &mut *tx,
        &query,
        "text_match_idx",
        "bare `@>` operator on text_match must engage the functional GIN index",
    )
    .await?;
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn needle_contained_by_haystack(pool: PgPool) -> anyhow::Result<()> {
    // `<@` (contained-by) is the COMMUTATOR of `@>`; the implemented
    // `eql_v3.contained_by` is otherwise untested. `aard <@ aardvark` holds for
    // the same shared-ngram reason `aardvark @> aard` does.
    let needle = payload_for(&pool, "aard").await?;
    let hay = payload_for(&pool, "aardvark").await?;
    let hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.text_match) <@ ($2::jsonb::eql_v3.text_match)",
    )
    .bind(&needle)
    .bind(&hay)
    .fetch_one(&pool)
    .await?;
    assert!(
        hit,
        "'aard' bloom must be contained by 'aardvark' (shared ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn disjoint_value_not_contained_by(pool: PgPool) -> anyhow::Result<()> {
    // `<@` negative, mirroring `disjoint_value_does_not_match`. "zzzz" (3-gram
    // `zzz`) and "aard" (`aar`, `ard`) are ngram-disjoint in TEXT_FIXTURES, so
    // this is a deterministic true negative (bloom filters admit false positives
    // only for inputs that share n-grams). Keep them disjoint if the fixture
    // list changes.
    let needle = payload_for(&pool, "zzzz").await?;
    let hay = payload_for(&pool, "aard").await?;
    let hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.text_match) <@ ($2::jsonb::eql_v3.text_match)",
    )
    .bind(&needle)
    .bind(&hay)
    .fetch_one(&pool)
    .await?;
    assert!(
        !hit,
        "disjoint 'zzzz' must not be contained by 'aard' (no shared ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v2_text")))]
async fn contains_and_contained_by_are_commutative(pool: PgPool) -> anyhow::Result<()> {
    // Pin the `COMMUTATOR = @>/<@` declaration behaviorally: `a @> b` must equal
    // `b <@ a` for the same operand pair, and both hold for the superset/subset
    // pair `aardvark`/`aard`.
    let sup = payload_for(&pool, "aardvark").await?;
    let sub = payload_for(&pool, "aard").await?;
    let (contains, contained_by): (bool, bool) = sqlx::query_as(
        "SELECT ($1::jsonb::eql_v3.text_match) @> ($2::jsonb::eql_v3.text_match),
                ($2::jsonb::eql_v3.text_match) <@ ($1::jsonb::eql_v3.text_match)",
    )
    .bind(&sup)
    .bind(&sub)
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        contains, contained_by,
        "`a @> b` and `b <@ a` must agree (COMMUTATOR)"
    );
    assert!(
        contains,
        "'aardvark' @> 'aard' must hold for the curated pair"
    );
    Ok(())
}
