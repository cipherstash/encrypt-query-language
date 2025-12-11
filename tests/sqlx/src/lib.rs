//! EQL test framework infrastructure
//!
//! Provides assertion builders and test helpers for EQL functionality tests.

use sqlx::PgPool;

pub mod assertions;
pub mod helpers;
pub mod index_types;
pub mod selectors;

pub use assertions::QueryAssertion;
pub use helpers::{
    analyze_table, assert_uses_index, assert_uses_seq_scan, create_jsonb_gin_index,
    explain_query, get_encrypted_term, get_ore_encrypted, get_ore_encrypted_as_jsonb,
    get_ste_vec_encrypted, get_ste_vec_selector_term, get_ste_vec_term_by_id,
};
pub use index_types as IndexTypes;
pub use selectors::Selectors;

/// Reset pg_stat_user_functions tracking before tests
pub async fn reset_function_stats(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::query("SELECT pg_stat_reset()").execute(pool).await?;
    Ok(())
}
