-- REQUIRE: src/schema.sql

-- extracts ste_vec index from a jsonb value
-- DROP FUNCTION IF EXISTS  eql_v1.blake3(val jsonb);

-- extracts blake3 index from a jsonb value
-- DROP FUNCTION IF EXISTS  eql_v1.blake3(val jsonb);

CREATE FUNCTION eql_v1.blake3(val jsonb)
  RETURNS eql_v1.blake3
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN

    IF NOT (val ? 'b') NULL THEN
        RAISE 'Expected a blake3 index (b) value in json: %', val;
    END IF;

    IF val->>'b' IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN val->>'b';
  END;
$$ LANGUAGE plpgsql;


-- extracts blake3 index from an eql_v1_encrypted value
-- DROP FUNCTION IF EXISTS  eql_v1.blake3(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.blake3(val eql_v1_encrypted)
  RETURNS eql_v1.blake3
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v1.blake3(val.data));
  END;
$$ LANGUAGE plpgsql;
