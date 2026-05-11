//! EQL lint runtime tests
//!
//! These tests run `eql_v2.lints()` against the installed EQL surface and
//! assert on the shape of the result.
//!
//! The lint is intentionally noisy on the current state of EQL — every
//! plpgsql / VOLATILE / SET-clause-bearing operator implementation is
//! reported. The tests here validate that the lint *runs* and that its
//! schema is sensible. A separate stacked PR (#193, the Phase 1 operator
//! inlining work) reduces the violation count, and at that point a
//! tighter test asserting `count = 0` for specific operators becomes
//! appropriate.

use anyhow::Result;
use sqlx::PgPool;

#[derive(Debug, sqlx::FromRow)]
struct LintRow {
    severity: String,
    category: String,
    object_name: String,
    #[allow(dead_code)]
    message: String,
}

async fn fetch_lints(pool: &PgPool) -> Result<Vec<LintRow>> {
    let rows = sqlx::query_as::<_, LintRow>(
        "SELECT severity, category, object_name, message FROM eql_v2.lints() ORDER BY category, object_name",
    )
    .fetch_all(pool)
    .await?;
    Ok(rows)
}

#[sqlx::test]
async fn lint_function_exists_and_returns_rows(pool: PgPool) -> Result<()> {
    let rows = fetch_lints(&pool).await?;
    // The current state of EQL has a non-trivial number of inlinability
    // violations on the operator surface. Confirm the lint produces output
    // and the columns parse correctly.
    assert!(
        !rows.is_empty(),
        "Expected lint to surface at least one inlinability violation \
         against the current EQL surface; got 0 rows"
    );
    Ok(())
}

#[sqlx::test]
async fn lint_severity_values_are_well_known(pool: PgPool) -> Result<()> {
    let rows = fetch_lints(&pool).await?;
    for row in rows {
        assert!(
            matches!(row.severity.as_str(), "error" | "warning" | "info"),
            "Unexpected severity {:?} for {} ({})",
            row.severity,
            row.object_name,
            row.category
        );
    }
    Ok(())
}

#[sqlx::test]
async fn lint_categories_are_well_known(pool: PgPool) -> Result<()> {
    let rows = fetch_lints(&pool).await?;
    let allowed = [
        "inlinability_language",
        "inlinability_volatility",
        "inlinability_set_clause",
        "inlinability_secdef",
        "inlinability_transitive",
    ];
    for row in rows {
        assert!(
            allowed.contains(&row.category.as_str()),
            "Unexpected lint category {:?} for {}",
            row.category,
            row.object_name
        );
    }
    Ok(())
}

/// Phase 1 regression: the operators rewritten in #193 (=, <>, ~~, ~~*,
/// @>, <@ on eql_v2_encrypted) must report zero lint violations. If this
/// test fails, an inlinability regression has been introduced into one
/// of the core operators that PostgREST and ORM bare-form queries rely
/// on.
#[sqlx::test]
async fn lint_phase_1_operators_are_clean(pool: PgPool) -> Result<()> {
    let rows = fetch_lints(&pool).await?;
    let phase_1_prefixes = [
        "operator =(eql_v2_encrypted",
        "operator <>(eql_v2_encrypted",
        "operator =(jsonb, eql_v2_encrypted",
        "operator <>(jsonb, eql_v2_encrypted",
        "operator ~~(eql_v2_encrypted",
        "operator ~~*(eql_v2_encrypted",
        "operator ~~(jsonb, eql_v2_encrypted",
        "operator ~~*(jsonb, eql_v2_encrypted",
        "operator @>(eql_v2_encrypted",
        "operator <@(eql_v2_encrypted",
    ];

    let violations: Vec<_> = rows
        .iter()
        .filter(|row| {
            phase_1_prefixes
                .iter()
                .any(|prefix| row.object_name.starts_with(prefix))
        })
        .collect();

    assert!(
        violations.is_empty(),
        "Phase 1 operators should report zero lint violations, but got: {:#?}",
        violations
    );
    Ok(())
}
