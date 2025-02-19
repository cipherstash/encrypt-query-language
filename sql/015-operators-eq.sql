-- Operators for unique comparisons of cs_encrypted_v1 types
--
-- Support for the following comparisons:
--
--      cs_encrypted_v1 = cs_encrypted_v1
--      cs_encrypted_v1 <> cs_encrypted_v1
--      cs_encrypted_v1 = jsonb
--      cs_encrypted_v1 <> jsonb
--      cs_encrypted_v1 = text
--      cs_encrypted_v1 <> text
--

DROP OPERATOR IF EXISTS = (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_encrypted_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) = cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = 0);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS = (cs_encrypted_v1, jsonb);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_encrypted_v1, b jsonb);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_encrypted_v1, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) = cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = 0);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=jsonb,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS = (jsonb, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a jsonb, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a jsonb, b cs_encrypted_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) = cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = 0);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=jsonb,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS = (cs_encrypted_v1, cs_unique_index_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_unique_index_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_unique_index_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) = b);
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_unique_index_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS = (cs_unique_index_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_unique_index_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_unique_index_v1, b cs_encrypted_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT a = cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR =(
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_unique_index_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


--- ------------------------------------------------------------


DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_encrypted_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) <> cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT cs_encrypted_ore_64_8_compare_v1(a, b) <> 0);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, jsonb);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_encrypted_v1, b jsonb);

CREATE FUNCTION cs_encrypted_neq_v1(a cs_encrypted_v1, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) <> cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT cs_encrypted_ore_64_8_compare_v1(a, b) <> 0);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=jsonb,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (jsonb, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a jsonb, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_neq_v1(a jsonb, b cs_encrypted_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) <> cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT cs_encrypted_ore_64_8_compare_v1(a, b) <> 0);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=jsonb,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, cs_unique_index_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_unique_index_v1);

--
-- Compare the cs_unique_index_v1 or return FALSE
-- cs_unique_index_v1 cannot be ore_64_8_v1
--
CREATE FUNCTION cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_unique_index_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT cs_unique_v1(a) <> b);
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_unique_index_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


--
-- Compare the cs_unique_index_v1 or return FALSE
-- cs_unique_index_v1 cannot be ore_64_8_v1
--
DROP OPERATOR IF EXISTS <> (cs_unique_index_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_unique_index_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_neq_v1(a cs_unique_index_v1, b cs_encrypted_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT a <> cs_unique_v1(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_unique_index_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


