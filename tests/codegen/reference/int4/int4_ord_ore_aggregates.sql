-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema-v3.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore_functions.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore_operators.sql

--! @file encrypted_domain/int4/int4_ord_ore_aggregates.sql
--! @brief Ordered domain of the int4 encrypted-domain family — MIN/MAX aggregates.

--! @brief State function for min aggregate on eql_v3.int4_ord_ore.
--! @internal
--!
--! @param state eql_v3.int4_ord_ore running extremum
--! @param value eql_v3.int4_ord_ore next non-NULL value
--! @return eql_v3.int4_ord_ore the minimum of state and value
-- LANGUAGE plpgsql, not sql: aggregate state functions are not index
-- expressions, so opacity to the planner is fine, and a multi-statement
-- BEGIN/IF/END body is the natural shape. (A LANGUAGE sql CASE would
-- also work, but the procedural form mirrors the blocker convention.)
CREATE FUNCTION eql_v3.min_sfunc(state eql_v3.int4_ord_ore, value eql_v3.int4_ord_ore)
RETURNS eql_v3.int4_ord_ore
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF value < state THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief Find the minimum encrypted value in a group of eql_v3.int4_ord_ore values.
--!
--! Comparison routes through the domain's `<` operator, which uses the ORE block term — no decryption.
--!
--! @param input eql_v3.int4_ord_ore encrypted values to aggregate
--! @return eql_v3.int4_ord_ore minimum of the group, or NULL if all inputs are NULL
-- combinefunc = sfunc: min/max are associative, so merging two partial
-- extrema is the same comparison. PARALLEL SAFE enables partial and
-- parallel aggregation on large GROUP BY workloads, with no decryption.
CREATE AGGREGATE eql_v3.min(eql_v3.int4_ord_ore) (
  sfunc = eql_v3.min_sfunc,
  stype = eql_v3.int4_ord_ore,
  combinefunc = eql_v3.min_sfunc,
  parallel = safe
);

--! @brief State function for max aggregate on eql_v3.int4_ord_ore.
--! @internal
--!
--! @param state eql_v3.int4_ord_ore running extremum
--! @param value eql_v3.int4_ord_ore next non-NULL value
--! @return eql_v3.int4_ord_ore the maximum of state and value
-- LANGUAGE plpgsql, not sql: aggregate state functions are not index
-- expressions, so opacity to the planner is fine, and a multi-statement
-- BEGIN/IF/END body is the natural shape. (A LANGUAGE sql CASE would
-- also work, but the procedural form mirrors the blocker convention.)
CREATE FUNCTION eql_v3.max_sfunc(state eql_v3.int4_ord_ore, value eql_v3.int4_ord_ore)
RETURNS eql_v3.int4_ord_ore
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF value > state THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief Find the maximum encrypted value in a group of eql_v3.int4_ord_ore values.
--!
--! Comparison routes through the domain's `>` operator, which uses the ORE block term — no decryption.
--!
--! @param input eql_v3.int4_ord_ore encrypted values to aggregate
--! @return eql_v3.int4_ord_ore maximum of the group, or NULL if all inputs are NULL
-- combinefunc = sfunc: min/max are associative, so merging two partial
-- extrema is the same comparison. PARALLEL SAFE enables partial and
-- parallel aggregation on large GROUP BY workloads, with no decryption.
CREATE AGGREGATE eql_v3.max(eql_v3.int4_ord_ore) (
  sfunc = eql_v3.max_sfunc,
  stype = eql_v3.int4_ord_ore,
  combinefunc = eql_v3.max_sfunc,
  parallel = safe
);
