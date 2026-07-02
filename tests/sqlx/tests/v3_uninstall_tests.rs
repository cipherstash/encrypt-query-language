//! Uninstall-symmetry gate for the `eql_v3` / `eql_v3_internal` split.
//!
//! Clean separation includes clean teardown: the shipped uninstaller must drop
//! BOTH schemas the installer creates, leaving nothing behind. Before this test,
//! the only uninstaller coverage was a file-existence check
//! (`build_validation_tests::v3_uninstaller_exists`); nothing ran it and
//! asserted the effect.
//!
//! This runs the ACTUAL shipped artifact — `release/cipherstash-encrypt-uninstall.sql`,
//! read from disk exactly as `build_validation_tests` does. In CI the shard
//! runners get `release/*.sql` from the `nextest-archive` artifact; locally it
//! is produced by `mise run build` (which `test:sqlx:prep` runs before the
//! suite). The `#[sqlx::test]` harness has already installed both schemas via
//! the `001_install_eql.sql` migration, so this test uninstalls on top of a real
//! install and verifies the schemas are gone.

use anyhow::Result;
use sqlx::PgPool;

/// The shipped uninstaller, relative to the test crate root (`tests/sqlx`).
/// `tasks/build.sh` produces it by appending `tasks/uninstall-v3.sql` verbatim,
/// so this file IS the shipped teardown.
const UNINSTALLER: &str = "../../release/cipherstash-encrypt-uninstall.sql";

async fn schema_count(pool: &PgPool) -> Result<i64> {
    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM pg_namespace WHERE nspname IN ('eql_v3', 'eql_v3_internal')",
    )
    .fetch_one(pool)
    .await?;
    Ok(n)
}

#[sqlx::test]
async fn uninstaller_drops_both_schemas(pool: PgPool) -> Result<()> {
    // Sanity: the migration installed both schemas, so the teardown has
    // something to remove (guards against a false pass if the install changed).
    assert_eq!(
        schema_count(&pool).await?,
        2,
        "expected both eql_v3 and eql_v3_internal installed by the migration before uninstall"
    );

    let uninstall_sql = std::fs::read_to_string(UNINSTALLER).unwrap_or_else(|e| {
        panic!(
            "failed to read shipped uninstaller {UNINSTALLER}: {e} — run `mise run build` \
             (or, in CI, ensure the nextest-archive artifact shipped release/*.sql)"
        )
    });

    // The uninstaller is multiple statements (DROP SCHEMA … CASCADE, twice), so
    // it must run over the simple query protocol — `raw_sql` executes the whole
    // script, unlike `query` which prepares a single statement.
    sqlx::raw_sql(&uninstall_sql).execute(&pool).await?;

    assert_eq!(
        schema_count(&pool).await?,
        0,
        "the shipped uninstaller must drop BOTH eql_v3 and eql_v3_internal"
    );

    // CASCADE removes everything the schemas contained; assert no objects remain
    // pinned to either namespace (types, functions, and the like).
    let leftover_objects: i64 = sqlx::query_scalar(
        r#"
        SELECT
          (SELECT count(*) FROM pg_catalog.pg_type t
             JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
            WHERE n.nspname IN ('eql_v3', 'eql_v3_internal'))
        + (SELECT count(*) FROM pg_catalog.pg_proc p
             JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname IN ('eql_v3', 'eql_v3_internal'))
        "#,
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(
        leftover_objects, 0,
        "no eql_v3 / eql_v3_internal objects should survive uninstall"
    );

    Ok(())
}
