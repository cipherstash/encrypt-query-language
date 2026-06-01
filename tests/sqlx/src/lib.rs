//! EQL test framework infrastructure
//!
//! Provides assertion builders and test helpers for EQL functionality tests.

use sqlx::PgPool;

pub mod assertions;
pub mod fixtures;
pub mod helpers;
pub mod index_types;
pub mod matrix;
pub mod scalar_domains;
pub mod selectors;

// Re-export `paste` under a stable path so the `scalar_domain_matrix!` macro
// can refer to `$crate::paste::paste!` without requiring callers to depend on
// the `paste` crate directly.
#[doc(hidden)]
pub use paste;

pub use assertions::{assert_db_error, QueryAssertion};
pub use helpers::{
    analyze_table, assert_no_seq_scan, assert_sequential_ids, assert_uses_index,
    assert_uses_seq_scan, create_jsonb_gin_index, ensure_pg_stat_statements, explain_analyze_avg,
    explain_json, explain_query, get_bench_encrypted_int, get_bench_encrypted_text,
    get_encrypted_term, get_ore_encrypted, get_ore_encrypted_as_jsonb, get_ore_text_encrypted,
    get_ore_text_encrypted_as_jsonb, get_ste_vec_encrypted, get_ste_vec_encrypted_pair,
    get_ste_vec_selector_term, get_ste_vec_sv_element, get_ste_vec_term_by_id,
    read_pg_stat_statements, reset_pg_stat_statements, ExplainStats, PgStatEntry,
    PLACEHOLDER_PAYLOAD,
};
pub use index_types as IndexTypes;
pub use scalar_domains::{
    assert_null, assert_raises, assert_scalar_plaintexts, blocker_msg, commute_op,
    fetch_fixture_payload, sql_string_literal, ScalarDomainSpec, ScalarType, Variant,
};
pub use selectors::Selectors;

/// Reset pg_stat_user_functions tracking before tests
pub async fn reset_function_stats(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::query("SELECT pg_stat_reset()").execute(pool).await?;
    Ok(())
}
