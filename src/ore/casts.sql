-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore/types.sql

-- casts text to ore_64_8_v2_term (bytea)

CREATE FUNCTION eql_v2.text_to_ore_64_8_v2_term(t text)
  RETURNS eql_v2.ore_64_8_v2_term
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	RETURN t::bytea;
END;

-- cast to cleanup ore_64_8_v2 extraction

CREATE CAST (text AS eql_v2.ore_64_8_v2_term)
	WITH FUNCTION eql_v2.text_to_ore_64_8_v2_term(text) AS IMPLICIT;
