-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/blake3/types.sql
-- REQUIRE: src/blake3/functions.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief Compute hash integer for encrypted value
--!
--! Produces a 32-bit integer hash suitable for PostgreSQL hash joins, GROUP BY,
--! DISTINCT, and hash aggregate operations. Uses deterministic index terms
--! (HMAC-256 or Blake3) to ensure consistency with the equality operator:
--! if a = b then hash(a) = hash(b).
--!
--! @param val eql_v2_encrypted Encrypted value to hash
--! @return integer 32-bit hash value derived from HMAC-256 or Blake3 index term
--!
--! @throws Exception if no HMAC-256 or Blake3 index term is present
--!
--! @note Requires a unique (hmac_256) or match (blake3) index configured on the column
--! @note ORE-only values cannot be hashed (ORE ciphertext is not deterministic)
--!
--! @see eql_v2.hmac_256
--! @see eql_v2.blake3
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.hash_encrypted(val eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
  ste_val eql_v2_encrypted;
BEGIN
  ste_val := eql_v2.to_ste_vec_value(val);

  IF eql_v2.has_hmac_256(ste_val) THEN
    RETURN hashtext(eql_v2.hmac_256(ste_val)::text);
  END IF;

  IF eql_v2.has_blake3(ste_val) THEN
    RETURN hashtext(eql_v2.blake3(ste_val)::text);
  END IF;

  RAISE EXCEPTION 'Cannot hash eql_v2_encrypted value: no hmac_256 or blake3 index term found. Configure a unique or match index for hash operations (GROUP BY, DISTINCT, hash joins).';
END;
$$ LANGUAGE plpgsql;
