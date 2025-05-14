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


--
-- Adds eql_v1.check_encrypted constraint to the column_name in table_name
--
-- Executes the ALTER TABLE statement
--   `ALTER TABLE {table_name} ADD CONSTRAINT eql_v1_encrypted_check_{column_name} CHECK (eql_v1.check_encrypted({column_name}))`
--
--
CREATE FUNCTION eql_v1.add_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
	BEGIN
		EXECUTE format('ALTER TABLE %I ADD CONSTRAINT eql_v1_encrypted_check_%I CHECK (eql_v1.check_encrypted(%I))', table_name, column_name, column_name);
	END;
$$ LANGUAGE plpgsql;


--
-- Removes the eql_v1.check_encrypted constraint from the column_name in table_name
--
-- Executes the ALTER TABLE statement
--   `ALTER TABLE {table_name} DROP CONSTRAINT eql_v1_encrypted_check_{column_name}`
--
CREATE FUNCTION eql_v1.remove_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
	BEGIN
		EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS eql_v1_encrypted_check_%I', table_name, column_name);
	END;
$$ LANGUAGE plpgsql;


