-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql


--! @brief Validate presence of ident field in encrypted payload
--! @internal
--!
--! Checks that the encrypted JSONB payload contains the required 'i' (ident) field.
--! The ident field tracks which table and column the encrypted value belongs to.
--!
--! @param val jsonb Encrypted payload to validate
--! @return boolean True if 'i' field is present
--! @throws Exception if 'i' field is missing
--!
--! @note Used in CHECK constraints to ensure payload structure
--! @see eql_v2.check_encrypted
CREATE FUNCTION eql_v2._encrypted_check_i(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF val ? 'i' THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing ident (i) field: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Validate table and column fields in ident
--! @internal
--!
--! Checks that the 'i' (ident) field contains both 't' (table) and 'c' (column)
--! subfields, which identify the origin of the encrypted value.
--!
--! @param val jsonb Encrypted payload to validate
--! @return boolean True if both 't' and 'c' subfields are present
--! @throws Exception if 't' or 'c' subfields are missing
--!
--! @note Used in CHECK constraints to ensure payload structure
--! @see eql_v2.check_encrypted
CREATE FUNCTION eql_v2._encrypted_check_i_ct(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val->'i' ?& array['t', 'c']) THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column ident (i) missing table (t) or column (c) fields: %', val;
  END;
$$ LANGUAGE plpgsql;

--! @brief Validate version field in encrypted payload
--! @internal
--!
--! Checks that the encrypted payload has version field 'v' set to '2',
--! the current EQL v2 payload version.
--!
--! @param val jsonb Encrypted payload to validate
--! @return boolean True if 'v' field is present and equals '2'
--! @throws Exception if 'v' field is missing or not '2'
--!
--! @note Used in CHECK constraints to ensure payload structure
--! @see eql_v2.check_encrypted
CREATE FUNCTION eql_v2._encrypted_check_v(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'v') THEN

      IF val->>'v' <> '2' THEN
        RAISE 'Expected encrypted column version (v) 2';
        RETURN false;
      END IF;

      RETURN true;
    END IF;
    RAISE 'Encrypted column missing version (v) field: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Validate ciphertext field in encrypted payload
--! @internal
--!
--! Checks that the encrypted payload contains the required 'c' (ciphertext) field
--! which stores the encrypted data.
--!
--! @param val jsonb Encrypted payload to validate
--! @return boolean True if 'c' field is present
--! @throws Exception if 'c' field is missing
--!
--! @note Used in CHECK constraints to ensure payload structure
--! @see eql_v2.check_encrypted
CREATE FUNCTION eql_v2._encrypted_check_c(val jsonb)
  RETURNS boolean
AS $$
	BEGIN
    IF (val ? 'c') THEN
      RETURN true;
    END IF;
    RAISE 'Encrypted column missing ciphertext (c) field: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Validate complete encrypted payload structure
--!
--! Comprehensive validation function that checks all required fields in an
--! encrypted JSONB payload: version ('v'), ciphertext ('c'), ident ('i'),
--! and ident subfields ('t', 'c').
--!
--! This function is used in CHECK constraints to ensure encrypted column
--! data integrity at the database level.
--!
--! @param val jsonb Encrypted payload to validate
--! @return Boolean True if all structure checks pass
--! @throws Exception if any required field is missing or invalid
--!
--! @example
--! -- Add validation constraint to encrypted column
--! ALTER TABLE users ADD CONSTRAINT check_email_encrypted
--!   CHECK (eql_v2.check_encrypted(encrypted_email::jsonb));
--!
--! @see eql_v2._encrypted_check_v
--! @see eql_v2._encrypted_check_c
--! @see eql_v2._encrypted_check_i
--! @see eql_v2._encrypted_check_i_ct
CREATE FUNCTION eql_v2.check_encrypted(val jsonb)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
    RETURN (
      eql_v2._encrypted_check_v(val) AND
      eql_v2._encrypted_check_c(val) AND
      eql_v2._encrypted_check_i(val) AND
      eql_v2._encrypted_check_i_ct(val)
    );
END;


--! @brief Validate encrypted composite type structure
--!
--! Validates an eql_v2_encrypted composite type by checking its underlying
--! JSONB payload. Delegates to eql_v2.check_encrypted(jsonb).
--!
--! @param val eql_v2_encrypted Encrypted value to validate
--! @return Boolean True if structure is valid
--! @throws Exception if any required field is missing or invalid
--!
--! @see eql_v2.check_encrypted(jsonb)
CREATE FUNCTION eql_v2.check_encrypted(val eql_v2_encrypted)
  RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
    RETURN eql_v2.check_encrypted(val.data);
END;

