-- REQUIRE: src/schema.sql

-- extracts ste_vec index from a jsonb value

-- extracts blake3 index from a jsonb value


CREATE FUNCTION eql_v2.blake3(val jsonb)
  RETURNS eql_v2.blake3
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN

    IF NOT (val ? 'b3') NULL THEN
        RAISE 'Expected a blake3 index (b3) value in json: %', val;
    END IF;

    IF val->>'b3' IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN val->>'b3';
  END;
$$ LANGUAGE plpgsql;


-- extracts blake3 index from an eql_v2_encrypted value

CREATE FUNCTION eql_v2.blake3(val eql_v2_encrypted)
  RETURNS eql_v2.blake3
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.blake3(val.data));
  END;
$$ LANGUAGE plpgsql;
