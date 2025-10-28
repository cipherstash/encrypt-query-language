//! Test helper functions for EQL tests
//!
//! Common utilities for working with encrypted data in tests.

use anyhow::{Context, Result};
use sqlx::{PgPool, Row};

/// Fetch ORE encrypted value from pre-seeded ore table
///
/// The ore table is created by migration `002_install_ore_data.sql`
/// and contains 99 pre-seeded records (ids 1-99) for testing.
pub async fn get_ore_encrypted(pool: &PgPool, id: i32) -> Result<String> {
    let sql = format!("SELECT e::text FROM ore WHERE id = {}", id);
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching ore encrypted value for id={}", id))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting text column for id={}", id))?;

    result.with_context(|| format!("ore table returned NULL for id={}", id))
}
