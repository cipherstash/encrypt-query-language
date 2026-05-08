-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief Compute hash integer for encrypted value
--!
--! Produces a 32-bit integer hash suitable for PostgreSQL hash joins, GROUP BY,
--! DISTINCT, and hash aggregate operations. Uses the HMAC-256 index term to
--! stay consistent with the equality operator: if a = b then hash(a) = hash(b).
--! The `=` operator on eql_v2_encrypted reduces to hmac_256(a) = hmac_256(b),
--! so the hash function must derive from hmac_256 as well — see the EQL
--! payload scheme discipline RFC for the single-term-per-purpose contract.
--!
--! @param val eql_v2_encrypted Encrypted value to hash
--! @return integer 32-bit hash value derived from the HMAC-256 index term
--!
--! @throws Exception if no HMAC-256 index term is present
--!
--! @note Requires a `unique` (hmac_256) index configured on the column.
--!       Match-only / ORE-only / OPE-only / ste_vec-only values cannot be
--!       hashed at the root.
--!
--! @see eql_v2.hmac_256
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.hash_encrypted(val eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
  ste_val eql_v2_encrypted;
BEGIN
  ste_val := eql_v2.to_ste_vec_value(val);

  IF eql_v2.has_hmac_256(ste_val) THEN
    RETURN hashtext(eql_v2.hmac_256(ste_val)::text);
  END IF;

  RAISE EXCEPTION 'Cannot hash eql_v2_encrypted value: no hmac_256 index term found. Configure a `unique` index on the column for hash operations (GROUP BY, DISTINCT, hash joins).';
END;
$$ LANGUAGE plpgsql;
