-- REQUIRE: src/schema.sql

--! @brief Extract Blake3 hash index term from JSONB payload
--!
--! Extracts the Blake3 hash value from the 'b3' field of an encrypted
--! data payload. Used internally for exact-match comparisons.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return eql_v2.blake3 Blake3 hash value, or NULL if not present
--! @throws Exception if 'b3' field is missing when blake3 index is expected
--!
--! @see eql_v2.has_blake3
--! @see eql_v2.compare_blake3
CREATE FUNCTION eql_v2.blake3(val jsonb)
  RETURNS eql_v2.blake3
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF NOT eql_v2.has_blake3(val) THEN
        RAISE 'Expected a blake3 index (b3) value in json: %', val;
    END IF;

    IF val->>'b3' IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN val->>'b3';
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract Blake3 hash index term from encrypted column value
--!
--! Extracts the Blake3 hash from an encrypted column value by accessing
--! its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2.blake3 Blake3 hash value, or NULL if not present
--!
--! @see eql_v2.blake3(jsonb)
CREATE FUNCTION eql_v2.blake3(val eql_v2_encrypted)
  RETURNS eql_v2.blake3
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.blake3(val.data));
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains Blake3 index term
--!
--! Tests whether the encrypted data payload includes a 'b3' field,
--! indicating a Blake3 hash is available for exact-match queries.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Boolean True if 'b3' field is present and non-null
--!
--! @see eql_v2.blake3
CREATE FUNCTION eql_v2.has_blake3(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ->> 'b3' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains Blake3 index term
--!
--! Tests whether an encrypted column value includes a Blake3 hash
--! by checking its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if Blake3 hash is present
--!
--! @see eql_v2.has_blake3(jsonb)
CREATE FUNCTION eql_v2.has_blake3(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_blake3(val.data);
  END;
$$ LANGUAGE plpgsql;

