-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/casts.sql
-- REQUIRE: src/encrypted/functions.sql


--
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


-- extracts ste_vec index from an eql_v2_encrypted value

CREATE FUNCTION eql_v2.ste_vec(val eql_v2_encrypted)
  RETURNS eql_v2_encrypted[]
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.ste_vec(val.data));
  END;
$$ LANGUAGE plpgsql;

--
-- Returns true if val is an SteVec with a single array item.
-- SteVec value items can be treated as regular eql_encrypted
--
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

CREATE FUNCTION eql_v2.is_ste_vec_value(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.is_ste_vec_value(val.data);
  END;
$$ LANGUAGE plpgsql;

--
-- Returns an SteVec with a single array item as an eql_encrypted
--
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

CREATE FUNCTION eql_v2.to_ste_vec_value(val eql_v2_encrypted)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.to_ste_vec_value(val.data);
  END;
$$ LANGUAGE plpgsql;

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


-- extracts ste_vec index from an eql_v2_encrypted value

CREATE FUNCTION eql_v2.selector(val eql_v2_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.selector(val.data));
  END;
$$ LANGUAGE plpgsql;



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


-- extracts ste_vec index from an eql_v2_encrypted value

CREATE FUNCTION eql_v2.is_ste_vec_array(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.is_ste_vec_array(val.data));
  END;
$$ LANGUAGE plpgsql;



-- Returns true if b is contained in any element of a
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


-- Returns true if a contains b
-- All values of b must be in a
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
