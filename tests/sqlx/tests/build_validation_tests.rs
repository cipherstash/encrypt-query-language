//! Build output validation tests
//!
//! Validates that build variants contain/exclude the expected components.
//! These tests run against the built SQL files, not the database.

use std::fs;
use std::path::Path;

/// Helper to read a release SQL file
fn read_release_sql(filename: &str) -> String {
    let path = format!("../../release/{}", filename);
    fs::read_to_string(&path).unwrap_or_else(|_| panic!("Failed to read {}", path))
}

// =============================================================================
// Protect Variant Tests
// =============================================================================

#[test]
fn protect_variant_file_exists() {
    assert!(
        Path::new("../../release/cipherstash-encrypt-protect.sql").exists(),
        "protect variant installer should exist"
    );
}

#[test]
fn protect_uninstaller_exists() {
    assert!(
        Path::new("../../release/cipherstash-encrypt-protect-uninstall.sql").exists(),
        "protect variant uninstaller should exist"
    );
}

#[test]
fn protect_variant_excludes_config_table() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("CREATE TABLE") || !sql.contains("eql_v2_configuration"),
        "protect variant should not contain eql_v2_configuration table"
    );
}

#[test]
fn protect_variant_excludes_config_state_type() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("eql_v2_configuration_state"),
        "protect variant should not contain eql_v2_configuration_state enum"
    );
}

#[test]
fn protect_variant_excludes_add_search_config() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("CREATE FUNCTION eql_v2.add_search_config")
            && !sql.contains("CREATE OR REPLACE FUNCTION eql_v2.add_search_config"),
        "protect variant should not contain add_search_config function"
    );
}

#[test]
fn protect_variant_excludes_add_column() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("CREATE FUNCTION eql_v2.add_column")
            && !sql.contains("CREATE OR REPLACE FUNCTION eql_v2.add_column"),
        "protect variant should not contain add_column function"
    );
}

#[test]
fn protect_variant_excludes_migrate_config() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("CREATE FUNCTION eql_v2.migrate_config")
            && !sql.contains("CREATE OR REPLACE FUNCTION eql_v2.migrate_config"),
        "protect variant should not contain migrate_config function"
    );
}

#[test]
fn protect_variant_excludes_create_encrypted_columns() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("CREATE FUNCTION eql_v2.create_encrypted_columns")
            && !sql.contains("CREATE OR REPLACE FUNCTION eql_v2.create_encrypted_columns"),
        "protect variant should not contain create_encrypted_columns function"
    );
}

#[test]
fn protect_variant_excludes_diff_config() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        !sql.contains("CREATE FUNCTION eql_v2.diff_config")
            && !sql.contains("CREATE OR REPLACE FUNCTION eql_v2.diff_config"),
        "protect variant should not contain diff_config function"
    );
}

#[test]
fn protect_variant_includes_core_encrypted_type() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        sql.contains("eql_v2_encrypted"),
        "protect variant should contain eql_v2_encrypted type"
    );
}

#[test]
fn protect_variant_includes_operators() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        sql.contains("CREATE OPERATOR"),
        "protect variant should contain operators"
    );
}

#[test]
fn protect_variant_includes_hmac_256() {
    let sql = read_release_sql("cipherstash-encrypt-protect.sql");
    assert!(
        sql.contains("eql_v2.hmac_256"),
        "protect variant should contain hmac_256 index type"
    );
}

#[test]
fn protect_variant_is_smaller_than_full() {
    let protect = read_release_sql("cipherstash-encrypt-protect.sql");
    let full = read_release_sql("cipherstash-encrypt.sql");
    assert!(
        protect.len() < full.len(),
        "protect variant ({} bytes) should be smaller than full variant ({} bytes)",
        protect.len(),
        full.len()
    );
}

// =============================================================================
// v3-only Variant Tests (design D9/D11 — self-contained eql_v3 surface)
// =============================================================================

#[test]
fn v3_variant_file_exists() {
    assert!(
        Path::new("../../release/cipherstash-encrypt-v3.sql").exists(),
        "v3-only variant installer should exist"
    );
}

#[test]
fn v3_uninstaller_exists() {
    assert!(
        Path::new("../../release/cipherstash-encrypt-v3-uninstall.sql").exists(),
        "v3-only variant uninstaller should exist"
    );
}

#[test]
fn v3_variant_creates_eql_v3_schema() {
    let sql = read_release_sql("cipherstash-encrypt-v3.sql");
    assert!(
        sql.contains("CREATE SCHEMA eql_v3"),
        "v3 variant must create the eql_v3 schema"
    );
}

#[test]
fn v3_variant_has_no_eql_v2_symbol() {
    let sql = read_release_sql("cipherstash-encrypt-v3.sql");
    // Reject both schema-qualified refs (`eql_v2.<fn>`) and bare v2 entity names
    // (`eql_v2_encrypted`, `eql_v2_configuration`, …). Prose mentions like
    // "the eql_v2 original is unchanged" in doc comments are still allowed.
    assert!(
        !sql.contains("eql_v2.") && !sql.contains("eql_v2_"),
        "v3 variant must be self-contained (no eql_v2.<symbol> or eql_v2_<entity> reference)"
    );
}

#[test]
fn v3_variant_omits_v2_coupled_pin_search_path() {
    // D11: the v3 artifact must NOT append tasks/pin_search_path.sql, which is
    // eql_v2-coupled (it references public.eql_v2_encrypted / eql_v2.ste_vec_entry
    // and only pins eql_v2 functions). Match the eql_v2-QUALIFIED markers: a bare
    // `ste_vec_entry` substring would false-positive on the legitimate
    // `eql_v3.ste_vec_entry` DOMAIN that the v3 jsonb document surface defines.
    let sql = read_release_sql("cipherstash-encrypt-v3.sql");
    assert!(
        !sql.contains("eql_v2.ste_vec_entry") && !sql.contains("eql_v2_encrypted"),
        "v3 variant must not carry the eql_v2-coupled pin_search_path script"
    );
}
