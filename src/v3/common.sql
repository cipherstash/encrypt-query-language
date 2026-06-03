-- REQUIRE: src/v3/schema.sql

--! @file v3/common.sql
--! @brief Common utility functions for the self-contained eql_v3 surface.
--!
--! Forked from src/common.sql (design D7) so the eql_v3 ORE constructor owns the
--! one transitive helper it needs without reaching into another schema. The
--! eql_v2 original is unchanged.

--! @brief Convert JSONB hex array to bytea array
--! @internal
--!
--! Converts a JSONB array of hex-encoded strings into a PostgreSQL bytea array.
--! Used for deserializing binary data (like ORE terms) from JSONB storage.
--!
--! @param val jsonb JSONB array of hex-encoded strings
--! @return bytea[] Array of decoded binary values
--!
--! @note Returns NULL if input is JSON null
--! @note Each array element is hex-decoded to bytea
CREATE FUNCTION eql_v3.jsonb_array_to_bytea_array(val jsonb)
RETURNS bytea[]
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
  terms_arr bytea[];
BEGIN
  IF jsonb_typeof(val) = 'null' THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(decode(value::text, 'hex')::bytea)
    INTO terms_arr
  FROM jsonb_array_elements_text(val) AS value;

  RETURN terms_arr;
END;
$$ LANGUAGE plpgsql;
