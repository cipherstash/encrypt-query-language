-- REQUIRE: src/schema.sql


-- extracts match index from an emcrypted column

CREATE FUNCTION eql_v2.match(val jsonb)
  RETURNS eql_v2.match_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'm' THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'m'))::eql_v2.match_index;
    END IF;
    RAISE 'Expected a match index (m) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts unique index from an encrypted column

CREATE FUNCTION eql_v2.match(val eql_v2_encrypted)
  RETURNS eql_v2.match_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.match(val.data));
  END;
$$ LANGUAGE plpgsql;
