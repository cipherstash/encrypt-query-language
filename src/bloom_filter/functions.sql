-- REQUIRE: src/schema.sql


-- extracts match index from an emcrypted column

CREATE FUNCTION eql_v2.bloom_filter(val jsonb)
  RETURNS eql_v2.bloom_filter_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'bf' THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'bf'))::eql_v2.bloom_filter_index;
    END IF;
    RAISE 'Expected a match index (bf) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts unique index from an encrypted column

CREATE FUNCTION eql_v2.bloom_filter(val eql_v2_encrypted)
  RETURNS eql_v2.bloom_filter_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.bloom_filter_index(val.data));
  END;
$$ LANGUAGE plpgsql;
