//! Privilege/exposure gate for the `eql_v3` / `eql_v3_internal` split.
//!
//! The installer grants nothing automatically: a runtime role gets access only
//! via explicit `GRANT`. README "Database Permissions" documents that a runtime
//! (query) role needs USAGE + EXECUTE on BOTH `eql_v3` and `eql_v3_internal` —
//! the public operators/extractors dispatch into `eql_v3_internal`, so granting
//! only the public schema is not enough. This contract used to live in prose
//! (`docs/upgrading/v3.0.md`); these tests make it executable.
//!
//! The `#[sqlx::test]` harness runs as a cluster superuser, so it can
//! `CREATE ROLE` / `SET ROLE`. Roles are cluster-global (not per-database), so
//! each test derives a unique role name from its isolated database name and
//! drops it on the way out to stay parallel-safe and leak-free.

use anyhow::Result;
use sqlx::{PgPool, Row};

/// A real equality query (`=` on `int4_eq`) over the committed fixture. The `=`
/// operator lives in `public` but is backed by `eql_v3_internal.eq`, and the
/// cast references the `eql_v3.int4_eq` domain — so it exercises BOTH schemas.
const EQ_QUERY: &str = "SELECT count(*) FROM fixtures.eql_v3_int4 \
     WHERE payload::eql_v3.int4_eq = payload::eql_v3.int4_eq";

/// A real ordering query (`<` on `int4_ord`, via the ORE comparator in
/// `eql_v3_internal`). `ORDER BY` a domain-cast column dispatches into the
/// internal comparator wrapper.
const ORD_QUERY: &str = "SELECT id FROM fixtures.eql_v3_int4 \
     ORDER BY payload::eql_v3.int4_ord LIMIT 1";

/// Derive a unique, valid role name from the per-test database name so parallel
/// tests (and reruns) never collide on the cluster-global role namespace.
async fn unique_role(conn: &mut sqlx::PgConnection) -> Result<String> {
    let db: String = sqlx::query_scalar("SELECT current_database()")
        .fetch_one(&mut *conn)
        .await?;
    // db names are `_sqlx_test_<rand>`; keep them identifier-safe.
    let suffix: String = db
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || *c == '_')
        .collect();
    Ok(format!("eqlpriv_{suffix}"))
}

/// Grant the common, non-EQL-schema prerequisites a runtime role always needs:
/// read the fixture table. (USAGE on `public` is granted to PUBLIC by default,
/// which is where the domain operators live.)
async fn grant_fixture_access(conn: &mut sqlx::PgConnection, role: &str) -> Result<()> {
    for stmt in [
        format!("GRANT USAGE ON SCHEMA fixtures TO \"{role}\""),
        format!("GRANT SELECT ON fixtures.eql_v3_int4 TO \"{role}\""),
    ] {
        sqlx::query(&stmt).execute(&mut *conn).await?;
    }
    Ok(())
}

/// Positive: a runtime role granted USAGE + EXECUTE on BOTH schemas (exactly the
/// README recipe) can run the documented equality and ordering query paths.
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v3_int4")))]
async fn runtime_role_with_both_schema_grants_can_query(pool: PgPool) -> Result<()> {
    // A single connection for the whole test: SET ROLE is connection-scoped.
    let mut conn = pool.acquire().await?;
    let role = unique_role(&mut conn).await?;
    sqlx::query(&format!("DROP ROLE IF EXISTS \"{role}\""))
        .execute(&mut *conn)
        .await?;
    sqlx::query(&format!("CREATE ROLE \"{role}\" NOSUPERUSER NOLOGIN"))
        .execute(&mut *conn)
        .await?;

    grant_fixture_access(&mut conn, &role).await?;
    for schema in ["eql_v3", "eql_v3_internal"] {
        sqlx::query(&format!("GRANT USAGE ON SCHEMA {schema} TO \"{role}\""))
            .execute(&mut *conn)
            .await?;
        sqlx::query(&format!(
            "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA {schema} TO \"{role}\""
        ))
        .execute(&mut *conn)
        .await?;
    }

    sqlx::query(&format!("SET ROLE \"{role}\""))
        .execute(&mut *conn)
        .await?;

    let eq_count: i64 = sqlx::query_scalar(EQ_QUERY).fetch_one(&mut *conn).await?;
    assert_eq!(
        eq_count, 17,
        "equality query should match all 17 fixture rows under the runtime role"
    );

    let top_id: i64 = sqlx::query(ORD_QUERY)
        .fetch_one(&mut *conn)
        .await?
        .get::<i64, _>("id");
    assert!(
        top_id > 0,
        "ordering query should return a row under the runtime role"
    );

    sqlx::query("RESET ROLE").execute(&mut *conn).await?;
    sqlx::query(&format!("DROP ROLE IF EXISTS \"{role}\""))
        .execute(&mut *conn)
        .await?;
    Ok(())
}

/// Negative: a runtime role granted the PUBLIC schema (`eql_v3`) but NOT
/// `eql_v3_internal` cannot run the query paths — the operators/extractors
/// dispatch into `eql_v3_internal`, so a missing internal grant raises
/// `insufficient_privilege` (42501). Pins *why* the README requires the internal
/// grant: `eql_v3` alone is not enough.
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v3_int4")))]
async fn runtime_role_without_internal_grant_is_denied(pool: PgPool) -> Result<()> {
    let mut conn = pool.acquire().await?;
    let role = unique_role(&mut conn).await?;
    sqlx::query(&format!("DROP ROLE IF EXISTS \"{role}\""))
        .execute(&mut *conn)
        .await?;
    sqlx::query(&format!("CREATE ROLE \"{role}\" NOSUPERUSER NOLOGIN"))
        .execute(&mut *conn)
        .await?;

    grant_fixture_access(&mut conn, &role).await?;
    // Public schema ONLY — deliberately omit eql_v3_internal.
    sqlx::query(&format!("GRANT USAGE ON SCHEMA eql_v3 TO \"{role}\""))
        .execute(&mut *conn)
        .await?;
    sqlx::query(&format!(
        "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA eql_v3 TO \"{role}\""
    ))
    .execute(&mut *conn)
    .await?;

    sqlx::query(&format!("SET ROLE \"{role}\""))
        .execute(&mut *conn)
        .await?;

    // Both query paths must be denied for lack of eql_v3_internal access.
    for query in [EQ_QUERY, ORD_QUERY] {
        let err = sqlx::query(query)
            .fetch_one(&mut *conn)
            .await
            .expect_err("query must be denied without eql_v3_internal grant");
        let db_err = err
            .as_database_error()
            .unwrap_or_else(|| panic!("expected a database error, got: {err:?}"));
        assert_eq!(
            db_err.code().as_deref(),
            Some("42501"),
            "expected insufficient_privilege (42501) referencing eql_v3_internal, got: {db_err:?}"
        );
    }

    sqlx::query("RESET ROLE").execute(&mut *conn).await?;
    sqlx::query(&format!("DROP ROLE IF EXISTS \"{role}\""))
        .execute(&mut *conn)
        .await?;
    Ok(())
}
