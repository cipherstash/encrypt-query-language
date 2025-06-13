-- REQUIRE: src/schema.sql


-- extracts match index from an emcrypted column

CREATE FUNCTION eql_v2.bloom_filter(val jsonb)
  RETURNS eql_v2.bloom_filter
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF val ? 'bf' THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'bf'))::eql_v2.bloom_filter;
    END IF;

    RAISE 'Expected a match index (bf) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts unique index from an encrypted column

CREATE FUNCTION eql_v2.bloom_filter(val eql_v2_encrypted)
  RETURNS eql_v2.bloom_filter
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.bloom_filter(val.data));
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.has_bloom_filter(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ? 'bf';
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.has_bloom_filter(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_bloom_filter(val.data);
  END;
$$ LANGUAGE plpgsql;
