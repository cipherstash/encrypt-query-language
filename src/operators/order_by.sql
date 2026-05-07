-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql
-- REQUIRE: src/ope_cllw_u64_65/types.sql
-- REQUIRE: src/ope_cllw_u64_65/functions.sql
-- REQUIRE: src/ope_cllw_var_8/types.sql
-- REQUIRE: src/ope_cllw_var_8/functions.sql

--! @brief Extract ORE index term for ordering encrypted values
--!
--! Helper function that extracts the ore_block_u64_8_256 index term from an encrypted value
--! for use in ORDER BY clauses when comparison operators are not appropriate or available.
--!
--! @param eql_v2_encrypted Encrypted value to extract order term from
--! @return eql_v2.ore_block_u64_8_256 ORE index term for ordering
--!
--! @example
--! -- Order encrypted values without using comparison operators
--! SELECT * FROM users ORDER BY eql_v2.order_by(encrypted_age);
--!
--! @note Requires 'ore' index configuration on the column
--! @see eql_v2.ore_block_u64_8_256
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.order_by(a eql_v2_encrypted)
  RETURNS eql_v2.ore_block_u64_8_256
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.ore_block_u64_8_256(a);
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract OPE ciphertext bytes for ordering encrypted values
--!
--! Returns the raw CLWW Order-Preserving Encryption ciphertext as `bytea` so
--! it can be used as an order key. OPE ciphertexts compare with standard
--! lexicographic byte ordering, so the returned bytea can be ordered directly
--! with `<`, `=`, `>` (no custom protocol required).
--!
--! Prefers the fixed-width variant (`opf`, ope_cllw_u64_65) when present and
--! falls back to the variable-width variant (`opv`, ope_cllw_var_8). Returns
--! NULL when neither is present.
--!
--! @param a eql_v2_encrypted Encrypted value to extract order key from
--! @return bytea OPE ciphertext bytes, or NULL if no OPE term is available
--!
--! @note Requires 'ope' index configuration on the column
--! @see eql_v2.ope_cllw_u64_65
--! @see eql_v2.ope_cllw_var_8
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.order_by_ope(a eql_v2_encrypted)
  RETURNS bytea
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN eql_v2.has_ope_cllw_u64_65(a) THEN (eql_v2.ope_cllw_u64_65(a)).bytes
    WHEN eql_v2.has_ope_cllw_var_8(a)  THEN (eql_v2.ope_cllw_var_8(a)).bytes
  END;
$$ LANGUAGE sql;



