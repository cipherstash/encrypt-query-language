use eql_tests::reset_function_stats;
use sqlx::PgPool;

#[sqlx::test]
async fn test_reset_function_stats(pool: PgPool) {
    // Verify function tracking is enabled
    let tracking_enabled = sqlx::query_scalar::<_, String>("SHOW track_functions")
        .fetch_one(&pool)
        .await
        .expect("Failed to check track_functions setting");

    assert_eq!(
        tracking_enabled, "all",
        "track_functions should be set to 'all'"
    );

    // Test: Call reset_function_stats and verify it completes without error
    reset_function_stats(&pool)
        .await
        .expect("reset_function_stats should complete without error");

    // The function wraps pg_stat_reset() which is a PostgreSQL built-in.
    // We've verified:
    // 1. The function compiles and can be called
    // 2. It doesn't return an error
    // 3. Function tracking is enabled in PostgreSQL
    //
    // The actual behavior of pg_stat_reset() is tested by PostgreSQL itself.
    // Testing asynchronous stats collection is complex and timing-dependent,
    // so we focus on verifying the wrapper works correctly.
}
