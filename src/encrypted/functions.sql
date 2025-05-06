-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/match/types.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/unique/types.sql


-- DROP FUNCTION IF EXISTS eql_v1.ciphertext(val jsonb);

CREATE FUNCTION eql_v1.ciphertext(val jsonb)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'c' THEN
      RETURN val->>'c';
    END IF;
    RAISE 'Expected a ciphertext (c) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.ciphertext(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.ciphertext(val eql_v1_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v1.ciphertext(val.data);
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.to_jsonb(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.to_jsonb(val eql_v1_encrypted)
  RETURNS jsonb
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val.data;
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1._first_grouped_value(jsonb, jsonb);

CREATE FUNCTION eql_v1._first_grouped_value(jsonb, jsonb)
RETURNS jsonb AS $$
  SELECT COALESCE($1, $2);
$$ LANGUAGE sql IMMUTABLE;

-- DROP AGGREGATE IF EXISTS eql_v1.cs_grouped_value(jsonb);

CREATE AGGREGATE eql_v1.cs_grouped_value(jsonb) (
  SFUNC = eql_v1._first_grouped_value,
  STYPE = jsonb
);
