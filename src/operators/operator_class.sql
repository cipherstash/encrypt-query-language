-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/operators/<.sql
-- REQUIRE: src/operators/<=.sql
-- REQUIRE: src/operators/=.sql
-- REQUIRE: src/operators/>=.sql
-- REQUIRE: src/operators/>.sql


--
-- Compare two eql_v2_encrypted values
-- Uses `ore_block_u64_8_256` or `has_hmac_256` index terms for comparison if defined on ONE of the compared value
--
-- Important note: -- Index order of operations is reversed from equality operator.
-- In equality operations, `has_hmac_256` is preferred as it reduces to a text comparison and is more efficient
-- As compare is used for ordering, `ore_block_u64_8_256` provides more complete ordering and is checked first.
-- THe assumption is that if you add ore you are adding it because you want to use it specifically for comparison.

-- Thusly, the logic for determining which index term to use:
--    Use ORE if BOTH parameters have ore index
--    Fallback to hmac if BOTH parameters have hmac index
--    Fallback to ORE if ONE of the parameters has ore index (will compare against a NULL term for the other parameter)
--    Fallback to hmac if ONE of the parameters has hmac index (will compare against a NULL term term for the other parameter)
--
-- As a general rule, columns should have the same index terms as they are encrypted with the same configuration.
-- Index terms should only be different during an encryption config migration.
-- eg, when adding an ore index to a column any existing values will NOT have the ore index until encryptindexed/migrated
--
CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN

    -- PERFORM eql_v2.log('eql_v2.has_hmac_256(a)', eql_v2.has_hmac_256(a)::text);
    -- PERFORM eql_v2.log('eql_v2.has_hmac_256(b)', eql_v2.has_hmac_256(b)::text);
    -- PERFORM eql_v2.log('eql_v2.has_ore_block_u64_8_256(b)', eql_v2.has_ore_block_u64_8_256(b)::text);
    -- PERFORM eql_v2.log('eql_v2.has_ore_block_u64_8_256(b)', eql_v2.has_ore_block_u64_8_256(b)::text);


    -- Use ORE if BOTH parameters have ore index
    IF eql_v2.has_ore_block_u64_8_256(a) AND eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    -- Fallback to hmac if BOTH parameters have hmac index
    IF eql_v2.has_hmac_256(a) AND eql_v2.has_hmac_256(b) THEN
      RETURN eql_v2.compare_hmac(a, b);
    END IF;

    -- Fallback to ORE if one of the parameters has ore index
    IF eql_v2.has_ore_block_u64_8_256(a) OR eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    -- Fallback to hmac if ONE of the parameters has hmac index
    IF eql_v2.has_hmac_256(a) OR eql_v2.has_hmac_256(b) THEN
      RETURN eql_v2.compare_hmac(a, b);
    END IF;

    RAISE 'Expected an hmac_256 (hm) or ore_block_u64_8_256 (ob) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

--------------------

CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_ore eql_v2.ore_block_u64_8_256;
    b_ore eql_v2.ore_block_u64_8_256;
  BEGIN

    a_ore := eql_v2.ore_block_u64_8_256(a);
    b_ore := eql_v2.ore_block_u64_8_256(b);

    IF a_ore IS NULL AND b_ore IS NULL THEN
      RETURN 0;
    END IF;

    IF a_ore IS NULL THEN
      RETURN -1;
    END IF;

    IF b_ore IS NULL THEN
      RETURN 1;
    END IF;

    RETURN eql_v2.compare_ore_array(a_ore.terms, b_ore.terms);
  END;
$$ LANGUAGE plpgsql;


--------------------

CREATE FUNCTION eql_v2.compare_hmac(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_hmac eql_v2.hmac_256;
    b_hmac eql_v2.hmac_256;
  BEGIN

    a_hmac = eql_v2.hmac_256(a);
    b_hmac = eql_v2.hmac_256(b);

    IF a_hmac IS NULL AND b_hmac IS NULL THEN
      RETURN 0;
    END IF;

    IF a_hmac IS NULL THEN
      RETURN -1;
    END IF;

    IF b_hmac IS NULL THEN
      RETURN 1;
    END IF;

    IF a_hmac = b_hmac THEN
      RETURN 0;
    END IF;

    IF a_hmac < b_hmac THEN
      RETURN -1;
    END IF;

    IF a_hmac > b_hmac THEN
      RETURN 1;
    END IF;

  END;
$$ LANGUAGE plpgsql;


--------------------

CREATE OPERATOR FAMILY eql_v2.encrypted_operator USING btree;

CREATE OPERATOR CLASS eql_v2.encrypted_operator DEFAULT FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted);


--------------------

-- CREATE OPERATOR FAMILY eql_v2.encrypted_operator_ore_block_u64_8_256 USING btree;

-- CREATE OPERATOR CLASS eql_v2.encrypted_operator_ore_block_u64_8_256 FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator_ore_block_u64_8_256 AS
--   OPERATOR 1 <,
--   OPERATOR 2 <=,
--   OPERATOR 3 =,
--   OPERATOR 4 >=,
--   OPERATOR 5 >,
--   FUNCTION 1 eql_v2.compare_ore_block_u64_8_256(a eql_v2_encrypted, b eql_v2_encrypted);

-- --------------------

-- CREATE OPERATOR FAMILY eql_v2.encrypted_hmac_256_operator USING btree;

-- CREATE OPERATOR CLASS eql_v2.encrypted_hmac_256_operator FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_hmac_256_operator AS
--   OPERATOR 1 <,
--   OPERATOR 2 <=,
--   OPERATOR 3 =,
--   OPERATOR 4 >=,
--   OPERATOR 5 >,
--   FUNCTION 1 eql_v2.compare_hmac(a eql_v2_encrypted, b eql_v2_encrypted);

