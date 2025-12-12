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
--! @param jsonb containing encrypted EQL payload
--! @return eql_v2_encrypted[] Array of encrypted STE vector elements
--!
--! @see eql_v2.ste_vec(eql_v2_encrypted)
--! @see eql_v2.ste_vec_contains
CREATE FUNCTION eql_v2.ste_vec(val jsonb)
  RETURNS public.eql_v2_encrypted[]
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv jsonb;
    ary public.eql_v2_encrypted[];
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
--! @param eql_v2_encrypted Encrypted column value
--! @return eql_v2_encrypted[] Array of encrypted STE vector elements
--!
--! @see eql_v2.ste_vec(jsonb)
CREATE FUNCTION eql_v2.ste_vec(val eql_v2_encrypted)
  RETURNS public.eql_v2_encrypted[]
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.ste_vec(val.data));
  END;
$$ LANGUAGE plpgsql;

--! @brief Check if JSONB payload is a single-element STE vector
--!
--! Tests whether the encrypted data payload contains an 'sv' field with exactly
--! one element. Single-element STE vectors can be treated as regular encrypted values.
--!
--! @param jsonb containing encrypted EQL payload
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
--! @param eql_v2_encrypted Encrypted column value
--! @return Boolean True if value is a single-element STE vector
--!
--! @see eql_v2.is_ste_vec_value(jsonb)
CREATE FUNCTION eql_v2.is_ste_vec_value(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.is_ste_vec_value(val.data);
  END;
$$ LANGUAGE plpgsql;

--! @brief Convert single-element STE vector to regular encrypted value
--!
--! Extracts the single element from a single-element STE vector and returns it
--! as a regular encrypted value, preserving metadata. If the input is not a
--! single-element STE vector, returns it unchanged.
--!
--! @param jsonb containing encrypted EQL payload
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
--! @param eql_v2_encrypted Encrypted column value
--! @return eql_v2_encrypted Regular encrypted value (unwrapped if single-element STE vector)
--!
--! @see eql_v2.to_ste_vec_value(jsonb)
CREATE FUNCTION eql_v2.to_ste_vec_value(val eql_v2_encrypted)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.to_ste_vec_value(val.data);
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract selector value from JSONB payload
--!
--! Extracts the selector ('s') field from an encrypted data payload.
--! Selectors are used to match STE vector elements during containment queries.
--!
--! @param jsonb containing encrypted EQL payload
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
--! @param eql_v2_encrypted Encrypted column value
--! @return Text The selector value
--!
--! @see eql_v2.selector(jsonb)
CREATE FUNCTION eql_v2.selector(val eql_v2_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.selector(val.data));
  END;
$$ LANGUAGE plpgsql;



--! @brief Check if JSONB payload is marked as an STE vector array
--!
--! Tests whether the encrypted data payload has the 'a' (array) flag set to true,
--! indicating it represents an array for STE vector operations.
--!
--! @param jsonb containing encrypted EQL payload
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
--! @param eql_v2_encrypted Encrypted column value
--! @return Boolean True if value is marked as an STE vector array
--!
--! @see eql_v2.is_ste_vec_array(jsonb)
CREATE FUNCTION eql_v2.is_ste_vec_array(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.is_ste_vec_array(val.data));
  END;
$$ LANGUAGE plpgsql;



--! @brief Extract full encrypted JSONB elements as array
--!
--! Extracts all JSONB elements from the STE vector including non-deterministic fields.
--! Use jsonb_array() instead for GIN indexing and containment queries.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return jsonb[] Array of full JSONB elements
--!
--! @see eql_v2.jsonb_array
CREATE FUNCTION eql_v2.jsonb_array_from_array_elements(val jsonb)
RETURNS jsonb[]
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT CASE
    WHEN val ? 'sv' THEN
      ARRAY(SELECT elem FROM jsonb_array_elements(val->'sv') AS elem)
    ELSE
      ARRAY[val]
  END;
$$;


--! @brief Extract full encrypted JSONB elements as array from encrypted column
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return jsonb[] Array of full JSONB elements
--!
--! @see eql_v2.jsonb_array_from_array_elements(jsonb)
CREATE FUNCTION eql_v2.jsonb_array_from_array_elements(val eql_v2_encrypted)
RETURNS jsonb[]
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array_from_array_elements(val.data);
$$;


--! @brief Extract deterministic fields as array for GIN indexing
--!
--! Extracts only deterministic search term fields (s, b3, hm, ocv, ocf) from each
--! STE vector element. Excludes non-deterministic ciphertext for correct containment
--! comparison using PostgreSQL's native @> operator.
--!
--! @param val jsonb containing encrypted EQL payload
--! @return jsonb[] Array of JSONB elements with only deterministic fields
--!
--! @note Use this for GIN indexes and containment queries
--! @see eql_v2.jsonb_contains
CREATE FUNCTION eql_v2.jsonb_array(val jsonb)
RETURNS jsonb[]
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT ARRAY(
    SELECT jsonb_object_agg(kv.key, kv.value)
    FROM jsonb_array_elements(
      CASE WHEN val ? 'sv' THEN val->'sv' ELSE jsonb_build_array(val) END
    ) AS elem,
    LATERAL jsonb_each(elem) AS kv(key, value)
    WHERE kv.key IN ('s', 'b3', 'hm', 'ocv', 'ocf')
    GROUP BY elem
  );
$$;


--! @brief Extract deterministic fields as array from encrypted column
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return jsonb[] Array of JSONB elements with only deterministic fields
--!
--! @see eql_v2.jsonb_array(jsonb)
CREATE FUNCTION eql_v2.jsonb_array(val eql_v2_encrypted)
RETURNS jsonb[]
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(val.data);
$$;


--! @brief GIN-indexable JSONB containment check
--!
--! Checks if encrypted value 'a' contains all JSONB elements from 'b'.
--! Uses jsonb[] arrays internally for native PostgreSQL GIN index support.
--!
--! This function is designed for use with a GIN index on jsonb_array(column).
--! When combined with such an index, PostgreSQL can efficiently search large tables.
--!
--! @param a eql_v2_encrypted Container value (typically a table column)
--! @param b eql_v2_encrypted Value to search for
--! @return Boolean True if a contains all elements of b
--!
--! @example
--! -- Create GIN index for efficient containment queries
--! CREATE INDEX idx ON mytable USING GIN (eql_v2.jsonb_array(encrypted_col));
--!
--! -- Query using the helper function
--! SELECT * FROM mytable WHERE eql_v2.jsonb_contains(encrypted_col, search_value);
--!
--! @see eql_v2.jsonb_array
CREATE FUNCTION eql_v2.jsonb_contains(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(a) @> eql_v2.jsonb_array(b);
$$;


--! @brief GIN-indexable JSONB containment check (encrypted, jsonb)
--!
--! Checks if encrypted value 'a' contains all JSONB elements from jsonb value 'b'.
--! Uses jsonb[] arrays internally for native PostgreSQL GIN index support.
--!
--! @param a eql_v2_encrypted Container value (typically a table column)
--! @param b jsonb JSONB value to search for
--! @return Boolean True if a contains all elements of b
--!
--! @see eql_v2.jsonb_array
--! @see eql_v2.jsonb_contains(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.jsonb_contains(a eql_v2_encrypted, b jsonb)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(a) @> eql_v2.jsonb_array(b);
$$;


--! @brief GIN-indexable JSONB containment check (jsonb, encrypted)
--!
--! Checks if jsonb value 'a' contains all JSONB elements from encrypted value 'b'.
--! Uses jsonb[] arrays internally for native PostgreSQL GIN index support.
--!
--! @param a jsonb Container JSONB value
--! @param b eql_v2_encrypted Encrypted value to search for
--! @return Boolean True if a contains all elements of b
--!
--! @see eql_v2.jsonb_array
--! @see eql_v2.jsonb_contains(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.jsonb_contains(a jsonb, b eql_v2_encrypted)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(a) @> eql_v2.jsonb_array(b);
$$;


--! @brief GIN-indexable JSONB "is contained by" check
--!
--! Checks if all JSONB elements from 'a' are contained in 'b'.
--! Uses jsonb[] arrays internally for native PostgreSQL GIN index support.
--!
--! @param a eql_v2_encrypted Value to check (typically a table column)
--! @param b eql_v2_encrypted Container value
--! @return Boolean True if all elements of a are contained in b
--!
--! @see eql_v2.jsonb_array
--! @see eql_v2.jsonb_contains
CREATE FUNCTION eql_v2.jsonb_contained_by(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(a) <@ eql_v2.jsonb_array(b);
$$;


--! @brief GIN-indexable JSONB "is contained by" check (encrypted, jsonb)
--!
--! Checks if all JSONB elements from encrypted value 'a' are contained in jsonb value 'b'.
--! Uses jsonb[] arrays internally for native PostgreSQL GIN index support.
--!
--! @param a eql_v2_encrypted Value to check (typically a table column)
--! @param b jsonb Container JSONB value
--! @return Boolean True if all elements of a are contained in b
--!
--! @see eql_v2.jsonb_array
--! @see eql_v2.jsonb_contained_by(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.jsonb_contained_by(a eql_v2_encrypted, b jsonb)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(a) <@ eql_v2.jsonb_array(b);
$$;


--! @brief GIN-indexable JSONB "is contained by" check (jsonb, encrypted)
--!
--! Checks if all JSONB elements from jsonb value 'a' are contained in encrypted value 'b'.
--! Uses jsonb[] arrays internally for native PostgreSQL GIN index support.
--!
--! @param a jsonb Value to check
--! @param b eql_v2_encrypted Container encrypted value
--! @return Boolean True if all elements of a are contained in b
--!
--! @see eql_v2.jsonb_array
--! @see eql_v2.jsonb_contained_by(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.jsonb_contained_by(a jsonb, b eql_v2_encrypted)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v2.jsonb_array(a) <@ eql_v2.jsonb_array(b);
$$;


--! @brief Check if STE vector array contains a specific encrypted element
--!
--! Tests whether any element in the STE vector array 'a' contains the encrypted value 'b'.
--! Matching requires both the selector and encrypted value to be equal.
--! Used internally by ste_vec_contains(encrypted, encrypted) for array containment checks.
--!
--! @param eql_v2_encrypted[] STE vector array to search within
--! @param eql_v2_encrypted Encrypted element to search for
--! @return Boolean True if b is found in any element of a
--!
--! @note Compares both selector and encrypted value for match
--!
--! @see eql_v2.selector
--! @see eql_v2.ste_vec_contains(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.ste_vec_contains(a public.eql_v2_encrypted[], b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    result boolean;
    _a public.eql_v2_encrypted;
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
    sv_a public.eql_v2_encrypted[];
    sv_b public.eql_v2_encrypted[];
    _b public.eql_v2_encrypted;
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
