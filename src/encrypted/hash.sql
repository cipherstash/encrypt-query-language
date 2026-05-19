-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql

--! @brief Compute hash integer for encrypted value
--!
--! Produces a 32-bit integer hash suitable for PostgreSQL hash joins, GROUP BY,
--! DISTINCT, and hash aggregate operations. Used by the `eql_v2_encrypted` hash
--! operator class (`FUNCTION 1`). Inlinable single-statement SQL — the SQL
--! function machinery is much cheaper per row than plpgsql, which matters
--! because HashAggregate / hash-join call this once per input row.
--!
--! Returns `hashtext(hm::text)` of the root payload's `hm` term. This is the
--! canonical bucket for equality groups, since `=` on `eql_v2_encrypted`
--! reduces to `hmac_256(a) = hmac_256(b)` post-#193.
--!
--! @par Contract
--! Equality on `eql_v2_encrypted` is hm-only at the root ([U-002]). Callers
--! using `GROUP BY` / `DISTINCT` / hash joins on this type MUST configure
--! the column with a `unique` index (so the crypto layer emits `hm`); a
--! missing `hm` is a misconfiguration. With `hm` absent, `eql_v2.hmac_256(val)`
--! returns NULL, `hashtext(NULL)` returns NULL, and the hash opclass support
--! function returns NULL — Postgres surfaces this as a clear function-result
--! error at the hash machinery boundary.
--!
--! @param val eql_v2_encrypted Encrypted value to hash
--! @return integer 32-bit hash value derived from `hm`
--!
--! @note For grouping a value extracted from an encrypted JSON document, use
--!       the field-level recipe directly: `GROUP BY eql_v2.hmac_256(col, '<selector>')`
--!       (or, post-#219, `GROUP BY eql_v2.hmac_256((col -> '<selector>').data::eql_v2.ste_vec_entry)`).
--!       Those bypass `hash_encrypted` entirely.
--!
--! @see eql_v2.hmac_256
--! @see eql_v2.has_hmac_256
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.hash_encrypted(val eql_v2_encrypted)
  RETURNS integer
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT pg_catalog.hashtext(eql_v2.hmac_256(val)::text)
$$;
