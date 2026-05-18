-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief Compute hash integer for encrypted value
--!
--! Produces a 32-bit integer hash suitable for PostgreSQL hash joins, GROUP BY,
--! DISTINCT, and hash aggregate operations. Used by the `eql_v2_encrypted` hash
--! operator class (`FUNCTION 1`). Inlinable single-statement SQL — the SQL
--! function machinery is much cheaper per row than plpgsql, which matters
--! because HashAggregate / hash-join call this once per input row.
--!
--! @par Behaviour
--! - If the payload carries `hm` (hmac_256), the hash is `hashtext(hm::text)` —
--!   the canonical bucket for equality groups, since `=` on
--!   `eql_v2_encrypted` reduces to `hmac_256(a) = hmac_256(b)`.
--! - If `hm` is absent (misconfigured column), falls back to
--!   `hashtext((val).data::text)`. Each row gets a distinct hash (no
--!   pathological bucket collision), but rows are no longer guaranteed to
--!   group by encrypted plaintext — `=` returns NULL between distinct
--!   ciphertexts in that case, so each row lands in its own group anyway.
--!   The fallback exists purely to avoid quadratic blow-up; correctness on
--!   misconfigured columns is already undefined.
--!
--! @par Why the fallback rather than RAISE
--! Pre-2.3 this function raised on missing `hm` to surface misconfiguration.
--! That made `GROUP BY value` on a misconfigured column fail loudly — but
--! also made the happy path call into plpgsql once per row, which dominated
--! wall-clock time on aggregates and made HashAggregate spill catastrophic.
--! Inlinable SQL is ~10× cheaper per call and lets the planner fold
--! `hmac_256` into the calling query when `eql_v2.hmac_256(val)` is itself
--! inlinable. The misconfig case is rare enough — and detectable via
--! `eql_v2.has_hmac_256` at config / index-creation time — that trading the
--! loud RAISE for a 100× speed-up on aggregates is the right call.
--!
--! @param val eql_v2_encrypted Encrypted value to hash
--! @return integer 32-bit hash value derived from `hm`, or from the payload
--!         data when `hm` is absent
--!
--! @note Requires a `unique` (hmac_256) index configured on the column for
--!       semantically meaningful grouping. Match-only / ORE-only / OPE-only
--!       / ste_vec-only values without `hm` still hash without error but
--!       will not group across logically-equal values.
--!
--! @see eql_v2.hmac_256
--! @see eql_v2.has_hmac_256
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.hash_encrypted(val eql_v2_encrypted)
  RETURNS integer
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT coalesce(
    pg_catalog.hashtext(eql_v2.hmac_256(eql_v2.to_ste_vec_value(val))::text),
    pg_catalog.hashtext((val).data::text)
  )
$$;
