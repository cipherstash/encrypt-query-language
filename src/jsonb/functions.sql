-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql

-- The jsonpath operators @? and @@ suppress the following errors:
--      missing object field or array element,
--      unexpected JSON item type,
--      datetime and numeric errors.
-- The jsonpath-related functions described below can also be told to suppress these types of errors.
-- This behavior might be helpful when searching JSON document collections of varying structure.



--
--
-- Returns the stevec encrypted element matching the selector
--
-- If the selector is not found, the function returns NULL
-- If the selector is found, the function returns the matching element
--
-- Array elements use the same selector
-- Multiple matching elements are wrapped into an eql_v1_encrypted with an array flag
--
--
-- DROP FUNCTION IF EXISTS eql_v1.jsonb_path_query(val jsonb, selector text);

CREATE FUNCTION eql_v1.jsonb_path_query(val jsonb, selector text)
  RETURNS SETOF eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v1_encrypted[];
    found jsonb[];
    e jsonb;
    ary boolean;
  BEGIN

    IF val IS NULL THEN
      RETURN NEXT NULL;
    END IF;

    sv := eql_v1.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      e := sv[idx];

      IF eql_v1.selector(e) = selector THEN
        found := array_append(found, e);
        IF eql_v1.is_ste_vec_array(e) THEN
          ary := true;
        END IF;

      END IF;
    END LOOP;

    IF found IS NOT NULL THEN

      IF ary THEN

        -- Wrapp found array elements as eql_v1_encrypted
        RETURN NEXT jsonb_build_object(
          'sv', found,
          'a', 1
        )::eql_v1_encrypted;

      ELSE
        RETURN NEXT found[1]::eql_v1_encrypted;
      END IF;

    END IF;

    RETURN;
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_path_query(val eql_v1_encrypted, selector text);

CREATE FUNCTION eql_v1.jsonb_path_query(val eql_v1_encrypted, selector text)
  RETURNS SETOF eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
    SELECT * FROM eql_v1.jsonb_path_query(val.data, selector);
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_path_exists(val jsonb, selector text);

CREATE FUNCTION eql_v1.jsonb_path_exists(val jsonb, selector text)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN EXISTS (
      SELECT eql_v1.jsonb_path_query(val, selector)
    );
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_path_exists(val eql_v1_encrypted, selector text);

CREATE FUNCTION eql_v1.jsonb_path_exists(val eql_v1_encrypted, selector text)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN EXISTS (
      SELECT eql_v1.jsonb_path_query(val, selector)
    );
  END;
$$ LANGUAGE plpgsql;


--
--
-- DROP FUNCTION IF EXISTS eql_v1.jsonb_path_query_first(val jsonb, selector text);

CREATE FUNCTION eql_v1.jsonb_path_query_first(val jsonb, selector text)
  RETURNS eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
      SELECT (
        SELECT e
        FROM eql_v1.jsonb_path_query(val.data, selector) AS e
        LIMIT 1
      )
    );
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_path_query_first(val eql_v1_encrypted, selector text);

CREATE FUNCTION eql_v1.jsonb_path_query_first(val eql_v1_encrypted, selector text)
  RETURNS eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
        SELECT e
        FROM eql_v1.jsonb_path_query(val.data, selector) as e
        LIMIT 1
    );
  END;
$$ LANGUAGE plpgsql;



--


-- =====================================================================
--
-- Returns the length of an encrypted jsonb array
---
-- An encrypted is a jsonb array if it contains an "a" field/attribute with a truthy value
--
-- DROP FUNCTION IF EXISTS eql_v1.jsonb_array_length(val jsonb);

CREATE FUNCTION eql_v1.jsonb_array_length(val jsonb)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v1_encrypted[];
    found eql_v1_encrypted[];
  BEGIN

    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF eql_v1.is_ste_vec_array(val) THEN
      sv := eql_v1.ste_vec(val);
      RETURN array_length(sv, 1);
    END IF;

    RAISE 'cannot get array length of a non-array';
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_array_length(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.jsonb_array_length(val eql_v1_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (
      SELECT eql_v1.jsonb_array_length(val.data)
    );
  END;
$$ LANGUAGE plpgsql;




-- =====================================================================
--
-- Returns the length of an encrypted jsonb array
---
-- An encrypted is a jsonb array if it contains an "a" field/attribute with a truthy value
--
-- DROP FUNCTION IF EXISTS eql_v1.jsonb_array_elements(val jsonb);

CREATE FUNCTION eql_v1.jsonb_array_elements(val jsonb)
  RETURNS SETOF eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v1_encrypted[];
    found eql_v1_encrypted[];
  BEGIN

    IF NOT eql_v1.is_ste_vec_array(val) THEN
      RAISE 'cannot extract elements from non-array';
    END IF;

    sv := eql_v1.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      RETURN NEXT sv[idx];
    END LOOP;

    RETURN;
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_array_elements(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.jsonb_array_elements(val eql_v1_encrypted)
  RETURNS SETOF eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
      SELECT * FROM eql_v1.jsonb_array_elements(val.data);
  END;
$$ LANGUAGE plpgsql;



-- =====================================================================
--
-- Returns the length of an encrypted jsonb array
---
-- An encrypted is a jsonb array if it contains an "a" field/attribute with a truthy value
--
-- DROP FUNCTION IF EXISTS eql_v1.jsonb_array_elements_text(val jsonb);

CREATE FUNCTION eql_v1.jsonb_array_elements_text(val jsonb)
  RETURNS SETOF text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v1_encrypted[];
    found eql_v1_encrypted[];
  BEGIN
    IF NOT eql_v1.is_ste_vec_array(val) THEN
      RAISE 'cannot extract elements from non-array';
    END IF;

    sv := eql_v1.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      RETURN NEXT eql_v1.ciphertext(sv[idx]);
    END LOOP;

    RETURN;
  END;
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.jsonb_array_elements_text(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.jsonb_array_elements_text(val eql_v1_encrypted)
  RETURNS SETOF text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN QUERY
      SELECT * FROM eql_v1.jsonb_array_elements_text(val.data);
  END;
$$ LANGUAGE plpgsql;
