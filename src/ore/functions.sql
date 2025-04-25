-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/ore/types.sql


DROP FUNCTION IF EXISTS eql_v1.jsonb_array_to_ore_64_8_v1(val jsonb);

-- Casts a jsonb array of hex-encoded strings to the `ore_64_8_v1` composite type.
-- In other words, this function takes the ORE index format sent through in the
-- EQL payload from Proxy and decodes it as the composite type that we use for
-- ORE operations on the Postgres side.
-- CREATE FUNCTION eql_v1.jsonb_array_to_ore_64_8_v1(val jsonb)
-- RETURNS eql_v1.ore_64_8_v1 AS $$
-- DECLARE
--   terms_arr eql_v1.ore_64_8_v1_term[];
-- BEGIN
--   IF jsonb_typeof(val) = 'null' THEN
--     RETURN NULL;
--   END IF;

--   SELECT array_agg(ROW(decode(value::text, 'hex'))::eql_v1.ore_64_8_v1_term)
--     INTO terms_arr
--   FROM jsonb_array_elements_text(val) AS value;

--   PERFORM eql_v1.log('terms', terms_arr::text);

--   RETURN ROW(terms_arr)::eql_v1.ore_64_8_v1;
-- END;
-- $$ LANGUAGE plpgsql;


CREATE FUNCTION eql_v1.jsonb_array_to_ore_64_8_v1(val jsonb)
RETURNS eql_v1.ore_64_8_v1 AS $$
DECLARE
  terms eql_v1.ore_64_8_v1_term[];
BEGIN
  IF jsonb_typeof(val) = 'null' THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(ROW(b)::eql_v1.ore_64_8_v1_term)
  INTO terms
  FROM unnest(eql_v1.jsonb_array_to_bytea_array(val)) AS b;

  RETURN ROW(terms)::eql_v1.ore_64_8_v1;
END;
$$ LANGUAGE plpgsql;


-- extracts ore index from jsonb
DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1(val jsonb);

CREATE FUNCTION eql_v1.ore_64_8_v1(val jsonb)
  RETURNS eql_v1.ore_64_8_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val ? 'o' THEN
      RETURN eql_v1.jsonb_array_to_ore_64_8_v1(val->'o');
    END IF;
    RAISE 'Expected an ore index (o) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


-- extracts ore index from an encrypted column
DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1(val eql_v1_encrypted);

CREATE FUNCTION eql_v1.ore_64_8_v1(val eql_v1_encrypted)
  RETURNS eql_v1.ore_64_8_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v1.ore_64_8_v1(val.data);
  END;
$$ LANGUAGE plpgsql;


-- This function uses lexicographic comparison
DROP FUNCTION IF EXISTS eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS integer AS $$
  BEGIN
    -- Recursively compare blocks bailing as soon as we can make a decision
    RETURN eql_v1.compare_ore_array(a.terms, b.terms);
  END
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.compare_ore_64_8_v1_term(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term);

CREATE FUNCTION eql_v1.compare_ore_64_8_v1_term(a eql_v1.ore_64_8_v1_term, b eql_v1.ore_64_8_v1_term)
  RETURNS integer
AS $$
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
