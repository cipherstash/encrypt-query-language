//! Shared helpers + test-stamping macro for the per-type `<T>_ord_ope`
//! literal-payload smoke suites (one top-level module per ordered scalar, so
//! the `test:matrix:catalog-coverage` gate's `<t>_<seg>::*` pattern sees every
//! catalog `ord_ope` domain covered).
//!
//! The CLLW-OPE term (`op`) is a hex-encoded ciphertext that is
//! order-preserving under native bytea comparison, so ordering assertions can
//! be stated directly on hand-built hex strings — deterministic, no
//! encryption/fixtures needed (the pinned cipherstash-client does not emit
//! `op` yet, so there is no generated fixture to lean on).

/// Literal cast expression for an `eql_v3.<domain>` payload carrying BOTH the
/// exact-equality term `hm` and the CLLW-OPE hex term `op`. Domain CHECKs
/// assert key *presence*, not absence of extras, so one builder serves both
/// the `[Ope]` integer-family domains (which ignore `hm`) and text's
/// `[Hm, Ope]` (which requires it).
pub fn ope_cast(domain: &str, hm: &str, op_hex: &str) -> String {
    format!(
        "'{{\"v\":3,\"i\":{{}},\"c\":\"x\",\"hm\":\"{hm}\",\"op\":\"{op_hex}\"}}'::jsonb::eql_v3.{domain}"
    )
}

/// Stamp the shared `_ord_ope` smoke tests for one domain. The assertions are
/// routing-agnostic: ordering pairs differ in BOTH `hm` and `op` (so they hold
/// whether `<` routes through `op` — every type — and whether `=`/`<>` route
/// through `op` (integer families) or `hm` (text)); the inequality case
/// differs in both terms for the same reason. Type-specific behaviour (text's
/// hm-routed equality, blockers, ORDER BY, aggregates) lives in the per-type
/// module files next to the macro invocation.
#[macro_export]
macro_rules! ope_ord_smoke {
    ($domain:literal) => {
        use sqlx::PgPool;

        #[sqlx::test]
        async fn ord_ope_orders_by_decoded_bytes(pool: PgPool) -> anyhow::Result<()> {
            // Native bytea order over the decoded hex: 0x00ff < 0x0100 (a
            // hex-STRING comparison would also say so; 0x02 < 0x0100 would not
            // — the pairs below fail if comparison ever degrades to text order
            // over the hex).
            for (lo, hi) in [("00ff", "0100"), ("00", "0100"), ("0a", "ff")] {
                let lt: bool = sqlx::query_scalar(&format!(
                    "SELECT ({}) < ({})",
                    crate::ope_support::ope_cast($domain, "aa", lo),
                    crate::ope_support::ope_cast($domain, "bb", hi)
                ))
                .fetch_one(&pool)
                .await?;
                assert!(lt, "{}: op {lo} must sort before op {hi}", $domain);

                let gt: bool = sqlx::query_scalar(&format!(
                    "SELECT ({}) > ({})",
                    crate::ope_support::ope_cast($domain, "aa", hi),
                    crate::ope_support::ope_cast($domain, "bb", lo)
                ))
                .fetch_one(&pool)
                .await?;
                assert!(gt, "{}: op {hi} must sort after op {lo}", $domain);
            }
            Ok(())
        }

        #[sqlx::test]
        async fn ord_ope_equality_and_inequality(pool: PgPool) -> anyhow::Result<()> {
            // Identical payloads compare equal under either routing (`op` for
            // the integer families, `hm` for text).
            let eq: bool = sqlx::query_scalar(&format!(
                "SELECT ({}) = ({})",
                crate::ope_support::ope_cast($domain, "aa", "00ffab"),
                crate::ope_support::ope_cast($domain, "aa", "00ffab")
            ))
            .fetch_one(&pool)
            .await?;
            assert!(eq, "{}: identical payloads must compare equal", $domain);

            // Differ in BOTH terms => not-equal under either routing.
            let neq: bool = sqlx::query_scalar(&format!(
                "SELECT ({}) <> ({})",
                crate::ope_support::ope_cast($domain, "aa", "00ffab"),
                crate::ope_support::ope_cast($domain, "bb", "00ffac")
            ))
            .fetch_one(&pool)
            .await?;
            assert!(
                neq,
                "{}: differing payloads must compare not-equal",
                $domain
            );
            Ok(())
        }

        #[sqlx::test]
        async fn ord_ope_check_requires_op(pool: PgPool) -> anyhow::Result<()> {
            // The domain CHECK requires the `op` key; a payload with only the
            // envelope + hm fails at the cast boundary (hm is present, so for
            // text the sole missing key is `op` too).
            let err = sqlx::query(&format!(
                "SELECT '{{\"v\":3,\"i\":{{}},\"c\":\"x\",\"hm\":\"aa\"}}'::jsonb::eql_v3.{}",
                $domain
            ))
            .execute(&pool)
            .await
            .unwrap_err();
            assert!(
                format!("{err}").contains("check constraint"),
                "{}: missing op must violate the domain CHECK, got: {err}",
                $domain
            );
            Ok(())
        }
    };
}
