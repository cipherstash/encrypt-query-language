-- Return the diff of two configurations
-- Returns the set of keys in a that have different values to b
-- The json comparison is on object values held by the key
DROP FUNCTION IF EXISTS eql_v1.diff_config(a JSONB, b JSONB);

CREATE FUNCTION eql_v1.diff_config(a JSONB, b JSONB)
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


-- Returns the set of columns with pending configuration changes
-- Compares the columns in pending configuration that do not match the active config
DROP FUNCTION IF EXISTS eql_v1.select_pending_columns();

CREATE FUNCTION eql_v1.select_pending_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT)
AS $$
	DECLARE
		active JSONB;
		pending JSONB;
		config_id BIGINT;
	BEGIN
		SELECT data INTO active FROM eql_v1_configuration WHERE state = 'active';

		-- set default config
    IF active IS NULL THEN
      active := '{}';
    END IF;

		SELECT id, data INTO config_id, pending FROM eql_v1_configuration WHERE state = 'pending';

		-- set default config
		IF config_id IS NULL THEN
			RAISE EXCEPTION 'No pending configuration exists to encrypt';
		END IF;

		RETURN QUERY
		SELECT d.table_name, d.column_name FROM eql_v1.diff_config(active, pending) as d;
	END;
$$ LANGUAGE plpgsql;

--
-- Returns the target columns with pending configuration
--
-- A `pending` column may be either a plaintext variant or eql_v1_encrypted.
-- A `target` column is always of type eql_v1_encrypted
--
-- On initial encryption from plaintext the target column will be `{column_name}_encrypted `
-- OR NULL if the column does not exist
--
DROP FUNCTION IF EXISTS eql_v1.select_target_columns();

CREATE FUNCTION eql_v1.select_target_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
	STABLE STRICT PARALLEL SAFE
AS $$
  SELECT
    c.table_name,
    c.column_name,
    s.column_name as target_column
  FROM
    eql_v1.select_pending_columns() c
  LEFT JOIN information_schema.columns s ON
    s.table_name = c.table_name AND
    (s.column_name = c.column_name OR s.column_name = c.column_name || '_encrypted') AND
    s.udt_name = 'eql_v1_encrypted';
$$ LANGUAGE sql;


--
-- Returns true if all pending columns have a target (encrypted) column
DROP FUNCTION IF EXISTS eql_v1.ready_for_encryption();

CREATE FUNCTION eql_v1.ready_for_encryption()
	RETURNS BOOLEAN
	STABLE STRICT PARALLEL SAFE
AS $$
	SELECT EXISTS (
	  SELECT *
	  FROM eql_v1.select_target_columns() AS c
	  WHERE c.target_column IS NOT NULL);
$$ LANGUAGE sql;


--
-- Creates eql_v1_encrypted columns for any plaintext columns with pending configuration
-- The new column name is `{column_name}_encrypted`
--
-- Executes the ALTER TABLE statement
--   `ALTER TABLE {target_table} ADD COLUMN {column_name}_encrypted eql_v1_encrypted;`
--
DROP FUNCTION IF EXISTS eql_v1.create_encrypted_columns();

CREATE FUNCTION eql_v1.create_encrypted_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT)
AS $$
	BEGIN
    FOR table_name, column_name IN
      SELECT c.table_name, (c.column_name || '_encrypted') FROM eql_v1.select_target_columns() AS c WHERE c.target_column IS NULL
    LOOP
		  EXECUTE format('ALTER TABLE %I ADD column %I eql_v1_encrypted;', table_name, column_name);
      RETURN NEXT;
    END LOOP;
	END;
$$ LANGUAGE plpgsql;


--
-- Renames plaintext and eql_v1_encrypted columns created for the initial encryption.
-- The source plaintext column is renamed to `{column_name}_plaintext`
-- The target encrypted column is renamed from `{column_name}_encrypted` to `{column_name}`
--
-- Executes the ALTER TABLE statements
--   `ALTER TABLE {target_table} RENAME COLUMN {column_name} TO {column_name}_plaintext;
--   `ALTER TABLE {target_table} RENAME COLUMN {column_name}_encrypted TO {column_name};`
--
DROP FUNCTION IF EXISTS eql_v1.rename_encrypted_columns();

CREATE FUNCTION eql_v1.rename_encrypted_columns()
	RETURNS TABLE(table_name TEXT, column_name TEXT, target_column TEXT)
AS $$
	BEGIN
    FOR table_name, column_name, target_column IN
      SELECT * FROM eql_v1.select_target_columns() as c WHERE c.target_column = c.column_name || '_encrypted'
    LOOP
		  EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, column_name, column_name || '_plaintext');
		  EXECUTE format('ALTER TABLE %I RENAME %I TO %I;', table_name, target_column, column_name);
      RETURN NEXT;
    END LOOP;
	END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.count_encrypted_with_active_config(table_name TEXT, column_name TEXT);

CREATE FUNCTION eql_v1.count_encrypted_with_active_config(table_name TEXT, column_name TEXT)
  RETURNS BIGINT
AS $$
DECLARE
  result BIGINT;
BEGIN
	EXECUTE format(
        'SELECT COUNT(%I) FROM %s t WHERE %I->>%L = (SELECT id::TEXT FROM eql_v1_configuration WHERE state = %L)',
        column_name, table_name, column_name, 'v', 'active'
    )
	INTO result;
  	RETURN result;
END;
$$ LANGUAGE plpgsql;

