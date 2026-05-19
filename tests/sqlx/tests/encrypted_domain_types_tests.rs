use anyhow::Result;
use sqlx::PgPool;

fn hmac_payload(ciphertext: &str, hm: &str) -> String {
    format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"col"}},"c":"{}","hm":"{}"}}"#,
        ciphertext, hm
    )
}

#[sqlx::test]
async fn encrypted_domain_types_exist_and_accept_jsonb(pool: PgPool) -> Result<()> {
    let text_payload = hmac_payload("alice-ciphertext", "hm-alice");
    let int_payload = hmac_payload("42-ciphertext", "hm-42");
    let json_payload = hmac_payload("json-ciphertext", "hm-json");

    let mut tx = pool.begin().await?;

    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_smoke (
            text_col encrypted_text,
            int_col eql_v2_int4,
            json_col encrypted_jsonb
        )
        "#,
    )
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        "INSERT INTO typed_smoke(text_col, int_col, json_col)
         VALUES ($1::jsonb::encrypted_text, $2::jsonb::eql_v2_int4, $3::jsonb::encrypted_jsonb)",
    )
    .bind(&text_payload)
    .bind(&int_payload)
    .bind(&json_payload)
    .execute(&mut *tx)
    .await?;

    let count: i64 = sqlx::query_scalar("SELECT count(*) FROM typed_smoke")
        .fetch_one(&mut *tx)
        .await?;

    assert_eq!(count, 1);
    Ok(())
}

fn text_payload(ciphertext: &str, hm: &str, bf: &[i16]) -> String {
    let bf_json = bf
        .iter()
        .map(|n| n.to_string())
        .collect::<Vec<_>>()
        .join(",");
    format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"text_col"}},"c":"{}","hm":"{}","bf":[{}]}}"#,
        ciphertext, hm, bf_json
    )
}

#[sqlx::test]
async fn encrypted_text_equality_uses_hmac_index(pool: PgPool) -> Result<()> {
    let needle = text_payload("needle-ciphertext", "hm-needle", &[1, 2, 3]);
    let other = text_payload("other-ciphertext", "hm-other", &[4, 5, 6]);
    let query = text_payload("query-ciphertext", "hm-needle", &[1, 2, 3]);

    let mut tx = pool.begin().await?;

    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_text_index (
            id integer GENERATED ALWAYS AS IDENTITY,
            value encrypted_text
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut *tx)
    .await?;

    for payload in [&needle, &other] {
        sqlx::query("INSERT INTO typed_text_index(value) VALUES ($1::jsonb::encrypted_text)")
            .bind(payload)
            .execute(&mut *tx)
            .await?;
    }

    sqlx::query(
        "CREATE INDEX typed_text_hmac_idx ON typed_text_index ((eql_v2.hmac_256(value::jsonb)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_text_index")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    // Domain-on-both-sides
    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM typed_text_index WHERE value = $1::jsonb::encrypted_text",
    )
    .bind(&query)
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(count, 1);

    // Cross-type: param bound as jsonb on the RHS (no explicit ::encrypted_text cast)
    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM typed_text_index WHERE value = $1::jsonb")
            .bind(&query)
            .fetch_one(&mut *tx)
            .await?;
    assert_eq!(count, 1);

    // Cross-type: jsonb on the LHS
    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM typed_text_index WHERE $1::jsonb = value")
            .bind(&query)
            .fetch_one(&mut *tx)
            .await?;
    assert_eq!(count, 1);

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM typed_text_index WHERE value = '{}'::jsonb",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_text_hmac_idx"),
        "expected hmac functional index for cross-type predicate; plan:\n{plan}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_text_like_uses_bloom_index(pool: PgPool) -> Result<()> {
    let haystack = text_payload("haystack-ciphertext", "hm-haystack", &[1, 2, 3, 4]);
    let other = text_payload("other-ciphertext", "hm-other", &[8, 9]);
    let needle = text_payload("needle-ciphertext", "hm-needle", &[2, 3]);

    let mut tx = pool.begin().await?;

    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_text_like_index (
            id integer GENERATED ALWAYS AS IDENTITY,
            value encrypted_text
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut *tx)
    .await?;

    for payload in [&haystack, &other] {
        sqlx::query("INSERT INTO typed_text_like_index(value) VALUES ($1::jsonb::encrypted_text)")
            .bind(payload)
            .execute(&mut *tx)
            .await?;
    }

    sqlx::query(
        "CREATE INDEX typed_text_bloom_idx ON typed_text_like_index USING gin ((eql_v2.bloom_filter(value::jsonb)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_text_like_index")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    // Same-domain ~~
    let count: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM typed_text_like_index WHERE value ~~ $1::jsonb::encrypted_text",
    )
    .bind(&needle)
    .fetch_one(&mut *tx)
    .await?;
    assert_eq!(count, 1);

    // Cross-type: param bound as jsonb on RHS
    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM typed_text_like_index WHERE value ~~ $1::jsonb")
            .bind(&needle)
            .fetch_one(&mut *tx)
            .await?;
    assert_eq!(count, 1);

    // Reverse shape: jsonb LHS, encrypted_text RHS. Exercises the
    // (jsonb, encrypted_text) ~~ operator (and ~~* via the same function).
    // Semantics: bloom_filter(lhs) @> bloom_filter(rhs). Using a superset
    // bloom filter on the LHS so the predicate matches the haystack row.
    let superset = text_payload("superset-ciphertext", "hm-superset", &[1, 2, 3, 4, 5, 6]);
    let count: i64 =
        sqlx::query_scalar("SELECT count(*) FROM typed_text_like_index WHERE $1::jsonb ~~ value")
            .bind(&superset)
            .fetch_one(&mut *tx)
            .await?;
    assert_eq!(count, 1, "reverse ~~ should match the haystack row whose bloom filter is a subset of the superset query");

    for op in ["~~", "~~*"] {
        let resolved: bool =
            sqlx::query_scalar(&format!("SELECT $1::jsonb {op} $2::jsonb::encrypted_text"))
                .bind(&superset)
                .bind(&needle)
                .fetch_one(&mut *tx)
                .await?;
        assert!(resolved, "reverse ({op}) bloom containment expected true");
    }

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM typed_text_like_index WHERE value ~~ '{}'::jsonb",
        needle
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_text_bloom_idx"),
        "expected bloom functional index for cross-type LIKE; plan:\n{plan}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_text_unsupported_operators_are_blocked(pool: PgPool) -> Result<()> {
    let a = text_payload("a-ciphertext", "hm-a", &[1]);
    let b = text_payload("b-ciphertext", "hm-b", &[2]);

    // Boolean-returning unsupported operators in all three type-pair shapes.
    let bool_ops = ["<", "<=", ">", ">=", "@>", "<@"];
    let shapes = [
        ("$1::jsonb::encrypted_text", "$2::jsonb::encrypted_text"),
        ("$1::jsonb::encrypted_text", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::encrypted_text"),
    ];

    for op in bool_ops {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query_scalar::<_, bool>(&sql)
                .bind(&a)
                .bind(&b)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("encrypted_text {op} should be blocked: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for encrypted_text");
            assert!(err.contains(&expected), "unexpected error for {sql}: {err}");
        }
    }

    // JSONB path operators with text RHS.
    for op in ["->", "->>"] {
        for lhs in ["$1::jsonb::encrypted_text", "$1::jsonb"] {
            let sql = if lhs == "$1::jsonb" {
                // For the (jsonb, encrypted_text) shape the RHS must also be domain typed.
                format!("SELECT {lhs} {op} $2::jsonb::encrypted_text")
            } else {
                format!("SELECT {lhs} {op} 'field'::text")
            };
            let err = sqlx::query(&sql)
                .bind(&a)
                .bind(&b)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("encrypted_text {op} should be blocked: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for encrypted_text");
            assert!(err.contains(&expected), "unexpected error for {sql}: {err}");
        }
    }

    // Integer-RHS path operators must also be blocked so encrypted_text -> 0
    // does not fall back to native jsonb -> integer.
    for op in ["->", "->>"] {
        let sql = format!("SELECT $1::jsonb::encrypted_text {op} 0::integer");
        let err = sqlx::query(&sql)
            .bind(&a)
            .fetch_one(&pool)
            .await
            .expect_err(&format!("encrypted_text {op} integer should be blocked"))
            .to_string();
        let expected = format!("operator {op} is not supported for encrypted_text");
        assert!(err.contains(&expected), "unexpected error for {sql}: {err}");
    }

    Ok(())
}

fn jsonb_payload(ciphertext: &str, hm: &str, selector: &str, b3: &str) -> String {
    format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"json_col"}},"c":"{}","hm":"{}","sv":[{{"s":"{}","b3":"{}","c":"{}-leaf"}}]}}"#,
        ciphertext, hm, selector, b3, ciphertext
    )
}

#[sqlx::test]
async fn encrypted_jsonb_equality_and_inequality_use_hmac_index(pool: PgPool) -> Result<()> {
    let document = jsonb_payload("doc-ciphertext", "hm-doc", "selector-email", "b3-alice");
    let other = jsonb_payload("other-ciphertext", "hm-other", "selector-email", "b3-bob");
    let query = jsonb_payload("query-ciphertext", "hm-doc", "selector-email", "b3-alice");

    let mut tx = pool.begin().await?;

    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_jsonb_eq_index (
            id integer GENERATED ALWAYS AS IDENTITY,
            value encrypted_jsonb
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut *tx)
    .await?;

    for payload in [&document, &other] {
        sqlx::query("INSERT INTO typed_jsonb_eq_index(value) VALUES ($1::jsonb::encrypted_jsonb)")
            .bind(payload)
            .execute(&mut *tx)
            .await?;
    }

    sqlx::query(
        // The encrypted_jsonb = / <> wrappers normalise both operands through
        // eql_v2.encrypted_jsonb_path_value before hashing. The function
        // returns encrypted_jsonb; the wrapper casts it back to jsonb for
        // hmac_256. The functional index must mirror that exact expression
        // shape so the planner can match the inlined predicate.
        "CREATE INDEX typed_jsonb_hmac_idx ON typed_jsonb_eq_index \
         ((eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(value::jsonb))::jsonb)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_jsonb_eq_index")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    for rhs in ["$1::jsonb::encrypted_jsonb", "$1::jsonb"] {
        let ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT id FROM typed_jsonb_eq_index WHERE value = {rhs} ORDER BY id"
        ))
        .bind(&query)
        .fetch_all(&mut *tx)
        .await?;
        assert_eq!(ids, vec![1], "forward = with rhs {rhs}");
    }
    let ids: Vec<i32> = sqlx::query_scalar(
        "SELECT id FROM typed_jsonb_eq_index WHERE $1::jsonb = value ORDER BY id",
    )
    .bind(&query)
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(ids, vec![1], "reverse = with jsonb LHS");

    for rhs in ["$1::jsonb::encrypted_jsonb", "$1::jsonb"] {
        let ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT id FROM typed_jsonb_eq_index WHERE value <> {rhs} ORDER BY id"
        ))
        .bind(&query)
        .fetch_all(&mut *tx)
        .await?;
        assert_eq!(ids, vec![2], "forward <> with rhs {rhs}");
    }
    let ids: Vec<i32> = sqlx::query_scalar(
        "SELECT id FROM typed_jsonb_eq_index WHERE $1::jsonb <> value ORDER BY id",
    )
    .bind(&query)
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(ids, vec![2], "reverse <> with jsonb LHS");

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM typed_jsonb_eq_index WHERE value = '{}'::jsonb",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_jsonb_hmac_idx"),
        "expected jsonb hmac functional index for cross-type predicate; plan:\n{plan}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_jsonb_containment_uses_gin_index(pool: PgPool) -> Result<()> {
    let document = jsonb_payload("doc-ciphertext", "hm-doc", "selector-email", "b3-alice");
    let other = jsonb_payload("other-ciphertext", "hm-other", "selector-email", "b3-bob");
    let query = jsonb_payload("query-ciphertext", "hm-query", "selector-email", "b3-alice");

    let mut tx = pool.begin().await?;

    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_jsonb_index (
            id integer GENERATED ALWAYS AS IDENTITY,
            value encrypted_jsonb
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut *tx)
    .await?;

    for payload in [&document, &other] {
        sqlx::query("INSERT INTO typed_jsonb_index(value) VALUES ($1::jsonb::encrypted_jsonb)")
            .bind(payload)
            .execute(&mut *tx)
            .await?;
    }

    sqlx::query(
        "CREATE INDEX typed_jsonb_array_idx ON typed_jsonb_index USING gin ((eql_v2.encrypted_jsonb_array(value)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_jsonb_index")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let universe = format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"json_col"}},"c":"universe","hm":"hm-u","sv":[{{"s":"selector-email","b3":"b3-alice","c":"doc-ciphertext-leaf"}},{{"s":"selector-email","b3":"b3-bob","c":"other-ciphertext-leaf"}}]}}"#
    );

    for rhs in ["$1::jsonb::encrypted_jsonb", "$1::jsonb"] {
        let ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT id FROM typed_jsonb_index WHERE value @> {rhs} ORDER BY id"
        ))
        .bind(&query)
        .fetch_all(&mut *tx)
        .await?;
        assert_eq!(ids, vec![1], "forward @> with rhs {rhs}");
    }

    let ids: Vec<i32> =
        sqlx::query_scalar("SELECT id FROM typed_jsonb_index WHERE $1::jsonb @> value ORDER BY id")
            .bind(&universe)
            .fetch_all(&mut *tx)
            .await?;
    assert_eq!(ids, vec![1, 2], "reverse @> with jsonb LHS (universe)");

    for rhs in ["$1::jsonb::encrypted_jsonb", "$1::jsonb"] {
        let ids: Vec<i32> = sqlx::query_scalar(&format!(
            "SELECT id FROM typed_jsonb_index WHERE value <@ {rhs} ORDER BY id"
        ))
        .bind(&universe)
        .fetch_all(&mut *tx)
        .await?;
        assert_eq!(ids, vec![1, 2], "forward <@ with rhs {rhs}");
    }

    let ids: Vec<i32> =
        sqlx::query_scalar("SELECT id FROM typed_jsonb_index WHERE $1::jsonb <@ value ORDER BY id")
            .bind(&universe)
            .fetch_all(&mut *tx)
            .await?;
    assert_eq!(
        ids,
        Vec::<i32>::new(),
        "reverse <@ with jsonb LHS (universe)"
    );

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN SELECT * FROM typed_jsonb_index WHERE value @> '{}'::jsonb",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_jsonb_array_idx"),
        "expected jsonb array functional index for cross-type @>; plan:\n{plan}"
    );

    tx.commit().await?;
    Ok(())
}

#[sqlx::test]
async fn encrypted_jsonb_path_operators_resolve(pool: PgPool) -> Result<()> {
    let document = jsonb_payload("doc-ciphertext", "hm-doc", "selector-email", "b3-alice");

    // Text selector via -> (returns encrypted_jsonb)
    let leaf_ciphertext: String = sqlx::query_scalar(
        "SELECT (($1::jsonb::encrypted_jsonb -> 'selector-email'::text)::jsonb)->>'c'",
    )
    .bind(&document)
    .fetch_one(&pool)
    .await?;
    assert_eq!(leaf_ciphertext, "doc-ciphertext-leaf");

    // Text selector via ->>. Contract: returns JSONB-as-text representation
    // of the encrypted child — must be valid JSON whose top-level `c` field
    // is the leaf ciphertext. A loose substring match (`contains`) would
    // also pass for the legacy composite-text shape and miss a regression
    // back to inheriting the eql_v2."->>" cast.
    let text_result: String =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb ->> 'selector-email'::text")
            .bind(&document)
            .fetch_one(&pool)
            .await?;
    let parsed: serde_json::Value = serde_json::from_str(&text_result)
        .expect("->> text result must be valid JSON per contract");
    assert_eq!(
        parsed.get("c").and_then(|v| v.as_str()),
        Some("doc-ciphertext-leaf"),
        "expected ->> text result to be JSONB with c=doc-ciphertext-leaf; got {text_result}"
    );

    // Integer selector via -> (array-element access). Build a payload with
    // `"a": true` (required by eql_v2.is_ste_vec_array) and a two-element
    // ste-vec array, so index 0 picks the first.
    let array_doc = format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"json_col"}},"c":"array-ciphertext","hm":"hm-arr","a":true,"sv":[{{"s":"item-0","b3":"b3-0","c":"first-leaf"}},{{"s":"item-1","b3":"b3-1","c":"second-leaf"}}]}}"#
    );

    let first_leaf: String =
        sqlx::query_scalar("SELECT (($1::jsonb::encrypted_jsonb -> 0::integer)::jsonb)->>'c'")
            .bind(&array_doc)
            .fetch_one(&pool)
            .await?;
    assert_eq!(first_leaf, "first-leaf");

    // Integer selector via ->>. Contract: the wrapper returns the
    // JSONB-as-text representation of the encrypted child at the array
    // index. The contract requires the returned text to be valid JSON
    // whose top-level `c` field is the leaf ciphertext — assert that
    // explicitly rather than a loose substring match.
    let second_text: String =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb ->> 1::integer")
            .bind(&array_doc)
            .fetch_one(&pool)
            .await?;
    let parsed: serde_json::Value = serde_json::from_str(&second_text)
        .expect("->> integer result must be valid JSON per contract");
    assert_eq!(
        parsed.get("c").and_then(|v| v.as_str()),
        Some("second-leaf"),
        "expected ->> integer result to be JSONB with c=second-leaf; got {second_text}"
    );

    Ok(())
}

#[sqlx::test]
async fn encrypted_jsonb_path_results_support_equality_and_inequality(pool: PgPool) -> Result<()> {
    let document = jsonb_payload("doc-ciphertext", "hm-doc", "selector-email", "b3-alice");
    let matching_leaf = r#"{"s":"selector-email","b3":"b3-alice","c":"doc-ciphertext-leaf"}"#;
    let other_leaf = r#"{"s":"selector-email","b3":"b3-bob","c":"other-ciphertext-leaf"}"#;

    let text_eq: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::encrypted_jsonb -> 'selector-email'::text) = $2::jsonb::encrypted_jsonb",
    )
    .bind(&document)
    .bind(matching_leaf)
    .fetch_one(&pool)
    .await?;
    assert!(
        text_eq,
        "text path result should compare equal to matching leaf"
    );

    let text_neq: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::encrypted_jsonb -> 'selector-email'::text) <> $2::jsonb::encrypted_jsonb",
    )
    .bind(&document)
    .bind(other_leaf)
    .fetch_one(&pool)
    .await?;
    assert!(
        text_neq,
        "text path result should compare unequal to non-matching leaf"
    );

    let array_doc = format!(
        r#"{{"v":2,"i":{{"t":"typed","c":"json_col"}},"c":"array-ciphertext","hm":"hm-arr","a":true,"sv":[{{"s":"item-0","b3":"b3-0","c":"first-leaf"}},{{"s":"item-1","b3":"b3-1","c":"second-leaf"}}]}}"#
    );

    let int_eq: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::encrypted_jsonb -> 0::integer) = $2::jsonb::encrypted_jsonb",
    )
    .bind(&array_doc)
    .bind(r#"{"s":"item-0","b3":"b3-0","c":"first-leaf"}"#)
    .fetch_one(&pool)
    .await?;
    assert!(
        int_eq,
        "integer path result should compare equal to matching leaf"
    );

    let int_neq: bool = sqlx::query_scalar(
        "SELECT ($1::jsonb::encrypted_jsonb -> 1::integer) <> $2::jsonb::encrypted_jsonb",
    )
    .bind(&array_doc)
    .bind(r#"{"s":"item-0","b3":"b3-0","c":"first-leaf"}"#)
    .fetch_one(&pool)
    .await?;
    assert!(
        int_neq,
        "integer path result should compare unequal to non-matching leaf"
    );

    Ok(())
}

#[sqlx::test]
async fn encrypted_jsonb_eq_normalises_both_operands(pool: PgPool) -> Result<()> {
    // Regression: both operands of `=` / `<>` on encrypted_jsonb must thread
    // through encrypted_jsonb_path_value. If only one side is normalised, a
    // leaf-shaped payload (no top-level `hm`) on the un-normalised side
    // makes hmac_256 raise, and the predicate becomes order-dependent.
    let leaf_a = r#"{"s":"selector-email","b3":"b3-alice","c":"a-ciphertext"}"#;
    let leaf_a_again = r#"{"s":"selector-email","b3":"b3-alice","c":"a-ciphertext-other"}"#;
    let leaf_b = r#"{"s":"selector-email","b3":"b3-bob","c":"b-ciphertext"}"#;

    // (domain, domain) — both leaves carry no top-level `hm`; previous bug
    // raised because the LHS skipped path_value.
    let eq: bool =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb = $2::jsonb::encrypted_jsonb")
            .bind(leaf_a)
            .bind(leaf_a_again)
            .fetch_one(&pool)
            .await?;
    assert!(
        eq,
        "(domain, domain) leaf=leaf same plaintext must be equal"
    );

    let neq: bool =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb <> $2::jsonb::encrypted_jsonb")
            .bind(leaf_a)
            .bind(leaf_b)
            .fetch_one(&pool)
            .await?;
    assert!(neq, "(domain, domain) leaf<>leaf different plaintext");

    // (domain, jsonb) — RHS bound as plain jsonb.
    let eq: bool = sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb = $2::jsonb")
        .bind(leaf_a)
        .bind(leaf_a_again)
        .fetch_one(&pool)
        .await?;
    assert!(eq, "(domain, jsonb) leaf=leaf");

    // (jsonb, domain) — LHS bound as plain jsonb. Was the order-sensitive case.
    let eq: bool = sqlx::query_scalar("SELECT $1::jsonb = $2::jsonb::encrypted_jsonb")
        .bind(leaf_a)
        .bind(leaf_a_again)
        .fetch_one(&pool)
        .await?;
    assert!(eq, "(jsonb, domain) leaf=leaf");

    Ok(())
}

#[sqlx::test]
async fn encrypted_jsonb_eq_handles_numeric_leaves_via_ocv(pool: PgPool) -> Result<()> {
    // Regression: numeric / float leaves carry deterministic ORE/OPE bytes
    // in `ocv` (or `ocf`) — they don't have a `b3` (which is the text-leaf
    // plaintext blake3). The previous COALESCE chain skipped ocv/ocf and
    // fell straight to `c` (random ciphertext), making equal numeric values
    // hash differently. Build two leaves with the same `ocv` but different
    // `c` and assert they compare equal.
    let leaf_score_10_v1 = r#"{"s":"selector-score","ocv":"deadbeef0000","c":"score-ct-v1"}"#;
    let leaf_score_10_v2 = r#"{"s":"selector-score","ocv":"deadbeef0000","c":"score-ct-v2"}"#;
    let leaf_score_20 = r#"{"s":"selector-score","ocv":"feedface0000","c":"score-ct-v3"}"#;

    let eq: bool =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb = $2::jsonb::encrypted_jsonb")
            .bind(leaf_score_10_v1)
            .bind(leaf_score_10_v2)
            .fetch_one(&pool)
            .await?;
    assert!(eq, "two leaves with the same ocv must compare equal");

    let neq: bool =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb <> $2::jsonb::encrypted_jsonb")
            .bind(leaf_score_10_v1)
            .bind(leaf_score_20)
            .fetch_one(&pool)
            .await?;
    assert!(neq, "leaves with different ocv must compare unequal");

    // Same shape but with `ocf` instead of `ocv` — the other deterministic
    // scalar term. Path_value's COALESCE chain should pick it up.
    let leaf_ocf_a = r#"{"s":"selector-score","ocf":"cafef00d","c":"score-ocf-a"}"#;
    let leaf_ocf_a_again = r#"{"s":"selector-score","ocf":"cafef00d","c":"score-ocf-b"}"#;
    let leaf_ocf_b = r#"{"s":"selector-score","ocf":"baadcafe","c":"score-ocf-c"}"#;

    let eq: bool =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb = $2::jsonb::encrypted_jsonb")
            .bind(leaf_ocf_a)
            .bind(leaf_ocf_a_again)
            .fetch_one(&pool)
            .await?;
    assert!(eq, "two leaves with the same ocf must compare equal");

    let neq: bool =
        sqlx::query_scalar("SELECT $1::jsonb::encrypted_jsonb = $2::jsonb::encrypted_jsonb")
            .bind(leaf_ocf_a)
            .bind(leaf_ocf_b)
            .fetch_one(&pool)
            .await?;
    assert!(!neq, "leaves with different ocf must not compare equal");

    Ok(())
}

#[sqlx::test]
async fn encrypted_jsonb_unsupported_operators_are_blocked(pool: PgPool) -> Result<()> {
    let a = jsonb_payload("a-ciphertext", "hm-a", "selector", "b3-a");
    let b = jsonb_payload("b-ciphertext", "hm-b", "selector", "b3-b");

    let bool_ops = ["<", "<=", ">", ">=", "~~", "~~*"];
    let shapes = [
        ("$1::jsonb::encrypted_jsonb", "$2::jsonb::encrypted_jsonb"),
        ("$1::jsonb::encrypted_jsonb", "$2::jsonb"),
        ("$1::jsonb", "$2::jsonb::encrypted_jsonb"),
    ];

    for op in bool_ops {
        for (lhs, rhs) in shapes {
            let sql = format!("SELECT {lhs} {op} {rhs}");
            let err = sqlx::query_scalar::<_, bool>(&sql)
                .bind(&a)
                .bind(&b)
                .fetch_one(&pool)
                .await
                .expect_err(&format!("encrypted_jsonb {op} should be blocked: {sql}"))
                .to_string();
            let expected = format!("operator {op} is not supported for encrypted_jsonb");
            assert!(err.contains(&expected), "unexpected error for {sql}: {err}");
        }
    }

    Ok(())
}

const INLINEABLE_DOMAIN_FUNCTIONS: &[&str] = &[
    "encrypted_text_eq",
    "encrypted_text_neq",
    "encrypted_text_like",
    // eql_v2_int4 variant family
    "eql_v2_int4_eq",
    "eql_v2_int4_neq",
    "eql_v2_int4_lt",
    "eql_v2_int4_lte",
    "eql_v2_int4_gt",
    "eql_v2_int4_gte",
    "eql_v2_int4_eq_eq",
    "eql_v2_int4_eq_neq",
    "eql_v2_int4_ord_ore_eq",
    "eql_v2_int4_ord_ore_neq",
    "eql_v2_int4_ord_ore_lt",
    "eql_v2_int4_ord_ore_lte",
    "eql_v2_int4_ord_ore_gt",
    "eql_v2_int4_ord_ore_gte",
    "eql_v2_int4_ord_ope_eq",
    "eql_v2_int4_ord_ope_neq",
    "eql_v2_int4_ord_ope_lt",
    "eql_v2_int4_ord_ope_lte",
    "eql_v2_int4_ord_ope_gt",
    "eql_v2_int4_ord_ope_gte",
    "eql_v2_int4_ord_ope_ope_key",
    "encrypted_jsonb_array",
    "encrypted_jsonb_eq",
    "encrypted_jsonb_neq",
    "encrypted_jsonb_contains",
    "encrypted_jsonb_contained_by",
    "encrypted_jsonb_arrow",
    "encrypted_jsonb_arrow_text",
    "encrypted_jsonb_arrow_int",
    "encrypted_jsonb_arrow_text_int",
];

#[sqlx::test]
async fn supported_domain_operator_functions_are_inlineable_sql(pool: PgPool) -> Result<()> {
    let expected: Vec<String> = INLINEABLE_DOMAIN_FUNCTIONS
        .iter()
        .map(|s| s.to_string())
        .collect();

    let rows: Vec<(String, String, String, Option<String>)> = sqlx::query_as(
        r#"
        SELECT p.proname, l.lanname, p.provolatile::text, p.proconfig::text
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_language l ON l.oid = p.prolang
        WHERE n.nspname = 'eql_v2'
          AND p.proname = ANY($1::text[])
        ORDER BY p.proname
        "#,
    )
    .bind(&expected)
    .fetch_all(&pool)
    .await?;

    let found: std::collections::HashSet<&str> =
        rows.iter().map(|(n, _, _, _)| n.as_str()).collect();
    let missing: Vec<&&str> = INLINEABLE_DOMAIN_FUNCTIONS
        .iter()
        .filter(|n| !found.contains(*n))
        .collect();
    assert!(missing.is_empty(), "missing functions: {missing:?}");

    for (name, language, volatility, config) in rows {
        assert_eq!(language, "sql", "{name} must be LANGUAGE sql");
        assert_eq!(volatility, "i", "{name} must be IMMUTABLE");
        assert_eq!(config, None, "{name} must not set search_path/proconfig");
    }

    Ok(())
}

#[sqlx::test]
async fn encrypted_text_equality_with_prepared_statement_uses_hmac_index(
    pool: PgPool,
) -> Result<()> {
    let needle = text_payload("needle-ciphertext", "hm-needle", &[1, 2, 3]);
    let other = text_payload("other-ciphertext", "hm-other", &[4, 5, 6]);
    let query = text_payload("query-ciphertext", "hm-needle", &[1, 2, 3]);

    let mut tx = pool.begin().await?;

    sqlx::query(
        r#"
        CREATE TEMP TABLE typed_text_prepared_index (
            id integer GENERATED ALWAYS AS IDENTITY,
            value encrypted_text
        ) ON COMMIT DROP;
        "#,
    )
    .execute(&mut *tx)
    .await?;

    for payload in [&needle, &other] {
        sqlx::query(
            "INSERT INTO typed_text_prepared_index(value) VALUES ($1::jsonb::encrypted_text)",
        )
        .bind(payload)
        .execute(&mut *tx)
        .await?;
    }

    sqlx::query(
        "CREATE INDEX typed_text_prepared_hmac_idx ON typed_text_prepared_index ((eql_v2.hmac_256(value::jsonb)))",
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query("ANALYZE typed_text_prepared_index")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    // Form A — prepared parameter type IS the domain. This is the spec's
    // explicit acceptance criterion. The argument literal in EXECUTE is
    // cast (jsonb -> encrypted_text) at execute time; the prepared plan
    // sees $1 as encrypted_text and resolves to the (domain, domain)
    // operator. Bind via SQLx also works because the protocol-level
    // parameter type is encrypted_text in the prepared plan and the
    // domain-over-jsonb cast accepts the binary jsonb payload.
    sqlx::query(
        "PREPARE typed_text_lookup_dom_param(encrypted_text) AS \
         SELECT id FROM typed_text_prepared_index WHERE value = $1",
    )
    .execute(&mut *tx)
    .await?;

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN EXECUTE typed_text_lookup_dom_param('{}'::jsonb::encrypted_text)",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_text_prepared_hmac_idx"),
        "Form A: expected domain-typed prepared parameter to use hmac index; plan:\n{plan}"
    );

    // EXECUTE with inline literal — PostgreSQL's EXECUTE statement does not
    // accept extended-query-protocol parameters from SQLx's prepared layer,
    // so the value is inlined as a SQL literal instead of bound.
    let ids: Vec<i32> = sqlx::query_scalar(&format!(
        "EXECUTE typed_text_lookup_dom_param('{}'::jsonb::encrypted_text)",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(ids, vec![1], "Form A inline execute");

    // Form B — jsonb parameter cast to domain in the WHERE clause.
    sqlx::query(
        "PREPARE typed_text_lookup_body_cast(jsonb) AS \
         SELECT id FROM typed_text_prepared_index WHERE value = $1::encrypted_text",
    )
    .execute(&mut *tx)
    .await?;

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN EXECUTE typed_text_lookup_body_cast('{}'::jsonb)",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_text_prepared_hmac_idx"),
        "Form B: expected body-cast prepared plan to use hmac index; plan:\n{plan}"
    );

    // Form C — no cast, cross-type (encrypted_text, jsonb) operator.
    sqlx::query(
        "PREPARE typed_text_lookup_xtype(jsonb) AS \
         SELECT id FROM typed_text_prepared_index WHERE value = $1",
    )
    .execute(&mut *tx)
    .await?;

    let plan_rows: Vec<String> = sqlx::query_scalar(&format!(
        "EXPLAIN EXECUTE typed_text_lookup_xtype('{}'::jsonb)",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    let plan = plan_rows.join("\n");
    assert!(
        plan.contains("typed_text_prepared_hmac_idx"),
        "Form C: expected cross-type prepared plan to use hmac index; plan:\n{plan}"
    );

    let ids: Vec<i32> = sqlx::query_scalar(&format!(
        "EXECUTE typed_text_lookup_xtype('{}'::jsonb)",
        query
    ))
    .fetch_all(&mut *tx)
    .await?;
    assert_eq!(ids, vec![1], "Form C inline execute");

    tx.commit().await?;
    Ok(())
}
