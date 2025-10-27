-- REQUIRE: src/config/types.sql

--! @brief Initialize default configuration structure
--! @internal
--!
--! Creates a default configuration object if input is NULL. Used internally
--! by public configuration functions to ensure consistent structure.
--!
--! @param config JSONB Existing configuration or NULL
--! @return JSONB Configuration with default structure (version 1, empty tables)
CREATE FUNCTION eql_v2.config_default(config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    IF config IS NULL THEN
      SELECT jsonb_build_object('v', 1, 'tables', jsonb_build_object()) INTO config;
    END IF;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;

--! @brief Add table to configuration if not present
--! @internal
--!
--! Ensures the specified table exists in the configuration structure.
--! Creates empty table entry if needed. Idempotent operation.
--!
--! @param table_name Text Name of table to add
--! @param config JSONB Configuration object
--! @return JSONB Updated configuration with table entry
CREATE FUNCTION eql_v2.config_add_table(table_name text, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  DECLARE
    tbl jsonb;
  BEGIN
    IF NOT config #> array['tables'] ? table_name THEN
      SELECT jsonb_insert(config, array['tables', table_name], jsonb_build_object()) INTO config;
    END IF;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;

--! @brief Add column to table configuration if not present
--! @internal
--!
--! Ensures the specified column exists in the table's configuration structure.
--! Creates empty column entry with indexes object if needed. Idempotent operation.
--!
--! @param table_name Text Name of parent table
--! @param column_name Text Name of column to add
--! @param config JSONB Configuration object
--! @return JSONB Updated configuration with column entry
CREATE FUNCTION eql_v2.config_add_column(table_name text, column_name text, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  DECLARE
    col jsonb;
  BEGIN
    IF NOT config #> array['tables', table_name] ? column_name THEN
      SELECT jsonb_build_object('indexes', jsonb_build_object()) into col;
      SELECT jsonb_set(config, array['tables', table_name, column_name], col) INTO config;
    END IF;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;

--! @brief Set cast type for column in configuration
--! @internal
--!
--! Updates the cast_as field for a column, specifying the PostgreSQL type
--! that decrypted values should be cast to.
--!
--! @param table_name Text Name of parent table
--! @param column_name Text Name of column
--! @param cast_as Text PostgreSQL type for casting (e.g., 'text', 'int', 'jsonb')
--! @param config JSONB Configuration object
--! @return JSONB Updated configuration with cast_as set
CREATE FUNCTION eql_v2.config_add_cast(table_name text, column_name text, cast_as text, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    SELECT jsonb_set(config, array['tables', table_name, column_name, 'cast_as'], to_jsonb(cast_as)) INTO config;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;

--! @brief Add search index to column configuration
--! @internal
--!
--! Inserts a search index entry (unique, match, ore, ste_vec) with its options
--! into the column's indexes object.
--!
--! @param table_name Text Name of parent table
--! @param column_name Text Name of column
--! @param index_name Text Type of index to add
--! @param opts JSONB Index-specific options
--! @param config JSONB Configuration object
--! @return JSONB Updated configuration with index added
CREATE FUNCTION eql_v2.config_add_index(table_name text, column_name text, index_name text, opts jsonb, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    SELECT jsonb_insert(config, array['tables', table_name, column_name, 'indexes', index_name], opts) INTO config;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;

--! @brief Generate default options for match index
--! @internal
--!
--! Returns default configuration for match (LIKE) indexes: k=6, bf=2048,
--! ngram tokenizer with token_length=3, downcase filter, include_original=true.
--!
--! @return JSONB Default match index options
CREATE FUNCTION eql_v2.config_match_default()
  RETURNS jsonb
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT jsonb_build_object(
            'k', 6,
            'bf', 2048,
            'include_original', true,
            'tokenizer', json_build_object('kind', 'ngram', 'token_length', 3),
            'token_filters', json_build_array(json_build_object('kind', 'downcase')));
END;
