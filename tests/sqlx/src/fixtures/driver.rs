//! `FixtureSpec::run()` — the generation driver.
//!
//! mise owns the containers; this owns the data. The driver assumes
//! `mise run proxy:up` has started `cipherstash-proxy` and that the
//! generation Postgres has EQL installed. Errors are `anyhow` with
//! `.context(...)` — a generator is a developer tool; a clear crash beats a
//! partial fixture.
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
use std::process::Command;
use std::time::Duration;

use anyhow::{anyhow, Context, Result};
use sqlx::postgres::PgConnectOptions;
use sqlx::{ConnectOptions, Connection, PgConnection, Row};

use super::eql_plaintext::EqlPlaintext;
use super::spec::FixtureSpec;

/// `cipherstash-proxy` — the fixed container_name from
/// `tests/docker-compose.proxy.yml`.
const PROXY_CONTAINER: &str = "cipherstash-proxy";

/// Bag of Rust-type bounds required of a fixture's plaintext value `T`.
/// Collapses the long `where` clause on `impl FixtureSpec<'a, T>` to a single
/// alias; the blanket impl below makes it auto-applied to any `T` that
/// already satisfies the bounds.
pub trait FixtureValue:
    EqlPlaintext
    + Copy
    + Send
    + Sync
    + for<'q> sqlx::Encode<'q, sqlx::Postgres>
    + sqlx::Type<sqlx::Postgres>
{
}

impl<T> FixtureValue for T where
    T: EqlPlaintext
        + Copy
        + Send
        + Sync
        + for<'q> sqlx::Encode<'q, sqlx::Postgres>
        + sqlx::Type<sqlx::Postgres>
{
}

/// Driver connection options, parsed once from the environment at the start
/// of `run`. `direct` is the unmediated Postgres connection (DDL +
/// rendering); `proxy` is the Proxy-mediated connection (encrypted inserts).
struct DriverConfig {
    direct: PgConnectOptions,
    proxy: PgConnectOptions,
}

impl DriverConfig {
    /// Build connection options from env vars, defaulting to the
    /// `mise.toml` `[env]` values. Port parses are strict — a malformed
    /// `POSTGRES_PORT` or `PROXY_PORT` surfaces as an `anyhow::Error` with
    /// the offending value, matching the rest of the driver's error story.
    fn from_env() -> Result<Self> {
        let host = env_or("POSTGRES_HOST", "localhost");
        let user = env_or("POSTGRES_USER", "cipherstash");
        let password = env_or("POSTGRES_PASSWORD", "password");
        let database = env_or("POSTGRES_DB", "cipherstash");
        let port = parse_port_env("POSTGRES_PORT", 7432)?;
        let proxy_port = parse_port_env("PROXY_PORT", 6432)?;

        let direct = PgConnectOptions::new()
            .host(&host)
            .port(port)
            .username(&user)
            .password(&password)
            .database(&database);

        // Proxy runs on the host at PROXY_PORT (default 6432); same credentials.
        let proxy = direct.clone().port(proxy_port);

        Ok(Self { direct, proxy })
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

/// Restart Proxy (so it reloads the new encrypt config) and poll until it
/// accepts a connection. On timeout, dump `docker logs` and fail.
async fn restart_proxy_and_wait(proxy_options: &PgConnectOptions) -> Result<()> {
    let status = Command::new("docker")
        .args(["restart", PROXY_CONTAINER])
        .status()
        .context("failed to spawn `docker restart`")?;
    if !status.success() {
        anyhow::bail!("`docker restart {PROXY_CONTAINER}` exited non-zero");
    }

    for _ in 0..60 {
        if let Ok(mut conn) = proxy_options.clone().connect().await {
            if sqlx::query("SELECT 1").execute(&mut conn).await.is_ok() {
                let _ = conn.close().await;
                return Ok(());
            }
        }
        tokio::time::sleep(Duration::from_secs(1)).await;
    }

    // `docker logs` sends the container's stdout to our stdout and its stderr
    // to our stderr; capture both so the diagnostic is non-empty regardless of
    // which stream the Proxy logs to.
    let logs = Command::new("docker")
        .args(["logs", "--tail", "40", PROXY_CONTAINER])
        .output()
        .map(|o| {
            format!(
                "{}{}",
                String::from_utf8_lossy(&o.stdout),
                String::from_utf8_lossy(&o.stderr),
            )
        })
        .unwrap_or_default();
    Err(anyhow!(
        "Proxy did not become ready within 60s after restart\n\
         === {PROXY_CONTAINER} logs ===\n{logs}"
    ))
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
    /// once, opens a direct Postgres connection, then delegates the
    /// schema + teardown orchestration to `run_with`, supplying
    /// `insert_through_proxy` as the closure. After `run_with` returns the
    /// rendered INSERT lines, this method composes them with
    /// `fixture_script_preamble` and writes the committed script to disk.
    pub async fn run(&self) -> Result<()> {
        let config = DriverConfig::from_env()?;

        let mut direct = config
            .direct
            .clone()
            .connect()
            .await
            .context("connecting to Postgres (direct)")?;

        let lines = self
            .run_with(&mut direct, || self.insert_through_proxy(&config.proxy))
            .await?;

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

    /// Restart Proxy so it picks up the new `add_search_config`, then open a
    /// Proxy connection and insert each plaintext value into the working
    /// table. Proxy intercepts each insert and writes the encrypted JSONB
    /// composite into `payload`. The production insert step extracted from
    /// `run`'s closure for skim-ability.
    async fn insert_through_proxy(&self, proxy_options: &PgConnectOptions) -> Result<()> {
        restart_proxy_and_wait(proxy_options).await?;

        let mut proxy = proxy_options
            .clone()
            .connect()
            .await
            .context("connecting to Proxy")?;
        let working = self.working_table();
        for (i, value) in self.values().iter().enumerate() {
            let id = (i as i64) + 1;
            let insert =
                format!("INSERT INTO {working} (id, plaintext, payload) VALUES ($1, $2, $3)");
            sqlx::query(&insert)
                .bind(id)
                .bind(*value)
                .bind(*value)
                .execute(&mut proxy)
                .await
                .with_context(|| format!("inserting value #{id} through Proxy"))?;
        }
        let _ = proxy.close().await;
        Ok(())
    }

    /// Orchestrates the schema-apply / insert / render / teardown pipeline
    /// against a caller-supplied `direct` connection, with the insert step
    /// pluggable via `insert_rows`. The pipeline is:
    ///
    /// 1. Check the spec is complete.
    /// 2. Apply `working_schema_sql` on `direct`. After this succeeds the
    ///    `public._fixture_<name>` table exists and MUST be dropped before
    ///    return, whatever happens next.
    /// 3. Run `insert_rows()`. Its result is captured (not `?`-propagated)
    ///    so the drop in step 5 always runs.
    /// 4. If the inserter succeeded, render the committed rows via
    ///    `render_rows_sql` on `direct`. Skipped on inserter error.
    /// 5. Drop the working table on `direct` unconditionally.
    /// 6. Propagate failures in causal order: inserter error first
    ///    (root cause), then render, then drop.
    ///
    /// `run()` calls this with `insert_through_proxy`. Tests call it with
    /// closures that insert hand-crafted `eql_v2_encrypted` composite
    /// literals directly (no Proxy required), or with closures that return
    /// `Err` to exercise the teardown contract.
    ///
    /// Private by design: this is a test seam, not a public API. Other
    /// fixtures must go through `run`.
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
        const VALUES: &[i32] = &[-1, 1, 42];
        FixtureSpec::new(name)
            .with_index("unique")
            .with_index("ore")
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

        let lines = spec
            .run_with(&mut *conn, move || async move {
                // Working table should exist while the closure runs.
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
                         VALUES ($1, $2, ROW($3::jsonb)::public.eql_v2_encrypted)"
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
            .run_with(&mut *conn, || async {
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
