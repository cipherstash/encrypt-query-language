-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw/types.sql


--! @brief Extract CLLW ORE index term from JSONB payload
--!
--! Returns the CLLW ORE ciphertext from the `oc` field of an encrypted
--! data payload. Inlinable single-statement SQL — the planner folds the
--! body into the calling query so the extractor disappears at planning
--! time. Whether index match engages depends on whether a custom operator
--! class is installed on the `eql_v2.ore_cllw` composite type
--! (`compare_ore_cllw_term` is the entry point); without one, Postgres
--! has no way to use a functional btree on this extractor because lex
--! `bytea` order does not match the CLLW order-revealing protocol.
--!
--! When the `oc` field is absent, returns a composite with `bytes IS NULL`
--! rather than raising. This is necessary for inlinability (a SQL function
--! body that may raise can't be inlined). Callers needing the loud RAISE
--! contract should check `eql_v2.has_ore_cllw(val)` first.
--!
--! @param val jsonb Encrypted EQL payload
--! @return eql_v2.ore_cllw Composite carrying the CLLW ciphertext, or
--!         `(bytes => NULL)` when the `oc` field is absent.
--!
--! @see eql_v2.has_ore_cllw
--! @see eql_v2.compare_ore_cllw
CREATE FUNCTION eql_v2.ore_cllw(val jsonb)
  RETURNS eql_v2.ore_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT ROW(decode(val ->> 'oc', 'hex'))::eql_v2.ore_cllw
$$;


--! @brief Extract CLLW ORE index term from encrypted column value
--!
--! Convenience overload that unwraps the encrypted column value's JSONB
--! payload and delegates to `eql_v2.ore_cllw(jsonb)`. Inlinable.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2.ore_cllw CLLW ORE ciphertext composite
--!
--! @see eql_v2.ore_cllw(jsonb)
CREATE FUNCTION eql_v2.ore_cllw(val eql_v2_encrypted)
  RETURNS eql_v2.ore_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_cllw(val.data)
$$;


--! @brief Check if JSONB payload contains CLLW ORE index term
--!
--! Tests whether the encrypted data payload includes an `oc` field,
--! indicating a CLLW ORE ciphertext is available for range queries
--! (Standard-mode `ste_vec` emissions). Inlinable.
--!
--! @param val jsonb Encrypted EQL payload
--! @return Boolean True if `oc` field is present and non-null
--!
--! @see eql_v2.ore_cllw
CREATE FUNCTION eql_v2.has_ore_cllw(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT val ->> 'oc' IS NOT NULL
$$;


--! @brief Check if encrypted column value contains CLLW ORE index term
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if CLLW ORE ciphertext is present
CREATE FUNCTION eql_v2.has_ore_cllw(val eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.has_ore_cllw(val.data)
$$;


--! @brief CLLW per-byte comparison helper
--! @internal
--!
--! Byte-by-byte comparison implementing the CLLW order-revealing protocol.
--! Used by `eql_v2.compare_ore_cllw_term` for the within-prefix step. The
--! protocol: walk both inputs byte-for-byte until a difference is found;
--! if `get_byte(y, 0) + 1 == get_byte(x, 0)` modulo 256 then x > y, else
--! x < y.
--!
--! Inputs MUST be the same length. The caller (`compare_ore_cllw_term`)
--! guarantees this by passing equal-length prefixes.
--!
--! Stays `LANGUAGE plpgsql` — the per-byte loop can't be expressed as a
--! single inlinable SQL expression. This is the architectural reason ORE
--! CLLW needs a custom operator class for index match, where OPE does not.
--!
--! @param a Bytea First CLLW ciphertext slice
--! @param b Bytea Second CLLW ciphertext slice
--! @return Integer -1, 0, or 1
--! @throws Exception if inputs are different lengths
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.compare_ore_cllw_term_bytes(a bytea, b bytea)
RETURNS int
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    len_a INT;
    len_b INT;
    x BYTEA;
    y BYTEA;
    i INT;
    differing boolean;
BEGIN

    len_a := LENGTH(a);
    len_b := LENGTH(b);

    IF len_a != len_b THEN
      RAISE EXCEPTION 'ore_cllw index terms are not the same length';
    END IF;

    FOR i IN 1..len_a LOOP
        x := SUBSTRING(a FROM i FOR 1);
        y := SUBSTRING(b FROM i FOR 1);

        IF x != y THEN
            differing := true;
            EXIT;
        END IF;
    END LOOP;

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


--! @brief Variable-length CLLW ORE term comparison
--! @internal
--!
--! Three-way comparison of two CLLW ORE ciphertext terms of potentially
--! different lengths. Compares the shared prefix via the CLLW per-byte
--! protocol; on equal prefixes, the shorter input sorts first.
--!
--! Handles both numeric (Standard-mode 65-byte CLLW outputs from the u64
--! variant) and string (variable-length CLLW outputs) by virtue of the
--! domain-tag byte being the first byte of `bytes`. A numeric/string pair
--! differs at byte 0 (`0x00` vs `0x01`), which the CLLW rule resolves
--! correctly to numeric < string.
--!
--! Stays `LANGUAGE plpgsql` because it dispatches to
--! `compare_ore_cllw_term_bytes`, which can't be inlined.
--!
--! @param a eql_v2.ore_cllw First term
--! @param b eql_v2.ore_cllw Second term
--! @return Integer -1, 0, or 1; NULL if either input is NULL
--!
--! @see eql_v2.compare_ore_cllw_term_bytes
--! @see eql_v2.compare_ore_cllw
CREATE FUNCTION eql_v2.compare_ore_cllw_term(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
RETURNS int
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    len_a INT;
    len_b INT;
    common_len INT;
    cmp_result INT;
BEGIN
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

    len_a := LENGTH(a.bytes);
    len_b := LENGTH(b.bytes);

    IF len_a = 0 AND len_b = 0 THEN
        RETURN 0;
    ELSIF len_a = 0 THEN
        RETURN -1;
    ELSIF len_b = 0 THEN
        RETURN 1;
    END IF;

    IF len_a < len_b THEN
        common_len := len_a;
    ELSE
        common_len := len_b;
    END IF;

    cmp_result := eql_v2.compare_ore_cllw_term_bytes(
      SUBSTRING(a.bytes FROM 1 FOR common_len),
      SUBSTRING(b.bytes FROM 1 FOR common_len)
    );

    IF cmp_result = -1 THEN
        RETURN -1;
    ELSIF cmp_result = 1 THEN
        RETURN 1;
    END IF;

    -- Equal prefixes: shorter sorts first
    IF len_a < len_b THEN
        RETURN -1;
    ELSIF len_a > len_b THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;
