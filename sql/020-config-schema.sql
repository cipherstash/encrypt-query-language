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
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v1_configuration_data') THEN
      CREATE DOMAIN public.eql_v1_configuration_data AS JSONB;
    END IF;
  END
$$;

--
-- cs_configuration_state_v1 is an ENUM that defines the valid configuration states
--
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v1_configuration_state') THEN
      CREATE TYPE public.eql_v1_configuration_state AS ENUM ('active', 'inactive', 'encrypting', 'pending');
    END IF;
  END
$$;



--
-- Extracts index keys/names from configuration json
--
-- Used by the eql_v1.config_check_indexes as part of the  cs_configuration_data_v1_check constraint
--
DROP FUNCTION IF EXISTS eql_v1.extract_indexes(jsonb);
CREATE FUNCTION eql_v1.extract_indexes(val jsonb)
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
DROP FUNCTION IF EXISTS eql_v1.config_check_indexes(jsonb);
CREATE FUNCTION eql_v1.config_check_indexes(val jsonb)
  RETURNS BOOLEAN
AS $$
	BEGIN
    IF (SELECT EXISTS (SELECT eql_v1.extract_indexes(val)))  THEN
      IF (SELECT bool_and(index = ANY('{match, ore, unique, ste_vec}')) FROM eql_v1.extract_indexes(val) AS index) THEN
        RETURN true;
      END IF;
      RAISE 'Configuration has an invalid index (%). Index should be one of {match, ore, unique, ste_vec}', val;
    END IF;
    RETURN true;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.config_check_cast(jsonb);

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
DROP FUNCTION IF EXISTS eql_v1.config_check_tables(jsonb);
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
DROP FUNCTION IF EXISTS eql_v1.config_check_v(jsonb);
CREATE FUNCTION eql_v1.config_check_v(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN
      RETURN true;
    END IF;
    RAISE 'Configuration missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


ALTER DOMAIN eql_v1_configuration_data DROP CONSTRAINT IF EXISTS eql_v1_configuration_data_check;

ALTER DOMAIN eql_v1_configuration_data
  ADD CONSTRAINT eql_v1_configuration_data_check CHECK (
    eql_v1.config_check_v(VALUE) AND
    eql_v1.config_check_tables(VALUE) AND
    eql_v1.config_check_cast(VALUE) AND
    eql_v1.config_check_indexes(VALUE)
);


--
-- CREATE the cs_configuration_v1 TABLE
--
CREATE TABLE IF NOT EXISTS eql_v1_configuration
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    state eql_v1_configuration_state NOT NULL DEFAULT 'pending',
    data eql_v1_configuration_data,
    created_at timestamptz not null default current_timestamp,
    PRIMARY KEY(id)
);

--
-- Define partial indexes to ensure that there is only one active, pending and encrypting config at a time
--
CREATE UNIQUE INDEX IF NOT EXISTS eql_v1_configuration_index_active ON eql_v1_configuration (state) WHERE state = 'active';
CREATE UNIQUE INDEX IF NOT EXISTS eql_v1_configuration_index_pending ON eql_v1_configuration (state) WHERE state = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS eql_v1_configuration_index_encrypting ON eql_v1_configuration (state) WHERE state = 'encrypting';
