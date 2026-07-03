//! Hard requirement: every supported `eql_v3` operator has a PUBLIC function
//! equivalent — callable by name on platforms without operator support.
//!
//! CipherStash Proxy fronts standard PostgreSQL, but not every deployment can
//! use custom operators. Supabase/PostgREST, for instance, exposes the database
//! through an auto-generated REST/RPC layer that invokes **functions**, not
//! operators (`WHERE col = $1` is not expressible; `eql_v3.eq(col, $1)` is). So
//! for EQL to be usable there, every supported operator (`=`, `<>`, `<`, `<=`,
//! `>`, `>=`, `@>`, `<@`, …) must also be reachable as a plainly-named function
//! in the PUBLIC `eql_v3` schema.
//!
//! DESIGN DECISION (mirrored in `src/v3/schema.sql`): only index-term TYPES and
//! never-invoked plumbing (blockers, aggregate state functions, opclass
//! comparators, CHECK validators) live in `eql_v3_internal`. The operator-backing
//! comparison WRAPPERS are public. These tests pin that invariant so a future
//! change that hides a wrapper — re-breaking operator-free platforms — fails CI.
//!
//! Structural + creds-free: they inspect `pg_catalog` on the installed schema,
//! no ciphertext required. Behavioural "callable by name" coverage lives in the
//! property/text_match/jsonb suites, which now call the public function forms
//! (`eql_v3.contains`, `eql_v3.jsonb_contains`, …) directly.

use anyhow::Result;
use sqlx::PgPool;

/// #1 — Every operator that operates on an `eql_v3` domain and is backed by a
/// real comparison WRAPPER (a `LANGUAGE sql` function — blockers are
/// `LANGUAGE plpgsql`) must have that wrapper in the PUBLIC `eql_v3` schema.
///
/// An offender is a supported operator whose function equivalent is hidden in
/// `eql_v3_internal`, where an operator-free caller cannot reach it.
#[sqlx::test]
async fn every_supported_eql_v3_operator_has_a_public_function_equivalent(
    pool: PgPool,
) -> Result<()> {
    let offenders: Vec<(String, String, String)> = sqlx::query_as(
        r#"
        SELECT
          o.oprname::text,
          format('%s.%s', pn.nspname, p.proname) AS backing_fn,
          format('%s %s %s',
                 lt.typname,
                 o.oprname,
                 COALESCE(rt.typname, '')) AS operator_shape
        FROM pg_catalog.pg_operator o
        JOIN pg_catalog.pg_proc       p  ON p.oid = o.oprcode
        JOIN pg_catalog.pg_namespace  pn ON pn.oid = p.pronamespace
        JOIN pg_catalog.pg_language   l  ON l.oid = p.prolang
        JOIN pg_catalog.pg_type       lt ON lt.oid = o.oprleft
        JOIN pg_catalog.pg_namespace  ln ON ln.oid = lt.typnamespace
        LEFT JOIN pg_catalog.pg_type      rt ON rt.oid = o.oprright
        LEFT JOIN pg_catalog.pg_namespace rn ON rn.oid = rt.typnamespace
        WHERE (ln.nspname = 'eql_v3' OR rn.nspname = 'eql_v3')  -- touches an eql_v3 domain
          AND l.lanname = 'sql'          -- a supported wrapper, not a plpgsql blocker
          AND pn.nspname <> 'eql_v3'     -- OFFENDER: backing wrapper is not public
        ORDER BY 3, 1
        "#,
    )
    .fetch_all(&pool)
    .await?;

    assert!(
        offenders.is_empty(),
        "Supported eql_v3 operators must be backed by a PUBLIC eql_v3 function so \
         they are callable by name on platforms without operator support \
         (Supabase/PostgREST). These operators bind a wrapper hidden in a \
         non-public schema: {offenders:?}. Move the wrapper to eql_v3 (see the \
         INTERNAL_SCHEMA/SCHEMA split in crates/eql-codegen and src/v3/jsonb)."
    );
    Ok(())
}

/// #2 — The specific public function equivalents that operator-free platforms
/// depend on must exist in `eql_v3` (by name). A rename or accidental
/// re-hiding is caught here with a targeted message, independent of #1's
/// structural scan and the public-surface golden.
#[sqlx::test]
async fn core_public_function_equivalents_exist_in_eql_v3(pool: PgPool) -> Result<()> {
    // (proname, must-exist-in-eql_v3). The comparison wrappers are overloaded
    // across many domains; we only assert at least one public overload exists.
    let expected = [
        "eq",
        "neq",
        "lt",
        "lte",
        "gt",
        "gte",
        "contains",
        "contained_by",
        "jsonb_contains",
        "jsonb_contained_by",
        "jsonb_array",
        "ste_vec_contains",
    ];

    let present: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT DISTINCT p.proname
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'eql_v3'
        "#,
    )
    .fetch_all(&pool)
    .await?;

    let missing: Vec<&str> = expected
        .iter()
        .copied()
        .filter(|name| !present.iter().any(|p| p == name))
        .collect();

    assert!(
        missing.is_empty(),
        "These operator-equivalent functions must be PUBLIC in eql_v3 (callable \
         by name without operators) but are absent from the public schema: {missing:?}"
    );
    Ok(())
}

/// #3 — Guard the split's other half: the pieces that MUST stay internal remain
/// in `eql_v3_internal` (never leak into the public surface). Blockers, aggregate
/// state functions, index-term type constructors, and CHECK validators are
/// implementation detail, not caller entrypoints.
#[sqlx::test]
async fn internal_only_helpers_stay_out_of_eql_v3(pool: PgPool) -> Result<()> {
    // Names that must NOT appear as functions in the public schema.
    let internal_only = [
        "min_sfunc",
        "max_sfunc",
        "jsonb_entry_min_sfunc",
        "jsonb_entry_max_sfunc",
        "is_valid_ste_vec_entry_payload",
        "is_ste_vec_array",
        "compare_ore_cllw_term",
        "ore_block_256_eq",
    ];

    let leaked: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT DISTINCT p.proname
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'eql_v3'
          AND p.proname = ANY($1)
        "#,
    )
    .bind(&internal_only[..])
    .fetch_all(&pool)
    .await?;

    assert!(
        leaked.is_empty(),
        "Internal-only helpers must stay in eql_v3_internal, but these appear in \
         the public eql_v3 schema: {leaked:?}"
    );
    Ok(())
}
