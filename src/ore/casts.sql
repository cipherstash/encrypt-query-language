-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore/types.sql

-- casts text to ore_64_8_v1_term (bytea)
DROP FUNCTION IF EXISTS eql_v1.text_to_ore_64_8_v1_term(t text);

CREATE FUNCTION eql_v1.text_to_ore_64_8_v1_term(t text)
  RETURNS eql_v1.ore_64_8_v1_term
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN t::bytea;
END;

-- cast to cleanup ore_64_8_v1 extraction
DROP CAST IF EXISTS (text AS eql_v1.ore_64_8_v1_term);

CREATE CAST (text AS eql_v1.ore_64_8_v1_term)
	WITH FUNCTION eql_v1.text_to_ore_64_8_v1_term(text) AS IMPLICIT;
