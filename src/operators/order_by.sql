-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql

--! @brief Extract ORE index term for ordering encrypted values
--!
--! Helper function that extracts the ore_block_u64_8_256 index term from an encrypted value
--! for use in ORDER BY clauses when comparison operators are not appropriate or available.
--!
--! @param a eql_v2_encrypted Encrypted value to extract order term from
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
AS $$
  BEGIN
    RETURN eql_v2.ore_block_u64_8_256(a);
  END;
$$ LANGUAGE plpgsql;



