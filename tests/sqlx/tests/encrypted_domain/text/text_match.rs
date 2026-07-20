//! Fuzzy-match coverage for `public.eql_v3_text_match` — separate from the
//! ordered matrix because `@@` is asymmetric/probabilistic, not a total order.
//! `@@` (`eql_v3.matches`) is bloom n-gram token matching, NOT containment
//!: `col @@ needle` reduces to `match_term(col) @> match_term(needle)`
//! on the extracted bloom terms. Asserts against the generated `eql_v3_text`
//! fixtures (which carry `bf`). The containment operators `@>`/`<@` now RAISE on
//! this domain (covered in `text_smoke`).
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
        "SELECT ($1::jsonb::public.eql_v3_text_match) @@ ($1::jsonb::public.eql_v3_text_match)",
    )
    .bind(&p)
    .fetch_one(&pool)
    .await?;
    assert!(hit, "a value's bloom filter must match itself");
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn haystack_matches_substring_needle(pool: PgPool) -> anyhow::Result<()> {
    let hay = payload_for(&pool, "aardvark").await?;
    let needle = payload_for(&pool, "aard").await?;
    let hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::public.eql_v3_text_match) @@ ($2::jsonb::public.eql_v3_text_match)",
    )
    .bind(&hay)
    .bind(&needle)
    .fetch_one(&pool)
    .await?;
    assert!(hit, "'aardvark' bloom must match 'aard' (shared ngrams)");
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
        "SELECT ($1::jsonb::public.eql_v3_text_match) @@ ($2::jsonb::public.eql_v3_text_match)",
    )
    .bind(&hay)
    .bind(&needle)
    .fetch_one(&pool)
    .await?;
    assert!(
        !hit,
        "'aard' must not match disjoint 'zzzz' (no shared ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn match_term_uses_functional_index(pool: PgPool) -> anyhow::Result<()> {
    // Explicit extractor form `match_term(col) @> match_term(needle)` — the raw
    // bloom array-containment the GIN index supports (unchanged by ; the
    // public `@@` operator reduces to exactly this). Forces `enable_seqscan = off`
    // so this is an index-VALIDITY proof on the small fixture (not a
    // cost-preference one), and uses the node-type-aware `assert_index_scan_uses`
    // rather than a plan substring match.
    let mut tx = pool.begin().await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "CREATE INDEX text_match_idx ON {TABLE} USING gin (eql_v3.match_term(payload::public.eql_v3_text_match))"
    ))
    .execute(&mut *tx)
    .await?;

    // Needle embedded via an uncorrelated subquery so the helper receives a
    // hardcoded query (it interpolates directly and takes no binds).
    let query = format!(
        "SELECT 1 FROM {TABLE} \
         WHERE eql_v3.match_term(payload::public.eql_v3_text_match) \
           @> eql_v3.match_term((SELECT payload::jsonb FROM {TABLE} WHERE plaintext = 'aard')::public.eql_v3_text_match)"
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

/// Companion to `match_term_uses_functional_index` proving the **bare operator**
/// form `WHERE col @@ needle` (not the explicit `match_term(col) @>
/// match_term(needle)`) reaches the GIN index — i.e. the generated `eql_v3.matches`
/// wrapper inlines through `match_term` to the native array-containment the index
/// supports. Forces `enable_seqscan = off` so this is an index-**validity** proof
/// on the small fixture, not a cost-preference one, and uses the node-type-aware
/// `assert_index_scan_uses` rather than a plan substring match.
#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn bare_matches_operator_uses_functional_index(pool: PgPool) -> anyhow::Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;
    sqlx::query(&format!(
        "CREATE INDEX text_match_idx ON {TABLE} USING gin (eql_v3.match_term(payload::public.eql_v3_text_match))"
    ))
    .execute(&mut *tx)
    .await?;

    // The needle is embedded via an uncorrelated subquery so the helper receives
    // a hardcoded query string (it interpolates directly and takes no binds).
    let query = format!(
        "SELECT 1 FROM {TABLE} \
         WHERE (payload::public.eql_v3_text_match) \
           @@ ((SELECT payload::jsonb FROM {TABLE} WHERE plaintext = 'aard')::public.eql_v3_text_match)"
    );
    eql_tests::matrix::assert_index_scan_uses(
        &mut *tx,
        &query,
        "text_match_idx",
        "bare `@@` operator on text_match must engage the functional GIN index",
    )
    .await?;
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn direct_matches_function_matches_operator(pool: PgPool) -> anyhow::Result<()> {
    // Exercises `eql_v3.matches(a, b)` by NAME (not the `@@` operator), and pins
    // that the function and the operator it backs agree. `aardvark` matches the
    // substring needle `aard` (shared ngrams); the disjoint `zzzz` does not.
    let hay = payload_for(&pool, "aardvark").await?;
    let aard = payload_for(&pool, "aard").await?;
    let zzzz = payload_for(&pool, "zzzz").await?;

    let (fn_hit, op_hit, fn_miss): (bool, bool, bool) = sqlx::query_as(
        "SELECT eql_v3.matches($1::jsonb::public.eql_v3_text_match, $2::jsonb::public.eql_v3_text_match),
                ($1::jsonb::public.eql_v3_text_match) @@ ($2::jsonb::public.eql_v3_text_match),
                eql_v3.matches($1::jsonb::public.eql_v3_text_match, $3::jsonb::public.eql_v3_text_match)",
    )
    .bind(&hay)
    .bind(&aard)
    .bind(&zzzz)
    .fetch_one(&pool)
    .await?;

    assert!(fn_hit, "eql_v3.matches('aardvark','aard') must be true");
    assert_eq!(
        fn_hit, op_hit,
        "eql_v3.matches must agree with the @@ operator"
    );
    assert!(
        !fn_miss,
        "eql_v3.matches('aardvark','zzzz') must be false (disjoint ngrams)"
    );
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn mixed_jsonb_domain_overloads_agree(pool: PgPool) -> anyhow::Result<()> {
    // The (text_match, jsonb), (jsonb, text_match) overloads cast the jsonb side
    // internally; they must agree with the fully-cast (text_match, text_match) form.
    // `aardvark` matches needle `aard` (shared ngrams).
    let hay = payload_for(&pool, "aardvark").await?;
    let aard = payload_for(&pool, "aard").await?;

    // $1 = haystack, $2 = needle. Each column leaves one operand as bare jsonb so a
    // DIFFERENT overload resolves; all must equal the all-domain baseline.
    let row: (bool, bool, bool) = sqlx::query_as(
        "SELECT
           eql_v3.matches($1::jsonb::public.eql_v3_text_match, $2::jsonb::public.eql_v3_text_match), -- baseline (domain,domain)
           eql_v3.matches($1::jsonb::public.eql_v3_text_match, $2::jsonb),                    -- (domain, jsonb)
           eql_v3.matches($1::jsonb, $2::jsonb::public.eql_v3_text_match)                     -- (jsonb, domain)
        ",
    )
    .bind(&hay)
    .bind(&aard)
    .fetch_one(&pool)
    .await?;

    let (baseline, matches_dom_json, matches_json_dom) = row;
    assert!(
        baseline,
        "baseline eql_v3.matches('aardvark','aard') must be true"
    );
    assert_eq!(
        matches_dom_json, baseline,
        "matches(domain, jsonb) must agree"
    );
    assert_eq!(
        matches_json_dom, baseline,
        "matches(jsonb, domain) must agree"
    );
    Ok(())
}

#[sqlx::test]
async fn direct_functions_propagate_null(pool: PgPool) -> anyhow::Result<()> {
    // STRICT: a NULL operand short-circuits the body and returns NULL, not false
    // and not an error. Covers the by-name function (the operator path is covered
    // by text_smoke::match_null_propagates) including a mixed (domain, jsonb) form.
    const BF: &str = r#"{"v":"3","i":{},"c":"x","bf":[1,2,3]}"#;

    // $1 NULL, $2 a real payload — and the reverse — in both operand positions,
    // and a mixed jsonb overload.
    for sql in [
        "SELECT eql_v3.matches($1::jsonb::public.eql_v3_text_match, $2::jsonb::public.eql_v3_text_match)",
        "SELECT eql_v3.matches($1::jsonb::public.eql_v3_text_match, $2::jsonb)", // mixed (domain, jsonb)
    ] {
        eql_tests::assert_null(&pool, sql, &[None, Some(BF)]).await?;
        eql_tests::assert_null(&pool, sql, &[Some(BF), None]).await?;
    }
    Ok(())
}

#[sqlx::test(fixtures(path = "../../../fixtures", scripts("eql_v3_text")))]
async fn bloom_matches_where_like_would_not(pool: PgPool) -> anyhow::Result<()> {
    // Locks in WHY v3 dropped `LIKE` for bloom matching: the two are not the same
    // relation. The needle's ngrams are all present in the haystack, so bloom `@@`
    // matches — but the needle is NOT a contiguous substring, so `LIKE '%needle%'`
    // would NOT match. This false-positive / order-independence is the deterministic
    // divergence from LIKE (bloom has no false negatives, so the reverse can't happen).
    // The pair is engineered for exactly this property in TEXT_FIXTURES.
    let hay = payload_for(&pool, "qabcqbcaqcabqabd").await?;
    let needle = payload_for(&pool, "abcabd").await?;

    // 1. bloom DOES match.
    let bloom_hit: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::public.eql_v3_text_match) @@ ($2::jsonb::public.eql_v3_text_match)",
    )
    .bind(&hay)
    .bind(&needle)
    .fetch_one(&pool)
    .await?;
    assert!(
        bloom_hit,
        "bloom @@ must match: needle ngrams are a subset of the haystack's"
    );

    // 2. Pin the *structural* reason `@@` matched, independently of the domain
    //    operator. The domain `@@` is `match_term(a) @> match_term(b)`, i.e.
    //    smallint[] array containment on the extracted bloom terms — so asserting it
    //    again would just re-run the operator under test (circular). Instead assert
    //    needle-bf ⊆ haystack-bf directly on the raw stored `bf` arrays via NATIVE
    //    jsonb containment, which routes through neither `eql_v3.match_term` nor the
    //    domain operator. This localizes a future tokenizer change (e.g. honoring
    //    `include_original`, a different ngram width) to a precise "bf arrays no
    //    longer a subset" failure instead of an opaque `@@`-returned-false.
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
