-- REQUIRE: src/schema.sql


-- extracts match index from an emcrypted column
DROP FUNCTION IF EXISTS eql_v1.match(val jsonb);

CREATE FUNCTION eql_v1.match(val jsonb)
  RETURNS eql_v1.match_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'm' THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'m'))::eql_v1.match_index;
    END IF;
    RAISE 'Expected a match index (m) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts unique index from an encrypted column
DROP FUNCTION IF EXISTS  eql_v1.match(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.match(val eql_v1_encrypted)
  RETURNS eql_v1.match_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v1.match(val.data));
  END;
$$ LANGUAGE plpgsql;
