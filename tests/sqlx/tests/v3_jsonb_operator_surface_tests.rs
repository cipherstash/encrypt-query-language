//! D12 — signature-aware operator-surface guard for the `eql_v3` encrypted-JSONB
//! (SteVec) surface.
//!
//! This binary reads `pg_operator`, not the fixture. It verifies BOTH sides of
//! the surface:
//!   1. Every native jsonb operator symbol is either a supported root symbol OR
//!      has an `public.json`-bound blocker (so a column can never silently route
//!      to plaintext-jsonb semantics).
//!   2. Every supported symbol is bound with EXACTLY the intended safe operand
//!      signatures, and unsupported root-document comparison signatures
//!      (`public.json = public.json`, etc.) are blocked.
//!   3. Every blocker is bound to `public.json` with PostgreSQL's real native
//!      RHS type for that operator.
//!
//! Design source of truth:
//! `docs/superpowers/plans/2026-06-09-eql-v3-jsonb-test-harness-design.md` (D12).

use sqlx::PgPool;
use std::collections::BTreeSet;

/// Root-document operator symbols the surface SUPPORTS (an `public.json`-bound
/// operator, not a blocker).
const SUPPORTED_ROOT_SYMBOLS: &[&str] = &["@>", "<@", "->", "->>"];

/// Entry comparison symbols on `public.jsonb_entry`.
const SUPPORTED_ENTRY_SYMBOLS: &[&str] = &["=", "<>", "<", "<=", ">", ">="];

/// Native jsonb operators the surface BLOCKS (each raises "is not supported").
const BLOCKED_ROOT_SYMBOLS: &[&str] = &[
    "?", "?|", "?&", "@?", "@@", "#>", "#>>", "-", "#-", "||", "=", "<>", "<", "<=", ">", ">=",
];

/// Fetch the set of `(oprname, lhs_regtype, rhs_regtype)` for every operator
/// with at least one operand among the v3 jsonb domains.
async fn v3_jsonb_operators(pool: &PgPool) -> anyhow::Result<Vec<(String, String, String)>> {
    let rows: Vec<(String, String, String)> = sqlx::query_as(
        r#"
        WITH d AS (
          SELECT 'public.json'::regtype          AS j,
                 'public.jsonb_entry'::regtype  AS e,
                 'public.jsonb_query'::regtype  AS q
        )
        SELECT o.oprname,
               pg_catalog.format_type(o.oprleft, NULL)  AS lhs,
               pg_catalog.format_type(o.oprright, NULL) AS rhs
        FROM pg_operator o, d
        WHERE o.oprleft  IN (d.j, d.e, d.q)
           OR o.oprright IN (d.j, d.e, d.q)
        "#,
    )
    .fetch_all(pool)
    .await?;
    Ok(rows)
}

/// `format_type` renders the reserved word `json` quoted (`public."json"`).
/// Normalise so comparisons read naturally.
fn norm(ty: &str) -> String {
    match ty {
        "\"json\"" => "public.json".to_string(),
        "jsonb_entry" => "public.jsonb_entry".to_string(),
        "jsonb_query" => "public.jsonb_query".to_string(),
        _ => ty.replace("public.\"json\"", "public.json"),
    }
}

// ============================================================================
// (1) Every native jsonb operator symbol is supported-or-blocked.
// ============================================================================

#[sqlx::test]
async fn v3_jsonb_surface_supported_or_blocked(pool: PgPool) -> anyhow::Result<()> {
    // Native jsonb operator symbols (left OR right operand is plaintext jsonb).
    let native: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT DISTINCT o.oprname
        FROM pg_catalog.pg_operator o
        WHERE (o.oprleft = 'jsonb'::regtype OR o.oprright = 'jsonb'::regtype)
        ORDER BY 1
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(
        !native.is_empty(),
        "expected pg_operator to expose jsonb operators"
    );

    // The blocked symbols MUST each have an public.json-bound operator.
    let bound: Vec<(String, String, String)> = v3_jsonb_operators(&pool).await?;
    let json_bound_symbols: BTreeSet<String> = bound
        .iter()
        .filter(|(_, l, r)| norm(l) == "public.json" || norm(r) == "public.json")
        .map(|(n, _, _)| n.clone())
        .collect();

    let supported: BTreeSet<&str> = SUPPORTED_ROOT_SYMBOLS.iter().copied().collect();

    let mut unaccounted: Vec<String> = Vec::new();
    for sym in &native {
        let is_supported = supported.contains(sym.as_str());
        let is_blocked =
            BLOCKED_ROOT_SYMBOLS.contains(&sym.as_str()) && json_bound_symbols.contains(sym);
        if !is_supported && !is_blocked {
            unaccounted.push(sym.clone());
        }
    }

    assert!(
        unaccounted.is_empty(),
        "native jsonb operator(s) neither supported, blocked, nor an intentionally-native \
         comparison on public.json: {unaccounted:#?}. Each would route an encrypted column \
         to native plaintext-jsonb semantics (e.g. key/path extraction). Add a supported \
         wrapper or an public.json-bound blocker."
    );

    // And every blocked symbol must actually be bound (no missing blocker).
    let mut missing_blockers: Vec<&str> = Vec::new();
    for sym in BLOCKED_ROOT_SYMBOLS {
        if !json_bound_symbols.contains(*sym) {
            missing_blockers.push(sym);
        }
    }
    assert!(
        missing_blockers.is_empty(),
        "blocked symbol(s) have no public.json-bound operator: {missing_blockers:?}"
    );
    Ok(())
}

// ============================================================================
// (2) Supported operand signatures exist EXACTLY as intended.
// ============================================================================

#[sqlx::test]
async fn v3_jsonb_surface_supported_signatures(pool: PgPool) -> anyhow::Result<()> {
    let bound = v3_jsonb_operators(&pool).await?;
    let have: BTreeSet<(String, String, String)> = bound
        .iter()
        .map(|(n, l, r)| (n.clone(), norm(l), norm(r)))
        .collect();

    // Exact supported operand signatures (verified against operators.sql).
    let expected_supported: &[(&str, &str, &str)] = &[
        // containment
        ("@>", "public.json", "public.json"),
        ("@>", "public.json", "public.jsonb_query"),
        ("@>", "public.json", "public.jsonb_entry"),
        ("<@", "public.json", "public.json"),
        ("<@", "public.jsonb_query", "public.json"),
        ("<@", "public.jsonb_entry", "public.json"),
        // path access
        ("->", "public.json", "text"),
        ("->", "public.json", "integer"),
        ("->>", "public.json", "text"),
        // entry comparisons
        ("=", "public.jsonb_entry", "public.jsonb_entry"),
        ("<>", "public.jsonb_entry", "public.jsonb_entry"),
        ("<", "public.jsonb_entry", "public.jsonb_entry"),
        ("<=", "public.jsonb_entry", "public.jsonb_entry"),
        (">", "public.jsonb_entry", "public.jsonb_entry"),
        (">=", "public.jsonb_entry", "public.jsonb_entry"),
    ];

    let mut missing: Vec<(&str, &str, &str)> = Vec::new();
    for (op, l, r) in expected_supported {
        if !have.contains(&(op.to_string(), l.to_string(), r.to_string())) {
            missing.push((op, l, r));
        }
    }
    assert!(
        missing.is_empty(),
        "expected supported operand signature(s) are absent: {missing:#?}"
    );
    Ok(())
}

// ============================================================================
// (2b) Unsupported root-document comparison signatures are BLOCKED.
// ============================================================================

#[sqlx::test]
async fn v3_jsonb_surface_root_comparisons_blocked(pool: PgPool) -> anyhow::Result<()> {
    let rows: Vec<(String, String, String)> = sqlx::query_as(
        r#"
        SELECT o.oprname,
               pg_catalog.format_type(o.oprleft, NULL),
               pg_catalog.format_type(o.oprright, NULL)
        FROM pg_operator o
        WHERE o.oprname IN ('=', '<>', '<', '<=', '>', '>=')
          AND ('public.json'::regtype IN (o.oprleft, o.oprright))
        ORDER BY 1, 2, 3
        "#,
    )
    .fetch_all(&pool)
    .await?;
    let have: BTreeSet<(String, String, String)> = rows
        .iter()
        .map(|(op, l, r)| (op.clone(), norm(l), norm(r)))
        .collect();
    for op in ["=", "<>", "<", "<=", ">", ">="] {
        for (l, r) in [
            ("public.json", "public.json"),
            ("public.json", "jsonb"),
            ("jsonb", "public.json"),
        ] {
            assert!(
                have.contains(&(op.to_string(), l.to_string(), r.to_string())),
                "root-document comparison blocker missing for {op}({l}, {r})"
            );
        }
    }
    Ok(())
}

// ============================================================================
// (2c) Mixed-shape entry signatures are ABSENT.
//
// The entry comparison operators must be (jsonb_entry, jsonb_entry) only —
// never (jsonb_entry, jsonb) or (jsonb, jsonb_entry), which would let a
// raw jsonb operand sneak past the domain. (A runtime such pair flattens to
// native jsonb, so absence is structural.)
// ============================================================================

#[sqlx::test]
async fn v3_jsonb_surface_entry_mixed_shapes_absent(pool: PgPool) -> anyhow::Result<()> {
    let mixed: Vec<(String, String, String)> = sqlx::query_as(
        r#"
        SELECT o.oprname,
               pg_catalog.format_type(o.oprleft, NULL),
               pg_catalog.format_type(o.oprright, NULL)
        FROM pg_operator o
        WHERE o.oprname IN ('=', '<>', '<', '<=', '>', '>=')
          AND ('public.jsonb_entry'::regtype IN (o.oprleft, o.oprright))
          AND NOT (o.oprleft = 'public.jsonb_entry'::regtype
                   AND o.oprright = 'public.jsonb_entry'::regtype)
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(
        mixed.is_empty(),
        "entry comparison operators must be (jsonb_entry, jsonb_entry) only; \
         found mixed-shape signature(s): {mixed:#?}"
    );

    // Sanity: all six entry symbols ARE present in the symmetric shape.
    let present: BTreeSet<String> = sqlx::query_scalar::<_, String>(
        r#"
        SELECT o.oprname
        FROM pg_operator o
        WHERE o.oprleft = 'public.jsonb_entry'::regtype
          AND o.oprright = 'public.jsonb_entry'::regtype
        "#,
    )
    .fetch_all(&pool)
    .await?
    .into_iter()
    .collect();
    for sym in SUPPORTED_ENTRY_SYMBOLS {
        assert!(
            present.contains(*sym),
            "entry operator {sym} missing on (jsonb_entry, jsonb_entry)"
        );
    }
    Ok(())
}

// ============================================================================
// (3) Each blocker is bound to public.json with PostgreSQL's real native RHS
//     type for that operator.
// ============================================================================

#[sqlx::test]
async fn v3_jsonb_surface_blocker_signatures(pool: PgPool) -> anyhow::Result<()> {
    let bound = v3_jsonb_operators(&pool).await?;
    let have: BTreeSet<(String, String, String)> = bound
        .iter()
        .map(|(n, l, r)| (n.clone(), norm(l), norm(r)))
        .collect();

    // Exact blocker operand signatures with PostgreSQL's real native RHS types
    // (verified against blockers.sql and the live catalog).
    let expected_blockers: &[(&str, &str, &str)] = &[
        ("?", "public.json", "text"),
        ("?|", "public.json", "text[]"),
        ("?&", "public.json", "text[]"),
        ("@?", "public.json", "jsonpath"),
        ("@@", "public.json", "jsonpath"),
        ("#>", "public.json", "text[]"),
        ("#>>", "public.json", "text[]"),
        ("-", "public.json", "text"),
        ("-", "public.json", "integer"),
        ("-", "public.json", "text[]"),
        ("#-", "public.json", "text[]"),
        ("||", "public.json", "jsonb"),
        // concat is also blocked with the domain on the RIGHT.
        ("||", "jsonb", "public.json"),
        // root comparisons are blocked for every typed domain/jsonb shape.
        ("=", "public.json", "public.json"),
        ("=", "public.json", "jsonb"),
        ("=", "jsonb", "public.json"),
        ("<>", "public.json", "public.json"),
        ("<>", "public.json", "jsonb"),
        ("<>", "jsonb", "public.json"),
        ("<", "public.json", "public.json"),
        ("<", "public.json", "jsonb"),
        ("<", "jsonb", "public.json"),
        ("<=", "public.json", "public.json"),
        ("<=", "public.json", "jsonb"),
        ("<=", "jsonb", "public.json"),
        (">", "public.json", "public.json"),
        (">", "public.json", "jsonb"),
        (">", "jsonb", "public.json"),
        (">=", "public.json", "public.json"),
        (">=", "public.json", "jsonb"),
        (">=", "jsonb", "public.json"),
        // mixed jsonb containment shapes are blocked; safe forms use json,
        // jsonb_query, or jsonb_entry.
        ("@>", "public.json", "jsonb"),
        ("@>", "jsonb", "public.json"),
        ("<@", "public.json", "jsonb"),
        ("<@", "jsonb", "public.json"),
    ];

    let mut missing: Vec<(&str, &str, &str)> = Vec::new();
    for (op, l, r) in expected_blockers {
        if !have.contains(&(op.to_string(), l.to_string(), r.to_string())) {
            missing.push((op, l, r));
        }
    }
    assert!(
        missing.is_empty(),
        "expected blocker signature(s) are absent: {missing:#?}"
    );

    // Every blocked symbol's public.json-bound operator backs a non-STRICT
    // plpgsql blocker function (proisstrict = false), so a NULL domain operand
    // still raises rather than short-circuiting to NULL.
    let strict_offenders: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT o.oprname, p.proname
        FROM pg_operator o
        JOIN pg_proc p ON p.oid = o.oprcode
        WHERE ('public.json'::regtype IN (o.oprleft, o.oprright))
          AND o.oprname IN ('?', '?|', '?&', '@?', '@@', '#>', '#>>', '-', '#-', '||',
                            '=', '<>', '<', '<=', '>', '>=', '@>', '<@')
          AND p.proname LIKE 'jsonb_blocked%'
          AND (p.proisstrict OR p.prolang <> (SELECT oid FROM pg_language WHERE lanname = 'plpgsql'))
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(
        strict_offenders.is_empty(),
        "blocker(s) must be non-STRICT plpgsql so NULL operands still raise; \
         offending (operator, function): {strict_offenders:#?}"
    );
    Ok(())
}

// ============================================================================
// (4) Each blocker's RETURN type matches the native operator it shadows, so a
//     COMPOSED expression resolves and the blocker body raises 'is not
//     supported' — rather than failing earlier at type resolution with a
//     misleading 'operator does not exist' on a boolean intermediate. (#267
//     review / aa13065.)
// ============================================================================

/// The non-boolean blocker functions and the native result type they must
/// shadow. Every other `jsonb_blocked%` function returns `boolean`.
const NON_BOOLEAN_BLOCKER_RETURN_TYPES: &[(&str, &str)] = &[
    ("jsonb_blocked_path_extract", "jsonb"),     // #>
    ("jsonb_blocked_path_extract_text", "text"), // #>>
    ("jsonb_blocked_delete_text", "jsonb"),      // - (text)
    ("jsonb_blocked_delete_int", "jsonb"),       // - (integer)
    ("jsonb_blocked_delete_array", "jsonb"),     // - (text[])
    ("jsonb_blocked_delete_path", "jsonb"),      // #-
    ("jsonb_blocked_concat", "jsonb"),           // ||  (json on left)
    ("jsonb_blocked_concat_rhs", "jsonb"),       // ||  (json on right)
];

#[sqlx::test]
async fn v3_jsonb_blocker_return_types_match_native(pool: PgPool) -> anyhow::Result<()> {
    // Every eql_v3_internal jsonb_blocked% function with its declared return type.
    let rows: Vec<(String, String)> = sqlx::query_as(
        r#"
        SELECT p.proname, pg_catalog.format_type(p.prorettype, NULL)
        FROM pg_proc p
        WHERE p.pronamespace = 'eql_v3_internal'::regnamespace
          AND p.proname LIKE 'jsonb_blocked%'
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(
        !rows.is_empty(),
        "expected eql_v3_internal jsonb_blocked% functions to exist"
    );

    let non_boolean: std::collections::BTreeMap<&str, &str> =
        NON_BOOLEAN_BLOCKER_RETURN_TYPES.iter().copied().collect();

    for (name, rettype) in &rows {
        let want = non_boolean.get(name.as_str()).copied().unwrap_or("boolean");
        assert_eq!(
            rettype, want,
            "blocker {name} must RETURN {want} (the native operator's result type) so composed \
             expressions resolve and the body raises; got {rettype}. A boolean here would make a \
             surrounding operator fail with 'operator does not exist'."
        );
    }

    // Cross-check: every name in the expected non-boolean list is actually present
    // (guards against a renamed/removed blocker silently dropping the guarantee).
    let present: BTreeSet<&str> = rows.iter().map(|(n, _)| n.as_str()).collect();
    let missing: Vec<&str> = NON_BOOLEAN_BLOCKER_RETURN_TYPES
        .iter()
        .map(|(n, _)| *n)
        .filter(|n| !present.contains(n))
        .collect();
    assert!(
        missing.is_empty(),
        "expected non-boolean blocker(s) absent: {missing:?}"
    );
    Ok(())
}

/// Assert a COMPOSED expression that wraps a blocked operator fails with the
/// blocker's `is not supported` (proving the composition RESOLVED and the
/// blocker body ran), NOT `operator does not exist` (which is the regression
/// signature of a blocker reverting to a boolean return type).
async fn assert_composed_blocked(pool: &PgPool, sql: &str) -> anyhow::Result<()> {
    let err = sqlx::query(sql)
        .fetch_optional(pool)
        .await
        .err()
        .ok_or_else(|| anyhow::anyhow!("composed blocked expression must raise: {sql}"))?;
    let msg = err.to_string();
    anyhow::ensure!(
        msg.contains("is not supported"),
        "expected the blocker's 'is not supported' (composition resolved, blocker fired); \
         got: {msg}\n  SQL: {sql}",
    );
    anyhow::ensure!(
        !msg.contains("operator does not exist"),
        "composed expression failed at TYPE RESOLUTION ('operator does not exist') — a blocker's \
         RETURN type no longer matches its native operator, so a surrounding operator cannot \
         resolve.\n  SQL: {sql}\n  err: {msg}",
    );
    Ok(())
}

#[sqlx::test]
async fn v3_jsonb_blocked_composed_expression_raises(pool: PgPool) -> anyhow::Result<()> {
    // A valid public.json document literal (empty sv array satisfies the CHECK).
    let j = r#"'{"i":{},"v":3,"sv":[]}'::public.json"#;

    // Each case wraps a blocked operator (whose return type was boolean before
    // the fix) in a surrounding operator that only resolves against the NATIVE
    // result type. With a boolean blocker these fail to type-resolve; with the
    // correct return type they resolve and the blocker raises 'is not supported'.
    let cases = [
        // #> returns jsonb → wrap with native jsonb @>
        format!("SELECT ({j} #> '{{a}}'::text[]) @> '{{}}'::jsonb"),
        // #>> returns text → wrap with native text ||
        format!("SELECT ({j} #>> '{{a}}'::text[]) || 'x'::text"),
        // - (text) returns jsonb → wrap with native jsonb @>
        format!("SELECT ({j} - 'a'::text) @> '{{}}'::jsonb"),
        // #- returns jsonb → wrap with native jsonb @>
        format!("SELECT ({j} #- '{{a}}'::text[]) @> '{{}}'::jsonb"),
        // || (json on left) returns jsonb → wrap with native jsonb @>
        format!("SELECT ({j} || '{{}}'::jsonb) @> '{{}}'::jsonb"),
    ];
    for sql in &cases {
        assert_composed_blocked(&pool, sql).await?;
    }
    Ok(())
}
