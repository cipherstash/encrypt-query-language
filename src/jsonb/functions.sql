-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql

--! @file jsonb/functions.sql
--! @brief JSONB path query and array manipulation functions for encrypted data
--!
--! These functions provide PostgreSQL-compatible operations on encrypted JSONB values
--! using Structured Transparent Encryption (STE). They support:
--! - Path-based queries to extract nested encrypted values
--! - Existence checks for encrypted fields
--! - Array operations (length, elements extraction)
--!
--! @note STE stores encrypted JSONB as a vector of encrypted elements ('sv') with selectors
--! @note Functions suppress errors for missing fields, type mismatches (similar to PostgreSQL jsonpath)


--! @brief Query encrypted JSONB for elements matching selector
--!
--! Searches the Structured Transparent Encryption (STE) vector for elements matching
--! the given selector path. Returns all matching encrypted elements. If multiple
--! matches form an array, they are wrapped with array metadata.
--!
--! @param val jsonb Encrypted JSONB payload containing STE vector ('sv')
--! @param selector text Path selector to match against encrypted elements
--! @return SETOF eql_v2_encrypted Matching encrypted elements (may return multiple rows)
--!
--! @throws Exception if selector is not found (returns empty set instead)
--!
--! @note Array elements use same selector; multiple matches wrapped with 'a' flag
--! @note Returns NULL if val is NULL, empty set if no matches
--! @see eql_v2.jsonb_path_query_first
--! @see eql_v2.jsonb_path_exists
CREATE FUNCTION eql_v2.jsonb_path_query(val jsonb, selector text)
  RETURNS SETOF eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v2_encrypted[];
    found jsonb[];
    e jsonb;
    meta jsonb;
    ary boolean;
  BEGIN

    IF val IS NULL THEN
      RETURN NEXT NULL;
    END IF;

    -- Column identifier and version
    meta := eql_v2.meta_data(val);

    sv := eql_v2.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      e := sv[idx];

      IF eql_v2.selector(e) = selector THEN
        found := array_append(found, e);
        IF eql_v2.is_ste_vec_array(e) THEN
          ary := true;
        END IF;

      END IF;
    END LOOP;

    IF found IS NOT NULL THEN

      IF ary THEN
        -- Wrap found array elements as eql_v2_encrypted

        RETURN NEXT (meta || jsonb_build_object(
          'sv', found,
          'a', 1
        ))::eql_v2_encrypted;

      ELSE
        RETURN NEXT (meta || found[1])::eql_v2_encrypted;
      END IF;

    END IF;

    RETURN;
  END;
$$ LANGUAGE plpgsql;


--! @brief Query encrypted JSONB with encrypted selector
--!
--! Overload that accepts encrypted selector and extracts its plaintext value
--! before delegating to main jsonb_path_query implementation.
--!
--! @param val eql_v2_encrypted Encrypted JSONB value to query
--! @param selector eql_v2_encrypted Encrypted selector to match against
--! @return SETOF eql_v2_encrypted Matching encrypted elements
--!
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query(val eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS SETOF eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
    SELECT * FROM eql_v2.jsonb_path_query(val.data, eql_v2.selector(selector));
  END;
$$ LANGUAGE plpgsql;


--! @brief Query encrypted JSONB with text selector
--!
--! Overload that accepts encrypted JSONB value and text selector,
--! extracting the JSONB payload before querying.
--!
--! @param val eql_v2_encrypted Encrypted JSONB value to query
--! @param selector text Path selector to match against
--! @return SETOF eql_v2_encrypted Matching encrypted elements
--!
--! @example
--! -- Query encrypted JSONB for specific field
--! SELECT * FROM eql_v2.jsonb_path_query(encrypted_document, '$.address.city');
--!
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query(val eql_v2_encrypted, selector text)
  RETURNS SETOF eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
    SELECT * FROM eql_v2.jsonb_path_query(val.data, selector);
  END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------


--! @brief Check if selector path exists in encrypted JSONB
--!
--! Tests whether any encrypted elements match the given selector path.
--! More efficient than jsonb_path_query when only existence check is needed.
--!
--! @param val jsonb Encrypted JSONB payload to check
--! @param selector text Path selector to test
--! @return boolean True if matching element exists, false otherwise
--!
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_exists(val jsonb, selector text)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN EXISTS (
      SELECT eql_v2.jsonb_path_query(val, selector)
    );
  END;
$$ LANGUAGE plpgsql;


--! @brief Check existence with encrypted selector
--!
--! Overload that accepts encrypted selector and extracts its value
--! before checking existence.
--!
--! @param val eql_v2_encrypted Encrypted JSONB value to check
--! @param selector eql_v2_encrypted Encrypted selector to test
--! @return boolean True if path exists
--!
--! @see eql_v2.jsonb_path_exists(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN EXISTS (
      SELECT eql_v2.jsonb_path_query(val, eql_v2.selector(selector))
    );
  END;
$$ LANGUAGE plpgsql;


--! @brief Check existence with text selector
--!
--! Overload that accepts encrypted JSONB value and text selector.
--!
--! @param val eql_v2_encrypted Encrypted JSONB value to check
--! @param selector text Path selector to test
--! @return boolean True if path exists
--!
--! @example
--! -- Check if encrypted document has address field
--! SELECT eql_v2.jsonb_path_exists(encrypted_document, '$.address');
--!
--! @see eql_v2.jsonb_path_exists(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector text)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN EXISTS (
      SELECT eql_v2.jsonb_path_query(val, selector)
    );
  END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------


--! @brief Get first element matching selector
--!
--! Returns only the first encrypted element matching the selector path,
--! or NULL if no match found. More efficient than jsonb_path_query when
--! only one result is needed.
--!
--! @param val jsonb Encrypted JSONB payload to query
--! @param selector text Path selector to match
--! @return eql_v2_encrypted First matching element or NULL
--!
--! @note Uses LIMIT 1 internally for efficiency
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query_first(val jsonb, selector text)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
      SELECT (
        SELECT e
        FROM eql_v2.jsonb_path_query(val.data, selector) AS e
        LIMIT 1
      )
    );
  END;
$$ LANGUAGE plpgsql;


--! @brief Get first element with encrypted selector
--!
--! Overload that accepts encrypted selector and extracts its value
--! before querying for first match.
--!
--! @param val eql_v2_encrypted Encrypted JSONB value to query
--! @param selector eql_v2_encrypted Encrypted selector to match
--! @return eql_v2_encrypted First matching element or NULL
--!
--! @see eql_v2.jsonb_path_query_first(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
        SELECT e
        FROM eql_v2.jsonb_path_query(val.data, eql_v2.selector(selector)) as e
        LIMIT 1
    );
  END;
$$ LANGUAGE plpgsql;


--! @brief Get first element with text selector
--!
--! Overload that accepts encrypted JSONB value and text selector.
--!
--! @param val eql_v2_encrypted Encrypted JSONB value to query
--! @param selector text Path selector to match
--! @return eql_v2_encrypted First matching element or NULL
--!
--! @example
--! -- Get first matching address from encrypted document
--! SELECT eql_v2.jsonb_path_query_first(encrypted_document, '$.addresses[*]');
--!
--! @see eql_v2.jsonb_path_query_first(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector text)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
        SELECT e
        FROM eql_v2.jsonb_path_query(val.data, selector) as e
        LIMIT 1
    );
  END;
$$ LANGUAGE plpgsql;



------------------------------------------------------------------------------------


--! @brief Get length of encrypted JSONB array
--!
--! Returns the number of elements in an encrypted JSONB array by counting
--! elements in the STE vector ('sv'). The encrypted value must have the
--! array flag ('a') set to true.
--!
--! @param val jsonb Encrypted JSONB payload representing an array
--! @return integer Number of elements in the array
--! @throws Exception if value is not an array (missing 'a' flag)
--!
--! @note Array flag 'a' must be set to truthy value
--! @see eql_v2.jsonb_array_elements
CREATE FUNCTION eql_v2.jsonb_array_length(val jsonb)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v2_encrypted[];
    found eql_v2_encrypted[];
  BEGIN

    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF eql_v2.is_ste_vec_array(val) THEN
      sv := eql_v2.ste_vec(val);
      RETURN array_length(sv, 1);
    END IF;

    RAISE 'cannot get array length of a non-array';
  END;
$$ LANGUAGE plpgsql;


--! @brief Get array length from encrypted type
--!
--! Overload that accepts encrypted composite type and extracts the
--! JSONB payload before computing array length.
--!
--! @param val eql_v2_encrypted Encrypted array value
--! @return integer Number of elements in the array
--! @throws Exception if value is not an array
--!
--! @example
--! -- Get length of encrypted array
--! SELECT eql_v2.jsonb_array_length(encrypted_tags);
--!
--! @see eql_v2.jsonb_array_length(jsonb)
CREATE FUNCTION eql_v2.jsonb_array_length(val eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
      SELECT eql_v2.jsonb_array_length(val.data)
    );
  END;
$$ LANGUAGE plpgsql;




--! @brief Extract elements from encrypted JSONB array
--!
--! Returns each element of an encrypted JSONB array as a separate row.
--! Each element is returned as an eql_v2_encrypted value with metadata
--! preserved from the parent array.
--!
--! @param val jsonb Encrypted JSONB payload representing an array
--! @return SETOF eql_v2_encrypted One row per array element
--! @throws Exception if value is not an array (missing 'a' flag)
--!
--! @note Each element inherits metadata (version, ident) from parent
--! @see eql_v2.jsonb_array_length
--! @see eql_v2.jsonb_array_elements_text
CREATE FUNCTION eql_v2.jsonb_array_elements(val jsonb)
  RETURNS SETOF eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v2_encrypted[];
    meta jsonb;
    item jsonb;
  BEGIN

    IF NOT eql_v2.is_ste_vec_array(val) THEN
      RAISE 'cannot extract elements from non-array';
    END IF;

    -- Column identifier and version
    meta := eql_v2.meta_data(val);

    sv := eql_v2.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      item = sv[idx];
      RETURN NEXT (meta || item)::eql_v2_encrypted;
    END LOOP;

    RETURN;
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract elements from encrypted array type
--!
--! Overload that accepts encrypted composite type and extracts each
--! array element as a separate row.
--!
--! @param val eql_v2_encrypted Encrypted array value
--! @return SETOF eql_v2_encrypted One row per array element
--! @throws Exception if value is not an array
--!
--! @example
--! -- Expand encrypted array into rows
--! SELECT * FROM eql_v2.jsonb_array_elements(encrypted_tags);
--!
--! @see eql_v2.jsonb_array_elements(jsonb)
CREATE FUNCTION eql_v2.jsonb_array_elements(val eql_v2_encrypted)
  RETURNS SETOF eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
      SELECT * FROM eql_v2.jsonb_array_elements(val.data);
  END;
$$ LANGUAGE plpgsql;



--! @brief Extract encrypted array elements as ciphertext
--!
--! Returns each element of an encrypted JSONB array as its raw ciphertext
--! value (text representation). Unlike jsonb_array_elements, this returns
--! only the ciphertext 'c' field without metadata.
--!
--! @param val jsonb Encrypted JSONB payload representing an array
--! @return SETOF text One ciphertext string per array element
--! @throws Exception if value is not an array (missing 'a' flag)
--!
--! @note Returns ciphertext only, not full encrypted structure
--! @see eql_v2.jsonb_array_elements
CREATE FUNCTION eql_v2.jsonb_array_elements_text(val jsonb)
  RETURNS SETOF text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v2_encrypted[];
    found eql_v2_encrypted[];
  BEGIN
    IF NOT eql_v2.is_ste_vec_array(val) THEN
      RAISE 'cannot extract elements from non-array';
    END IF;

    sv := eql_v2.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      RETURN NEXT eql_v2.ciphertext(sv[idx]);
    END LOOP;

    RETURN;
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract array elements as ciphertext from encrypted type
--!
--! Overload that accepts encrypted composite type and extracts each
--! array element's ciphertext as text.
--!
--! @param val eql_v2_encrypted Encrypted array value
--! @return SETOF text One ciphertext string per array element
--! @throws Exception if value is not an array
--!
--! @example
--! -- Get ciphertext of each array element
--! SELECT * FROM eql_v2.jsonb_array_elements_text(encrypted_tags);
--!
--! @see eql_v2.jsonb_array_elements_text(jsonb)
CREATE FUNCTION eql_v2.jsonb_array_elements_text(val eql_v2_encrypted)
  RETURNS SETOF text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
      SELECT * FROM eql_v2.jsonb_array_elements_text(val.data);
  END;
$$ LANGUAGE plpgsql;
