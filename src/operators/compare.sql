-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql

-- REQUIRE: src/blake3/types.sql
-- REQUIRE: src/blake3/functions.sql

-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql

-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql

-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql

-- REQUIRE: src/ore_cllw_var_8/types.sql
-- REQUIRE: src/ore_cllw_var_8/functions.sql


--
-- Compare two eql_v2_encrypted values
--
-- Function is used to implement all operators required for btree indexing"
--      - `<`
--      - `<=`
--      - `=`
--      - `>=`
--      - `>`
--
--
-- Index terms are checked in the following order:
--    - `ore_block_u64_8_256`
--    - `ore_cllw_u64_8`
--    - `ore_cllw_var_8`
--    - `hmac_256`
--    - `blake3`
--
-- The first index term present for both values is used for comparsion.
--
-- If no index terms are found, the encrypted data is compared as a jsonb literal.
-- Btree index must have a consistent ordering for a given state, without this text fallback, database errors with "lock BufferContent is not held"
--
CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
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

    -- Use ORE if both parameters have ore index
    IF eql_v2.has_ore_block_u64_8_256(a) AND eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    IF eql_v2.has_ore_cllw_u64_8(a) AND eql_v2.has_ore_cllw_u64_8(b) THEN
      RETURN eql_v2.compare_ore_cllw_u64_8(a, b);
    END IF;

    IF eql_v2.has_ore_cllw_var_8(a) AND eql_v2.has_ore_cllw_var_8(b) THEN
      RETURN eql_v2.compare_ore_cllw_var_8(a, b);
    END IF;

    -- Fallback to hmac if both parameters have hmac index
    IF eql_v2.has_hmac_256(a) AND eql_v2.has_hmac_256(b) THEN
      RETURN eql_v2.compare_hmac_256(a, b);
    END IF;

    IF eql_v2.has_blake3(a) AND eql_v2.has_blake3(b) THEN
      RETURN eql_v2.compare_blake3(a, b);
    END IF;

    -- Fallback to literal comparison of the encrypted data
    -- Compare must have consistent ordering for a given state
    -- Without this text fallback, database errors with "lock BufferContent is not held"
    RETURN eql_v2.compare_literal(a, b);

  END;
$$ LANGUAGE plpgsql;
