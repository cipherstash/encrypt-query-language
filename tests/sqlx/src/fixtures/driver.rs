//! `FixtureSpec::run()` — the generation driver.
//!
//! mise owns the containers; this owns the data. The driver opens a direct
//! Postgres connection and encrypts each plaintext value via
//! `cipherstash-client` (see the sibling `cipherstash` module) before
//! inserting the result into a transient working table. Errors are `anyhow`
//! with `.context(...)` — a generator is a developer tool; a clear crash
//! beats a partial fixture.
//!
//! The `public._fixture_<name>` working table is transient plumbing: `.run()`
//! creates it, encrypts into it, renders the committed rows from it, then
//! drops it before returning. The drop runs unconditionally once the table
//! exists — on success *and* on any returned error: `run` captures the
//! post-schema result, drops the table, and only then propagates a failure.
//! So the table never outlives a *returned* run; only a hard crash (panic /
//! `kill`) can leak it, and the next run's start-of-schema
//! `DROP TABLE IF EXISTS` reclaims that case.

use std::path::PathBuf;

use anyhow::{Context, Result};
use sqlx::postgres::PgConnectOptions;
use sqlx::{ConnectOptions, Connection, PgConnection, Row};

use super::cipherstash;
use super::eql_plaintext::EqlPlaintext;
use super::spec::FixtureSpec;

/// Bag of Rust-type bounds required of a fixture's plaintext value `T`.
/// Collapses the long `where` clause on `impl FixtureSpec<'a, T>` to a single
/// alias; the blanket impl below makes it auto-applied to any `T` that
/// already satisfies the bounds.
pub trait FixtureValue:
    EqlPlaintext
    + Clone
    + Send
    + Sync
    + for<'q> sqlx::Encode<'q, sqlx::Postgres>
    + sqlx::Type<sqlx::Postgres>
{
}

impl<T> FixtureValue for T where
    T: EqlPlaintext
        + Clone
        + Send
        + Sync
        + for<'q> sqlx::Encode<'q, sqlx::Postgres>
        + sqlx::Type<sqlx::Postgres>
{
}

/// Driver connection options, parsed once from the environment at the start
/// of `run`. Only the unmediated Postgres connection is needed: DDL,
/// inserts, and the render step all run against it. Encryption happens in
/// Rust (cipherstash-client), so there is no second connection.
struct DriverConfig {
    direct: PgConnectOptions,
}

impl DriverConfig {
    /// Build connection options from env vars, defaulting to the
    /// `mise.toml` `[env]` values. Port parses are strict — a malformed
    /// `POSTGRES_PORT` surfaces as an `anyhow::Error` with the offending
    /// value, matching the rest of the driver's error story.
    fn from_env() -> Result<Self> {
        let host = env_or("POSTGRES_HOST", "localhost");
        let user = env_or("POSTGRES_USER", "cipherstash");
        let password = env_or("POSTGRES_PASSWORD", "password");
        let database = env_or("POSTGRES_DB", "cipherstash");
        let port = parse_port_env("POSTGRES_PORT", 7432)?;

        let direct = PgConnectOptions::new()
            .host(&host)
            .port(port)
            .username(&user)
            .password(&password)
            .database(&database);

        Ok(Self { direct })
    }
}

fn env_or(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.to_string())
}

fn parse_port_env(key: &str, default: u16) -> Result<u16> {
    match std::env::var(key) {
        Ok(value) => value
            .parse::<u16>()
            .with_context(|| format!("{key}={value:?} must be a valid u16")),
        Err(_) => Ok(default),
    }
}

/// Absolute path to `tests/sqlx/fixtures/<name>.sql`. Resolved from
/// `CARGO_MANIFEST_DIR` (the `tests/sqlx` crate root) so the path is correct
/// regardless of the process working directory.
fn fixture_script_path(filename: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("fixtures")
        .join(filename)
}

impl<'a, T> FixtureSpec<'a, T>
where
    T: FixtureValue,
{
    /// Generate and write `tests/sqlx/fixtures/<name>.sql`.
    ///
    /// The production entry point. Parses the env-driven `DriverConfig`
    /// once, opens a single direct Postgres connection, runs the
    /// schema/insert/render/drop pipeline inline against that connection
    /// (no second connection needed — encryption happens in Rust via
    /// cipherstash-client), then composes the rendered INSERT lines with
    /// `fixture_script_preamble` and writes the committed script to disk.
    ///
    /// The pipeline mirrors the teardown contract in `run_with`: drop the
    /// working table unconditionally once it has been created, and
    /// propagate failures in causal order (insert error first).
    pub async fn run(&self) -> Result<()> {
        let config = DriverConfig::from_env()?;

        let mut direct = config
            .direct
            .clone()
            .connect()
            .await
            .context("connecting to Postgres (direct)")?;

        self.check_complete().context("invalid FixtureSpec")?;

        sqlx::raw_sql(&self.working_schema_sql())
            .execute(&mut direct)
            .await
            .context("applying working-table schema")?;

        // Insert directly on the same connection used for schema/render/drop.
        // The earlier two-connection design existed because `run_with` borrows
        // `direct` mutably across the closure call; production has no such
        // need — `insert_direct` is the only caller of cipherstash-client and
        // can hold the same `&mut direct` for its duration.
        let insert_result = self.insert_direct(&mut direct).await;
        let render_result = if insert_result.is_ok() {
            sqlx::query(&self.render_rows_sql())
                .fetch_all(&mut direct)
                .await
                .context("rendering fixture rows")
        } else {
            Ok(Vec::new())
        };

        let working = self.working_table();
        let drop_result = sqlx::raw_sql(&format!("DROP TABLE IF EXISTS public.{working};"))
            .execute(&mut direct)
            .await;

        insert_result?;
        let rows = render_result?;
        drop_result.context("dropping the working table")?;

        let lines: Vec<String> = rows
            .iter()
            .map(|r| r.try_get::<String, _>(0).context("reading rendered INSERT"))
            .collect::<Result<_>>()?;

        let _ = direct.close().await;

        let mut script = self.fixture_script_preamble();
        for line in &lines {
            script.push_str(line);
            script.push('\n');
        }

        let path = fixture_script_path(&self.script_filename());
        std::fs::write(&path, script)
            .with_context(|| format!("writing fixture script {}", path.display()))?;
        println!("wrote {} ({} rows)", path.display(), self.values().len());
        Ok(())
    }

    /// Encrypt every plaintext value via cipherstash-client in **one
    /// batched call**, then INSERT each ciphertext into the working
    /// table as plain JSONB. The committed `ColumnConfig` is built once
    /// from the spec's indexes + cast — the fixture name is fed as the
    /// table identifier so the resulting payload's `i.t` field matches
    /// the working table, preserving the shape Proxy used to emit.
    ///
    /// Batching means one ZeroKMS round trip per fixture run regardless
    /// of value count; the INSERT loop is per-row because the working
    /// table is local Postgres and the per-row execute cost is in
    /// microseconds.
    async fn insert_direct(&self, direct: &mut PgConnection) -> Result<()> {
        let config = cipherstash::column_config_for(self.indexes(), T::CAST)
            .context("building ColumnConfig from FixtureSpec indexes")?;

        let working = self.working_table();
        let payloads = cipherstash::encrypt_store(
            &working,
            cipherstash::PAYLOAD_COLUMN,
            self.values(),
            &config,
        )
        .await
        .context("encrypting fixture values")?;

        let insert = format!(
            "INSERT INTO public.{working} (id, plaintext, {col}) VALUES ($1, $2, $3)",
            col = cipherstash::PAYLOAD_COLUMN
        );
        for (i, (value, payload)) in self.values().iter().zip(payloads).enumerate() {
            let id = (i as i64) + 1;
            sqlx::query(&insert)
                .bind(id)
                .bind(value.clone())
                .bind(sqlx::types::Json(payload))
                .execute(&mut *direct)
                .await
                .with_context(|| format!("inserting value #{id}"))?;
        }
        Ok(())
    }

    /// **Test seam** for the schema-apply / insert / render / teardown
    /// pipeline. Production code uses `run()`, which inlines the same
    /// pipeline on a single connection. This entry point exists so tests
    /// can plug in arbitrary insert behavior (hand-crafted JSONB,
    /// deliberate failures) without going through cipherstash-client.
    /// Gated behind `#[cfg(test)]` so it is never linked into a
    /// production build.
    ///
    /// Pipeline:
    /// 1. Check the spec is complete.
    /// 2. Apply `working_schema_sql` on `direct`. After this succeeds the
    ///    `public._fixture_<name>` table exists and MUST be dropped before
    ///    return, whatever happens next.
    /// 3. Run `insert_rows()`. Its result is captured (not
    ///    `?`-propagated) so the drop in step 5 always runs.
    /// 4. If the inserter succeeded, render the committed rows via
    ///    `render_rows_sql` on `direct`. Skipped on inserter error.
    /// 5. Drop the working table on `direct` unconditionally.
    /// 6. Propagate failures in causal order: inserter error first
    ///    (root cause), then render, then drop.
    ///
    /// The closure has no `&mut PgConnection` parameter because the
    /// caller (a test) closes over its own pool / connection — the
    /// production path's single-connection invariant is enforced inside
    /// `run`, not here.
    ///
    /// Private by design: this is a test seam, not a public API.
    #[cfg(test)]
    async fn run_with<F, Fut>(
        &self,
        direct: &mut PgConnection,
        insert_rows: F,
    ) -> Result<Vec<String>>
    where
        F: FnOnce() -> Fut + Send,
        Fut: std::future::Future<Output = Result<()>> + Send,
    {
        self.check_complete().context("invalid FixtureSpec")?;

        sqlx::raw_sql(&self.working_schema_sql())
            .execute(&mut *direct)
            .await
            .context("applying working-table schema")?;

        let insert_result = insert_rows().await;
        let render_result = if insert_result.is_ok() {
            sqlx::query(&self.render_rows_sql())
                .fetch_all(&mut *direct)
                .await
                .context("rendering fixture rows")
        } else {
            // Empty placeholder — never observed; `insert_result?` below short-circuits.
            Ok(Vec::new())
        };

        let working = self.working_table();
        let drop_result = sqlx::raw_sql(&format!("DROP TABLE IF EXISTS public.{working};"))
            .execute(&mut *direct)
            .await;

        insert_result?;
        let rows = render_result?;
        drop_result.context("dropping the working table")?;

        rows.iter()
            .map(|r| r.try_get::<String, _>(0).context("reading rendered INSERT"))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::PgPool;

    /// A small int4 spec for driver tests. Three values keeps the test fast;
    /// the driver's orchestration is independent of value count.
    fn small_spec(name: &'static str) -> FixtureSpec<'static, i32> {
        use super::super::index_kind::IndexKind;
        const VALUES: &[i32] = &[-1, 1, 42];
        FixtureSpec::new(name)
            .with_index(IndexKind::Unique)
            .with_index(IndexKind::Ore)
            .with_column_type("jsonb")
            .with_values(VALUES)
    }

    #[sqlx::test]
    async fn run_with_renders_committed_rows_and_drops_working_table(pool: PgPool) -> Result<()> {
        let spec = small_spec("driver_test_a");
        let working = spec.working_table();
        let working_for_closure = working.clone();
        let pool_for_closure = pool.clone();

        let mut conn = pool.acquire().await?;

        // `run_with` is the test seam; it borrows `&mut conn` for the
        // schema/render/drop steps, so a test that wants to insert via
        // sqlx must close over its own connection — exactly the
        // two-connection shape production (`run`) was rewritten to
        // avoid. Tests pay this cost so production doesn't have to.
        let lines = spec
            .run_with(&mut conn, move || async move {
                let mut c = pool_for_closure.acquire().await?;
                let exists: Option<String> = sqlx::query_scalar(&format!(
                    "SELECT to_regclass('public.{working_for_closure}')::text"
                ))
                .fetch_one(&mut *c)
                .await?;
                assert!(
                    exists.is_some(),
                    "working table should exist inside the closure"
                );

                for (i, value) in [-1i32, 1, 42].iter().enumerate() {
                    let id = (i as i64) + 1;
                    let insert = format!(
                        "INSERT INTO public.{working_for_closure} \
                         (id, plaintext, payload) \
                         VALUES ($1, $2, $3::jsonb)"
                    );
                    sqlx::query(&insert)
                        .bind(id)
                        .bind(*value)
                        .bind(
                            r#"{"v":2,"c":"x","i":{"t":"_fixture_driver_test_a","c":"payload"},"hm":"x","ob":["1"]}"#,
                        )
                        .execute(&mut *c)
                        .await?;
                }
                Ok(())
            })
            .await?;

        assert_eq!(lines.len(), 3, "one rendered INSERT per inserted row");
        for line in &lines {
            assert!(
                line.starts_with(
                    "INSERT INTO fixtures.driver_test_a (id, plaintext, payload) VALUES ("
                ),
                "rendered line should target the committed table: {line}"
            );
        }

        let after: Option<String> =
            sqlx::query_scalar(&format!("SELECT to_regclass('public.{working}')::text"))
                .fetch_one(&pool)
                .await?;
        assert!(
            after.is_none(),
            "working table should be dropped after run_with returns"
        );

        Ok(())
    }

    #[sqlx::test]
    async fn run_with_drops_working_table_on_inserter_error(pool: PgPool) -> Result<()> {
        let spec = small_spec("driver_test_b");
        let working = spec.working_table();

        let mut conn = pool.acquire().await?;

        let result = spec
            .run_with(&mut conn, || async {
                anyhow::bail!("forced failure for test")
            })
            .await;

        assert!(
            result.is_err(),
            "run_with should propagate the inserter error"
        );
        let err_msg = format!("{:#}", result.unwrap_err());
        assert!(
            err_msg.contains("forced failure for test"),
            "error chain should contain the forced failure: {err_msg}"
        );

        let after: Option<String> =
            sqlx::query_scalar(&format!("SELECT to_regclass('public.{working}')::text"))
                .fetch_one(&pool)
                .await?;
        assert!(
            after.is_none(),
            "working table should be dropped even on inserter error"
        );

        Ok(())
    }
}
