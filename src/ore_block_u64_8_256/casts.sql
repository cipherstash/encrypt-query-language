-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql

-- casts text to ore_block_u64_8_256_term (bytea)

CREATE FUNCTION eql_v2.text_to_ore_block_u64_8_256_term(t text)
  RETURNS eql_v2.ore_block_u64_8_256_term
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN t::bytea;
END;

-- cast to cleanup ore_block_u64_8_256 extraction

CREATE CAST (text AS eql_v2.ore_block_u64_8_256_term)
	WITH FUNCTION eql_v2.text_to_ore_block_u64_8_256_term(text) AS IMPLICIT;
