//! EQL test framework infrastructure
//!
//! Provides assertion builders and test helpers for EQL functionality tests.

use sqlx::PgPool;

pub mod assertions;
pub mod selectors;

pub use assertions::QueryAssertion;
pub use selectors::Selectors;

/// Reset pg_stat_user_functions tracking before tests
pub async fn reset_function_stats(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::query("SELECT pg_stat_reset()")
        .execute(pool)
        .await?;
    Ok(())
}
