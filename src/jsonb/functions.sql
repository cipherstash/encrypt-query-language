-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @file jsonb/functions.sql
--! @brief JSONB path query and array manipulation functions for encrypted data
--!
--! These functions provide PostgreSQL-compatible operations on encrypted JSONB values
--! using Structured Transparent Encryption (STE). They support:
--! - Path-based queries to extract nested encrypted values
--! - Existence checks for encrypted fields
--! - Array operations (length, elements extraction)
--! - Field-level HMAC term extraction for equality / GROUP BY / DISTINCT
--!
--! @note STE stores encrypted JSONB as a vector of encrypted elements ('sv') with selectors
--! @note Functions suppress errors for missing fields, type mismatches (similar to PostgreSQL jsonpath)
--! @note `selector` parameters in this module are *encrypted-side* selector
--!       hashes — the deterministic hash that the crypto layer (e.g.
--!       `@cipherstash/protect`) emits in the `s` field of each `sv` element
--!       (e.g. `'a7cea93975ed8c01f861ccb6bd082784'`). Plaintext JSONPaths
--!       like `'$.address.city'` are never accepted at runtime; the proxy /
--!       client rewrites them to selector hashes before the query reaches EQL.


--! @brief Query encrypted JSONB for elements matching selector
--!
--! Searches the Structured Transparent Encryption (STE) vector for elements matching
--! the given selector path. Returns all matching encrypted elements. If multiple
--! matches form an array, they are wrapped with array metadata.
--!
--! @param jsonb Encrypted JSONB payload containing STE vector ('sv')
--! @param text Path selector to match against encrypted elements
--! @return SETOF eql_v2_encrypted Matching encrypted elements (may return multiple rows)
--!
--! @note Returns empty set if selector is not found (does not throw exception)
--! @note Array elements use same selector; multiple matches wrapped with 'a' flag
--! @note Returns a set containing NULL if val is NULL; returns empty set if no matches found
--! @see eql_v2.jsonb_path_query_first
--! @see eql_v2.jsonb_path_exists
CREATE FUNCTION eql_v2.jsonb_path_query(val jsonb, selector text)
  RETURNS SETOF eql_v2_encrypted
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT
    CASE
      WHEN bool_or(eql_v2.is_ste_vec_array(elem)) THEN
        (eql_v2.meta_data(val) || jsonb_build_object('sv', jsonb_agg(elem), 'a', 1))::eql_v2_encrypted
      ELSE
        (eql_v2.meta_data(val) || (array_agg(elem))[1])::eql_v2_encrypted
    END
  FROM jsonb_array_elements(val -> 'sv') elem
  WHERE elem ->> 's' = selector
  HAVING count(*) > 0
$$;


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
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT * FROM eql_v2.jsonb_path_query((val).data, eql_v2._selector(selector));
$$;


--! @brief Query encrypted JSONB with text selector
--!
--! Overload that accepts encrypted JSONB value and text selector,
--! extracting the JSONB payload before querying.
--!
--! @param eql_v2_encrypted Encrypted JSONB value to query
--! @param text Path selector to match against
--! @return SETOF eql_v2_encrypted Matching encrypted elements
--!
--! @example
--! -- Query encrypted JSONB for the sv element at a given selector hash
--! SELECT * FROM eql_v2.jsonb_path_query(encrypted_document, 'a7cea93975ed8c01f861ccb6bd082784');
--!
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query(val eql_v2_encrypted, selector text)
  RETURNS SETOF eql_v2_encrypted
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT * FROM eql_v2.jsonb_path_query((val).data, selector);
$$;


------------------------------------------------------------------------------------


--! @brief Check if selector path exists in encrypted JSONB
--!
--! Tests whether any encrypted elements match the given selector path.
--! More efficient than jsonb_path_query when only existence check is needed.
--!
--! @param jsonb Encrypted JSONB payload to check
--! @param text Path selector to test
--! @return boolean True if matching element exists, false otherwise
--!
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_exists(val jsonb, selector text)
  RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM jsonb_array_elements(val -> 'sv') elem
    WHERE elem ->> 's' = selector
  );
$$;


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
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.jsonb_path_exists((val).data, eql_v2._selector(selector));
$$;


--! @brief Check existence with text selector
--!
--! Overload that accepts encrypted JSONB value and text selector.
--!
--! @param eql_v2_encrypted Encrypted JSONB value to check
--! @param text Path selector to test
--! @return boolean True if path exists
--!
--! @example
--! -- Check if the encrypted document has an sv element at a given selector hash
--! SELECT eql_v2.jsonb_path_exists(encrypted_document, 'a7cea93975ed8c01f861ccb6bd082784');
--!
--! @see eql_v2.jsonb_path_exists(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector text)
  RETURNS boolean
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.jsonb_path_exists((val).data, selector);
$$;


------------------------------------------------------------------------------------


--! @brief Get first element matching selector
--!
--! Returns only the first encrypted element matching the selector path,
--! or NULL if no match found. More efficient than jsonb_path_query when
--! only one result is needed.
--!
--! @param jsonb Encrypted JSONB payload to query
--! @param text Path selector to match
--! @return eql_v2_encrypted First matching element or NULL
--!
--! @note Uses LIMIT 1 internally for efficiency
--! @see eql_v2.jsonb_path_query(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query_first(val jsonb, selector text)
  RETURNS eql_v2_encrypted
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (eql_v2.meta_data(val) || elem)::eql_v2_encrypted
  FROM jsonb_array_elements(val -> 'sv') elem
  WHERE elem ->> 's' = selector
  LIMIT 1
$$;


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
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.jsonb_path_query_first((val).data, eql_v2._selector(selector));
$$;


--! @brief Get first element with text selector
--!
--! Overload that accepts encrypted JSONB value and text selector.
--!
--! @param eql_v2_encrypted Encrypted JSONB value to query
--! @param text Path selector to match
--! @return eql_v2_encrypted First matching element or NULL
--!
--! @example
--! -- Get the first matching sv element from an encrypted document
--! SELECT eql_v2.jsonb_path_query_first(encrypted_document, 'a7cea93975ed8c01f861ccb6bd082784');
--!
--! @see eql_v2.jsonb_path_query_first(jsonb, text)
CREATE FUNCTION eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector text)
  RETURNS eql_v2_encrypted
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.jsonb_path_query_first((val).data, selector);
$$;



------------------------------------------------------------------------------------


--! @brief Get length of encrypted JSONB array
--!
--! Returns the number of elements in an encrypted JSONB array by counting
--! elements in the STE vector ('sv'). The encrypted value must have the
--! array flag ('a') set to true.
--!
--! @param jsonb Encrypted JSONB payload representing an array
--! @return integer Number of elements in the array
--! @throws Exception 'cannot get array length of a non-array' if 'a' flag is missing or not true
--!
--! @note Array flag 'a' must be present and set to true value
--! @see eql_v2.jsonb_array_elements
CREATE FUNCTION eql_v2.jsonb_array_length(val jsonb)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
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
--! @param eql_v2_encrypted Encrypted array value
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
  SET search_path = pg_catalog, extensions, public
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
--! @param jsonb Encrypted JSONB payload representing an array
--! @return SETOF eql_v2_encrypted One row per array element
--! @throws Exception if value is not an array (missing 'a' flag)
--!
--! @note Each element inherits metadata (version, ident) from parent
--! @see eql_v2.jsonb_array_length
--! @see eql_v2.jsonb_array_elements_text
CREATE FUNCTION eql_v2.jsonb_array_elements(val jsonb)
  RETURNS SETOF eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
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
--! @param eql_v2_encrypted Encrypted array value
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
  SET search_path = pg_catalog, extensions, public
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
--! @param jsonb Encrypted JSONB payload representing an array
--! @return SETOF text One ciphertext string per array element
--! @throws Exception if value is not an array (missing 'a' flag)
--!
--! @note Returns ciphertext only, not full encrypted structure
--! @see eql_v2.jsonb_array_elements
CREATE FUNCTION eql_v2.jsonb_array_elements_text(val jsonb)
  RETURNS SETOF text
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
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
--! @param eql_v2_encrypted Encrypted array value
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
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN QUERY
      SELECT * FROM eql_v2.jsonb_array_elements_text(val.data);
  END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------------------


--! @brief Extract HMAC-SHA256 index term for a specific ste_vec selector
--!
--! Field-level equality extractor: walks the encrypted value's sv array,
--! finds the element whose selector matches @p selector, and returns its
--! `hm` term. Mirrors the root-level `eql_v2.hmac_256(val)` at the field
--! level so the same hash/index/equality recipes compose.
--!
--! Single-statement SQL — inlinable into the calling query, so a btree
--! hash index built on `eql_v2.hmac_256(col, '<selector-hash>')` engages
--! structurally for WHERE / GROUP BY / DISTINCT / hash-join.
--!
--! @param val      eql_v2_encrypted Encrypted column value
--! @param selector text             Encrypted-side selector hash (see file-level note)
--! @return eql_v2.hmac_256 HMAC-SHA256 hash for that selector's element, or NULL
--!
--! @note Returns NULL if @p selector matches no sv element, or if the
--!       matched element carries no `hm`.
--!
--! @see eql_v2.hmac_256(eql_v2_encrypted)
--! @see eql_v2.hmac_256_terms
--! @see eql_v2.ste_vec_contains
--!
--! @example
--! CREATE INDEX users_data_email_idx ON users
--!   USING hash (eql_v2.hmac_256(data_encrypted, 'a7cea93975ed8c01f861ccb6bd082784'));
--! SELECT count(*) FROM users
--!   GROUP BY eql_v2.hmac_256(data_encrypted, 'a7cea93975ed8c01f861ccb6bd082784');
CREATE FUNCTION eql_v2.hmac_256(val eql_v2_encrypted, selector text)
  RETURNS eql_v2.hmac_256
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (elem ->> 'hm')::eql_v2.hmac_256
  FROM jsonb_array_elements((val).data -> 'sv') elem
  WHERE elem ->> 's' = selector
  LIMIT 1
$$;


--! @brief Aggregate all (selector, hmac) pairs from ste_vec elements
--!
--! Returns a jsonb array of `{"s": <selector>, "hm": <hmac>}` objects, one
--! per sv element that carries an `hm` term. Designed for use with a GIN
--! index — one index covers field-level equality / containment across
--! every selector in the encrypted document, instead of one per selector.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return jsonb Array of `{s, hm}` objects (empty array when no sv elements)
--!
--! @note Selector values in `s` are the deterministic selector hashes
--!       emitted by the crypto layer, not plaintext JSONPaths. See the
--!       file-level @note for the convention.
--!
--! @see eql_v2.hmac_256(eql_v2_encrypted, text)
--!
--! @example
--! CREATE INDEX users_data_hmac_terms_idx
--!   ON users USING gin (eql_v2.hmac_256_terms(data_encrypted));
--!
--! SELECT * FROM users
--!   WHERE eql_v2.hmac_256_terms(data_encrypted)
--!       @> '[{"s":"a7cea93975ed8c01f861ccb6bd082784","hm":"<hash>"}]'::jsonb;
CREATE FUNCTION eql_v2.hmac_256_terms(val eql_v2_encrypted)
  RETURNS jsonb
  LANGUAGE sql
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object('s', elem ->> 's', 'hm', elem ->> 'hm')
    ),
    '[]'::jsonb
  )
  FROM jsonb_array_elements((val).data -> 'sv') elem
  WHERE elem ->> 'hm' IS NOT NULL
$$;
