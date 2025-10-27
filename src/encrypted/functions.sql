-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/bloom_filter/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/hmac_256/types.sql

--! @brief Extract ciphertext from encrypted JSONB value
--!
--! Extracts the ciphertext (c field) from a raw JSONB encrypted value.
--! The ciphertext is the base64-encoded encrypted data.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Text Base64-encoded ciphertext string
--! @throws Exception if 'c' field is not present in JSONB
--!
--! @example
--! -- Extract ciphertext from JSONB literal
--! SELECT eql_v2.ciphertext('{"c":"AQIDBA==","i":{"unique":"..."}}'::jsonb);
--!
--! @see eql_v2.ciphertext(eql_v2_encrypted)
--! @see eql_v2.meta_data
CREATE FUNCTION eql_v2.ciphertext(val jsonb)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'c' THEN
      RETURN val->>'c';
    END IF;
    RAISE 'Expected a ciphertext (c) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract ciphertext from encrypted column value
--!
--! Extracts the ciphertext from an encrypted column value. Convenience
--! overload that unwraps eql_v2_encrypted type and delegates to JSONB version.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Text Base64-encoded ciphertext string
--! @throws Exception if encrypted value is malformed
--!
--! @example
--! -- Extract ciphertext from encrypted column
--! SELECT eql_v2.ciphertext(encrypted_email) FROM users;
--!
--! @see eql_v2.ciphertext(jsonb)
--! @see eql_v2.meta_data
CREATE FUNCTION eql_v2.ciphertext(val eql_v2_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.ciphertext(val.data);
  END;
$$ LANGUAGE plpgsql;

--! @brief State transition function for grouped_value aggregate
--! @internal
--!
--! Returns the first non-null value encountered. Used as state function
--! for the grouped_value aggregate to select first value in each group.
--!
--! @param $1 JSONB Accumulated state (first non-null value found)
--! @param $2 JSONB New value from current row
--! @return JSONB First non-null value (state or new value)
--!
--! @see eql_v2.grouped_value
CREATE FUNCTION eql_v2._first_grouped_value(jsonb, jsonb)
RETURNS jsonb AS $$
  SELECT COALESCE($1, $2);
$$ LANGUAGE sql IMMUTABLE;

--! @brief Return first non-null encrypted value in a group
--!
--! Aggregate function that returns the first non-null encrypted value
--! encountered within a GROUP BY clause. Useful for deduplication or
--! selecting representative values from grouped encrypted data.
--!
--! @param input JSONB Encrypted values to aggregate
--! @return JSONB First non-null encrypted value in group
--!
--! @example
--! -- Get first email per user group
--! SELECT user_id, eql_v2.grouped_value(encrypted_email)
--! FROM user_emails
--! GROUP BY user_id;
--!
--! -- Deduplicate encrypted values
--! SELECT DISTINCT ON (user_id)
--!   user_id,
--!   eql_v2.grouped_value(encrypted_ssn) as primary_ssn
--! FROM user_records
--! GROUP BY user_id;
--!
--! @see eql_v2._first_grouped_value
CREATE AGGREGATE eql_v2.grouped_value(jsonb) (
  SFUNC = eql_v2._first_grouped_value,
  STYPE = jsonb
);

--! @brief Add validation constraint to encrypted column
--!
--! Adds a CHECK constraint to ensure column values conform to encrypted data
--! structure. Constraint uses eql_v2.check_encrypted to validate format.
--! Called automatically by eql_v2.add_column.
--!
--! @param table_name TEXT Name of table containing the column
--! @param column_name TEXT Name of column to constrain
--! @return Void
--!
--! @example
--! -- Manually add constraint (normally done by add_column)
--! SELECT eql_v2.add_encrypted_constraint('users', 'encrypted_email');
--!
--! -- Resulting constraint:
--! -- ALTER TABLE users ADD CONSTRAINT eql_v2_encrypted_check_encrypted_email
--! --   CHECK (eql_v2.check_encrypted(encrypted_email));
--!
--! @see eql_v2.add_column
--! @see eql_v2.remove_encrypted_constraint
CREATE FUNCTION eql_v2.add_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
	BEGIN
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT eql_v2_encrypted_constraint_%I_%I CHECK (eql_v2.check_encrypted(%I))', table_name, table_name, column_name, column_name);
  EXCEPTION
    WHEN duplicate_table THEN
    WHEN duplicate_object THEN
      RAISE NOTICE 'Constraint `eql_v2_encrypted_constraint_%_%` already exists, skipping', table_name, column_name;
  END;
$$ LANGUAGE plpgsql;

--! @brief Remove validation constraint from encrypted column
--!
--! Removes the CHECK constraint that validates encrypted data structure.
--! Called automatically by eql_v2.remove_column. Uses IF EXISTS to avoid
--! errors if constraint doesn't exist.
--!
--! @param table_name TEXT Name of table containing the column
--! @param column_name TEXT Name of column to unconstrain
--! @return Void
--!
--! @example
--! -- Manually remove constraint (normally done by remove_column)
--! SELECT eql_v2.remove_encrypted_constraint('users', 'encrypted_email');
--!
--! @see eql_v2.remove_column
--! @see eql_v2.add_encrypted_constraint
CREATE FUNCTION eql_v2.remove_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
	BEGIN
		EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS eql_v2_encrypted_constraint_%I_%I', table_name, table_name, column_name);
	END;
$$ LANGUAGE plpgsql;

--! @brief Extract metadata from encrypted JSONB value
--!
--! Extracts index terms (i) and version (v) from a raw JSONB encrypted value.
--! Returns metadata object containing searchable index terms without ciphertext.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return JSONB Metadata object with 'i' (index terms) and 'v' (version) fields
--!
--! @example
--! -- Extract metadata to inspect index terms
--! SELECT eql_v2.meta_data('{"c":"...","i":{"unique":"abc123"},"v":1}'::jsonb);
--! -- Returns: {"i":{"unique":"abc123"},"v":1}
--!
--! @see eql_v2.meta_data(eql_v2_encrypted)
--! @see eql_v2.ciphertext
CREATE FUNCTION eql_v2.meta_data(val jsonb)
  RETURNS jsonb
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
     RETURN jsonb_build_object(
      'i', val->'i',
      'v', val->'v'
    );
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract metadata from encrypted column value
--!
--! Extracts index terms and version from an encrypted column value.
--! Convenience overload that unwraps eql_v2_encrypted type and
--! delegates to JSONB version.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return JSONB Metadata object with 'i' (index terms) and 'v' (version) fields
--!
--! @example
--! -- Inspect index terms for encrypted column
--! SELECT user_id, eql_v2.meta_data(encrypted_email) as email_metadata
--! FROM users;
--!
--! @see eql_v2.meta_data(jsonb)
--! @see eql_v2.ciphertext
CREATE FUNCTION eql_v2.meta_data(val eql_v2_encrypted)
  RETURNS jsonb
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
     RETURN eql_v2.meta_data(val.data);
  END;
$$ LANGUAGE plpgsql;

