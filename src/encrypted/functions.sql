-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/bloom_filter/types.sql
-- REQUIRE: ore_block_u64_8_256types.sql
-- REQUIRE: src/hmac_256/types.sql



CREATE FUNCTION eql_v2.ciphertext(val jsonb)
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



CREATE FUNCTION eql_v2.ciphertext(val eql_v2_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.ciphertext(val.data);
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2._first_grouped_value(jsonb, jsonb)
RETURNS jsonb AS $$
  SELECT COALESCE($1, $2);
$$ LANGUAGE sql IMMUTABLE;


CREATE AGGREGATE eql_v2.grouped_value(jsonb) (
  SFUNC = eql_v2._first_grouped_value,
  STYPE = jsonb
);


--
-- Adds eql_v2.check_encrypted constraint to the column_name in table_name
--
-- Executes the ALTER TABLE statement
--   `ALTER TABLE {table_name} ADD CONSTRAINT eql_v2_encrypted_check_{column_name} CHECK (eql_v2.check_encrypted({column_name}))`
--
--
CREATE FUNCTION eql_v2.add_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
	BEGIN
		EXECUTE format('ALTER TABLE %I ADD CONSTRAINT eql_v2_encrypted_check_%I CHECK (eql_v2.check_encrypted(%I))', table_name, column_name, column_name);
	END;
$$ LANGUAGE plpgsql;


--
-- Removes the eql_v2.check_encrypted constraint from the column_name in table_name
--
-- Executes the ALTER TABLE statement
--   `ALTER TABLE {table_name} DROP CONSTRAINT eql_v2_encrypted_check_{column_name}`
--
CREATE FUNCTION eql_v2.remove_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
	BEGIN
		EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS eql_v2_encrypted_check_%I', table_name, column_name);
	END;
$$ LANGUAGE plpgsql;


