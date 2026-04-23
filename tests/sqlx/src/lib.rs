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
    analyze_table, assert_no_seq_scan, assert_sequential_ids, assert_uses_index,
    assert_uses_seq_scan, create_jsonb_gin_index, ensure_pg_stat_statements, explain_analyze_avg,
    explain_json, explain_query, get_bench_encrypted_int, get_bench_encrypted_text,
    get_encrypted_term, get_ore_encrypted, get_ore_encrypted_as_jsonb, get_ore_text_encrypted,
    get_ore_text_encrypted_as_jsonb, get_ste_vec_encrypted, get_ste_vec_encrypted_pair,
    get_ste_vec_selector_term, get_ste_vec_sv_element, get_ste_vec_term_by_id,
    read_pg_stat_statements, reset_pg_stat_statements, ExplainStats, PgStatEntry,
};
pub use index_types as IndexTypes;
pub use selectors::Selectors;

/// Reset pg_stat_user_functions tracking before tests
pub async fn reset_function_stats(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::query("SELECT pg_stat_reset()").execute(pool).await?;
    Ok(())
}
