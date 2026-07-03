-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ore_cllw/types.sql

--! @file v3/sem/ore_cllw/functions.sql
--! @brief CLLW ORE index-term extraction and comparison (eql_v3 SEM).

--! @brief Extract CLLW ORE index term from raw jsonb
--!
--! Returns the CLLW ORE ciphertext from the `oc` field of a single sv element
--! supplied as raw jsonb. Inlinable single-statement SQL — the planner folds
--! the body into the calling query.
--!
--! **Missing-`oc` semantics**: returns SQL-level NULL (not a composite with
--! NULL bytes) when `oc` is absent, so btree's NULL handling filters those
--! rows from range queries.
--!
--! @param val jsonb An object carrying an `oc` field
--! @return eql_v3_internal.ore_cllw Composite carrying the CLLW ciphertext, or NULL
--!         when the `oc` field is absent.
--! @see eql_v3_internal.has_ore_cllw
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.ore_cllw(val jsonb)
  RETURNS eql_v3_internal.ore_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE WHEN val ->> 'oc' IS NULL THEN NULL
              ELSE ROW(decode(val ->> 'oc', 'hex'))::eql_v3_internal.ore_cllw
         END
$$;

COMMENT ON FUNCTION eql_v3_internal.ore_cllw(jsonb) IS
  'eql-inline-critical: raw-jsonb CLLW extractor; must stay inlinable (unpinned search_path)';

--! @brief Check if a raw jsonb value contains a CLLW ORE index term
--! @param val jsonb An object that may carry an `oc` field
--! @return boolean True if `oc` field is present and non-null
CREATE FUNCTION eql_v3_internal.has_ore_cllw(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT val ->> 'oc' IS NOT NULL
$$;

COMMENT ON FUNCTION eql_v3_internal.has_ore_cllw(jsonb) IS
  'eql-inline-critical: raw-jsonb CLLW presence helper; must stay inlinable (unpinned search_path)';

--! @brief CLLW per-byte comparison helper
--! @internal
--!
--! Byte-by-byte comparison implementing the CLLW order-revealing protocol.
--! Identify the index of the first differing byte; if `(y_byte + 1) == x_byte`
--! (mod 256) there, then x > y; otherwise x < y. Equal inputs return 0. Inputs
--! MUST be the same length (the caller guarantees this). Stays `LANGUAGE
--! plpgsql` — the per-byte loop can't be a single inlinable SQL expression.
--!
--! @param a bytea First CLLW ciphertext slice
--! @param b bytea Second CLLW ciphertext slice
--! @return integer -1, 0, or 1
--! @throws Exception if inputs are different lengths
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE FUNCTION eql_v3_internal.compare_ore_cllw_term_bytes(a bytea, b bytea)
RETURNS int
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    len_a INT;
    len_b INT;
    i INT;
    first_diff INT := 0;
BEGIN

    len_a := LENGTH(a);
    len_b := LENGTH(b);

    IF len_a != len_b THEN
      RAISE EXCEPTION 'ore_cllw index terms are not the same length';
    END IF;

    FOR i IN 1..len_a LOOP
        IF first_diff = 0 AND get_byte(a, i - 1) != get_byte(b, i - 1) THEN
            first_diff := i;
        END IF;
    END LOOP;

    IF first_diff = 0 THEN
        RETURN 0;
    END IF;

    IF ((get_byte(b, first_diff - 1) + 1) & 255) = get_byte(a, first_diff - 1) THEN
        RETURN 1;
    ELSE
        RETURN -1;
    END IF;
END;
$$ LANGUAGE plpgsql;

--! @brief Variable-length CLLW ORE term comparison
--! @internal
--!
--! Three-way comparison of two CLLW ORE ciphertext terms of potentially
--! different lengths. Compares the shared prefix via the CLLW per-byte
--! protocol; on equal prefixes, the shorter input sorts first. The leading
--! domain-tag byte makes numeric (`0x00`) sort before string (`0x01`). Stays
--! `LANGUAGE plpgsql` because it dispatches to `compare_ore_cllw_term_bytes`.
--!
--! btree filters NULL composites at the row level, so this should never see a
--! NULL composite under normal operation; the IS-NULL guard returns NULL
--! defensively. A non-NULL composite with NULL `bytes` is a contract violation
--! — the extractor returns SQL NULL (not ROW(NULL)) on missing `oc`, so raise
--! loudly rather than silently misorder.
--!
--! @param a eql_v3_internal.ore_cllw First term
--! @param b eql_v3_internal.ore_cllw Second term
--! @return integer -1, 0, or 1; NULL if either composite is NULL
--! @throws Exception if either composite has a NULL `bytes` field
--! @see eql_v3_internal.compare_ore_cllw_term_bytes
CREATE FUNCTION eql_v3_internal.compare_ore_cllw_term(a eql_v3_internal.ore_cllw, b eql_v3_internal.ore_cllw)
RETURNS int
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    len_a INT;
    len_b INT;
    common_len INT;
    cmp_result INT;
BEGIN
    -- The `::text` cast is load-bearing, not a stylistic choice. For the
    -- single-field `ore_cllw` composite, `ROW(NULL)::ore_cllw IS NULL` is TRUE
    -- but `(ROW(NULL)::ore_cllw)::text IS NULL` is FALSE. Casting to text first
    -- means a NULL-component composite falls THROUGH to the RAISE below (the
    -- extractor-invariant violation) instead of silently returning NULL and
    -- masking it. A plain `a IS NULL` would reintroduce that masking bug.
    IF a::text IS NULL OR b::text IS NULL THEN
      RETURN NULL;
    END IF;

    IF a.bytes IS NULL OR b.bytes IS NULL THEN
      RAISE EXCEPTION 'eql_v3_internal.compare_ore_cllw_term: composite has NULL bytes field — extractor invariant violated. Check that the index expression uses eql_v3_internal.ore_cllw(...) and not a hand-crafted ROW(NULL).';
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

    cmp_result := eql_v3_internal.compare_ore_cllw_term_bytes(
      SUBSTRING(a.bytes FROM 1 FOR common_len),
      SUBSTRING(b.bytes FROM 1 FOR common_len)
    );

    IF cmp_result = -1 THEN
        RETURN -1;
    ELSIF cmp_result = 1 THEN
        RETURN 1;
    END IF;

    IF len_a < len_b THEN
        RETURN -1;
    ELSIF len_a > len_b THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;
