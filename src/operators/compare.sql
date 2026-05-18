-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql

-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql

-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ore_cllw/functions.sql
-- REQUIRE: src/ore_cllw/compare.sql

--! @brief Three-way ordering function for encrypted values
--!
--! Returns the ORE-based order between two encrypted values: `-1` if `a < b`,
--! `0` if `a = b` (same encrypted plaintext under deterministic ORE), `1` if
--! `a > b`. Used by the btree operator class on `eql_v2_encrypted`
--! (FUNCTION 1), by the legacy `eql_v2.lt` / `eql_v2.lte` / `eql_v2.gt` /
--! `eql_v2.gte` helpers, and by `sort_compare`'s `strategy = 'compare'`
--! fallback path.
--!
--! **Strict ORE contract.** This function is for ordering only. It requires
--! both operands to carry an ORE term on the same scope:
--!   - `ob` (Block ORE) at the root, for scalar `eql_v2_encrypted` values
--!   - `oc` (CLLW ORE) at the sv-element scope (the input is normalised
--!     through `eql_v2.to_ste_vec_value` first, so an sv-shaped payload is
--!     unwrapped to its sv[0] for inspection)
--!
--! Missing both raises with a clear error directing callers to the correct
--! recipe. **`hm` and literal-bytes fallbacks have been removed:** equality
--! on `eql_v2_encrypted` is hm-only and runs through the inlined `=` /
--! `<>` operators (post-#193) — it does *not* go through this function.
--! `eql_v2.eq` and `eql_v2.neq` are also hm-only now (inlinable SQL
--! mirroring the operators). The previous literal-bytes fallback covered
--! btree-correctness on misconfigured columns; with the strict contract,
--! misconfigured columns raise loudly at query time instead of silently
--! producing meaningless ordering.
--!
--! @param a eql_v2_encrypted First encrypted value (STRICT — NULL inputs short-circuit to NULL)
--! @param b eql_v2_encrypted Second encrypted value (STRICT — NULL inputs short-circuit to NULL)
--! @return integer -1, 0, or 1
--!
--! @throws Exception when neither value carries `ob` (root) nor `oc` (sv element)
--!
--! @see eql_v2.compare_ore_block_u64_8_256
--! @see eql_v2.compare_ore_cllw
--! @see eql_v2."=" -- hm-only equality, post-#193 inlining
CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    a := eql_v2.to_ste_vec_value(a);
    b := eql_v2.to_ste_vec_value(b);

    IF eql_v2.has_ore_block_u64_8_256(a) AND eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    IF eql_v2.has_ore_cllw(a) AND eql_v2.has_ore_cllw(b) THEN
      RETURN eql_v2.compare_ore_cllw(a, b);
    END IF;

    RAISE EXCEPTION
      'eql_v2.compare requires an ORE term on both operands: `ob` (Block ORE, root scalars) or `oc` (CLLW ORE, sv elements). Equality is hmac-only via the `=` operator — this function is for ordering only.'
      USING ERRCODE = 'feature_not_supported';
  END;
$$ LANGUAGE plpgsql;
