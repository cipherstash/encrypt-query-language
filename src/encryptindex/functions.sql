--! @file encryptindex/functions.sql
--! @brief Configuration lifecycle and column encryption management
--!
--! Provides functions for managing encryption configuration transitions:
--! - Comparing configurations to identify changes
--! - Identifying columns needing encryption
--! - Creating and renaming encrypted columns during initial setup
--! - Tracking encryption progress
--!
--! These functions support the workflow of activating a pending configuration
--! and performing the initial encryption of plaintext columns.


--! @brief Compare two configurations and find differences
--! @internal
--!
--! Returns table/column pairs where configuration differs between two configs.
--! Used to identify which columns need encryption when activating a pending config.
--!
--! @param a jsonb First configuration to compare
--! @param b jsonb Second configuration to compare
--! @return TABLE(table_name text, column_name text) Columns with differing configuration
--!
--! @note Compares configuration structure, not just presence/absence
--! @see eql_v2.select_pending_columns
CREATE FUNCTION eql_v2.diff_config(a JSONB, b JSONB)
	RETURNS TABLE(table_name TEXT, column_name TEXT)
IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
    WITH table_keys AS (
      SELECT jsonb_object_keys(a->'tables') AS key
      UNION
      SELECT jsonb_object_keys(b->'tables') AS key
    ),
    column_keys AS (
      SELECT tk.key AS table_key, jsonb_object_keys(a->'tables'->tk.key) AS column_key
      FROM table_keys tk
      UNION
      SELECT tk.key AS table_key, jsonb_object_keys(b->'tables'->tk.key) AS column_key
      FROM table_keys tk
    )
    SELECT
      ck.table_key AS table_name,
      ck.column_key AS column_name
    FROM
      column_keys ck
    WHERE
      (a->'tables'->ck.table_key->ck.column_key IS DISTINCT FROM b->'tables'->ck.table_key->ck.column_key);
  END;
$$ LANGUAGE plpgsql;


--! @brief Get columns with pending configuration changes
--!
--! Compares 'pending' and 'active' configurations to identify columns that need
--! encryption or re-encryption. Returns columns where configuration differs.
--!
--! @return TABLE(table_name text, column_name text) Columns needing encryption
--! @throws Exception if no pending configuration exists
--!
--! @note Treats missing active config as empty config
--! @see eql_v2.diff_config
--! @see eql_v2.select_target_columns
CREATE FUNCTION eql_v2.select_pending_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT)
AS $$
	DECLARE
		active JSONB;
		pending JSONB;
		config_id BIGINT;
	BEGIN
		SELECT data INTO active FROM eql_v2_configuration WHERE state = 'active';

		-- set default config
    IF active IS NULL THEN
      active := '{}';
    END IF;

		SELECT id, data INTO config_id, pending FROM eql_v2_configuration WHERE state = 'pending';

		-- set default config
		IF config_id IS NULL THEN
			RAISE EXCEPTION 'No pending configuration exists to encrypt';
		END IF;

		RETURN QUERY
		SELECT d.table_name, d.column_name FROM eql_v2.diff_config(active, pending) as d;
	END;
$$ LANGUAGE plpgsql;


--! @brief Map pending columns to their encrypted target columns
--!
--! For each column with pending configuration, identifies the corresponding
--! encrypted column. During initial encryption, target is '{column_name}_encrypted'.
--! Returns NULL for target_column if encrypted column doesn't exist yet.
--!
--! @return TABLE(table_name text, column_name text, target_column text) Column mappings
--!
--! @note Target column is NULL if no column exists matching either 'column_name' or 'column_name_encrypted' with type eql_v2_encrypted
--! @note The LEFT JOIN checks both original and '_encrypted' suffix variations with type verification
--! @see eql_v2.select_pending_columns
--! @see eql_v2.create_encrypted_columns
CREATE FUNCTION eql_v2.select_target_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
	STABLE STRICT PARALLEL SAFE
AS $$
  SELECT
    c.table_name,
    c.column_name,
    s.column_name as target_column
  FROM
    eql_v2.select_pending_columns() c
  LEFT JOIN information_schema.columns s ON
    s.table_name = c.table_name AND
    (s.column_name = c.column_name OR s.column_name = c.column_name || '_encrypted') AND
    s.udt_name = 'eql_v2_encrypted';
$$ LANGUAGE sql;


--! @brief Check if database is ready for encryption
--!
--! Verifies that all columns with pending configuration have corresponding
--! encrypted target columns created. Returns true if encryption can proceed.
--!
--! @return boolean True if all pending columns have target encrypted columns
--!
--! @note Returns false if any pending column lacks encrypted column
--! @see eql_v2.select_target_columns
--! @see eql_v2.create_encrypted_columns
CREATE FUNCTION eql_v2.ready_for_encryption()
	RETURNS BOOLEAN
	STABLE STRICT PARALLEL SAFE
AS $$
	SELECT EXISTS (
	  SELECT *
	  FROM eql_v2.select_target_columns() AS c
	  WHERE c.target_column IS NOT NULL);
$$ LANGUAGE sql;


--! @brief Create encrypted columns for initial encryption
--!
--! For each plaintext column with pending configuration that lacks an encrypted
--! target column, creates a new column '{column_name}_encrypted' of type
--! eql_v2_encrypted. This prepares the database schema for initial encryption.
--!
--! @return TABLE(table_name text, column_name text) Created encrypted columns
--!
--! @warning Executes dynamic DDL (ALTER TABLE ADD COLUMN) - modifies database schema
--! @note Only creates columns that don't already exist
--! @see eql_v2.select_target_columns
--! @see eql_v2.rename_encrypted_columns
CREATE FUNCTION eql_v2.create_encrypted_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT)
AS $$
	BEGIN
    FOR table_name, column_name IN
      SELECT c.table_name, (c.column_name || '_encrypted') FROM eql_v2.select_target_columns() AS c WHERE c.target_column IS NULL
    LOOP
		  EXECUTE format('ALTER TABLE %I ADD column %I eql_v2_encrypted;', table_name, column_name);
      RETURN NEXT;
    END LOOP;
	END;
$$ LANGUAGE plpgsql;


--! @brief Finalize initial encryption by renaming columns
--!
--! After initial encryption completes, renames columns to complete the transition:
--! - Plaintext column '{column_name}' → '{column_name}_plaintext'
--! - Encrypted column '{column_name}_encrypted' → '{column_name}'
--!
--! This makes the encrypted column the primary column with the original name.
--!
--! @return TABLE(table_name text, column_name text, target_column text) Renamed columns
--!
--! @warning Executes dynamic DDL (ALTER TABLE RENAME COLUMN) - modifies database schema
--! @note Only renames columns where target is '{column_name}_encrypted'
--! @see eql_v2.create_encrypted_columns
CREATE FUNCTION eql_v2.rename_encrypted_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
AS $$
	BEGIN
    FOR table_name, column_name, target_column IN
      SELECT * FROM eql_v2.select_target_columns() as c WHERE c.target_column = c.column_name || '_encrypted'
    LOOP
		  EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, column_name, column_name || '_plaintext');
		  EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, target_column, column_name);
      RETURN NEXT;
    END LOOP;
	END;
$$ LANGUAGE plpgsql;


--! @brief Count rows encrypted with active configuration
--! @internal
--!
--! Counts rows in a table where the encrypted column was encrypted using
--! the currently active configuration. Used to track encryption progress.
--!
--! @param table_name text Name of table to check
--! @param column_name text Name of encrypted column to check
--! @return bigint Count of rows encrypted with active configuration
--!
--! @note The 'v' field in encrypted payloads stores the payload version ("2"), not the configuration ID
--! @note Configuration tracking mechanism is implementation-specific
CREATE FUNCTION eql_v2.count_encrypted_with_active_config(table_name TEXT, column_name TEXT)
  RETURNS BIGINT
AS $$
DECLARE
  result BIGINT;
BEGIN
	EXECUTE format(
        'SELECT COUNT(%I) FROM %s t WHERE %I->>%L = (SELECT id::TEXT FROM eql_v2_configuration WHERE state = %L)',
        column_name, table_name, column_name, 'v', 'active'
    )
	INTO result;
  	RETURN result;
END;
$$ LANGUAGE plpgsql;

