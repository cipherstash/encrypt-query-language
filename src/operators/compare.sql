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

--! @brief Core comparison function for encrypted values
--!
--! Compares two encrypted values using their index terms without decryption.
--! This function implements all comparison operators required for btree indexing
--! (<, <=, =, >=, >).
--!
--! Index terms are checked in the following priority order:
--! 1. ore_block_u64_8_256 (Order-Revealing Encryption)
--! 2. ore_cllw_u64_8 (Order-Revealing Encryption)
--! 3. ore_cllw_var_8 (Order-Revealing Encryption)
--! 4. hmac_256 (Hash-based equality)
--! 5. blake3 (Hash-based equality)
--!
--! The first index term type present in both values is used for comparison.
--! If no matching index terms are found, falls back to JSONB literal comparison
--! to ensure consistent ordering (required for btree correctness).
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note Literal fallback prevents "lock BufferContent is not held" errors
--! @see eql_v2.compare_ore_block_u64_8_256
--! @see eql_v2.compare_blake3
--! @see eql_v2.compare_hmac_256
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

    a := eql_v2.to_ste_vec_value(a);
    b := eql_v2.to_ste_vec_value(b);

    IF eql_v2.has_ore_block_u64_8_256(a) AND eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    IF eql_v2.has_ore_cllw_u64_8(a) AND eql_v2.has_ore_cllw_u64_8(b) THEN
      RETURN eql_v2.compare_ore_cllw_u64_8(a, b);
    END IF;

    IF eql_v2.has_ore_cllw_var_8(a) AND eql_v2.has_ore_cllw_var_8(b) THEN
      RETURN eql_v2.compare_ore_cllw_var_8(a, b);
    END IF;

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
