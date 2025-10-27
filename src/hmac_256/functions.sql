-- REQUIRE: src/schema.sql
-- REQUIRE: src/hmac_256/types.sql

--! @brief Extract HMAC-SHA256 index term from JSONB payload
--!
--! Extracts the HMAC-SHA256 hash value from the 'hm' field of an encrypted
--! data payload. Used internally for exact-match comparisons.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return eql_v2.hmac_256 HMAC-SHA256 hash value
--! @throws Exception if 'hm' field is missing when hmac_256 index is expected
--!
--! @see eql_v2.has_hmac_256
--! @see eql_v2.compare_hmac_256
CREATE FUNCTION eql_v2.hmac_256(val jsonb)
  RETURNS eql_v2.hmac_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF eql_v2.has_hmac_256(val) THEN
      RETURN val->>'hm';
    END IF;
    RAISE 'Expected a hmac_256 index (hm) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains HMAC-SHA256 index term
--!
--! Tests whether the encrypted data payload includes an 'hm' field,
--! indicating an HMAC-SHA256 hash is available for exact-match queries.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Boolean True if 'hm' field is present and non-null
--!
--! @see eql_v2.hmac_256
CREATE FUNCTION eql_v2.has_hmac_256(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ->> 'hm' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains HMAC-SHA256 index term
--!
--! Tests whether an encrypted column value includes an HMAC-SHA256 hash
--! by checking its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if HMAC-SHA256 hash is present
--!
--! @see eql_v2.has_hmac_256(jsonb)
CREATE FUNCTION eql_v2.has_hmac_256(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_hmac_256(val.data);
  END;
$$ LANGUAGE plpgsql;



--! @brief Extract HMAC-SHA256 index term from encrypted column value
--!
--! Extracts the HMAC-SHA256 hash from an encrypted column value by accessing
--! its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2.hmac_256 HMAC-SHA256 hash value
--!
--! @see eql_v2.hmac_256(jsonb)
CREATE FUNCTION eql_v2.hmac_256(val eql_v2_encrypted)
  RETURNS eql_v2.hmac_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.hmac_256(val.data));
  END;
$$ LANGUAGE plpgsql;


