//! Containment with index tests (@> and <@) for encrypted JSONB
//!
//! Tests cover all operator/type combinations in the coverage matrix:
//!
//! | Operator           | LHS          | RHS          | Test                            |
//! |--------------------|--------------|--------------|----------------------------------|
//! | jsonb_contains     | encrypted    | jsonb_param  | contains_encrypted_jsonb_param   |
//! | jsonb_contains     | encrypted    | encrypted    | contains_encrypted_encrypted     |
//! | jsonb_contains     | jsonb_param  | encrypted    | contains_jsonb_param_encrypted   |
//! | jsonb_contained_by | encrypted    | jsonb_param  | contained_by_encrypted_jsonb_param |
//! | jsonb_contained_by | encrypted    | encrypted    | contained_by_encrypted_encrypted |
//! | jsonb_contained_by | jsonb_param  | encrypted    | contained_by_jsonb_param_encrypted |
//!
//! Uses parameterized queries (jsonb_param) as the primary pattern since
//! that's what real clients use when integrating with EQL.
//!
//! Uses the ste_vec_vast table (500 rows) from migration 005_install_ste_vec_vast_data.sql

use anyhow::Result;
use eql_tests::{
    analyze_table, assert_uses_index, assert_uses_seq_scan, create_jsonb_gin_index, explain_query,
    get_ste_vec_encrypted, get_ste_vec_sv_element,
};
use sqlx::PgPool;

// Constants for ste_vec_vast table testing
const STE_VEC_VAST_TABLE: &str = "ste_vec_vast";
const STE_VEC_VAST_GIN_INDEX: &str = "ste_vec_vast_gin_idx";

// ============================================================================
// GIN Index Helper Functions
// ============================================================================

/// Setup GIN index on ste_vec_vast table for testing
///
/// Creates the GIN index and runs ANALYZE to ensure query planner
/// has accurate statistics.
async fn setup_ste_vec_vast_gin_index(pool: &PgPool) -> Result<()> {
    create_jsonb_gin_index(pool, STE_VEC_VAST_TABLE, STE_VEC_VAST_GIN_INDEX).await?;
    analyze_table(pool, STE_VEC_VAST_TABLE).await?;
    Ok(())
}

// ============================================================================
// Sanity Tests: Value Contains Itself (Exact Match)
// ============================================================================
//
// These tests verify basic functionality - a value trivially contains itself.
// They serve as sanity checks that the GIN index and containment functions work.

#[sqlx::test]
async fn sanity_before_after_index_creation(pool: PgPool) -> Result<()> {
    // Demonstrates GIN index impact: Seq Scan before, Index Scan after
    analyze_table(&pool, STE_VEC_VAST_TABLE).await?;

    let id = 1;
    let row = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT 1 FROM {} WHERE eql_v2.jsonb_array(e) @> eql_v2.jsonb_array('{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, row
    );

    // BEFORE: Without index, should use Seq Scan
    let explain_before = explain_query(&pool, &sql).await?;
    assert_uses_seq_scan(&explain_before);

    // Create the GIN index
    setup_ste_vec_vast_gin_index(&pool).await?;

    // AFTER: With index, should use the GIN index
    assert_uses_index(&pool, &sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn sanity_non_matching_returns_empty(pool: PgPool) -> Result<()> {
    // Non-existent value returns no results
    setup_ste_vec_vast_gin_index(&pool).await?;

    let sql = format!(
        "SELECT count(*) FROM {} WHERE eql_v2.jsonb_array(e) @> ARRAY['{{\"s\":\"nonexistent\",\"v\":1}}'::jsonb]",
        STE_VEC_VAST_TABLE
    );

    let count: (i64,) = sqlx::query_as(&sql).fetch_one(&pool).await?;
    assert_eq!(count.0, 0, "Expected no matches for non-existent selector");

    Ok(())
}

// ============================================================================
// Coverage Matrix Tests: All Operator/Type Combinations
// ============================================================================
//
// Each test covers exactly one operator/type combination.
// Uses parameterized queries (jsonb_param) as the primary pattern
// since that's what real clients use.

#[sqlx::test]
async fn contains_encrypted_jsonb_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted, jsonb_param)
    // Most common pattern - client sends jsonb parameter
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&sv_element)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted, jsonb_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    // Verify index usage with literal for EXPLAIN (can't EXPLAIN with params)
    let explain_sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, '{}'::jsonb) LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element
    );
    assert_uses_index(&pool, &explain_sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn contains_encrypted_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted, encrypted)
    // Encrypted column contains another encrypted value
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - should contain itself
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Use parameterized query with encrypted value as jsonb
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted, encrypted) should find match (value contains itself)"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contains_jsonb_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(jsonb_param, encrypted)
    // Check if jsonb parameter contains the encrypted column
    // This is the inverse - rarely used but must work
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - it contains its own sv elements
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Check if the full encrypted value (as param) contains the column
    // This should match because encrypted contains itself
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(jsonb_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contains_encrypted_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted_param, encrypted)
    // Check if encrypted parameter contains the encrypted column
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - it contains its own sv elements
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    // Check if the encrypted value (as param) contains the column
    // Should match because encrypted contains itself
    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contains_encrypted_encrypted_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contains(encrypted, encrypted_param)
    // Encrypted column contains an encrypted value passed as parameter
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value to use as parameter
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contains(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contains(encrypted, encrypted_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

// ============================================================================
// Helper Function Tests
// ============================================================================

#[sqlx::test]
async fn test_get_ste_vec_encrypted_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_encrypted returns serde_json::Value
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, 1).await?;

    // Should be an object with expected encrypted structure
    assert!(
        encrypted.is_object(),
        "encrypted value should be a JSON object"
    );
    assert!(
        encrypted.get("sv").is_some(),
        "encrypted value should have 'sv' field"
    );

    Ok(())
}

#[sqlx::test]
async fn test_get_ste_vec_sv_element_returns_json_value(pool: PgPool) -> Result<()> {
    // Test that get_ste_vec_sv_element returns serde_json::Value with expected fields
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, 1, 0).await?;

    // Should be an object with expected fields
    assert!(sv_element.is_object(), "sv element should be a JSON object");
    assert!(
        sv_element.get("s").is_some(),
        "sv element should have 's' (selector) field"
    );

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_jsonb_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted, jsonb_param)
    // Is encrypted column contained by the jsonb parameter?
    // True when param equals or is superset of encrypted
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - column is contained by itself
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted, jsonb_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted, encrypted)
    // Is encrypted column contained by another encrypted value?
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - column is contained by itself
    let encrypted = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_encrypted_param(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted, encrypted_param)
    // Is encrypted column contained by the encrypted parameter?
    // True when param equals or is superset of encrypted
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - column is contained by itself
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by(e, $1::jsonb) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted, encrypted_param) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

#[sqlx::test]
async fn contained_by_jsonb_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(jsonb_param, encrypted)
    // Is jsonb parameter contained by the encrypted column?
    // Single sv element should be contained in the full encrypted value
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let sv_element = get_ste_vec_sv_element(&pool, STE_VEC_VAST_TABLE, id, 0).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&sv_element)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(jsonb_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    // Verify index usage
    let explain_sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by('{}'::jsonb, e) LIMIT 1",
        STE_VEC_VAST_TABLE, sv_element
    );
    assert_uses_index(&pool, &explain_sql, STE_VEC_VAST_GIN_INDEX).await?;

    Ok(())
}

#[sqlx::test]
async fn contained_by_encrypted_param_encrypted(pool: PgPool) -> Result<()> {
    // Coverage: jsonb_contained_by(encrypted_param, encrypted)
    // Is encrypted parameter contained by the encrypted column?
    // True when column equals or is superset of parameter
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    // Get full encrypted value - parameter is contained by itself in column
    let encrypted_param = get_ste_vec_encrypted(&pool, STE_VEC_VAST_TABLE, id).await?;

    let sql = format!(
        "SELECT id FROM {} WHERE eql_v2.jsonb_contained_by($1::jsonb, e) AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&encrypted_param)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "jsonb_contained_by(encrypted_param, encrypted) should find match"
    );
    assert_eq!(result.unwrap().0, id as i64);

    Ok(())
}

// ===========================================================================
// Typed needle: stevec_query DOMAIN
// ===========================================================================

#[sqlx::test]
async fn stevec_query_domain_rejects_payloads_with_c(_pool: PgPool) -> Result<()> {
    // The DOMAIN CHECK on `eql_v2.stevec_query` forbids any `c` field on sv
    // elements — `c` is ciphertext, which a containment needle never matches.
    let result = sqlx::query_scalar::<_, bool>(
        "SELECT '{\"sv\":[{\"s\":\"x\",\"c\":\"y\",\"hm\":\"z\"}]}'::eql_v2.stevec_query \
         IS NOT NULL",
    )
    .fetch_one(&_pool)
    .await;

    assert!(
        result.is_err(),
        "stevec_query cast should raise on a payload carrying `c`"
    );

    let msg = format!("{}", result.unwrap_err());
    assert!(
        msg.contains("violates check constraint"),
        "expected CHECK violation, got: {msg}"
    );

    Ok(())
}

#[sqlx::test]
async fn stevec_query_domain_rejects_non_sv_objects(_pool: PgPool) -> Result<()> {
    let result =
        sqlx::query_scalar::<_, bool>("SELECT '{\"x\":1}'::eql_v2.stevec_query IS NOT NULL")
            .fetch_one(&_pool)
            .await;

    assert!(result.is_err());
    let msg = format!("{}", result.unwrap_err());
    assert!(msg.contains("violates check constraint"));
    Ok(())
}

#[sqlx::test]
async fn stevec_query_domain_accepts_valid_payload(_pool: PgPool) -> Result<()> {
    let result: serde_json::Value = sqlx::query_scalar(
        "SELECT '{\"sv\":[{\"s\":\"x\",\"hm\":\"y\"}]}'::eql_v2.stevec_query::jsonb",
    )
    .fetch_one(&_pool)
    .await?;

    assert_eq!(result["sv"][0]["s"], "x");
    assert_eq!(result["sv"][0]["hm"], "y");
    Ok(())
}

#[sqlx::test]
async fn contains_with_stevec_query_overload(pool: PgPool) -> Result<()> {
    // The recommended recipe: `e @> '{"sv":[...]}'::eql_v2.stevec_query`.
    // Verifies the new operator overload dispatches correctly. Build a
    // clean needle ({s, hm-or-oc} only) — extracted entries carry the
    // root's `i`/`v` envelope metadata which would otherwise prevent
    // the jsonb @> subset match.
    setup_ste_vec_vast_gin_index(&pool).await?;

    let id = 1;
    let entry: serde_json::Value = sqlx::query_scalar(&format!(
        "SELECT jsonb_strip_nulls(jsonb_build_object( \
           's',  (e -> ((e).data -> 'sv' -> 0 ->> 's')::text) -> 's',  \
           'hm', (e -> ((e).data -> 'sv' -> 0 ->> 's')::text) -> 'hm', \
           'oc', (e -> ((e).data -> 'sv' -> 0 ->> 's')::text) -> 'oc'  \
         )) \
         FROM {} WHERE id = $1",
        STE_VEC_VAST_TABLE
    ))
    .bind(id)
    .fetch_one(&pool)
    .await?;

    // Wrap the (already-normalised) entry into a `stevec_query`-shaped payload.
    let needle = serde_json::json!({ "sv": [entry] });

    let sql = format!(
        "SELECT id FROM {} WHERE e @> $1::jsonb::eql_v2.stevec_query AND id = $2",
        STE_VEC_VAST_TABLE
    );

    let result: Option<(i64,)> = sqlx::query_as(&sql)
        .bind(&needle)
        .bind(id)
        .fetch_optional(&pool)
        .await?;

    assert!(
        result.is_some(),
        "e @> stevec_query should match the row the entry was extracted from"
    );
    assert_eq!(result.unwrap().0, id as i64);
    Ok(())
}

#[sqlx::test]
async fn cast_eql_v2_encrypted_to_stevec_query_strips_c(_pool: PgPool) -> Result<()> {
    // `to_stevec_query` is the cast function from `eql_v2_encrypted` to
    // `eql_v2.stevec_query` — strips `c` fields from each sv element.
    let result: serde_json::Value = sqlx::query_scalar(
        "SELECT (eql_v2.to_stevec_query(
                  '{\"v\":2,\"i\":{\"t\":\"t\",\"c\":\"c\"},
                    \"sv\":[
                      {\"s\":\"sel1\",\"c\":\"ct1\",\"hm\":\"hm1\"},
                      {\"s\":\"sel2\",\"c\":\"ct2\",\"oc\":\"oc2\"}
                    ]}'::jsonb::eql_v2_encrypted
                ))::jsonb",
    )
    .fetch_one(&_pool)
    .await?;

    let sv = result["sv"].as_array().expect("sv should be array");
    assert_eq!(sv.len(), 2);
    for elem in sv {
        assert!(
            elem.get("c").is_none(),
            "to_stevec_query should strip `c` fields; got: {elem}"
        );
    }
    Ok(())
}

// ===========================================================================
// XOR-aware containment: hm- and oc-bearing selectors both engage
// ===========================================================================
//
// Regression coverage for a structural gap we shipped in earlier rounds:
// the previous canonical recipe (`hmac_256_terms(col) @> ...`) silently
// dropped oc-bearing sv elements (string / number leaves carry `oc`, not
// `hm`), so containment via that recipe never matched on those selectors.
// The canonical replacement (`to_stevec_query(col)::jsonb @> needle::jsonb`,
// which the typed `@>(eql_v2_encrypted, eql_v2.stevec_query)` inlines to)
// is XOR-aware and matches both kinds.
//
// These tests use hand-synthesised payloads so they don't depend on
// fixture data (which historically violated the XOR contract for some
// selectors).

const XOR_TABLE: &str = "xor_containment_test";

async fn setup_xor_table(pool: &PgPool) -> Result<()> {
    sqlx::query(&format!("DROP TABLE IF EXISTS {XOR_TABLE}"))
        .execute(pool)
        .await?;
    sqlx::query(&format!(
        "CREATE TABLE {XOR_TABLE} (
           id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
           e eql_v2_encrypted NOT NULL
         )"
    ))
    .execute(pool)
    .await?;
    // Row 1: sv with one hm-bearing element under selector `bool_sel`
    sqlx::query(&format!(
        "INSERT INTO {XOR_TABLE}(e) VALUES (
           '{{\"v\":2,\"i\":{{\"t\":\"{XOR_TABLE}\",\"c\":\"e\"}},
              \"sv\":[
                {{\"s\":\"bool_sel\",\"c\":\"row1_ct\",\"hm\":\"deadbeef\"}}
              ]}}'::jsonb::eql_v2_encrypted
         )"
    ))
    .execute(pool)
    .await?;
    // Row 2: sv with one oc-bearing element under selector `string_sel`
    sqlx::query(&format!(
        "INSERT INTO {XOR_TABLE}(e) VALUES (
           '{{\"v\":2,\"i\":{{\"t\":\"{XOR_TABLE}\",\"c\":\"e\"}},
              \"sv\":[
                {{\"s\":\"string_sel\",\"c\":\"row2_ct\",\"oc\":\"abcd1234\"}}
              ]}}'::jsonb::eql_v2_encrypted
         )"
    ))
    .execute(pool)
    .await?;
    // Row 3: mixed sv with one hm element + one oc element
    sqlx::query(&format!(
        "INSERT INTO {XOR_TABLE}(e) VALUES (
           '{{\"v\":2,\"i\":{{\"t\":\"{XOR_TABLE}\",\"c\":\"e\"}},
              \"sv\":[
                {{\"s\":\"bool_sel\",\"c\":\"row3_ct1\",\"hm\":\"cafef00d\"}},
                {{\"s\":\"string_sel\",\"c\":\"row3_ct2\",\"oc\":\"feedface\"}}
              ]}}'::jsonb::eql_v2_encrypted
         )"
    ))
    .execute(pool)
    .await?;
    Ok(())
}

#[sqlx::test]
async fn typed_contains_matches_hm_bearing_selector(pool: PgPool) -> Result<()> {
    setup_xor_table(&pool).await?;
    // Needle: {s, hm} only — selector matches row 1 (hm: deadbeef)
    let sql = format!(
        "SELECT id FROM {XOR_TABLE} \
         WHERE e @> '{{\"sv\":[{{\"s\":\"bool_sel\",\"hm\":\"deadbeef\"}}]}}'::eql_v2.stevec_query \
         ORDER BY id"
    );
    let rows: Vec<(i64,)> = sqlx::query_as(&sql).fetch_all(&pool).await?;
    let ids: Vec<i64> = rows.into_iter().map(|(i,)| i).collect();
    assert_eq!(ids, vec![1], "hm-bearing needle should match only row 1");
    Ok(())
}

#[sqlx::test]
async fn typed_contains_matches_oc_bearing_selector(pool: PgPool) -> Result<()> {
    // The marquee test: under the previous hmac_256_terms recipe this
    // selector was invisible (string leaves carry oc, not hm). The
    // typed @>(stevec_query) inlines to a jsonb @> over to_stevec_query,
    // which preserves both terms, so the needle matches.
    setup_xor_table(&pool).await?;
    let sql = format!(
        "SELECT id FROM {XOR_TABLE} \
         WHERE e @> '{{\"sv\":[{{\"s\":\"string_sel\",\"oc\":\"abcd1234\"}}]}}'::eql_v2.stevec_query \
         ORDER BY id"
    );
    let rows: Vec<(i64,)> = sqlx::query_as(&sql).fetch_all(&pool).await?;
    let ids: Vec<i64> = rows.into_iter().map(|(i,)| i).collect();
    assert_eq!(
        ids,
        vec![2],
        "oc-bearing needle MUST match row 2 — this is the XOR-correctness regression check"
    );
    Ok(())
}

#[sqlx::test]
async fn typed_contains_mixed_sv_engages_both_selector_kinds(pool: PgPool) -> Result<()> {
    setup_xor_table(&pool).await?;
    // Row 3 has both hm and oc; either needle should match
    let sql_hm = format!(
        "SELECT id FROM {XOR_TABLE} \
         WHERE e @> '{{\"sv\":[{{\"s\":\"bool_sel\",\"hm\":\"cafef00d\"}}]}}'::eql_v2.stevec_query"
    );
    let sql_oc = format!(
        "SELECT id FROM {XOR_TABLE} \
         WHERE e @> '{{\"sv\":[{{\"s\":\"string_sel\",\"oc\":\"feedface\"}}]}}'::eql_v2.stevec_query"
    );
    let (ids_hm, ids_oc) = tokio::join!(
        sqlx::query_scalar::<_, i64>(&sql_hm).fetch_all(&pool),
        sqlx::query_scalar::<_, i64>(&sql_oc).fetch_all(&pool),
    );
    assert_eq!(ids_hm?, vec![3]);
    assert_eq!(ids_oc?, vec![3]);
    Ok(())
}

#[sqlx::test]
async fn typed_contains_wrong_term_does_not_match(pool: PgPool) -> Result<()> {
    setup_xor_table(&pool).await?;
    // Right selector, wrong oc bytes → no match
    let sql = format!(
        "SELECT id FROM {XOR_TABLE} \
         WHERE e @> '{{\"sv\":[{{\"s\":\"string_sel\",\"oc\":\"00000000\"}}]}}'::eql_v2.stevec_query"
    );
    let rows: Vec<(i64,)> = sqlx::query_as(&sql).fetch_all(&pool).await?;
    assert!(rows.is_empty(), "wrong oc bytes must not match");
    Ok(())
}

#[sqlx::test]
async fn functional_gin_on_to_stevec_query_engages_for_typed_contains(pool: PgPool) -> Result<()> {
    // Load-bearing plan assertion: a GIN on `to_stevec_query(col)::jsonb`
    // (jsonb_path_ops) is matched structurally by the inlined body of
    // `@>(eql_v2_encrypted, eql_v2.stevec_query)`. With enable_seqscan
    // off (small fixture), the planner must engage the functional GIN.
    setup_xor_table(&pool).await?;

    sqlx::query(&format!(
        "CREATE INDEX {XOR_TABLE}_stevec_query_idx \
         ON {XOR_TABLE} USING gin ((eql_v2.to_stevec_query(e)::jsonb) jsonb_path_ops)"
    ))
    .execute(&pool)
    .await?;
    // ANALYZE skipped intentionally: the deprecated
    // `encrypted_operator_class` btree on `eql_v2_encrypted` (U-001;
    // dropped in installs but still ships as the schema's default opclass)
    // uses the strict-post-#211 `eql_v2.compare` for sample comparisons,
    // which raises on sv-shaped payloads (no root `ob`). The functional
    // GIN index match below works without stats once we force
    // enable_seqscan = off.

    // Wrap SET + EXPLAIN in a single transaction so SET LOCAL persists.
    let mut tx = pool.begin().await?;
    sqlx::query("SET LOCAL enable_seqscan = off")
        .execute(&mut *tx)
        .await?;

    let explain_sql = format!(
        "EXPLAIN SELECT id FROM {XOR_TABLE} \
         WHERE e @> '{{\"sv\":[{{\"s\":\"string_sel\",\"oc\":\"abcd1234\"}}]}}'::eql_v2.stevec_query"
    );
    let plan: String = sqlx::query_scalar::<_, String>(&explain_sql)
        .fetch_all(&mut *tx)
        .await?
        .join("\n");
    tx.rollback().await?;

    assert!(
        plan.contains(&format!("{XOR_TABLE}_stevec_query_idx")),
        "Expected GIN engagement on functional to_stevec_query index. Plan:\n{plan}"
    );
    assert!(
        plan.contains("Bitmap Index Scan") || plan.contains("Bitmap Heap Scan"),
        "Expected Bitmap Index Scan in plan. Plan:\n{plan}"
    );
    Ok(())
}
