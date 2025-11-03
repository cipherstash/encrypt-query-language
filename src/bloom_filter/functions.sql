-- REQUIRE: src/schema.sql


--! @brief Extract Bloom filter index term from JSONB payload
--!
--! Extracts the Bloom filter array from the 'bf' field of an encrypted
--! data payload. Used internally for pattern-match queries (LIKE operator).
--!
--! @param val jsonb containing encrypted EQL payload
--! @return eql_v2.bloom_filter Bloom filter as smallint array
--! @throws Exception if 'bf' field is missing when bloom_filter index is expected
--!
--! @see eql_v2.has_bloom_filter
--! @see eql_v2."~~"
CREATE FUNCTION eql_v2.bloom_filter(val jsonb)
  RETURNS eql_v2.bloom_filter
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF eql_v2.has_bloom_filter(val) THEN
      RETURN ARRAY(SELECT jsonb_array_elements(val->'bf'))::eql_v2.bloom_filter;
    END IF;

    RAISE 'Expected a match index (bf) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract Bloom filter index term from encrypted column value
--!
--! Extracts the Bloom filter from an encrypted column value by accessing
--! its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2.bloom_filter Bloom filter as smallint array
--!
--! @see eql_v2.bloom_filter(jsonb)
CREATE FUNCTION eql_v2.bloom_filter(val eql_v2_encrypted)
  RETURNS eql_v2.bloom_filter
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.bloom_filter($1));
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains Bloom filter index term
--!
--! Tests whether the encrypted data payload includes a 'bf' field,
--! indicating a Bloom filter is available for pattern-match queries.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Boolean True if 'bf' field is present and non-null
--!
--! @see eql_v2.bloom_filter
CREATE FUNCTION eql_v2.has_bloom_filter(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ->> 'bf' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains Bloom filter index term
--!
--! Tests whether an encrypted column value includes a Bloom filter
--! by checking its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if Bloom filter is present
--!
--! @see eql_v2.has_bloom_filter(jsonb)
CREATE FUNCTION eql_v2.has_bloom_filter(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_bloom_filter($1);
  END;
$$ LANGUAGE plpgsql;
