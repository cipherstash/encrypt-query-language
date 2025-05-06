-- REQUIRE: src/config/types.sql

--
-- Extracts index keys/names from configuration json
--
-- Used by the eql_v1.config_check_indexes as part of the configuration_data_v1 constraint
--
-- DROP FUNCTION IF EXISTS eql_v1.config_get_indexes(jsonb);
CREATE FUNCTION eql_v1.config_get_indexes(val jsonb)
    RETURNS SETOF text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	SELECT jsonb_object_keys(jsonb_path_query(val,'$.tables.*.*.indexes'));
END;

--
-- _cs_check_config_get_indexes returns true if the table configuration only includes valid index types
--
-- Used by the cs_configuration_data_v1_check constraint
--
-- DROP FUNCTION IF EXISTS eql_v1.config_check_indexes(jsonb);
CREATE FUNCTION eql_v1.config_check_indexes(val jsonb)
  RETURNS BOOLEAN
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN

    IF (SELECT EXISTS (SELECT eql_v1.config_get_indexes(val))) THEN
      IF (SELECT bool_and(index = ANY('{match, ore, unique, ste_vec}')) FROM eql_v1.config_get_indexes(val) AS index) THEN
        RETURN true;
      END IF;
      RAISE 'Configuration has an invalid index (%). Index should be one of {match, ore, unique, ste_vec}', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.config_check_cast(jsonb);

CREATE FUNCTION eql_v1.config_check_cast(val jsonb)
  RETURNS BOOLEAN
AS $$
	BEGIN
    IF EXISTS (SELECT jsonb_array_elements_text(jsonb_path_query_array(val, '$.tables.*.*.cast_as')) = ANY('{text, int, small_int, big_int, real, double, boolean, date, jsonb}')) THEN
      RETURN true;
    END IF;
    RAISE 'Configuration has an invalid cast_as (%). Cast should be one of {text, int, small_int, big_int, real, double, boolean, date, jsonb}', val;
  END;
$$ LANGUAGE plpgsql;

--
-- Should include a tables field
-- Tables should not be empty
-- DROP FUNCTION IF EXISTS eql_v1.config_check_tables(jsonb);
CREATE FUNCTION eql_v1.config_check_tables(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'tables') AND (val->'tables' <> '{}'::jsonb) THEN
      RETURN true;
    END IF;
    RAISE 'Configuration missing tables (tables) field: %', val;
  END;
$$ LANGUAGE plpgsql;

-- Should include a version field
-- DROP FUNCTION IF EXISTS eql_v1.config_check_version(jsonb);
CREATE FUNCTION eql_v1.config_check_version(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN
      RETURN true;
    END IF;
    RAISE 'Configuration missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


ALTER TABLE public.eql_v1_configuration DROP CONSTRAINT IF EXISTS eql_v1_configuration_data_check;

ALTER TABLE public.eql_v1_configuration
  ADD CONSTRAINT eql_v1_configuration_data_check CHECK (
    eql_v1.config_check_version(data) AND
    eql_v1.config_check_tables(data) AND
    eql_v1.config_check_cast(data) AND
    eql_v1.config_check_indexes(data)
);


