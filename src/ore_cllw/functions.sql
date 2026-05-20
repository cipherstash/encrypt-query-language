-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ste_vec/types.sql


--! @brief Extract CLLW ORE index term from a ste_vec entry
--!
--! Returns the CLLW ORE ciphertext from the `oc` field of an `sv` element.
--! `oc` is **only ever present on a `SteVecElement`** in the v2.3 payload
--! shape — never at the root of an `eql_v2_encrypted` column value — so the
--! type signature accepts `eql_v2.ste_vec_entry` directly. Callers must
--! extract first: `eql_v2.ore_cllw(col -> '<selector>')`.
--!
--! Inlinable single-statement SQL — the planner folds the body into the
--! calling query so the extractor disappears at planning time. Functional
--! btree index match on this extractor requires the `eql_v2.ore_cllw_ops`
--! opclass (installed automatically by the main / protect variants; absent
--! in the supabase variant).
--!
--! **Missing-`oc` semantics**: when the `oc` field is absent, returns a
--! SQL-level NULL (not a composite with NULL bytes). Btree's standard
--! NULL handling then filters those rows from range queries: they don't
--! match `WHERE ore_cllw(col) <op> $1`, they sort at the NULLS LAST end
--! of `ORDER BY ore_cllw(col)`, and they never reach the comparator.
--! This avoids the btree FUNCTION 1 contract violation that
--! `(bytes => NULL)` would otherwise cause (`compare_ore_cllw_term`
--! must return non-NULL int for non-NULL composite inputs).
--!
--! Callers needing a loud RAISE on missing `oc` should check
--! `eql_v2.has_ore_cllw(entry)` first.
--!
--! @param entry eql_v2.ste_vec_entry STE-vec entry (extracted via `->`)
--! @return eql_v2.ore_cllw Composite carrying the CLLW ciphertext, or
--!         NULL when the `oc` field is absent.
--!
--! @see eql_v2.has_ore_cllw
--! @see eql_v2.compare_ore_cllw_term
--! @see src/operators/->.sql
CREATE FUNCTION eql_v2.ore_cllw(entry eql_v2.ste_vec_entry)
  RETURNS eql_v2.ore_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE WHEN entry ->> 'oc' IS NULL THEN NULL
              ELSE ROW(decode(entry ->> 'oc', 'hex'))::eql_v2.ore_cllw
         END
$$;


--! @brief Extract CLLW ORE index term from raw jsonb (RHS parameter helper)
--!
--! Companion overload for `eql_v2.ore_cllw(eql_v2.ste_vec_entry)` that
--! accepts a raw `jsonb` value. Intended for the right-hand side of
--! comparisons where the caller binds a literal/parameter jsonb representing
--! a single ste_vec entry: `... < eql_v2.ore_cllw($1::jsonb)`. The (jsonb)
--! form skips the domain CHECK constraint so it works for ad-hoc test inputs
--! and for the GenericComparison case in `eql_v2.compare_ore_cllw_term`.
--!
--! Returns SQL-level NULL when the input lacks `oc`, matching the
--! `(ste_vec_entry)` overload's missing-`oc` semantics so a `WHERE
--! ore_cllw(col) < ore_cllw($1::jsonb)` with a malformed query needle
--! evaluates to no rows rather than indexing a NULL-bytes composite.
--!
--! @param val jsonb An object carrying an `oc` field
--! @return eql_v2.ore_cllw Composite carrying the CLLW ciphertext, or
--!         NULL when the `oc` field is absent.
CREATE FUNCTION eql_v2.ore_cllw(val jsonb)
  RETURNS eql_v2.ore_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE WHEN val ->> 'oc' IS NULL THEN NULL
              ELSE ROW(decode(val ->> 'oc', 'hex'))::eql_v2.ore_cllw
         END
$$;


--! @brief Check if a ste_vec entry contains a CLLW ORE index term
--!
--! Tests whether the entry includes an `oc` field. Inlinable.
--!
--! @param entry eql_v2.ste_vec_entry STE-vec entry
--! @return Boolean True if `oc` field is present and non-null
--!
--! @see eql_v2.ore_cllw
CREATE FUNCTION eql_v2.has_ore_cllw(entry eql_v2.ste_vec_entry)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT entry ->> 'oc' IS NOT NULL
$$;


--! @brief Check if a raw jsonb value contains a CLLW ORE index term
--!
--! Companion to `eql_v2.has_ore_cllw(ste_vec_entry)` for raw jsonb inputs.
--!
--! @param val jsonb An object that may carry an `oc` field
--! @return Boolean True if `oc` field is present and non-null
CREATE FUNCTION eql_v2.has_ore_cllw(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT val ->> 'oc' IS NOT NULL
$$;


--! @brief CLLW per-byte comparison helper
--! @internal
--!
--! Byte-by-byte comparison implementing the CLLW order-revealing protocol.
--! Used by `eql_v2.compare_ore_cllw_term` for the within-prefix step. The
--! protocol: identify the index of the first differing byte across both
--! inputs; if `(y_byte + 1) == x_byte` modulo 256 at that index, then x > y;
--! otherwise x < y. Equal inputs return 0.
--!
--! Inputs MUST be the same length. The caller (`compare_ore_cllw_term`)
--! guarantees this by passing equal-length prefixes.
--!
--! @par Soft constant-time intent
--! Plpgsql is not a constant-time environment — the interpreter, `SUBSTRING`,
--! `get_byte`, and the SQL bytea representation all leak timing in ways we
--! can't control from here. Still, the loop deliberately walks every byte
--! (no `EXIT` on first difference) and the rotation check uses a bitmask
--! (`& 255`) instead of `% 256` so that what little timing structure plpgsql
--! does expose is independent of the position and value of the differing
--! byte. This is hardening intent, not a guarantee.
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
    i INT;
    first_diff INT := 0;
BEGIN

    len_a := LENGTH(a);
    len_b := LENGTH(b);

    IF len_a != len_b THEN
      RAISE EXCEPTION 'ore_cllw index terms are not the same length';
    END IF;

    -- Walk every byte, even after a difference is found. Record only the
    -- index of the first difference (1-based; 0 means "no difference").
    -- Avoids an early `EXIT` whose presence is itself a timing signal.
    FOR i IN 1..len_a LOOP
        IF first_diff = 0 AND get_byte(a, i - 1) != get_byte(b, i - 1) THEN
            first_diff := i;
        END IF;
    END LOOP;

    IF first_diff = 0 THEN
        RETURN 0;
    END IF;

    -- Bitmask instead of `% 256` — the modulo's operand is a power of two
    -- so the two are arithmetically equivalent, but `& 255` is a single
    -- machine instruction with no division-related timing variance.
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
--! @par Null handling — btree FUNCTION 1 contract
--! PostgreSQL's btree filters NULL composites at the row level, so this
--! function should never be called with `a IS NULL` or `b IS NULL` under
--! normal operation. The leading IS-NULL guard returns NULL defensively
--! to cover edge cases (e.g., a non-index `ORDER BY` or `WHERE` path
--! that bypasses the opclass).
--!
--! A composite that is non-NULL but whose `bytes` field is NULL is a
--! contract violation: btree expects FUNCTION 1 to return a non-NULL
--! integer for non-NULL composite inputs. The extractor overloads of
--! `eql_v2.ore_cllw` are designed to return SQL NULL (not `ROW(NULL)`)
--! when the source payload lacks `oc`, so a NULL-bytes composite should
--! only arise from a hand-crafted literal or a future field addition to
--! the composite type. Raise loudly to surface the bug instead of
--! producing silent misordering downstream.
--!
--! @param a eql_v2.ore_cllw First term
--! @param b eql_v2.ore_cllw Second term
--! @return Integer -1, 0, or 1; NULL if either composite is NULL
--! @throws Exception if either composite has a NULL `bytes` field
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
    -- Composite-level NULL: btree's null-handling layer filters these at
    -- the row level under normal operation. Returning NULL covers
    -- non-index code paths that might still reach here.
    IF a IS NULL OR b IS NULL THEN
      RETURN NULL;
    END IF;

    -- Non-NULL composite with NULL bytes is a contract violation: btree's
    -- FUNCTION 1 must return non-NULL int for non-NULL composite inputs.
    -- The extractors return SQL NULL (not ROW(NULL)) on missing `oc`, so
    -- reaching here means a hand-crafted literal or a regression in the
    -- extractor body. Raise loudly rather than silently misorder.
    IF a.bytes IS NULL OR b.bytes IS NULL THEN
      RAISE EXCEPTION 'eql_v2.compare_ore_cllw_term: composite has NULL bytes field — extractor invariant violated. Check that the index expression uses eql_v2.ore_cllw(...) and not a hand-crafted ROW(NULL).';
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
