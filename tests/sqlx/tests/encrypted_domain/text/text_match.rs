//! Match-containment coverage for `eql_v3.text_match` — separate from the
//! ordered matrix because `@>` is asymmetric/probabilistic, not a total order.
//! Asserts against the generated `eql_v3_text` fixtures (which carry `bf`).
use sqlx::PgPool;

const TABLE: &str = "fixtures.eql_v3_text";

async fn payload_for(pool: &PgPool, plaintext: &str) -> anyhow::Result<serde_json::Value> {
    Ok(sqlx::query_scalar::<_, serde_json::Value>(&format!(
        "SELECT payload::jsonb FROM {TABLE} WHERE plaintext = $1"
    ))
    .bind(plaintext)
    .fetch_one(pool)
    .await?)
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn disjoint_value_does_not_match(pool: PgPool) -> anyhow::Result<()> {
    // A bloom filter is probabilistic and admits false positives, so a true
    // negative is only deterministic for inputs that share no n-grams. "aard"
    // (3-grams `aar`, `ard`) and "zzzz" (`zzz`) are chosen ngram-disjoint in
    // TEXT_FIXTURES (crates/eql-domains/src/lib.rs) precisely for this assertion;
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
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
#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn needle_contained_by_haystack(pool: PgPool) -> anyhow::Result<()> {
    // `<@` (contained-by) is the COMMUTATOR of `@>`; the implemented
    // `eql_v3_internal.contained_by` is otherwise untested. `aard <@ aardvark` holds for
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
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

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn direct_contains_function_matches_operator(pool: PgPool) -> anyhow::Result<()> {
    // Exercises `eql_v3_internal.contains(a, b)` by NAME (not the `@>` operator), and pins
    // that the function and the operator it backs agree. `aardvark` contains the
    // substring needle `aard` (shared ngrams); the disjoint `zzzz` does not.
    let hay = payload_for(&pool, "aardvark").await?;
    let aard = payload_for(&pool, "aard").await?;
    let zzzz = payload_for(&pool, "zzzz").await?;

    let (fn_hit, op_hit, fn_miss): (bool, bool, bool) = sqlx::query_as(
        "SELECT eql_v3_internal.contains($1::jsonb::eql_v3.text_match, $2::jsonb::eql_v3.text_match),
                ($1::jsonb::eql_v3.text_match) @> ($2::jsonb::eql_v3.text_match),
                eql_v3_internal.contains($1::jsonb::eql_v3.text_match, $3::jsonb::eql_v3.text_match)",
    )
    .bind(&hay)
    .bind(&aard)
    .bind(&zzzz)
    .fetch_one(&pool)
    .await?;

    assert!(fn_hit, "eql_v3_internal.contains('aardvark','aard') must be true");
    assert_eq!(
        fn_hit, op_hit,
        "eql_v3_internal.contains must agree with the @> operator"
    );
    assert!(
        !fn_miss,
        "eql_v3_internal.contains('aardvark','zzzz') must be false (disjoint ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn direct_contained_by_function_matches_operator(pool: PgPool) -> anyhow::Result<()> {
    // Exercises `eql_v3_internal.contained_by(a, b)` by NAME (not the `<@` operator). `aard`
    // is contained by `aardvark`; `zzzz` is not contained by `aard` (disjoint ngrams).
    let aard = payload_for(&pool, "aard").await?;
    let hay = payload_for(&pool, "aardvark").await?;
    let zzzz = payload_for(&pool, "zzzz").await?;

    let (fn_hit, op_hit, fn_miss): (bool, bool, bool) = sqlx::query_as(
        "SELECT eql_v3_internal.contained_by($1::jsonb::eql_v3.text_match, $2::jsonb::eql_v3.text_match),
                ($1::jsonb::eql_v3.text_match) <@ ($2::jsonb::eql_v3.text_match),
                eql_v3_internal.contained_by($3::jsonb::eql_v3.text_match, $1::jsonb::eql_v3.text_match)",
    )
    .bind(&aard)
    .bind(&hay)
    .bind(&zzzz)
    .fetch_one(&pool)
    .await?;

    assert!(
        fn_hit,
        "eql_v3_internal.contained_by('aard','aardvark') must be true"
    );
    assert_eq!(
        fn_hit, op_hit,
        "eql_v3_internal.contained_by must agree with the <@ operator"
    );
    assert!(
        !fn_miss,
        "eql_v3_internal.contained_by('zzzz','aard') must be false (disjoint ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn mixed_jsonb_domain_overloads_agree(pool: PgPool) -> anyhow::Result<()> {
    // The (text_match, jsonb), (jsonb, text_match) overloads cast the jsonb side
    // internally; they must agree with the fully-cast (text_match, text_match) form.
    // `aardvark` contains needle `aard` (shared ngrams).
    let hay = payload_for(&pool, "aardvark").await?;
    let aard = payload_for(&pool, "aard").await?;

    // $1 = haystack, $2 = needle. Each column leaves one operand as bare jsonb so a
    // DIFFERENT overload resolves; all must equal the all-domain baseline.
    let row: (bool, bool, bool, bool, bool) = sqlx::query_as(
        "SELECT
           eql_v3_internal.contains($1::jsonb::eql_v3.text_match, $2::jsonb::eql_v3.text_match), -- baseline (domain,domain)
           eql_v3_internal.contains($1::jsonb::eql_v3.text_match, $2::jsonb),                    -- (domain, jsonb)
           eql_v3_internal.contains($1::jsonb, $2::jsonb::eql_v3.text_match),                    -- (jsonb, domain)
           eql_v3_internal.contained_by($2::jsonb::eql_v3.text_match, $1::jsonb),                -- (domain, jsonb)
           eql_v3_internal.contained_by($2::jsonb, $1::jsonb::eql_v3.text_match)                 -- (jsonb, domain)
        ",
    )
    .bind(&hay)
    .bind(&aard)
    .fetch_one(&pool)
    .await?;

    let (baseline, contains_dom_json, contains_json_dom, cby_dom_json, cby_json_dom) = row;
    assert!(
        baseline,
        "baseline eql_v3_internal.contains('aardvark','aard') must be true"
    );
    assert_eq!(
        contains_dom_json, baseline,
        "contains(domain, jsonb) must agree"
    );
    assert_eq!(
        contains_json_dom, baseline,
        "contains(jsonb, domain) must agree"
    );
    assert_eq!(
        cby_dom_json, baseline,
        "contained_by(domain, jsonb) must agree (commutator of contains)"
    );
    assert_eq!(
        cby_json_dom, baseline,
        "contained_by(jsonb, domain) must agree"
    );
    Ok(())
}

#[sqlx::test]
async fn direct_functions_propagate_null(pool: PgPool) -> anyhow::Result<()> {
    // STRICT: a NULL operand short-circuits the body and returns NULL, not false
    // and not an error. Covers the by-name functions (the operator path is covered
    // by text_smoke::match_null_propagates) including a mixed (domain, jsonb) form.
    const BF: &str = r#"{"v":"2","i":{},"c":"x","bf":[1,2,3]}"#;

    // $1 NULL, $2 a real payload — and the reverse — across both functions, both
    // operand positions, and a mixed jsonb overload.
    for sql in [
        "SELECT eql_v3_internal.contains($1::jsonb::eql_v3.text_match, $2::jsonb::eql_v3.text_match)",
        "SELECT eql_v3_internal.contained_by($1::jsonb::eql_v3.text_match, $2::jsonb::eql_v3.text_match)",
        "SELECT eql_v3_internal.contains($1::jsonb::eql_v3.text_match, $2::jsonb)", // mixed (domain, jsonb)
    ] {
        eql_tests::assert_null(&pool, sql, &[None, Some(BF)]).await?;
        eql_tests::assert_null(&pool, sql, &[Some(BF), None]).await?;
    }
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn bloom_matches_where_like_would_not(pool: PgPool) -> anyhow::Result<()> {
    // Locks in WHY v3 dropped `LIKE` for bloom containment: the two are not the same
    // relation. The needle's ngrams are all present in the haystack, so bloom `@>`
    // matches — but the needle is NOT a contiguous substring, so `LIKE '%needle%'`
    // would NOT match. This false-positive / order-independence is the deterministic
    // divergence from LIKE (bloom has no false negatives, so the reverse can't happen).
    // The pair is engineered for exactly this property in TEXT_FIXTURES.
    let hay = payload_for(&pool, "qabcqbcaqcabqabd").await?;
    let needle = payload_for(&pool, "abcabd").await?;

    // 1. bloom DOES match.
    let bloom_hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::eql_v3.text_match) @> ($2::jsonb::eql_v3.text_match)",
    )
    .bind(&hay)
    .bind(&needle)
    .fetch_one(&pool)
    .await?;
    assert!(
        bloom_hit,
        "bloom @> must match: needle ngrams are a subset of the haystack's"
    );

    // 2. Pin the *structural* reason `@>` matched, independently of the domain
    //    operator. The domain `@>` is `match_term(a) @> match_term(b)`, i.e.
    //    smallint[] array containment on the extracted bloom terms — so asserting it
    //    again would just re-run the operator under test (circular). Instead assert
    //    needle-bf ⊆ haystack-bf directly on the raw stored `bf` arrays via NATIVE
    //    jsonb containment, which routes through neither `eql_v3.match_term` nor the
    //    domain operator. This localizes a future tokenizer change (e.g. honoring
    //    `include_original`, a different ngram width) to a precise "bf arrays no
    //    longer a subset" failure instead of an opaque `@>`-returned-false.
    let bf_subset: bool = sqlx::query_scalar("SELECT ($1::jsonb -> 'bf') @> ($2::jsonb -> 'bf')")
        .bind(&hay)
        .bind(&needle)
        .fetch_one(&pool)
        .await?;
    assert!(
        bf_subset,
        "needle's raw bf terms must be a subset of the haystack's (native jsonb containment)"
    );

    // 3. LIKE would NOT match the same plaintext pair — pin the divergence directly on
    //    the cleartext so the assertion documents the contract independently of any
    //    encrypted representation.
    let like_hit: bool = sqlx::query_scalar("SELECT $1 LIKE '%' || $2 || '%'")
        .bind("qabcqbcaqcabqabd")
        .bind("abcabd")
        .fetch_one(&pool)
        .await?;
    assert!(
        !like_hit,
        "LIKE must NOT match: the needle is not a contiguous substring of the haystack"
    );

    Ok(())
}
