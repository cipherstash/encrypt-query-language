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
--! Returns `hashtext` of the root payload's `hm` term. This is the canonical
--! bucket for equality groups, since `=` on `eql_v2_encrypted` reduces to
--! `hmac_256(a) = hmac_256(b)` post-#193.
--!
--! @par Contract
--! Callers using `GROUP BY` / `DISTINCT` / hash joins on `eql_v2_encrypted`
--! MUST configure the column with a `unique` index so the crypto layer
--! emits `hm` — `hm` is assumed present. A missing `hm` is a misconfiguration
--! that surfaces upstream via [U-002](docs/upgrading/v2.3.md#u-002-equality-and-hashing-require-hmac).
--!
--! @param val eql_v2_encrypted Encrypted value to hash
--! @return integer 32-bit hash value derived from `hm`
--!
--! @note For grouping a value extracted from an encrypted JSON document, use
--!       the field-level recipe directly: `GROUP BY eql_v2.eq_term(col -> '<selector>')`
--!       (covers both hm-bearing and oc-bearing selectors via the XOR-aware
--!       extractor — see `src/ste_vec/eq_term.sql`). That bypasses
--!       `hash_encrypted` entirely.
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
