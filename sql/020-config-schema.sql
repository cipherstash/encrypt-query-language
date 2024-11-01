--
-- Configuration Schema
--
--  Defines core config state and storage types
--  Creates the cs_configuration_v1 table with constraint and unique indexes
--
--


--
-- cs_configuration_data_v1 is a jsonb column that stores the actuak configuration
--
-- For some reason CREATE DFOMAIN and CREATE TYPE do not support IF NOT EXISTS
-- Types cannot be dropped if used by a table, and we never drop the configuration table
-- DOMAIN constraints are added separately and not tied to DOMAIN creation
--
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_configuration_data_v1') THEN
      CREATE DOMAIN cs_configuration_data_v1 AS JSONB;
    END IF;
  END
$$;

--
-- cs_configuration_state_v1 is an ENUM that defines the valid configuration states
--
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cs_configuration_state_v1') THEN
      CREATE TYPE cs_configuration_state_v1 AS ENUM ('active', 'inactive', 'encrypting', 'pending');
    END IF;
  END
$$;



--
-- Extracts index keys/names from configuration json
--
-- Used by the _cs_config_check_indexes as part of the  cs_configuration_data_v1_check constraint
--
DROP FUNCTION IF EXISTS _cs_extract_indexes(jsonb);
CREATE FUNCTION _cs_extract_indexes(val jsonb)
    RETURNS SETOF text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
	SELECT jsonb_object_keys(jsonb_path_query(val,'$.tables.*.*.indexes'));
END;

--
-- _cs_check_config_indexes returns true if the table configuration only includes valid index types
--
-- Used by the cs_configuration_data_v1_check constraint
--
DROP FUNCTION IF EXISTS _cs_config_check_indexes(jsonb);
CREATE FUNCTION _cs_config_check_indexes(val jsonb)
  RETURNS BOOLEAN
AS $$
	BEGIN
    IF (SELECT EXISTS (SELECT _cs_extract_indexes(val)))  THEN
      IF (SELECT bool_and(index = ANY('{match, ore, unique, ste_vec}')) FROM _cs_extract_indexes(val) AS index) THEN
        RETURN true;
      END IF;
      RAISE 'Invalid index (%) in configuration. Index should be one of {match, ore, unique, ste_vec}', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS _cs_config_check_cast(jsonb);

CREATE FUNCTION _cs_config_check_cast(val jsonb)
  RETURNS BOOLEAN
AS $$
	BEGIN
    IF EXISTS (SELECT jsonb_array_elements_text(jsonb_path_query_array(val, '$.tables.*.*.cast_as')) = ANY('{text, int, small_int, big_int, real, double, boolean, date, jsonb}')) THEN
      RETURN true;
    END IF;
    RAISE 'Invalid cast (%) in configuration. Cast should be one of {text, int, small_int, big_int, real, double, boolean, date, jsonb}', val;
  END;
$$ LANGUAGE plpgsql;

--
-- Should include a tables field
-- Tables should not be empty
DROP FUNCTION IF EXISTS _cs_config_check_tables(jsonb);
CREATE FUNCTION _cs_config_check_tables(val jsonb)
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
DROP FUNCTION IF EXISTS _cs_config_check_v(jsonb);
CREATE FUNCTION _cs_config_check_v(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN
      RETURN true;
    END IF;
    RAISE 'Configuration missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


ALTER DOMAIN cs_configuration_data_v1 DROP CONSTRAINT IF EXISTS cs_configuration_data_v1_check;

ALTER DOMAIN cs_configuration_data_v1
  ADD CONSTRAINT cs_configuration_data_v1_check CHECK (
    _cs_config_check_v(VALUE) AND
    _cs_config_check_tables(VALUE) AND
    _cs_config_check_cast(VALUE) AND
    _cs_config_check_indexes(VALUE)
);


--
-- CREATE the cs_configuration_v1 TABLE
--
CREATE TABLE IF NOT EXISTS cs_configuration_v1
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    state cs_configuration_state_v1 NOT NULL DEFAULT 'pending',
    data cs_configuration_data_v1,
    created_at timestamptz not null default current_timestamp,
    PRIMARY KEY(id)
);

--
-- Define partial indexes to ensure that there is only one active, pending and encrypting config at a time
--
CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_active ON cs_configuration_v1 (state) WHERE state = 'active';
CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_pending ON cs_configuration_v1 (state) WHERE state = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS cs_configuration_v1_index_encrypting ON cs_configuration_v1 (state) WHERE state = 'encrypting';
