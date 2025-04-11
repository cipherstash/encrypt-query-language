CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE eql_v1.ore_64_8_v1_term AS (
  bytes bytea
);

CREATE TYPE eql_v1.ore_64_8_v1 AS (
  terms eql_v1.ore_64_8_v1_term[]
);

DROP FUNCTION IF EXISTS eql_v1.compare_ore_64_8_v1_term(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.compare_ore_64_8_v1_term(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term) returns integer AS $$
  DECLARE
    eq boolean := true;
    unequal_block smallint := 0;
    hash_key bytea;
    target_block bytea;

    left_block_size CONSTANT smallint := 16;
    right_block_size CONSTANT smallint := 32;
    right_offset CONSTANT smallint := 136; -- 8 * 17

    indicator smallint := 0;
  BEGIN
    IF a IS NULL AND b IS NULL THEN
      RETURN 0;
    END IF;

    IF a IS NULL THEN
      RETURN -1;
    END IF;

    IF b IS NULL THEN
      RETURN 1;
    END IF;

    IF bit_length(a.bytes) != bit_length(b.bytes) THEN
      RAISE EXCEPTION 'Ciphertexts are different lengths';
    END IF;

    FOR block IN 0..7 LOOP
      -- Compare each PRP (byte from the first 8 bytes) and PRF block (8 byte
      -- chunks of the rest of the value).
      -- NOTE:
      -- * Substr is ordinally indexed (hence 1 and not 0, and 9 and not 8).
      -- * We are not worrying about timing attacks here; don't fret about
      --   the OR or !=.
      IF
        substr(a.bytes, 1 + block, 1) != substr(b.bytes, 1 + block, 1)
        OR substr(a.bytes, 9 + left_block_size * block, left_block_size) != substr(b.bytes, 9 + left_block_size * BLOCK, left_block_size)
      THEN
        -- set the first unequal block we find
        IF eq THEN
          unequal_block := block;
        END IF;
        eq = false;
      END IF;
    END LOOP;

    IF eq THEN
      RETURN 0::integer;
    END IF;

    -- Hash key is the IV from the right CT of b
    hash_key := substr(b.bytes, right_offset + 1, 16);

    -- first right block is at right offset + nonce_size (ordinally indexed)
    target_block := substr(b.bytes, right_offset + 17 + (unequal_block * right_block_size), right_block_size);

    indicator := (
      get_bit(
        encrypt(
          substr(a.bytes, 9 + (left_block_size * unequal_block), left_block_size),
          hash_key,
          'aes-ecb'
        ),
        0
      ) + get_bit(target_block, get_byte(a.bytes, unequal_block))) % 2;

    IF indicator = 1 THEN
      RETURN 1::integer;
    ELSE
      RETURN -1::integer;
    END IF;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_term_eq(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.ore_64_8_v1_term_eq(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1_term(a, b) = 0
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_term_neq(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.ore_64_8_v1_term_neq(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1_term(a, b) <> 0
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_term_lt(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.ore_64_8_v1_term_lt(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1_term(a, b) = -1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_term_lte(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.ore_64_8_v1_term_lte(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1_term(a, b) != 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_term_gt(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.ore_64_8_v1_term_gt(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1_term(a, b) = 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_term_gte(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.ore_64_8_v1_term_gte(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1_term(a, b) != -1
$$ LANGUAGE SQL;


DROP OPERATOR IF EXISTS = (eql_v1.ore_64_8_v1_term, eql_v1.ore_64_8_v1_term);

CREATE OPERATOR = (
  FUNCTION=eql_v1.ore_64_8_v1_term_eq,
  LEFTARG=eql_v1.ore_64_8_v1_term,
  RIGHTARG=eql_v1.ore_64_8_v1_term,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (eql_v1.ore_64_8_v1_term, eql_v1.ore_64_8_v1_term);

CREATE OPERATOR <> (
  FUNCTION=eql_v1.ore_64_8_v1_term_neq,
  LEFTARG=eql_v1.ore_64_8_v1_term,
  RIGHTARG=eql_v1.ore_64_8_v1_term,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS > (eql_v1.ore_64_8_v1_term, eql_v1.ore_64_8_v1_term);

CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_64_8_v1_term_gt,
  LEFTARG=eql_v1.ore_64_8_v1_term,
  RIGHTARG=eql_v1.ore_64_8_v1_term,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

DROP OPERATOR IF EXISTS < (eql_v1.ore_64_8_v1_term, eql_v1.ore_64_8_v1_term);

CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_64_8_v1_term_lt,
  LEFTARG=eql_v1.ore_64_8_v1_term,
  RIGHTARG=eql_v1.ore_64_8_v1_term,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

DROP OPERATOR IF EXISTS <= (eql_v1.ore_64_8_v1_term, eql_v1.ore_64_8_v1_term);

CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_64_8_v1_term_lte,
  LEFTARG=eql_v1.ore_64_8_v1_term,
  RIGHTARG=eql_v1.ore_64_8_v1_term,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);

DROP OPERATOR IF EXISTS >= (eql_v1.ore_64_8_v1_term, eql_v1.ore_64_8_v1_term);

CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_64_8_v1_term_gte,
  LEFTARG=eql_v1.ore_64_8_v1_term,
  RIGHTARG=eql_v1.ore_64_8_v1_term,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);

DROP OPERATOR FAMILY IF EXISTS eql_v1.ore_64_8_v1_term_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ore_64_8_v1_term_btree_ops USING btree;


DROP OPERATOR CLASS IF EXISTS eql_v1.ore_64_8_v1_term_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_64_8_v1_term_btree_ops DEFAULT FOR TYPE eql_v1.ore_64_8_v1_term USING btree FAMILY eql_v1.ore_64_8_v1_term_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ore_64_8_v1_term(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

-- Compare the "head" of each array and recurse if necessary
-- This function assumes an empty string is "less than" everything else
-- so if a is empty we return -1, if be is empty and a isn't, we return 1.
-- If both are empty we return 0. This cases probably isn't necessary as equality
-- doesn't always make sense but it's here for completeness.
-- If both are non-empty, we compare the first element. If they are equal
-- we need to consider the next block so we recurse, otherwise we return the comparison result.
DROP FUNCTION IF EXISTS eql_v1.compare_ore_array(a eql_v1.ore_64_8_v1_term[], b eql_v1.ore_64_8_v1_term[]);

CREATE FUNCTION eql_v1.compare_ore_array(a eql_v1.ore_64_8_v1_term[], b eql_v1.ore_64_8_v1_term[])
RETURNS integer AS $$
  DECLARE
    cmp_result integer;
  BEGIN

    -- NULLs are NULL
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

    -- empty a and b
    IF cardinality(a) = 0 AND cardinality(b) = 0 THEN
      RETURN 0;
    END IF;

    -- empty a and some b
    IF (cardinality(a) = 0) AND cardinality(b) > 0 THEN
      RETURN -1;
    END IF;

    -- some a and empty b
    IF cardinality(a) > 0 AND (cardinality(b) = 0) THEN
      RETURN 1;
    END IF;

    cmp_result := eql_v1.compare_ore_64_8_v1_term(a[1], b[1]);
    IF cmp_result = 0 THEN
    -- Removes the first element in the array, and calls this fn again to compare the next element/s in the array.
      RETURN eql_v1.compare_ore_array(a[2:array_length(a,1)], b[2:array_length(b,1)]);
    END IF;

    RETURN cmp_result;
  END
$$ LANGUAGE plpgsql;

-- This function uses lexicographic comparison
DROP FUNCTION IF EXISTS eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS integer AS $$
  DECLARE
    cmp_result integer;
  BEGIN
    -- Recursively compare blocks bailing as soon as we can make a decision
    RETURN eql_v1.compare_ore_array(a.terms, b.terms);
  END
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_eq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_eq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = 0
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_neq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_neq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) <> 0
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = -1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) != 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) != -1
$$ LANGUAGE SQL;


DROP OPERATOR IF EXISTS = (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR = (
  FUNCTION=eql_v1.ore_64_8_v1_eq,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR <> (
  FUNCTION=eql_v1.ore_64_8_v1_neq,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS > (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_64_8_v1_gt,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


DROP OPERATOR IF EXISTS < (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_64_8_v1_lt,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS <= (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_64_8_v1_lte,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >= (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_64_8_v1_gte,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR FAMILY IF EXISTS eql_v1.ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ore_64_8_v1_btree_ops USING btree;


DROP OPERATOR CLASS IF EXISTS eql_v1.ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_64_8_v1_btree_ops DEFAULT FOR TYPE eql_v1.ore_64_8_v1 USING btree FAMILY eql_v1.ore_64_8_v1_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);
