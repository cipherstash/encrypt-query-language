-- REQUIRE: src/config/types.sql
-- REQUIRE: src/config/functions_private.sql
-- REQUIRE: src/encrypted/functions.sql

--! @brief Add a search index configuration for an encrypted column
--!
--! Configures a searchable encryption index (unique, match, ore, or ste_vec) on an
--! encrypted column. Creates or updates the pending configuration, then migrates
--! and activates it unless migrating flag is set.
--!
--! @param table_name Text Name of the table containing the column
--! @param column_name Text Name of the column to configure
--! @param index_name Text Type of index ('unique', 'match', 'ore', 'ste_vec')
--! @param cast_as Text PostgreSQL type for decrypted values (default: 'text')
--! @param opts JSONB Index-specific options (default: '{}')
--! @param migrating Boolean Skip auto-migration if true (default: false)
--! @return JSONB Updated configuration object
--! @throws Exception if index already exists for this column
--! @throws Exception if cast_as is not a valid type
--!
--! @example
--! -- Add unique index for exact-match searches
--! SELECT eql_v2.add_search_config('users', 'email', 'unique');
--!
--! -- Add match index for LIKE searches with custom token length
--! SELECT eql_v2.add_search_config('posts', 'content', 'match', 'text',
--!   '{"token_filters": [{"kind": "downcase"}], "tokenizer": {"kind": "ngram", "token_length": 3}}'
--! );
--!
--! @see eql_v2.add_column
--! @see eql_v2.remove_search_config
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

--! @brief Remove a search index configuration from an encrypted column
--!
--! Removes a previously configured search index from an encrypted column.
--! Updates the pending configuration, then migrates and activates it
--! unless migrating flag is set.
--!
--! @param table_name Text Name of the table containing the column
--! @param column_name Text Name of the column
--! @param index_name Text Type of index to remove
--! @param migrating Boolean Skip auto-migration if true (default: false)
--! @return JSONB Updated configuration object
--! @throws Exception if no active or pending configuration exists
--! @throws Exception if table is not configured
--! @throws Exception if column is not configured
--!
--! @example
--! -- Remove match index from column
--! SELECT eql_v2.remove_search_config('posts', 'content', 'match');
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.modify_search_config
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

--! @brief Modify a search index configuration for an encrypted column
--!
--! Updates an existing search index configuration by removing and re-adding it
--! with new options. Convenience function that combines remove and add operations.
--! If index does not exist, it is added.
--!
--! @param table_name Text Name of the table containing the column
--! @param column_name Text Name of the column
--! @param index_name Text Type of index to modify
--! @param cast_as Text PostgreSQL type for decrypted values (default: 'text')
--! @param opts JSONB New index-specific options (default: '{}')
--! @param migrating Boolean Skip auto-migration if true (default: false)
--! @return JSONB Updated configuration object
--!
--! @example
--! -- Change match index tokenizer settings
--! SELECT eql_v2.modify_search_config('posts', 'content', 'match', 'text',
--!   '{"tokenizer": {"kind": "ngram", "token_length": 4}}'
--! );
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.remove_search_config
CREATE FUNCTION eql_v2.modify_search_config(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}', migrating boolean DEFAULT false)
  RETURNS jsonb
AS $$
  BEGIN
    PERFORM eql_v2.remove_search_config(table_name, column_name, index_name, migrating);
    RETURN eql_v2.add_search_config(table_name, column_name, index_name, cast_as, opts, migrating);
  END;
$$ LANGUAGE plpgsql;

--! @brief Migrate pending configuration to encrypting state
--!
--! Transitions the pending configuration to encrypting state, validating that
--! all configured columns have encrypted target columns ready. This is part of
--! the configuration lifecycle: pending → encrypting → active.
--!
--! @return Boolean True if migration succeeds
--! @throws Exception if encryption already in progress
--! @throws Exception if no pending configuration exists
--! @throws Exception if configured columns lack encrypted targets
--!
--! @example
--! -- Manually migrate configuration (normally done automatically)
--! SELECT eql_v2.migrate_config();
--!
--! @see eql_v2.activate_config
--! @see eql_v2.add_column
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

--! @brief Activate encrypting configuration
--!
--! Transitions the encrypting configuration to active state, making it the
--! current operational configuration. Marks previous active configuration as
--! inactive. Final step in configuration lifecycle: pending → encrypting → active.
--!
--! @return Boolean True if activation succeeds
--! @throws Exception if no encrypting configuration exists to activate
--!
--! @example
--! -- Manually activate configuration (normally done automatically)
--! SELECT eql_v2.activate_config();
--!
--! @see eql_v2.migrate_config
--! @see eql_v2.add_column
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

--! @brief Discard pending configuration
--!
--! Deletes the pending configuration without applying changes. Use this to
--! abandon configuration changes before they are migrated and activated.
--!
--! @return Boolean True if discard succeeds
--! @throws Exception if no pending configuration exists to discard
--!
--! @example
--! -- Discard uncommitted configuration changes
--! SELECT eql_v2.discard();
--!
--! @see eql_v2.add_column
--! @see eql_v2.add_search_config
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

--! @brief Configure a column for encryption
--!
--! Adds a column to the encryption configuration, making it eligible for
--! encrypted storage and search indexes. Creates or updates pending configuration,
--! adds encrypted constraint, then migrates and activates unless migrating flag is set.
--!
--! @param table_name Text Name of the table containing the column
--! @param column_name Text Name of the column to encrypt
--! @param cast_as Text PostgreSQL type to cast decrypted values (default: 'text')
--! @param migrating Boolean Skip auto-migration if true (default: false)
--! @return JSONB Updated configuration object
--! @throws Exception if column already configured for encryption
--!
--! @example
--! -- Configure email column for encryption
--! SELECT eql_v2.add_column('users', 'email', 'text');
--!
--! -- Configure age column with integer casting
--! SELECT eql_v2.add_column('users', 'age', 'int');
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.remove_column
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

--! @brief Remove a column from encryption configuration
--!
--! Removes a column from the encryption configuration, including all associated
--! search indexes. Removes encrypted constraint, updates pending configuration,
--! then migrates and activates unless migrating flag is set.
--!
--! @param table_name Text Name of the table containing the column
--! @param column_name Text Name of the column to remove
--! @param migrating Boolean Skip auto-migration if true (default: false)
--! @return JSONB Updated configuration object
--! @throws Exception if no active or pending configuration exists
--! @throws Exception if table is not configured
--! @throws Exception if column is not configured
--!
--! @example
--! -- Remove email column from encryption
--! SELECT eql_v2.remove_column('users', 'email');
--!
--! @see eql_v2.add_column
--! @see eql_v2.remove_search_config
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

--! @brief Reload configuration from CipherStash Proxy
--!
--! Placeholder function for reloading configuration from the CipherStash Proxy.
--! Currently returns NULL without side effects.
--!
--! @return Void
--!
--! @note This function may be used for configuration synchronization in future versions
CREATE FUNCTION eql_v2.reload_config()
  RETURNS void
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  RETURN NULL;
END;

--! @brief Query encryption configuration in tabular format
--!
--! Returns the active encryption configuration as a table for easier querying
--! and filtering. Shows all configured tables, columns, cast types, and indexes.
--!
--! @return TABLE Contains configuration state, relation name, column name, cast type, and indexes
--!
--! @example
--! -- View all encrypted columns
--! SELECT * FROM eql_v2.config();
--!
--! -- Find all columns with match indexes
--! SELECT relation, col_name FROM eql_v2.config()
--! WHERE indexes ? 'match';
--!
--! @see eql_v2.add_column
--! @see eql_v2.add_search_config
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
