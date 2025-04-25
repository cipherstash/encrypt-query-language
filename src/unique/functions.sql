-- REQUIRE: src/schema.sql
-- REQUIRE: src/unique/types.sql

-- extracts unique index from an encrypted column
DROP FUNCTION IF EXISTS  eql_v1.unique(val jsonb);

CREATE FUNCTION eql_v1.unique(val jsonb)
  RETURNS eql_v1.unique_index
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
DROP FUNCTION IF EXISTS  eql_v1.unique(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.unique(val eql_v1_encrypted)
  RETURNS eql_v1.unique_index
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v1.unique(val.data));
  END;
$$ LANGUAGE plpgsql;


