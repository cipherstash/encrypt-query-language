-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql

--! @brief Cast text to ORE block term
--! @internal
--!
--! Converts text to bytea and wraps in ore_block_u64_8_256_term type.
--! Used internally for ORE block extraction and manipulation.
--!
--! @param t Text Text value to convert
--! @return eql_v2.ore_block_u64_8_256_term ORE term containing bytea representation
--!
--! @see eql_v2.ore_block_u64_8_256_term
CREATE FUNCTION eql_v2.text_to_ore_block_u64_8_256_term(t text)
  RETURNS eql_v2.ore_block_u64_8_256_term
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN t::bytea;
END;

--! @brief Implicit cast from text to ORE block term
--!
--! Defines an implicit cast allowing automatic conversion of text values
--! to ore_block_u64_8_256_term type for ORE operations.
--!
--! @see eql_v2.text_to_ore_block_u64_8_256_term
CREATE CAST (text AS eql_v2.ore_block_u64_8_256_term)
	WITH FUNCTION eql_v2.text_to_ore_block_u64_8_256_term(text) AS IMPLICIT;
