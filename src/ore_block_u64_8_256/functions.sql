-- REQUIRE: src/schema.sql
-- REQUIRE: src/crypto.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql


--! @brief Convert JSONB array to ORE block composite type
--! @internal
--!
--! Converts a JSONB array of hex-encoded ORE terms from the CipherStash Proxy
--! payload into the PostgreSQL composite type used for ORE operations.
--!
--! @param val JSONB Array of hex-encoded ORE block terms
--! @return eql_v2.ore_block_u64_8_256 ORE block composite type, or NULL if input is null
--!
--! @see eql_v2.ore_block_u64_8_256(jsonb)
CREATE FUNCTION eql_v2.jsonb_array_to_ore_block_u64_8_256(val jsonb)
RETURNS eql_v2.ore_block_u64_8_256 AS $$
DECLARE
  terms eql_v2.ore_block_u64_8_256_term[];
BEGIN
  IF jsonb_typeof(val) = 'null' THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(ROW(b)::eql_v2.ore_block_u64_8_256_term)
  INTO terms
  FROM unnest(eql_v2.jsonb_array_to_bytea_array(val)) AS b;

  RETURN ROW(terms)::eql_v2.ore_block_u64_8_256;
END;
$$ LANGUAGE plpgsql;


--! @brief Extract ORE block index term from JSONB payload
--!
--! Extracts the ORE block array from the 'ob' field of an encrypted
--! data payload. Used internally for range query comparisons.
--!
--! @param val JSONB Encrypted data payload containing index terms
--! @return eql_v2.ore_block_u64_8_256 ORE block index term
--! @throws Exception if 'ob' field is missing when ore index is expected
--!
--! @see eql_v2.has_ore_block_u64_8_256
--! @see eql_v2.compare_ore_block_u64_8_256
CREATE FUNCTION eql_v2.ore_block_u64_8_256(val jsonb)
  RETURNS eql_v2.ore_block_u64_8_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF eql_v2.has_ore_block_u64_8_256(val) THEN
      RETURN eql_v2.jsonb_array_to_ore_block_u64_8_256(val->'ob');
    END IF;
    RAISE 'Expected an ore index (ob) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract ORE block index term from encrypted column value
--!
--! Extracts the ORE block from an encrypted column value by accessing
--! its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2.ore_block_u64_8_256 ORE block index term
--!
--! @see eql_v2.ore_block_u64_8_256(jsonb)
CREATE FUNCTION eql_v2.ore_block_u64_8_256(val eql_v2_encrypted)
  RETURNS eql_v2.ore_block_u64_8_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.ore_block_u64_8_256(val.data);
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains ORE block index term
--!
--! Tests whether the encrypted data payload includes an 'ob' field,
--! indicating an ORE block is available for range queries.
--!
--! @param val JSONB Encrypted data payload
--! @return Boolean True if 'ob' field is present and non-null
--!
--! @see eql_v2.ore_block_u64_8_256
CREATE FUNCTION eql_v2.has_ore_block_u64_8_256(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ->> 'ob' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains ORE block index term
--!
--! Tests whether an encrypted column value includes an ORE block
--! by checking its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if ORE block is present
--!
--! @see eql_v2.has_ore_block_u64_8_256(jsonb)
CREATE FUNCTION eql_v2.has_ore_block_u64_8_256(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_ore_block_u64_8_256(val.data);
  END;
$$ LANGUAGE plpgsql;



--! @brief Compare two ORE block terms using cryptographic comparison
--! @internal
--!
--! Performs a three-way comparison (returns -1/0/1) of individual ORE block terms
--! using the ORE cryptographic protocol. Compares PRP and PRF blocks to determine
--! ordering without decryption.
--!
--! @param a eql_v2.ore_block_u64_8_256_term First ORE term to compare
--! @param b eql_v2.ore_block_u64_8_256_term Second ORE term to compare
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--! @throws Exception if ciphertexts are different lengths
--!
--! @note Uses AES-ECB encryption for bit comparisons per ORE protocol
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256_term(a eql_v2.ore_block_u64_8_256_term, b eql_v2.ore_block_u64_8_256_term)
  RETURNS integer
AS $$
  DECLARE
    eq boolean := true;
    unequal_block smallint := 0;
    hash_key bytea;
    data_block bytea;
    encrypt_block bytea;
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

    data_block := substr(a.bytes, 9 + (left_block_size * unequal_block), left_block_size);

    encrypt_block := public.encrypt(data_block::bytea, hash_key::bytea, 'aes-ecb');

    indicator := (
      get_bit(
        encrypt_block,
        0
      ) + get_bit(target_block, get_byte(a.bytes, unequal_block))) % 2;

    IF indicator = 1 THEN
      RETURN 1::integer;
    ELSE
      RETURN -1::integer;
    END IF;
  END;
$$ LANGUAGE plpgsql;


--! @brief Compare arrays of ORE block terms recursively
--! @internal
--!
--! Recursively compares arrays of ORE block terms element-by-element.
--! Empty arrays are considered less than non-empty arrays. If the first elements
--! are equal, recursively compares remaining elements.
--!
--! @param a eql_v2.ore_block_u64_8_256_term[] First array of ORE terms
--! @param b eql_v2.ore_block_u64_8_256_term[] Second array of ORE terms
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b, NULL if either array is NULL
--!
--! @note Empty arrays sort before non-empty arrays
--! @see eql_v2.compare_ore_block_u64_8_256_term
CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256_terms(a eql_v2.ore_block_u64_8_256_term[], b eql_v2.ore_block_u64_8_256_term[])
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

    cmp_result := eql_v2.compare_ore_block_u64_8_256_term(a[1], b[1]);

    IF cmp_result = 0 THEN
    -- Removes the first element in the array, and calls this fn again to compare the next element/s in the array.
      RETURN eql_v2.compare_ore_block_u64_8_256_terms(a[2:array_length(a,1)], b[2:array_length(b,1)]);
    END IF;

    RETURN cmp_result;
  END
$$ LANGUAGE plpgsql;


--! @brief Compare ORE block composite types
--! @internal
--!
--! Wrapper function that extracts term arrays from ORE block composite types
--! and delegates to the array comparison function.
--!
--! @param a eql_v2.ore_block_u64_8_256 First ORE block
--! @param b eql_v2.ore_block_u64_8_256 Second ORE block
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @see eql_v2.compare_ore_block_u64_8_256_terms(eql_v2.ore_block_u64_8_256_term[], eql_v2.ore_block_u64_8_256_term[])
CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256_terms(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
RETURNS integer AS $$
  BEGIN
    RETURN eql_v2.compare_ore_block_u64_8_256_terms(a.terms, b.terms);
  END
$$ LANGUAGE plpgsql;
