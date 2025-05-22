-- REQUIRE: src/config/types.sql
--
-- Private configuration functions
-- Internal implemention details that customers should not need to worry about.
--
--

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


-- Add the column if it doesn't exist

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


-- Set the cast

CREATE FUNCTION eql_v2.config_add_cast(table_name text, column_name text, cast_as text, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    SELECT jsonb_set(config, array['tables', table_name, column_name, 'cast_as'], to_jsonb(cast_as)) INTO config;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;


-- Add the column if it doesn't exist

CREATE FUNCTION eql_v2.config_add_index(table_name text, column_name text, index_name text, opts jsonb, config jsonb)
  RETURNS jsonb
  IMMUTABLE PARALLEL SAFE
AS $$
  BEGIN
    SELECT jsonb_insert(config, array['tables', table_name, column_name, 'indexes', index_name], opts) INTO config;
    RETURN config;
  END;
$$ LANGUAGE plpgsql;


--
-- Default options for match index
--

CREATE FUNCTION eql_v2.config_match_default()
  RETURNS jsonb
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT jsonb_build_object(
            'k', 6,
            'm', 2048,
            'include_original', true,
            'tokenizer', json_build_object('kind', 'ngram', 'token_length', 3),
            'token_filters', json_build_array(json_build_object('kind', 'downcase')));
END;
