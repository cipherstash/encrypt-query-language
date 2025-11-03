-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/casts.sql
-- REQUIRE: src/encrypted/functions.sql


--! @brief Extract STE vector index from JSONB payload
--!
--! Extracts the STE (Searchable Symmetric Encryption) vector from the 'sv' field
--! of an encrypted data payload. Returns an array of encrypted values used for
--! containment queries (@>, <@). If no 'sv' field exists, wraps the entire payload
--! as a single-element array.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return eql_v2_encrypted[] Array of encrypted STE vector elements
--!
--! @see eql_v2.ste_vec(eql_v2_encrypted)
--! @see eql_v2.ste_vec_contains
CREATE FUNCTION eql_v2.ste_vec(val jsonb)
  RETURNS eql_v2_encrypted[]
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv jsonb;
    ary eql_v2_encrypted[];
	BEGIN

    IF val ? 'sv' THEN
      sv := val->'sv';
    ELSE
      sv := jsonb_build_array(val);
    END IF;

    SELECT array_agg(eql_v2.to_encrypted(elem))
      INTO ary
      FROM jsonb_array_elements(sv) AS elem;

    RETURN ary;
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract STE vector index from encrypted column value
--!
--! Extracts the STE vector from an encrypted column value by accessing its
--! underlying JSONB data field. Used for containment query operations.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2_encrypted[] Array of encrypted STE vector elements
--!
--! @see eql_v2.ste_vec(jsonb)
CREATE FUNCTION eql_v2.ste_vec(val eql_v2_encrypted)
  RETURNS eql_v2_encrypted[]
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.ste_vec($1));
  END;
$$ LANGUAGE plpgsql;

--! @brief Check if JSONB payload is a single-element STE vector
--!
--! Tests whether the encrypted data payload contains an 'sv' field with exactly
--! one element. Single-element STE vectors can be treated as regular encrypted values.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Boolean True if 'sv' field exists with exactly one element
--!
--! @see eql_v2.to_ste_vec_value
CREATE FUNCTION eql_v2.is_ste_vec_value(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'sv' THEN
      RETURN jsonb_array_length(val->'sv') = 1;
    END IF;

    RETURN false;
  END;
$$ LANGUAGE plpgsql;

--! @brief Check if encrypted column value is a single-element STE vector
--!
--! Tests whether an encrypted column value is a single-element STE vector
--! by checking its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if value is a single-element STE vector
--!
--! @see eql_v2.is_ste_vec_value(jsonb)
CREATE FUNCTION eql_v2.is_ste_vec_value(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.is_ste_vec_value($1);
  END;
$$ LANGUAGE plpgsql;

--! @brief Convert single-element STE vector to regular encrypted value
--!
--! Extracts the single element from a single-element STE vector and returns it
--! as a regular encrypted value, preserving metadata. If the input is not a
--! single-element STE vector, returns it unchanged.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return eql_v2_encrypted Regular encrypted value (unwrapped if single-element STE vector)
--!
--! @see eql_v2.is_ste_vec_value
CREATE FUNCTION eql_v2.to_ste_vec_value(val jsonb)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    meta jsonb;
    sv jsonb;
	BEGIN

    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF eql_v2.is_ste_vec_value(val) THEN
      meta := eql_v2.meta_data(val);
      sv := val->'sv';
      sv := sv[0];

      RETURN eql_v2.to_encrypted(meta || sv);
    END IF;

    RETURN eql_v2.to_encrypted(val);
  END;
$$ LANGUAGE plpgsql;

--! @brief Convert single-element STE vector to regular encrypted value (encrypted type)
--!
--! Converts an encrypted column value to a regular encrypted value by unwrapping
--! if it's a single-element STE vector.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2_encrypted Regular encrypted value (unwrapped if single-element STE vector)
--!
--! @see eql_v2.to_ste_vec_value(jsonb)
CREATE FUNCTION eql_v2.to_ste_vec_value(val eql_v2_encrypted)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.to_ste_vec_value($1);
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract selector value from JSONB payload
--!
--! Extracts the selector ('s') field from an encrypted data payload.
--! Selectors are used to match STE vector elements during containment queries.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Text The selector value
--! @throws Exception if 's' field is missing
--!
--! @see eql_v2.ste_vec_contains
CREATE FUNCTION eql_v2.selector(val jsonb)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF val ? 's' THEN
      RETURN val->>'s';
    END IF;
    RAISE 'Expected a selector index (s) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract selector value from encrypted column value
--!
--! Extracts the selector from an encrypted column value by accessing its
--! underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Text The selector value
--!
--! @see eql_v2.selector(jsonb)
CREATE FUNCTION eql_v2.selector(val eql_v2_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.selector($1));
  END;
$$ LANGUAGE plpgsql;



--! @brief Check if JSONB payload is marked as an STE vector array
--!
--! Tests whether the encrypted data payload has the 'a' (array) flag set to true,
--! indicating it represents an array for STE vector operations.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return Boolean True if 'a' field is present and true
--!
--! @see eql_v2.ste_vec
CREATE FUNCTION eql_v2.is_ste_vec_array(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'a' THEN
      RETURN (val->>'a')::boolean;
    END IF;

    RETURN false;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value is marked as an STE vector array
--!
--! Tests whether an encrypted column value has the array flag set by checking
--! its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if value is marked as an STE vector array
--!
--! @see eql_v2.is_ste_vec_array(jsonb)
CREATE FUNCTION eql_v2.is_ste_vec_array(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.is_ste_vec_array($1));
  END;
$$ LANGUAGE plpgsql;



--! @brief Check if STE vector array contains a specific encrypted element
--!
--! Tests whether any element in the STE vector array 'a' contains the encrypted value 'b'.
--! Matching requires both the selector and encrypted value to be equal.
--! Used internally by ste_vec_contains(encrypted, encrypted) for array containment checks.
--!
--! @param a eql_v2_encrypted[] STE vector array to search within
--! @param b eql_v2_encrypted Encrypted element to search for
--! @return Boolean True if b is found in any element of a
--!
--! @note Compares both selector and encrypted value for match
--!
--! @see eql_v2.selector
--! @see eql_v2.ste_vec_contains(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.ste_vec_contains(a eql_v2_encrypted[], b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    result boolean;
    _a eql_v2_encrypted;
  BEGIN

    result := false;

    FOR idx IN 1..array_length(a, 1) LOOP
      _a := a[idx];
      result := result OR (eql_v2.selector(_a) = eql_v2.selector(b) AND _a = b);
    END LOOP;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted value 'a' contains all elements of encrypted value 'b'
--!
--! Performs STE vector containment comparison between two encrypted values.
--! Returns true if all elements in b's STE vector are found in a's STE vector.
--! Used internally by the @> containment operator for searchable encryption.
--!
--! @param a eql_v2_encrypted First encrypted value (container)
--! @param b eql_v2_encrypted Second encrypted value (elements to find)
--! @return Boolean True if all elements of b are contained in a
--!
--! @note Empty b is always contained in any a
--! @note Each element of b must match both selector and value in a
--!
--! @see eql_v2.ste_vec
--! @see eql_v2.ste_vec_contains(eql_v2_encrypted[], eql_v2_encrypted)
--! @see eql_v2."@>"
CREATE FUNCTION eql_v2.ste_vec_contains(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    result boolean;
    sv_a eql_v2_encrypted[];
    sv_b eql_v2_encrypted[];
    _b eql_v2_encrypted;
  BEGIN

    -- jsonb arrays of ste_vec encrypted values
    sv_a := eql_v2.ste_vec(a);
    sv_b := eql_v2.ste_vec(b);

    -- an empty b is always contained in a
    IF array_length(sv_b, 1) IS NULL THEN
      RETURN true;
    END IF;

    IF array_length(sv_a, 1) IS NULL THEN
      RETURN false;
    END IF;

    result := true;

    -- for each element of b check if it is in a
    FOR idx IN 1..array_length(sv_b, 1) LOOP
      _b := sv_b[idx];
      result := result AND eql_v2.ste_vec_contains(sv_a, _b);
    END LOOP;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;
