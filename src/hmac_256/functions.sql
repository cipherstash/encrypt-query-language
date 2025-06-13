-- REQUIRE: src/schema.sql
-- REQUIRE: src/hmac_256/types.sql

-- extracts hmac_256 index from an encrypted column

CREATE FUNCTION eql_v2.hmac_256(val jsonb)
  RETURNS eql_v2.hmac_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF val ? 'hm' THEN
      RETURN val->>'hm';
    END IF;
    RAISE 'Expected a hmac_256 index (hm) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.has_hmac_256(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ? 'hm';
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v2.has_hmac_256(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_hmac_256(val.data);
  END;
$$ LANGUAGE plpgsql;



-- extracts hmac_256 index from an encrypted column

CREATE FUNCTION eql_v2.hmac_256(val eql_v2_encrypted)
  RETURNS eql_v2.hmac_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.hmac_256(val.data));
  END;
$$ LANGUAGE plpgsql;


