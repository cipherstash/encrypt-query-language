-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql


--! @brief Extract CLLW ORE index term from JSONB payload
--!
--! Extracts the CLLW ORE ciphertext from the 'ocf' field of an encrypted
--! data payload. Used internally for range query comparisons.
--!
--! @param jsonb containing encrypted EQL payload
--! @return eql_v2.ore_cllw_u64_8 CLLW ORE ciphertext
--! @throws Exception if 'ocf' field is missing when ore index is expected
--!
--! @see eql_v2.has_ore_cllw_u64_8
--! @see eql_v2.compare_ore_cllw_u64_8
CREATE FUNCTION eql_v2.ore_cllw_u64_8(val jsonb)
  RETURNS eql_v2.ore_cllw_u64_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    IF val IS NULL THEN
      RETURN NULL;
    END IF;

    IF NOT (eql_v2.has_ore_cllw_u64_8(val)) THEN
        RAISE 'Expected a ore_cllw_u64_8 index (ocf) value in json: %', val;
    END IF;

    RETURN ROW(decode(val->>'ocf', 'hex'));
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract CLLW ORE index term from encrypted column value
--!
--! Extracts the CLLW ORE ciphertext from an encrypted column value by accessing
--! its underlying JSONB data field.
--!
--! @param eql_v2_encrypted Encrypted column value
--! @return eql_v2.ore_cllw_u64_8 CLLW ORE ciphertext
--!
--! @see eql_v2.ore_cllw_u64_8(jsonb)
CREATE FUNCTION eql_v2.ore_cllw_u64_8(val eql_v2_encrypted)
  RETURNS eql_v2.ore_cllw_u64_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN (SELECT eql_v2.ore_cllw_u64_8(val.data));
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if JSONB payload contains CLLW ORE index term
--!
--! Tests whether the encrypted data payload includes an 'ocf' field,
--! indicating a CLLW ORE ciphertext is available for range queries.
--!
--! @param jsonb containing encrypted EQL payload
--! @return Boolean True if 'ocf' field is present and non-null
--!
--! @see eql_v2.ore_cllw_u64_8
CREATE FUNCTION eql_v2.has_ore_cllw_u64_8(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN val ->> 'ocf' IS NOT NULL;
  END;
$$ LANGUAGE plpgsql;


--! @brief Check if encrypted column value contains CLLW ORE index term
--!
--! Tests whether an encrypted column value includes a CLLW ORE ciphertext
--! by checking its underlying JSONB data field.
--!
--! @param eql_v2_encrypted Encrypted column value
--! @return Boolean True if CLLW ORE ciphertext is present
--!
--! @see eql_v2.has_ore_cllw_u64_8(jsonb)
CREATE FUNCTION eql_v2.has_ore_cllw_u64_8(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2.has_ore_cllw_u64_8(val.data);
  END;
$$ LANGUAGE plpgsql;



--! @brief Compare CLLW ORE ciphertext bytes
--! @internal
--!
--! Byte-by-byte comparison of CLLW ORE ciphertexts implementing the CLLW
--! comparison algorithm. Used by both fixed-width (ore_cllw_u64_8) and
--! variable-width (ore_cllw_var_8) ORE variants.
--!
--! @param a Bytea First CLLW ORE ciphertext
--! @param b Bytea Second CLLW ORE ciphertext
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--! @throws Exception if ciphertexts are different lengths
--!
--! @note Shared comparison logic for multiple ORE CLLW schemes
--! @see eql_v2.compare_ore_cllw_u64_8
CREATE FUNCTION eql_v2.compare_ore_cllw_term_bytes(a bytea, b bytea)
RETURNS int AS $$
DECLARE
    len_a INT;
    len_b INT;
    x BYTEA;
    y BYTEA;
    i INT;
    differing boolean;
BEGIN

    -- Check if the lengths of the two bytea arguments are the same
    len_a := LENGTH(a);
    len_b := LENGTH(b);

    IF len_a != len_b THEN
      RAISE EXCEPTION 'ore_cllw index terms are not the same length';
    END IF;

    -- Iterate over each byte and compare them
    FOR i IN 1..len_a LOOP
        x := SUBSTRING(a FROM i FOR 1);
        y := SUBSTRING(b FROM i FOR 1);

        -- Check if there's a difference
        IF x != y THEN
            differing := true;
            EXIT;
        END IF;
    END LOOP;

    -- If a difference is found, compare the bytes as in Rust logic
    IF differing THEN
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


