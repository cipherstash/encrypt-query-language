-- Operators for match comparisons of eql_v1_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v1_encrypted > >= < <=  eql_v1_encrypted
--      eql_v1_encrypted > jsonb
--      eql_v1_encrypted > ore_64_8_v1
--

DROP OPERATOR IF EXISTS > (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) > eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gt",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


DROP OPERATOR IF EXISTS > (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1_encrypted, b jsonb)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) > eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gt",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


DROP OPERATOR IF EXISTS > (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1_encrypted, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1_encrypted, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) > b;
$$ LANGUAGE SQL;

CREATE OPERATOR >(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gt",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);



DROP OPERATOR IF EXISTS > (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gt(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gt(a jsonb, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) > eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gt",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


DROP OPERATOR IF EXISTS > (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT a > eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gt",
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


-----------------------------------------------------------------------------------------
-- LT


DROP OPERATOR IF EXISTS < (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) < eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lt",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS < (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1_encrypted, b jsonb)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) < eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lt",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS < (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lt(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lt(a jsonb, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) < eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lt",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



DROP OPERATOR IF EXISTS <(eql_v1_encrypted, ore_64_8_v1);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1_encrypted, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1_encrypted, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) < b;
$$ LANGUAGE SQL;

CREATE OPERATOR <(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lt",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS <(eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT a < eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lt",
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


-----------------------------------------------------------------------------------------


DROP OPERATOR IF EXISTS >=(eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) >= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gte",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >= (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1_encrypted, b jsonb)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) >= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gte",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >= (eql_v1_encrypted, eql_v1.ore_64_8_v1);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1_encrypted, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1_encrypted, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) >= b;
$$ LANGUAGE SQL;

CREATE OPERATOR >=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gte",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >= (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gte(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gte(a jsonb, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) >= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gte",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >=(eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT a >= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR >=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_gte",
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


-----------------------------------------------------------------------------------------


DROP OPERATOR IF EXISTS <= (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) <= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lte",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS <= (eql_v1_encrypted, jsonb);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1_encrypted, b jsonb)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) <= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lte",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS <= (jsonb, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lte(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lte(a jsonb, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) <= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lte",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS <= (eql_v1_encrypted, ore_64_8_v1);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1_encrypted, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1_encrypted, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.ore_64_8_v1(a) <= b;
$$ LANGUAGE SQL;

CREATE OPERATOR <=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lte",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS <= (eql_v1.ore_64_8_v1, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT a <= eql_v1.ore_64_8_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <=(
  PROCEDURE="eql_v1.encrypted_ore_64_8_v1_lte",
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1_encrypted,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


-----------------------------------------------------------------------------------------


DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_compare(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_compare(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS integer AS $$
  BEGIN
    RETURN eql_v1.compare_ore_64_8_v1(eql_v1.ore_64_8_v1(a), eql_v1.ore_64_8_v1(b));
  END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS eql_v1.encrypted_ore_64_8_compare(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1.encrypted_ore_64_8_compare(a eql_v1_encrypted, b jsonb)
  RETURNS integer AS $$
  BEGIN
    RETURN eql_v1.compare_ore_64_8_v1(eql_v1.ore_64_8_v1(a), eql_v1.ore_64_8_v1(b));
  END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v1.encrypted_ore_64_8_compare(a eql_v1_encrypted, b jsonb)
  RETURNS integer AS $$
  BEGIN
    RETURN eql_v1.compare_ore_64_8_v1(eql_v1.ore_64_8_v1(a), eql_v1.ore_64_8_v1(b));
  END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------


DROP OPERATOR FAMILY IF EXISTS eql_v1.encrypted_ore_64_8_v1_btree_op USING btree;

CREATE OPERATOR FAMILY eql_v1.encrypted_ore_64_8_v1_btree_op USING btree;


DROP OPERATOR CLASS IF EXISTS eql_v1.ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.cs_encrypted_ore_64_8_v1_btree_ops_v1 DEFAULT
FOR TYPE eql_v1_encrypted USING btree
  FAMILY eql_v1.cs_encrypted_ore_64_8_v1_btree_ops_v1 AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 eql_v1.encrypted_ore_64_8_compare(a eql_v1_encrypted, b eql_v1_encrypted);
