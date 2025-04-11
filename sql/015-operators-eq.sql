-- Operators for unique comparisons of eql_v1_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v1_encrypted = eql_v1_encrypted
--      eql_v1_encrypted <> eql_v1_encrypted
--      eql_v1_encrypted = jsonb
--      eql_v1_encrypted <> jsonb
--      eql_v1_encrypted = text
--      eql_v1_encrypted <> text
--

DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_eq(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) = eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT eql_v1.ore_64_8_v1(a) = eql_v1.ore_64_8_v1(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS = (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_eq(a eql_v1_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) = eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) = eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR = (
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS = (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_eq(a jsonb, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) = eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) = eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1.unique_index);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a eql_v1_encrypted, b eql_v1.unique_index);

CREATE FUNCTION eql_v1.encrypted_eq(a eql_v1_encrypted, b eql_v1.unique_index)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) = b);
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.unique_index,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS = (eql_v1.unique_index, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a eql_v1.unique_index, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_eq(a eql_v1.unique_index, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT a = eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR =(
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=eql_v1.unique_index,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



DROP OPERATOR IF EXISTS = (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a eql_v1_encrypted, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.encrypted_eq(a eql_v1_encrypted, b eql_v1.ore_64_8_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    o boolean;
  BEGIN

    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) = b);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN o;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.ore_64_8_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS = (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_eq(a eql_v1.ore_64_8_v1, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_eq(a eql_v1.ore_64_8_v1, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    o boolean;
  BEGIN

    BEGIN
      o := (SELECT a = eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN o;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR =(
  FUNCTION=eql_v1.encrypted_eq,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



--- ------------------------------------------------------------

DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_neq(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) <> eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) <> eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_neq(a eql_v1_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) <> eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) <> eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_neq(a jsonb, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
    o boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) <> eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) <> eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN u OR o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, eql_v1.unique_index);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a eql_v1_encrypted, b eql_v1.unique_index);

--
-- Compare the eql_v1.unique_index or return FALSE
-- eql_v1.unique_index cannot be eql_v1.ore_64_8_v1
--
CREATE FUNCTION eql_v1.encrypted_neq(a eql_v1_encrypted, b eql_v1.unique_index)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT eql_v1.unique(a) <> b);
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.unique_index,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


--
-- Compare the eql_v1.unique_index or return FALSE
-- eql_v1.unique_index cannot be eql_v1.ore_64_8_v1
--
DROP OPERATOR IF EXISTS <> (eql_v1.unique_index, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a eql_v1.unique_index, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_neq(a eql_v1.unique_index, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    u boolean;
  BEGIN
    BEGIN
      u := (SELECT a <> eql_v1.unique(b));
    EXCEPTION WHEN OTHERS THEN
      u := false;
    END;

    RETURN u;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=eql_v1.unique_index,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);




DROP OPERATOR IF EXISTS <> (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a eql_v1_encrypted, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.encrypted_neq(a eql_v1_encrypted, b eql_v1.ore_64_8_v1)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    o boolean;
  BEGIN
    BEGIN
      o := (SELECT eql_v1.cs_ore_64_8(a) <> b);
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.ore_64_8_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_neq(a eql_v1.ore_64_8_v1, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_neq(a eql_v1.ore_64_8_v1, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    o boolean;
  BEGIN

    BEGIN
      o := (SELECT a <> eql_v1.cs_ore_64_8(b));
    EXCEPTION WHEN OTHERS THEN
      o := false;
    END;

    RETURN o;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1.encrypted_neq,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



