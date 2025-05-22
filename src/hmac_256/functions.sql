-- REQUIRE: src/schema.sql
-- REQUIRE: src/unique/types.sql

-- extracts unique index from an encrypted column

CREATE FUNCTION eql_v2.hmac_256(val jsonb)
  RETURNS eql_v2.hmac_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'u' THEN
      RETURN val->>'u';
    END IF;
    RAISE 'Expected a unique index (u) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts unique index from an encrypted column

CREATE FUNCTION eql_v2.hmac_256(val eql_v2_encrypted)
  RETURNS eql_v2.hmac_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.hmac_256(val.data));
  END;
$$ LANGUAGE plpgsql;


