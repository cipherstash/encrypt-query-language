CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE DOMAIN ore_64_8_index_v1 AS bytea[];

DROP FUNCTION IF EXISTS compare_ore_64_8_v1_term(a bytea, b bytea);

CREATE FUNCTION compare_ore_64_8_v1_term(a bytea, b bytea) returns integer AS $$
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

    IF bit_length(a) != bit_length(b) THEN
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
        substr(a, 1 + block, 1) != substr(b, 1 + block, 1)
        OR substr(a, 9 + left_block_size * block, left_block_size) != substr(b, 9 + left_block_size * BLOCK, left_block_size)
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
    hash_key := substr(b, right_offset + 1, 16);

    -- first right block is at right offset + nonce_size (ordinally indexed)
    target_block := substr(b, right_offset + 17 + (unequal_block * right_block_size), right_block_size);

    indicator := (
      get_bit(
        encrypt(
          substr(a, 9 + (left_block_size * unequal_block), left_block_size),
          hash_key,
          'aes-ecb'
        ),
        0
      ) + get_bit(target_block, get_byte(a, unequal_block))) % 2;

    IF indicator = 1 THEN
      RETURN 1::integer;
    ELSE
      RETURN -1::integer;
    END IF;
  END;
$$ LANGUAGE plpgsql;


-- Compare the "head" of each array and recurse if necessary
-- This function assumes an empty string is "less than" everything else
-- so if a is empty we return -1, if be is empty and a isn't, we return 1.
-- If both are empty we return 0. This cases probably isn't necessary as equality
-- doesn't always make sense but it's here for completeness.
-- If both are non-empty, we compare the first element. If they are equal
-- we need to consider the next block so we recurse, otherwise we return the comparison result.


CREATE FUNCTION compare_ore_array(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS integer AS $$
  DECLARE
    cmp_result integer;
  BEGIN
    IF (array_length(a, 1) = 0 OR a IS NULL) AND (array_length(b, 1) = 0 OR b IS NULL) THEN
      RETURN 0;
    END IF;

    IF array_length(a, 1) = 0 OR a IS NULL THEN
      RETURN -1;
    END IF;

    IF array_length(b, 1) = 0 OR a IS NULL THEN
      RETURN 1;
    END IF;

    cmp_result := compare_ore_64_8_v1_term(a[1], b[1]);

    IF cmp_result = 0 THEN
    -- Removes the first element in the array, and calls this fn again to compare the next element/s in the array.
      RETURN compare_ore_array(a[2:array_length(a,1)], b[2:array_length(b,1)]);
    END IF;

    RETURN cmp_result;
  END
$$ LANGUAGE plpgsql;

-- This function uses lexicographic comparison
DROP FUNCTION IF EXISTS compare_ore_64_8_v1(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION compare_ore_64_8_v1(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS integer AS $$
  BEGIN
    -- Recursively compare blocks bailing as soon as we can make a decision
    RETURN compare_ore_array(a, b);
  END
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS ore_64_8_v1_eq(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION ore_64_8_v1_eq(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS boolean AS $$
  SELECT compare_ore_64_8_v1(a, b) = 0
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS ore_64_8_v1_neq(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION ore_64_8_v1_neq(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS boolean AS $$
  SELECT compare_ore_64_8_v1(a, b) <> 0
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS ore_64_8_v1_lt(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION ore_64_8_v1_lt(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS boolean AS $$
  SELECT compare_ore_64_8_v1(a, b) = -1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS ore_64_8_v1_lte(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION ore_64_8_v1_lte(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS boolean AS $$
  SELECT compare_ore_64_8_v1(a, b) != 1
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS ore_64_8_v1_gt(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION ore_64_8_v1_gt(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS boolean AS $$
  BEGIN
    SELECT compare_ore_64_8_v1(a, b) = 1;
  END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS ore_64_8_v1_gte(a ore_64_8_index_v1, b ore_64_8_index_v1);

CREATE FUNCTION ore_64_8_v1_gte(a ore_64_8_index_v1, b ore_64_8_index_v1)
RETURNS boolean AS $$
  SELECT compare_ore_64_8_v1(a, b) != -1
$$ LANGUAGE SQL;


DROP OPERATOR IF EXISTS = (ore_64_8_index_v1, ore_64_8_index_v1);

CREATE OPERATOR = (
  PROCEDURE="ore_64_8_v1_eq",
  LEFTARG=ore_64_8_v1,
  RIGHTARG=ore_64_8_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (ore_64_8_index_v1, ore_64_8_index_v1);

CREATE OPERATOR <> (
  PROCEDURE="ore_64_8_v1_neq",
  LEFTARG=ore_64_8_v1,
  RIGHTARG=ore_64_8_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS > (ore_64_8_index_v1, ore_64_8_index_v1);

CREATE OPERATOR > (
  PROCEDURE="ore_64_8_v1_gt",
  LEFTARG=ore_64_8_v1,
  RIGHTARG=ore_64_8_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


DROP OPERATOR IF EXISTS < (ore_64_8_index_v1, ore_64_8_index_v1);

CREATE OPERATOR < (
  PROCEDURE="ore_64_8_v1_lt",
  LEFTARG=ore_64_8_v1,
  RIGHTARG=ore_64_8_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS <= (ore_64_8_index_v1, ore_64_8_index_v1);

CREATE OPERATOR <= (
  PROCEDURE="ore_64_8_v1_lte",
  LEFTARG=ore_64_8_v1,
  RIGHTARG=ore_64_8_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >= (ore_64_8_index_v1, ore_64_8_index_v1);

CREATE OPERATOR >= (
  PROCEDURE="ore_64_8_v1_gte",
  LEFTARG=ore_64_8_v1,
  RIGHTARG=ore_64_8_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR FAMILY IF EXISTS ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR FAMILY ore_64_8_v1_btree_ops USING btree;


DROP OPERATOR CLASS IF EXISTS ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR CLASS ore_64_8_v1_btree_ops DEFAULT FOR TYPE ore_64_8_v1 USING btree FAMILY ore_64_8_v1_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 compare_ore_64_8_v1(a ore_64_8_index_v1, b ore_64_8_index_v1);
