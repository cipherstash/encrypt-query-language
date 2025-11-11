-- REQUIRE: src/config/types.sql

--! @file config/constraints.sql
--! @brief Configuration validation functions and constraints
--!
--! Provides CHECK constraint functions to validate encryption configuration structure.
--! Ensures configurations have required fields (version, tables) and valid values
--! for index types and cast types before being stored.
--!
--! @see config/tables.sql where constraints are applied


--! @brief Extract index type names from configuration
--! @internal
--!
--! Helper function that extracts all index type names from the configuration's
--! 'indexes' sections across all tables and columns.
--!
--! @param jsonb Configuration data to extract from
--! @return SETOF text Index type names (e.g., 'match', 'ore', 'unique', 'ste_vec')
--!
--! @note Used by config_check_indexes for validation
--! @see eql_v2.config_check_indexes
CREATE FUNCTION eql_v2.config_get_indexes(val jsonb)
    RETURNS SETOF text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	SELECT jsonb_object_keys(jsonb_path_query(val,'$.tables.*.*.indexes'));
END;


--! @brief Validate index types in configuration
--! @internal
--!
--! Checks that all index types specified in the configuration are valid.
--! Valid index types are: match, ore, unique, ste_vec.
--!
--! @param jsonb Configuration data to validate
--! @return boolean True if all index types are valid
--! @throws Exception if any invalid index type found
--!
--! @note Used in CHECK constraint on eql_v2_configuration table
--! @see eql_v2.config_get_indexes
CREATE FUNCTION eql_v2.config_check_indexes(val jsonb)
  RETURNS BOOLEAN
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN

    IF (SELECT EXISTS (SELECT eql_v2.config_get_indexes(val))) THEN
      IF (SELECT bool_and(index = ANY('{match, ore, unique, ste_vec}')) FROM eql_v2.config_get_indexes(val) AS index) THEN
        RETURN true;
      END IF;
      RAISE 'Configuration has an invalid index (%). Index should be one of {match, ore, unique, ste_vec}', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


--! @brief Validate cast types in configuration
--! @internal
--!
--! Checks that all 'cast_as' types specified in the configuration are valid.
--! Valid cast types are: text, int, small_int, big_int, real, double, boolean, date, jsonb.
--!
--! @param jsonb Configuration data to validate
--! @return boolean True if all cast types are valid or no cast types specified
--! @throws Exception if any invalid cast type found
--!
--! @note Used in CHECK constraint on eql_v2_configuration table
--! @note Empty configurations (no cast_as fields) are valid
--! @note Cast type names are EQL's internal representations, not PostgreSQL native types
CREATE FUNCTION eql_v2.config_check_cast(val jsonb)
  RETURNS BOOLEAN
AS $$
	BEGIN
    -- If there are cast_as fields, validate them
    IF EXISTS (SELECT jsonb_array_elements_text(jsonb_path_query_array(val, '$.tables.*.*.cast_as'))) THEN
      IF (SELECT bool_and(cast_as = ANY('{text, int, small_int, big_int, real, double, boolean, date, jsonb}')) 
          FROM (SELECT jsonb_array_elements_text(jsonb_path_query_array(val, '$.tables.*.*.cast_as')) AS cast_as) casts) THEN
        RETURN true;
      END IF;
      RAISE 'Configuration has an invalid cast_as (%). Cast should be one of {text, int, small_int, big_int, real, double, boolean, date, jsonb}', val;
    END IF;
    -- If no cast_as fields exist (empty config), that's valid
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


--! @brief Validate tables field presence
--! @internal
--!
--! Ensures the configuration has a 'tables' field, which is required
--! to specify which database tables contain encrypted columns.
--!
--! @param jsonb Configuration data to validate
--! @return boolean True if 'tables' field exists
--! @throws Exception if 'tables' field is missing
--!
--! @note Used in CHECK constraint on eql_v2_configuration table
CREATE FUNCTION eql_v2.config_check_tables(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'tables') THEN
      RETURN true;
    END IF;
    RAISE 'Configuration missing tables (tables) field: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Validate version field presence
--! @internal
--!
--! Ensures the configuration has a 'v' (version) field, which tracks
--! the configuration format version.
--!
--! @param jsonb Configuration data to validate
--! @return boolean True if 'v' field exists
--! @throws Exception if 'v' field is missing
--!
--! @note Used in CHECK constraint on eql_v2_configuration table
CREATE FUNCTION eql_v2.config_check_version(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN
      RETURN true;
    END IF;
    RAISE 'Configuration missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Drop existing data validation constraint if present
--! @note Allows constraint to be recreated during upgrades
ALTER TABLE public.eql_v2_configuration DROP CONSTRAINT IF EXISTS eql_v2_configuration_data_check;


--! @brief Comprehensive configuration data validation
--!
--! CHECK constraint that validates all aspects of configuration data:
--! - Version field presence
--! - Tables field presence
--! - Valid cast_as types
--! - Valid index types
--!
--! @note Combines all config_check_* validation functions
--! @see eql_v2.config_check_version
--! @see eql_v2.config_check_tables
--! @see eql_v2.config_check_cast
--! @see eql_v2.config_check_indexes
ALTER TABLE public.eql_v2_configuration
  ADD CONSTRAINT eql_v2_configuration_data_check CHECK (
    eql_v2.config_check_version(data) AND
    eql_v2.config_check_tables(data) AND
    eql_v2.config_check_cast(data) AND
    eql_v2.config_check_indexes(data)
);


