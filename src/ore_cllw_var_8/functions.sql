-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw_var_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql


--! @brief Extract variable-width CLLW ORE index term from JSONB payload
--!
--! Extracts the variable-width CLLW ORE ciphertext from the 'ocv' field of an encrypted
--! data payload. Used internally for range query comparisons.
--!
--! @param jsonb containing encrypted EQL payload
--! @return eql_v2.ore_cllw_var_8 Variable-width CLLW ORE ciphertext
--! @throws Exception if 'ocv' field is missing when ore index is expected
--!
--! @see eql_v2.has_ore_cllw_var_8
--! @see eql_v2.compare_ore_cllw_var_8
CREATE FUNCTION eql_v2.ore_cllw_var_8(val jsonb)
  RETURNS eql_v2.ore_cllw_var_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN

    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF NOT (eql_v2.has_ore_cllw_var_8(val)) THEN
        RAISE 'Expected a ore_cllw_var_8 index (ocv) value in json: %', val;
    END IF;

    RETURN ROW(decode(val->>'ocv', 'hex'));
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract variable-width CLLW ORE index term from encrypted column value
--!
--! Extracts the variable-width CLLW ORE ciphertext from an encrypted column value by accessing
--! its underlying JSONB data field.
--!
--! @param eql_v2_encrypted Encrypted column value
--! @return eql_v2.ore_cllw_var_8 Variable-width CLLW ORE ciphertext
--!
--! @see eql_v2.ore_cllw_var_8(jsonb)
CREATE FUNCTION eql_v2.ore_cllw_var_8(val eql_v2_encrypted)
  RETURNS eql_v2.ore_cllw_var_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.ore_cllw_var_8(val.data));
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains variable-width CLLW ORE index term
--!
--! Tests whether the encrypted data payload includes an 'ocv' field,
--! indicating a variable-width CLLW ORE ciphertext is available for range queries.
--!
--! @param jsonb containing encrypted EQL payload
--! @return Boolean True if 'ocv' field is present and non-null
--!
--! @see eql_v2.ore_cllw_var_8
CREATE FUNCTION eql_v2.has_ore_cllw_var_8(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ->> 'ocv' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains variable-width CLLW ORE index term
--!
--! Tests whether an encrypted column value includes a variable-width CLLW ORE ciphertext
--! by checking its underlying JSONB data field.
--!
--! @param eql_v2_encrypted Encrypted column value
--! @return Boolean True if variable-width CLLW ORE ciphertext is present
--!
--! @see eql_v2.has_ore_cllw_var_8(jsonb)
CREATE FUNCTION eql_v2.has_ore_cllw_var_8(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_ore_cllw_var_8(val.data);
  END;
$$ LANGUAGE plpgsql;


--! @brief Compare variable-width CLLW ORE ciphertext terms
--! @internal
--!
--! Three-way comparison of variable-width CLLW ORE ciphertexts. Compares the common
--! prefix using byte-by-byte CLLW comparison, then falls back to length comparison
--! if the common prefix is equal. Used by compare_ore_cllw_var_8 for range queries.
--!
--! @param a eql_v2.ore_cllw_var_8 First variable-width CLLW ORE ciphertext
--! @param b eql_v2.ore_cllw_var_8 Second variable-width CLLW ORE ciphertext
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note Handles variable-length ciphertexts by comparing common prefix first
--! @note Returns NULL if either input is NULL
--!
--! @see eql_v2.compare_ore_cllw_term_bytes
--! @see eql_v2.compare_ore_cllw_var_8
CREATE FUNCTION eql_v2.compare_ore_cllw_var_8_term(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8)
RETURNS int AS $$
DECLARE
    len_a INT;
    len_b INT;
    -- length of the common part of the two bytea values
    common_len INT;
    cmp_result INT;
BEGIN
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

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

    -- Use the compare_ore_cllw_term function to compare byte by byte
    cmp_result := eql_v2.compare_ore_cllw_term_bytes(
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
