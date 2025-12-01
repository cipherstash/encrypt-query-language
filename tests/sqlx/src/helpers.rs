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

/// Extract encrypted term from encrypted table by selector
///
/// Extracts a field from the first record in the encrypted table using
/// the provided selector hash. Used for containment operator tests.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `selector` - Selector hash for the field to extract (e.g., from Selectors constants)
///
/// # Example
/// ```ignore
/// let term = get_encrypted_term(&pool, Selectors::HELLO).await?;
/// ```
pub async fn get_encrypted_term(pool: &PgPool, selector: &str) -> Result<String> {
    // Note: Must cast selector to ::text to disambiguate operator overload
    // The -> operator has multiple signatures (text, eql_v2_encrypted, integer)
    let sql = format!(
        "SELECT (e -> '{}'::text)::text FROM encrypted LIMIT 1",
        selector
    );
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("extracting encrypted term for selector={}", selector))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("getting text column for selector={}", selector))?;

    result.with_context(|| {
        format!(
            "encrypted term extraction returned NULL for selector={}",
            selector
        )
    })
}

/// Fetch ORE encrypted value as JSONB for comparison
///
/// This creates a JSONB value from the ore table that can be used with JSONB comparison
/// operators. The ore table values only contain {"ob": [...]}, so we merge in the required
/// "i" (index metadata) and "v" (version) fields to create a valid eql_v2_encrypted structure.
pub async fn get_ore_encrypted_as_jsonb(pool: &PgPool, id: i32) -> Result<String> {
    let sql = format!(
        "SELECT (e::jsonb || jsonb_build_object('i', jsonb_build_object('t', 'ore'), 'v', 2))::text FROM ore WHERE id = {}",
        id
    );

    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching ore encrypted as jsonb for id={}", id))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting jsonb text for id={}", id))?;

    result.with_context(|| format!("ore table returned NULL for id={}", id))
}

/// Fetch STE vec encrypted value from ste_vec table
///
/// The ste_vec table is created by migration `003_install_ste_vec_data.sql`
/// and contains 10 pre-seeded records (ids 1-10) with ore_cllw_u64_8 and ore_cllw_var_8 indexes.
///
/// Test data structure:
/// - Records have selectors for $.hello (a7cea93975ed8c01f861ccb6bd082784) with ore_cllw_var_8
/// - Records have selectors for $.n (2517068c0d1f9d4d41d2c666211f785e) with ore_cllw_u64_8
pub async fn get_ste_vec_encrypted(pool: &PgPool, id: i32) -> Result<String> {
    let sql = format!("SELECT e::text FROM ste_vec WHERE id = {}", id);
    let row = sqlx::query(&sql)
        .fetch_one(pool)
        .await
        .with_context(|| format!("fetching ste_vec encrypted value for id={}", id))?;

    let result: Option<String> = row
        .try_get(0)
        .with_context(|| format!("extracting text column for id={}", id))?;

    result.with_context(|| format!("ste_vec table returned NULL for id={}", id))
}

/// Extract selector term using SQL helper functions
///
/// Uses the get_numeric_ste_vec_*() helper functions to extract a selector term.
/// This matches the SQL test pattern exactly.
///
/// # Arguments
/// * `pool` - Database connection pool
/// * `value` - Which STE vec value to use (10, 20, 30, or 42)
/// * `selector` - Selector hash to extract (e.g., Selectors::N, Selectors::HELLO)
///
/// # Example
/// ```ignore
/// // Extract $.n selector from n=30 test data
/// let term = get_ste_vec_selector_term(&pool, 30, Selectors::N).await?;
/// ```
pub async fn get_ste_vec_selector_term(
    pool: &PgPool,
    value: i32,
    selector: &str,
) -> Result<String> {
    // Call the appropriate get_numeric_ste_vec_*() function
    let func_name = match value {
        10 => "get_numeric_ste_vec_10",
        20 => "get_numeric_ste_vec_20",
        30 => "get_numeric_ste_vec_30",
        42 => "get_numeric_ste_vec_42",
        _ => {
            return Err(anyhow::anyhow!(
                "Invalid value: {}. Must be 10, 20, 30, or 42",
                value
            ))
        }
    };

    // SQL equivalent: sv := get_numeric_ste_vec_30()::eql_v2_encrypted;
    //                  term := sv->'2517068c0d1f9d4d41d2c666211f785e'::text;
    let sql = format!(
        "SELECT ({}()::eql_v2_encrypted -> '{}'::text)::text",
        func_name, selector
    );

    let row = sqlx::query(&sql).fetch_one(pool).await.with_context(|| {
        format!(
            "extracting selector '{}' from ste_vec value={}",
            selector, value
        )
    })?;

    let result: Option<String> = row.try_get(0).with_context(|| {
        format!(
            "getting text column for selector '{}' from value={}",
            selector, value
        )
    })?;

    result.with_context(|| {
        format!(
            "selector extraction returned NULL for selector='{}', value={}",
            selector, value
        )
    })
}
