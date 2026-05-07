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

/// Smoke test: at least one operator equality / pattern operator on
/// `eql_v2_encrypted` is reported pre-#193. Once #193 lands and reduces
/// violations on those specific operators, this test should be updated
/// or removed.
#[sqlx::test]
async fn lint_reports_eql_v2_encrypted_operators(pool: PgPool) -> Result<()> {
    let rows = fetch_lints(&pool).await?;
    let names: Vec<&str> = rows.iter().map(|r| r.object_name.as_str()).collect();
    assert!(
        names
            .iter()
            .any(|n| n.starts_with("operator =(eql_v2_encrypted")
                || n.starts_with("operator <>(eql_v2_encrypted")
                || n.starts_with("operator ~~(eql_v2_encrypted")
                || n.starts_with("operator @>(eql_v2_encrypted")),
        "Expected at least one violation on a core eql_v2_encrypted \
         operator; got: {:?}",
        names
    );
    Ok(())
}
