-- REQUIRE: src/config/types.sql
-- REQUIRE: src/config/functions_private.sql
-- REQUIRE: src/encrypted/functions.sql


-- Customer-facing configuration functions
-- Depends on private functions for implemenation
--
--

--
-- Adds an index term to the configuration
--

CREATE FUNCTION eql_v2.add_search_config(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}', migrating boolean DEFAULT false)
  RETURNS jsonb

AS $$
  DECLARE
    o jsonb;
    _config jsonb;
  BEGIN

    -- set the active config
    SELECT data INTO _config FROM public.eql_v2_configuration WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- if index exists
    IF _config #> array['tables', table_name, column_name, 'indexes'] ?  index_name THEN
      RAISE EXCEPTION '% index exists for column: % %', index_name, table_name, column_name;
    END IF;

    IF NOT cast_as = ANY('{text, int, small_int, big_int, real, double, boolean, date, jsonb}') THEN
      RAISE EXCEPTION '% is not a valid cast type', cast_as;
    END IF;

    -- set default config
    SELECT eql_v2.config_default(_config) INTO _config;

    SELECT eql_v2.config_add_table(table_name, _config) INTO _config;

    SELECT eql_v2.config_add_column(table_name, column_name, _config) INTO _config;

    SELECT eql_v2.config_add_cast(table_name, column_name, cast_as, _config) INTO _config;

    -- set default options for index if opts empty
    IF index_name = 'match' AND opts = '{}' THEN
      SELECT eql_v2.config_match_default() INTO opts;
    END IF;

    SELECT eql_v2.config_add_index(table_name, column_name, index_name, opts, _config) INTO _config;

    --  create a new pending record if we don't have one
    INSERT INTO public.eql_v2_configuration (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO UPDATE
      SET data = _config;

    IF NOT migrating THEN
      PERFORM eql_v2.migrate_config();
      PERFORM eql_v2.activate_config();
    END IF;

    PERFORM eql_v2.add_encrypted_constraint(table_name, column_name);

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.remove_search_config(table_name text, column_name text, index_name text, migrating boolean DEFAULT false)
  RETURNS jsonb
AS $$
  DECLARE
    _config jsonb;
  BEGIN

    -- set the active config
    SELECT data INTO _config FROM public.eql_v2_configuration WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- if no config
    IF _config IS NULL THEN
      RAISE EXCEPTION 'No active or pending configuration exists';
    END IF;

    -- if the table doesn't exist
    IF NOT _config #> array['tables'] ? table_name THEN
      RAISE EXCEPTION 'No configuration exists for table: %', table_name;
    END IF;

    -- if the index does not exist
    -- IF NOT _config->key ? index_name THEN
    IF NOT _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'No % index exists for column: % %', index_name, table_name, column_name;
    END IF;

    --  create a new pending record if we don't have one
    INSERT INTO public.eql_v2_configuration (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO NOTHING;

    -- remove the index
    SELECT _config #- array['tables', table_name, column_name, 'indexes', index_name] INTO _config;

    -- update the config and migrate (even if empty)
    UPDATE public.eql_v2_configuration SET data = _config WHERE state = 'pending';
    
    IF NOT migrating THEN
      PERFORM eql_v2.migrate_config();
      PERFORM eql_v2.activate_config();
    END IF;

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.modify_search_config(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}', migrating boolean DEFAULT false)
  RETURNS jsonb
AS $$
  BEGIN
    PERFORM eql_v2.remove_search_config(table_name, column_name, index_name, migrating);
    RETURN eql_v2.add_search_config(table_name, column_name, index_name, cast_as, opts, migrating);
  END;
$$ LANGUAGE plpgsql;



--
--
-- Marks the currently `pending` configuration as `encrypting`.
--
-- Validates the database schema and raises an exception if the configured columns are not `cs_encrypted_v2` type.
--
-- Accepts an optional `force` parameter.
-- If `force` is `true`, the schema validation is skipped.
--
-- Raises an exception if the configuration is already `encrypting` or if there is no `pending` configuration to encrypt.
--

CREATE FUNCTION eql_v2.migrate_config()
  RETURNS boolean
AS $$
	BEGIN

    IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'encrypting') THEN
      RAISE EXCEPTION 'An encryption is already in progress';
    END IF;

		IF NOT EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'pending') THEN
			RAISE EXCEPTION 'No pending configuration exists to encrypt';
		END IF;

    IF NOT eql_v2.ready_for_encryption() THEN
      RAISE EXCEPTION 'Some pending columns do not have an encrypted target';
    END IF;

    UPDATE public.eql_v2_configuration SET state = 'encrypting' WHERE state = 'pending';
		RETURN true;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.activate_config()
  RETURNS boolean
AS $$
	BEGIN

	  IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'encrypting') THEN
	  	UPDATE public.eql_v2_configuration SET state = 'inactive' WHERE state = 'active';
			UPDATE public.eql_v2_configuration SET state = 'active' WHERE state = 'encrypting';
			RETURN true;
		ELSE
			RAISE EXCEPTION 'No encrypting configuration exists to activate';
		END IF;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.discard()
  RETURNS boolean
AS $$
  BEGIN
    IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'pending') THEN
        DELETE FROM public.eql_v2_configuration WHERE state = 'pending';
      RETURN true;
    ELSE
      RAISE EXCEPTION 'No pending configuration exists to discard';
    END IF;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.add_column(table_name text, column_name text, cast_as text DEFAULT 'text', migrating boolean DEFAULT false)
  RETURNS jsonb
AS $$
  DECLARE
    key text;
    _config jsonb;
  BEGIN
    -- set the active config
    SELECT data INTO _config FROM public.eql_v2_configuration WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- set default config
    SELECT eql_v2.config_default(_config) INTO _config;

    -- if index exists
    IF _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'Config exists for column: % %', table_name, column_name;
    END IF;

    SELECT eql_v2.config_add_table(table_name, _config) INTO _config;

    SELECT eql_v2.config_add_column(table_name, column_name, _config) INTO _config;

    SELECT eql_v2.config_add_cast(table_name, column_name, cast_as, _config) INTO _config;

    --  create a new pending record if we don't have one
    INSERT INTO public.eql_v2_configuration (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO UPDATE
      SET data = _config;

    IF NOT migrating THEN
      PERFORM eql_v2.migrate_config();
      PERFORM eql_v2.activate_config();
    END IF;

    PERFORM eql_v2.add_encrypted_constraint(table_name, column_name);

    -- exeunt
    RETURN _config;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.remove_column(table_name text, column_name text, migrating boolean DEFAULT false)
  RETURNS jsonb
AS $$
  DECLARE
    key text;
    _config jsonb;
  BEGIN
     -- set the active config
    SELECT data INTO _config FROM public.eql_v2_configuration WHERE state = 'active' OR state = 'pending' ORDER BY state DESC;

    -- if no config
    IF _config IS NULL THEN
      RAISE EXCEPTION 'No active or pending configuration exists';
    END IF;

    -- if the table doesn't exist
    IF NOT _config #> array['tables'] ? table_name THEN
      RAISE EXCEPTION 'No configuration exists for table: %', table_name;
    END IF;

    -- if the column does not exist
    IF NOT _config #> array['tables', table_name] ?  column_name THEN
      RAISE EXCEPTION 'No configuration exists for column: % %', table_name, column_name;
    END IF;

    --  create a new pending record if we don't have one
    INSERT INTO public.eql_v2_configuration (state, data) VALUES ('pending', _config)
    ON CONFLICT (state)
      WHERE state = 'pending'
    DO NOTHING;

    -- remove the column
    SELECT _config #- array['tables', table_name, column_name] INTO _config;

    -- if table  is now empty, remove the table
    IF _config #> array['tables', table_name] = '{}' THEN
      SELECT _config #- array['tables', table_name] INTO _config;
    END IF;

    PERFORM eql_v2.remove_encrypted_constraint(table_name, column_name);

    -- update the config (even if empty) and activate
    UPDATE public.eql_v2_configuration SET data = _config WHERE state = 'pending';
    
    IF NOT migrating THEN
      -- For empty configs, skip migration validation and directly activate
      IF _config #> array['tables'] = '{}' THEN
        UPDATE public.eql_v2_configuration SET state = 'inactive' WHERE state = 'active';
        UPDATE public.eql_v2_configuration SET state = 'active' WHERE state = 'pending';
      ELSE
        PERFORM eql_v2.migrate_config();
        PERFORM eql_v2.activate_config();
      END IF;
    END IF;

    -- exeunt
    RETURN _config;

  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.reload_config()
  RETURNS void
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  RETURN NULL;
END;


-- A convenience function to return the configuration in a tabular format, allowing for easier filtering, and querying.
-- Query using `SELECT * FROM cs_config();`
--
CREATE FUNCTION eql_v2.config() RETURNS TABLE (
    state eql_v2_configuration_state,
    relation text,
    col_name text,
    decrypts_as text,
    indexes jsonb
)
AS $$
BEGIN
    RETURN QUERY
      WITH tables AS (
          SELECT config.state, tables.key AS table, tables.value AS config
          FROM public.eql_v2_configuration config, jsonb_each(data->'tables') tables
          WHERE config.data->>'v' = '1'
      )
      SELECT
          tables.state,
          tables.table,
          column_config.key,
          column_config.value->>'cast_as',
          column_config.value->'indexes'
      FROM tables, jsonb_each(tables.config) column_config;
END;
$$ LANGUAGE plpgsql;
