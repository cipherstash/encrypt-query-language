-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ore_cllw/functions.sql


--! @brief Compare two encrypted values via their CLLW ORE terms
--!
--! Three-way comparison (`-1` / `0` / `1`) of encrypted values using their
--! CLLW ORE ciphertexts (the `oc` field). Used internally by `eql_v2.compare`
--! as the second priority in its dispatch chain (after `ob` / Block ORE,
--! before `op` / OPE and `hm` / hmac equality).
--!
--! Either input may carry an `oc` term or not — the function follows the
--! same NULL-sorts-first convention as `eql_v2.compare_ore_block_u64_8_256`
--! for the case where one side has `oc` and the other doesn't.
--!
--! @param a eql_v2_encrypted First encrypted value (NOT NULL — function is STRICT)
--! @param b eql_v2_encrypted Second encrypted value (NOT NULL — function is STRICT)
--! @return Integer -1, 0, or 1
--!
--! @see eql_v2.ore_cllw
--! @see eql_v2.has_ore_cllw
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.compare_ore_cllw(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    a_term eql_v2.ore_cllw;
    b_term eql_v2.ore_cllw;
  BEGIN
    IF eql_v2.has_ore_cllw(a) THEN
      a_term := eql_v2.ore_cllw(a);
    END IF;

    IF eql_v2.has_ore_cllw(b) THEN
      b_term := eql_v2.ore_cllw(b);
    END IF;

    IF a_term IS NULL AND b_term IS NULL THEN
      RETURN 0;
    END IF;

    IF a_term IS NULL THEN
      RETURN -1;
    END IF;

    IF b_term IS NULL THEN
      RETURN 1;
    END IF;

    RETURN eql_v2.compare_ore_cllw_term(a_term, b_term);
  END;
$$ LANGUAGE plpgsql;
