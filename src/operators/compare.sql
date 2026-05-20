-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql

-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql

-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ore_cllw/functions.sql
-- REQUIRE: src/ste_vec/types.sql

--! @file src/operators/compare.sql
--! @brief Three-way ordering on the root `eql_v2_encrypted` type
--!
--! Returns `-1` / `0` / `1` for two encrypted column values that carry
--! Block ORE (`ob`) terms at the root. Used by the btree operator class on
--! `eql_v2_encrypted` (FUNCTION 1), by the legacy `eql_v2.lt` / `lte` /
--! `gt` / `gte` helpers, and by `sort_compare`'s `strategy = 'compare'`
--! fallback path.
--!
--! **Strict Block-ORE-only contract.** Root-level `eql_v2_encrypted` values
--! only carry root-scope ORE terms (`ob`) per the v2.3 payload shape — the
--! `oc` field (CLLW ORE) is sv-element scope only and never appears on a
--! root payload. Equality on `eql_v2_encrypted` is hm-only and runs through
--! the inlined `=` / `<>` operators (post-#193) — it does *not* go through
--! this function. For sv-element ordering, use the typed
--! `eql_v2.compare(eql_v2.ste_vec_entry, eql_v2.ste_vec_entry)` overload
--! (or the `<` / `<=` / `>` / `>=` operators on the same pair).
--!
--! @param a eql_v2_encrypted First encrypted value (STRICT — NULL inputs short-circuit to NULL)
--! @param b eql_v2_encrypted Second encrypted value (STRICT — NULL inputs short-circuit to NULL)
--! @return integer -1, 0, or 1
--!
--! @throws Exception when either value lacks an `ob` (Block ORE) term
--!
--! @see eql_v2.compare_ore_block_u64_8_256
--! @see eql_v2.compare(eql_v2.ste_vec_entry, eql_v2.ste_vec_entry)
--! @see eql_v2."=" -- hm-only equality, post-#193 inlining
CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    IF eql_v2.has_ore_block_u64_8_256(a) AND eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    RAISE EXCEPTION
      'eql_v2.compare requires Block ORE (`ob`) on both root operands. For sv-element ordering, extract entries via `col -> ''<selector>''` and use eql_v2.compare on the resulting `eql_v2.ste_vec_entry` values (or their `<` / `<=` / `>` / `>=` operators). Equality is hmac-only via the `=` operator — this function is for ordering only.'
      USING ERRCODE = 'feature_not_supported';
  END;
$$ LANGUAGE plpgsql;


--! @brief Three-way ordering on `eql_v2.ste_vec_entry`
--!
--! CLLW ORE three-way comparator on ste-vec entries. Returns `-1` / `0` /
--! `1` by extracting the `oc` term from each entry and delegating to
--! `eql_v2.compare_ore_cllw_term`. Use this when you need an `int` ordering
--! out of two extracted ste-vec entries — for the boolean-form operators
--! (`<` / `<=` / `>` / `>=`) on the same pair, see
--! `src/operators/ste_vec_entry.sql`.
--!
--! Note: the caller is responsible for extracting an `eql_v2.ste_vec_entry`
--! first; the `(eql_v2_encrypted, text)` form would be a natural extension
--! but is deliberately *not* added here so that callers stay aware of the
--! two-step shape (extract via `->`, then compare).
--!
--! @param a eql_v2.ste_vec_entry First entry
--! @param b eql_v2.ste_vec_entry Second entry
--! @return integer -1, 0, or 1
--!
--! @throws Exception when either entry lacks an `oc` term
--!
--! @see eql_v2.compare_ore_cllw_term
--! @see src/operators/ste_vec_entry.sql
CREATE FUNCTION eql_v2.compare(a eql_v2.ste_vec_entry, b eql_v2.ste_vec_entry)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    IF NOT (eql_v2.has_ore_cllw(a) AND eql_v2.has_ore_cllw(b)) THEN
      RAISE EXCEPTION
        'eql_v2.compare(ste_vec_entry, ste_vec_entry) requires `oc` (CLLW ORE) on both entries.'
        USING ERRCODE = 'feature_not_supported';
    END IF;

    RETURN eql_v2.compare_ore_cllw_term(eql_v2.ore_cllw(a), eql_v2.ore_cllw(b));
  END;
$$ LANGUAGE plpgsql;
