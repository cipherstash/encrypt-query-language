
---
--- ORE CLLW types, functions, and operators
---

-- Represents a ciphertext encrypted with the CLLW ORE scheme for a fixed output size
-- Each output block is 8-bits
CREATE TYPE eql_v1.ore_cllw_8_v1 AS (
  bytes bytea
);

-- Represents a ciphertext encrypted with the CLLW ORE scheme for a variable output size
-- Each output block is 8-bits
CREATE TYPE eql_v1.ore_cllw_8_variable_v1 AS (
  bytes bytea
);

DROP FUNCTION IF EXISTS eql_v1.__bytea_ct_eq(a bytea, b bytea);

-- Constant time comparison of 2 bytea values
CREATE FUNCTION eql_v1.__bytea_ct_eq(a bytea, b bytea) RETURNS boolean AS $$
DECLARE
    result boolean;
    differing bytea;
BEGIN
    -- Check if the bytea values are the same length
    IF LENGTH(a) != LENGTH(b) THEN
        RETURN false;
    END IF;

    -- Compare each byte in the bytea values
    result := true;
    FOR i IN 1..LENGTH(a) LOOP
        IF SUBSTRING(a FROM i FOR 1) != SUBSTRING(b FROM i FOR 1) THEN
            result := result AND false;
        END IF;
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS eql_v1.__compare_inner_ore_cllw_8_v1(a bytea, b bytea);

CREATE FUNCTION eql_v1.__compare_inner_ore_cllw_8_v1(a bytea, b bytea)
RETURNS int AS $$
DECLARE
    len_a INT;
    x BYTEA;
    y BYTEA;
    i INT;
    differing RECORD;
BEGIN
    len_a := LENGTH(a);

    -- Iterate over each byte and compare them
    FOR i IN 1..len_a LOOP
        x := SUBSTRING(a FROM i FOR 1);
        y := SUBSTRING(b FROM i FOR 1);

        -- Check if there's a difference
        IF x != y THEN
            differing := (x, y);
            EXIT;
        END IF;
    END LOOP;

    -- If a difference is found, compare the bytes as in Rust logic
    IF differing IS NOT NULL THEN
        IF (get_byte(y, 0) + 1) % 256 = get_byte(x, 0) THEN
            RETURN 1;
        ELSE
            RETURN -1;
        END IF;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.compare_ore_cllw_8_v1(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.compare_ore_cllw_8_v1(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS int AS $$
DECLARE
    len_a INT;
    len_b INT;
    x BYTEA;
    y BYTEA;
    i INT;
    differing RECORD;
BEGIN
    -- Check if the lengths of the two bytea arguments are the same
    len_a := LENGTH(a.bytes);
    len_b := LENGTH(b.bytes);

    IF len_a != len_b THEN
      RAISE EXCEPTION 'Numeric ORE comparison requires bytea values of the same length';
    END IF;

    RETURN eql_v1.__compare_inner_ore_cllw_8_v1(a.bytes, b.bytes);
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.compare_lex_ore_cllw_8_v1(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE FUNCTION eql_v1.compare_lex_ore_cllw_8_v1(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1)
RETURNS int AS $$
DECLARE
    len_a INT;
    len_b INT;
    -- length of the common part of the two bytea values
    common_len INT;
    cmp_result INT;
BEGIN
    -- Get the lengths of both bytea inputs
    len_a := LENGTH(a.bytes);
    len_b := LENGTH(b.bytes);

    -- Handle empty cases
    IF len_a = 0 AND len_b = 0 THEN
        RETURN 0;
    ELSIF len_a = 0 THEN
        RETURN -1;
    ELSIF len_b = 0 THEN
        RETURN 1;
    END IF;

    -- Find the length of the shorter bytea
    IF len_a < len_b THEN
        common_len := len_a;
    ELSE
        common_len := len_b;
    END IF;

    -- Use the compare_bytea function to compare byte by byte
    cmp_result := eql_v1.__compare_inner_ore_cllw_8_v1(
      SUBSTRING(a.bytes FROM 1 FOR common_len),
      SUBSTRING(b.bytes FROM 1 FOR common_len)
    );

    -- If the comparison returns 'less' or 'greater', return that result
    IF cmp_result = -1 THEN
        RETURN -1;
    ELSIF cmp_result = 1 THEN
        RETURN 1;
    END IF;

    -- If the bytea comparison is 'equal', compare lengths
    IF len_a < len_b THEN
        RETURN -1;
    ELSIF len_a > len_b THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_eq(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.ore_cllw_8_v1_eq(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.__bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_neq(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.ore_cllw_8_v1_neq(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS boolean AS $$
  SELECT not eql_v1.__bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_lt(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.ore_cllw_8_v1_lt(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_8_v1(a, b) = -1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_lte(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.ore_cllw_8_v1_lte(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_8_v1(a, b) != 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_gt(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.ore_cllw_8_v1_gt(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_8_v1(a, b) = 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_gte(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

CREATE FUNCTION eql_v1.ore_cllw_8_v1_gte(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_8_v1(a, b) != -1
$$ LANGUAGE SQL;


DROP OPERATOR IF EXISTS = (eql_v1.ore_cllw_8_v1, eql_v1.ore_cllw_8_v1);

CREATE OPERATOR = (
  FUNCTION=eql_v1.ore_cllw_8_v1_eq,
  LEFTARG=eql_v1.ore_cllw_8_v1,
  RIGHTARG=eql_v1.ore_cllw_8_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (eql_v1.ore_cllw_8_v1, eql_v1.ore_cllw_8_v1);

CREATE OPERATOR <> (
  FUNCTION=eql_v1.ore_cllw_8_v1_neq,
  LEFTARG=eql_v1.ore_cllw_8_v1,
  RIGHTARG=eql_v1.ore_cllw_8_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS > (eql_v1.ore_cllw_8_v1, eql_v1.ore_cllw_8_v1);

CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_cllw_8_v1_gt,
  LEFTARG=eql_v1.ore_cllw_8_v1,
  RIGHTARG=eql_v1.ore_cllw_8_v1,
  NEGATOR = <=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS < (eql_v1.ore_cllw_8_v1, eql_v1.ore_cllw_8_v1);

CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_cllw_8_v1_lt,
  LEFTARG=eql_v1.ore_cllw_8_v1,
  RIGHTARG=eql_v1.ore_cllw_8_v1,
  NEGATOR = >=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS >= (eql_v1.ore_cllw_8_v1, eql_v1.ore_cllw_8_v1);

CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_cllw_8_v1_gte,
  LEFTARG=eql_v1.ore_cllw_8_v1,
  RIGHTARG=eql_v1.ore_cllw_8_v1,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <= (eql_v1.ore_cllw_8_v1, eql_v1.ore_cllw_8_v1);

CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_cllw_8_v1_lte,
  LEFTARG=eql_v1.ore_cllw_8_v1,
  RIGHTARG=eql_v1.ore_cllw_8_v1,
  NEGATOR = >,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);

-- Lexical comparison operators

DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_variable_v1_eq(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE OR REPLACE FUNCTION eql_v1.ore_cllw_8_variable_v1_eq(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1) RETURNS boolean AS $$
  SELECT eql_v1.__bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_variable_v1_neq(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE OR REPLACE FUNCTION eql_v1.ore_cllw_8_variable_v1_neq(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1) RETURNS boolean AS $$
  SELECT not eql_v1.__bytea_ct_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_lt_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE OR REPLACE FUNCTION eql_v1.ore_cllw_8_v1_lt_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1) RETURNS boolean AS $$
  SELECT eql_v1.compare_lex_ore_cllw_8_v1(a, b) = -1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_lte_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE OR REPLACE FUNCTION eql_v1.ore_cllw_8_v1_lte_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1) RETURNS boolean AS $$
  SELECT eql_v1.compare_lex_ore_cllw_8_v1(a, b) != 1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_gt_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE OR REPLACE FUNCTION eql_v1.ore_cllw_8_v1_gt_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1) RETURNS boolean AS $$
  SELECT eql_v1.compare_lex_ore_cllw_8_v1(a, b) = 1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS eql_v1.ore_cllw_8_v1_gte_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);

CREATE OR REPLACE FUNCTION eql_v1.ore_cllw_8_v1_gte_lex(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1) RETURNS boolean AS $$
  SELECT eql_v1.compare_lex_ore_cllw_8_v1(a, b) != -1
$$ LANGUAGE SQL;

DROP OPERATOR IF EXISTS = (eql_v1.ore_cllw_8_variable_v1, eql_v1.ore_cllw_8_variable_v1);

CREATE OPERATOR = (
  FUNCTION=eql_v1.ore_cllw_8_variable_v1_eq,
  LEFTARG=eql_v1.ore_cllw_8_variable_v1,
  RIGHTARG=eql_v1.ore_cllw_8_variable_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <> (eql_v1.ore_cllw_8_variable_v1, eql_v1.ore_cllw_8_variable_v1);

CREATE OPERATOR <> (
  FUNCTION=eql_v1.ore_cllw_8_variable_v1_neq,
  LEFTARG=eql_v1.ore_cllw_8_variable_v1,
  RIGHTARG=eql_v1.ore_cllw_8_variable_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS > (eql_v1.ore_cllw_8_variable_v1, eql_v1.ore_cllw_8_variable_v1);

CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_cllw_8_v1_gt_lex,
  LEFTARG=eql_v1.ore_cllw_8_variable_v1,
  RIGHTARG=eql_v1.ore_cllw_8_variable_v1,
  NEGATOR = <=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS < (eql_v1.ore_cllw_8_variable_v1, eql_v1.ore_cllw_8_variable_v1);

CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_cllw_8_v1_lt_lex,
  LEFTARG=eql_v1.ore_cllw_8_variable_v1,
  RIGHTARG=eql_v1.ore_cllw_8_variable_v1,
  NEGATOR = >=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS >= (eql_v1.ore_cllw_8_variable_v1, eql_v1.ore_cllw_8_variable_v1);

CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_cllw_8_v1_gte_lex,
  LEFTARG=eql_v1.ore_cllw_8_variable_v1,
  RIGHTARG=eql_v1.ore_cllw_8_variable_v1,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <= (eql_v1.ore_cllw_8_variable_v1, eql_v1.ore_cllw_8_variable_v1);

CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_cllw_8_v1_lte_lex,
  LEFTARG=eql_v1.ore_cllw_8_variable_v1,
  RIGHTARG=eql_v1.ore_cllw_8_variable_v1,
  NEGATOR = >,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR FAMILY IF EXISTS eql_v1.ore_cllw_8_v1_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ore_cllw_8_v1_btree_ops USING btree;

DROP OPERATOR CLASS IF EXISTS eql_v1.ore_cllw_8_v1_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_cllw_8_v1_btree_ops DEFAULT FOR TYPE eql_v1.ore_cllw_8_v1 USING btree FAMILY eql_v1.ore_cllw_8_v1_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ore_cllw_8_v1(a eql_v1.ore_cllw_8_v1, b eql_v1.ore_cllw_8_v1);

-- Lexical comparison operator class

DROP OPERATOR FAMILY IF EXISTS eql_v1.ore_cllw_8_v1_variable_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ore_cllw_8_v1_variable_btree_ops USING btree;

DROP OPERATOR CLASS IF EXISTS eql_v1.ore_cllw_8_v1_variable_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_cllw_8_v1_variable_btree_ops DEFAULT FOR TYPE eql_v1.ore_cllw_8_variable_v1 USING btree FAMILY eql_v1.ore_cllw_8_v1_variable_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_lex_ore_cllw_8_v1(a eql_v1.ore_cllw_8_variable_v1, b eql_v1.ore_cllw_8_variable_v1);
