
-- REQUIRE: src/encrypted/types.sql


--! @brief Convert JSONB to encrypted type
--!
--! Wraps a JSONB encrypted payload into the eql_v2_encrypted composite type.
--! Used internally for type conversions and operator implementations.
--!
--! @param jsonb JSONB encrypted payload with structure: {"c": "...", "i": {...}, "k": "...", "v": "2"}
--! @return eql_v2_encrypted Encrypted value wrapped in composite type
--!
--! @note This is primarily used for implicit casts in operator expressions
--! @see eql_v2.to_jsonb
CREATE FUNCTION eql_v2.to_encrypted(data jsonb)
    RETURNS public.eql_v2_encrypted
    IMMUTABLE STRICT PARALLEL SAFE
    LANGUAGE SQL
AS $$
    SELECT ROW(data)::public.eql_v2_encrypted;
$$;


--! @brief Implicit cast from JSONB to encrypted type
--!
--! Enables PostgreSQL to automatically convert JSONB values to eql_v2_encrypted
--! in assignment contexts and comparison operations.
--!
--! @see eql_v2.to_encrypted(jsonb)
CREATE CAST (jsonb AS public.eql_v2_encrypted)
	WITH FUNCTION eql_v2.to_encrypted(jsonb) AS ASSIGNMENT;


--! @brief Convert text to encrypted type
--!
--! Parses a text representation of encrypted JSONB payload and wraps it
--! in the eql_v2_encrypted composite type.
--!
--! @param text Text representation of JSONB encrypted payload
--! @return eql_v2_encrypted Encrypted value wrapped in composite type
--!
--! @note Delegates to eql_v2.to_encrypted(jsonb) after parsing text as JSON
--! @see eql_v2.to_encrypted(jsonb)
CREATE FUNCTION eql_v2.to_encrypted(data text)
    RETURNS public.eql_v2_encrypted
    IMMUTABLE STRICT PARALLEL SAFE
    LANGUAGE SQL
AS $$
    SELECT eql_v2.to_encrypted(data::jsonb);
$$;


--! @brief Implicit cast from text to encrypted type
--!
--! Enables PostgreSQL to automatically convert text JSON strings to eql_v2_encrypted
--! in assignment contexts.
--!
--! @see eql_v2.to_encrypted(text)
CREATE CAST (text AS public.eql_v2_encrypted)
	WITH FUNCTION eql_v2.to_encrypted(text) AS ASSIGNMENT;



--! @brief Convert encrypted type to JSONB
--!
--! Extracts the underlying JSONB payload from an eql_v2_encrypted composite type.
--! Useful for debugging or when raw encrypted payload access is needed.
--!
--! @param e eql_v2_encrypted Encrypted value to unwrap
--! @return jsonb Raw JSONB encrypted payload
--!
--! @note Returns the raw encrypted structure including ciphertext and index terms
--! @see eql_v2.to_encrypted(jsonb)
CREATE FUNCTION eql_v2.to_jsonb(e public.eql_v2_encrypted)
    RETURNS jsonb
    IMMUTABLE STRICT PARALLEL SAFE
    LANGUAGE SQL
AS $$
    SELECT e.data;
$$;

--! @brief Implicit cast from encrypted type to JSONB
--!
--! Enables PostgreSQL to automatically extract the JSONB payload from
--! eql_v2_encrypted values in assignment contexts.
--!
--! @see eql_v2.to_jsonb(eql_v2_encrypted)
CREATE CAST (public.eql_v2_encrypted AS jsonb)
	WITH FUNCTION eql_v2.to_jsonb(public.eql_v2_encrypted) AS ASSIGNMENT;



