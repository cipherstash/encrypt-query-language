//! Public-surface gates for the `eql_v3` schema (the split's raison d'être).
//!
//! `eql_v3` is the public API; `eql_v3_internal` holds implementation detail
//! (SEM index-term types, wrappers/blockers/state functions, the jsonb engine).
//! The split exists to keep index-term-only TYPES out of what a Supabase Studio
//! Table Builder user sees. Nothing else in the suite pins *what lives in
//! `eql_v3`*, so a new internal object accidentally created in the public schema
//! would ship unnoticed. These tests close that gap two ways:
//!
//!   * `eql_v3_public_surface_matches_golden` — an exhaustive committed snapshot
//!     of every object visible in `eql_v3` (types, functions, aggregates,
//!     operators, casts). Any addition/removal/rename forces a conscious
//!     snapshot update, mirroring the `snapshots/matrix_tests.txt` gate.
//!   * The placement invariants — structural rules (no naked composite/enum
//!     types in the public schema; every public type is a jsonb-backed domain;
//!     every catalog-generated domain landed in `eql_v3`) that are cheaper to
//!     reason about than the golden and independent of a frozen text file.
//!
//! The golden is regenerated in place with `EQL_UPDATE_SNAPSHOTS=1` (see
//! `mise run test:surface:snapshot:regen`); the file lives next to the matrix
//! snapshots under `tests/sqlx/snapshots/`.

use anyhow::Result;
use sqlx::PgPool;

/// The committed golden snapshot, embedded at compile time. Embedding (not
/// runtime `std::fs`) is required because CI compiles the test binary on one
/// runner (`cargo nextest archive`) and executes it on another, where the
/// build-machine `CARGO_MANIFEST_DIR` path no longer exists — the same reason
/// fixtures are `include_str!`'d in this suite.
const GOLDEN: &str = include_str!("../snapshots/eql_v3_public_surface.txt");

/// Filesystem path to the golden, used ONLY by the local regen path
/// (`EQL_UPDATE_SNAPSHOTS=1`), which always runs on the build machine where this
/// compile-time path is valid.
const GOLDEN_PATH: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/snapshots/eql_v3_public_surface.txt");

/// Enumerates every object owned by the `eql_v3` public schema as normalized,
/// schema-qualified text lines. Run on a connection with
/// `search_path = pg_catalog` so `regtype`/identity-argument rendering
/// fully-qualifies non-catalog schemas (`eql_v3.*`) and leaves built-ins
/// (`jsonb`) bare — deterministic across environments and PG versions.
const SURFACE_SQL: &str = r#"
    SELECT format('type %s.%s %s', n.nspname, t.typname, t.typtype)
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'eql_v3' AND t.typtype IN ('d','c','e')

    UNION ALL

    SELECT format('%s %s.%s(%s)',
      CASE p.prokind
        WHEN 'a' THEN 'aggregate'
        WHEN 'w' THEN 'window'
        WHEN 'p' THEN 'procedure'
        ELSE 'function'
      END,
      n.nspname, p.proname,
      pg_catalog.pg_get_function_identity_arguments(p.oid))
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'eql_v3'

    UNION ALL

    SELECT format('operator %s.%s(%s,%s)',
      n.nspname, o.oprname, o.oprleft::regtype, o.oprright::regtype)
    FROM pg_catalog.pg_operator o
    JOIN pg_catalog.pg_namespace n ON n.oid = o.oprnamespace
    WHERE n.nspname = 'eql_v3'

    UNION ALL

    SELECT format('cast %s -> %s', c.castsource::regtype, c.casttarget::regtype)
    FROM pg_catalog.pg_cast c
    WHERE EXISTS (
        SELECT 1 FROM pg_catalog.pg_type st
        JOIN pg_catalog.pg_namespace sn ON sn.oid = st.typnamespace
        WHERE st.oid = c.castsource AND sn.nspname = 'eql_v3')
      OR EXISTS (
        SELECT 1 FROM pg_catalog.pg_type tt
        JOIN pg_catalog.pg_namespace tn ON tn.oid = tt.typnamespace
        WHERE tt.oid = c.casttarget AND tn.nspname = 'eql_v3')
"#;

/// Fetch the sorted public-surface entry list.
async fn public_surface(pool: &PgPool) -> Result<Vec<String>> {
    let mut conn = pool.acquire().await?;
    sqlx::query("SET search_path = pg_catalog")
        .execute(&mut *conn)
        .await?;
    let mut entries: Vec<String> = sqlx::query_scalar(SURFACE_SQL).fetch_all(&mut *conn).await?;
    // Byte-order sort to match the `LC_ALL=C sort` convention used by the other
    // committed snapshots.
    entries.sort();
    Ok(entries)
}

/// The catalog-generated domain names, as they appear in SQL: `<family>` for the
/// storage domain (empty term-name), `<family>_<term>` otherwise. These MUST
/// live in `eql_v3` (never `eql_v3_internal`), and are a subset of the installed
/// `eql_v3` domains (the hand-written jsonb-family domains — `json`,
/// `ste_vec_query`, `ste_vec_entry` — are the remainder).
fn catalog_domain_names() -> Vec<String> {
    let mut names = Vec::new();
    for family in eql_domains::CATALOG {
        for domain in family.domains {
            if domain.name.is_empty() {
                names.push(family.name.to_string());
            } else {
                names.push(format!("{}_{}", family.name, domain.name));
            }
        }
    }
    names.sort();
    names
}

/// #1 — Exhaustive golden snapshot of the `eql_v3` public surface.
#[sqlx::test]
async fn eql_v3_public_surface_matches_golden(pool: PgPool) -> Result<()> {
    let entries = public_surface(&pool).await?;
    let actual = format!("{}\n", entries.join("\n"));

    if std::env::var_os("EQL_UPDATE_SNAPSHOTS").is_some() {
        std::fs::write(GOLDEN_PATH, &actual)?;
        eprintln!(
            "wrote golden snapshot ({} entries): {GOLDEN_PATH}",
            entries.len()
        );
        return Ok(());
    }

    if actual != GOLDEN {
        let expected_lines: std::collections::BTreeSet<&str> = GOLDEN.lines().collect();
        let actual_lines: std::collections::BTreeSet<&str> = actual.lines().collect();
        let added: Vec<&str> = actual_lines.difference(&expected_lines).copied().collect();
        let removed: Vec<&str> = expected_lines.difference(&actual_lines).copied().collect();
        panic!(
            "eql_v3 public surface drifted from the committed golden.\n\
             Objects added to eql_v3 (not in golden):\n  {}\n\
             Objects removed from eql_v3 (still in golden):\n  {}\n\
             If this change is intentional, regenerate with \
             `EQL_UPDATE_SNAPSHOTS=1 mise run test:surface:snapshot:regen` and commit \
             {GOLDEN_PATH}.\n\
             If an object should be internal, create it in eql_v3_internal instead.",
            if added.is_empty() { "(none)".to_string() } else { added.join("\n  ") },
            if removed.is_empty() { "(none)".to_string() } else { removed.join("\n  ") },
        );
    }
    Ok(())
}

/// #2 — Placement invariant: `eql_v3` contains no naked composite or enum types.
/// Every SEM index-term composite (`ore_block_256_term`, …) belongs in
/// `eql_v3_internal`; a composite/enum in the public schema is exactly the
/// Table-Builder-picker clutter the split exists to prevent.
#[sqlx::test]
async fn eql_v3_has_no_naked_composite_or_enum_types(pool: PgPool) -> Result<()> {
    let offenders: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT format('%I (typtype=%s)', t.typname, t.typtype)
        FROM pg_catalog.pg_type t
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'eql_v3'
          AND t.typtype IN ('c', 'e')
        ORDER BY 1
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(
        offenders.is_empty(),
        "eql_v3 must contain no naked composite/enum types — these belong in \
         eql_v3_internal so they stay out of the Supabase type picker. Found: {offenders:?}"
    );
    Ok(())
}

/// #2 — Placement invariant: every type in `eql_v3` is a jsonb-backed domain.
/// The public surface is exclusively jsonb domains (the scalar families plus the
/// hand-written jsonb-document domains); anything else is misplaced.
#[sqlx::test]
async fn every_eql_v3_type_is_a_jsonb_domain(pool: PgPool) -> Result<()> {
    let offenders: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT format('%I (typtype=%s, base=%s)',
                      t.typname, t.typtype, COALESCE(bt.typname, '<none>'))
        FROM pg_catalog.pg_type t
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        LEFT JOIN pg_catalog.pg_type bt ON bt.oid = t.typbasetype
        WHERE n.nspname = 'eql_v3'
          AND t.typtype IN ('d', 'c', 'e')
          AND NOT (t.typtype = 'd' AND bt.typname = 'jsonb')
        ORDER BY 1
        "#,
    )
    .fetch_all(&pool)
    .await?;
    assert!(
        offenders.is_empty(),
        "every eql_v3 type must be a jsonb-backed domain; found non-jsonb-domain type(s): {offenders:?}"
    );
    Ok(())
}

/// #2 — Placement invariant: every catalog-generated domain landed in `eql_v3`.
/// Ties the public surface back to `eql_domains::CATALOG` (the source of truth)
/// independent of the golden text file: a generated domain created in the wrong
/// schema (or missing) fails here without a manual snapshot update.
#[sqlx::test]
async fn every_catalog_domain_is_present_in_eql_v3(pool: PgPool) -> Result<()> {
    let installed: Vec<String> = sqlx::query_scalar(
        r#"
        SELECT t.typname::text
        FROM pg_catalog.pg_type t
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'eql_v3' AND t.typtype = 'd'
        "#,
    )
    .fetch_all(&pool)
    .await?;
    let installed: std::collections::BTreeSet<String> = installed.into_iter().collect();

    let missing: Vec<String> = catalog_domain_names()
        .into_iter()
        .filter(|name| !installed.contains(name))
        .collect();
    assert!(
        missing.is_empty(),
        "catalog-generated domain(s) not found as jsonb domains in eql_v3 \
         (created in the wrong schema, or not created?): {missing:?}"
    );
    Ok(())
}
