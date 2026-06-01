-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_functions.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_operators.sql

--! @file encrypted_domain/int4/int4_ord_aggregates.sql
--! @brief Ordered domain of the int4 encrypted-domain family — MIN/MAX aggregates.

--! @brief State function for min aggregate on eql_v2_int4_ord.
--! @internal
--!
--! @param state eql_v2_int4_ord running extremum
--! @param value eql_v2_int4_ord next non-NULL value
--! @return eql_v2_int4_ord the minimum of state and value
-- LANGUAGE plpgsql, not sql: aggregate state functions are not index
-- expressions, so opacity to the planner is fine, and a multi-statement
-- BEGIN/IF/END body is the natural shape. (A LANGUAGE sql CASE would
-- also work, but the procedural form mirrors the blocker convention.)
CREATE FUNCTION eql_v2.min_sfunc(state eql_v2_int4_ord, value eql_v2_int4_ord)
RETURNS eql_v2_int4_ord
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

--! @brief Find the minimum encrypted value in a group of eql_v2_int4_ord values.
--!
--! Comparison routes through the domain's `<` operator, which uses the ORE block term — no decryption.
--!
--! @param input eql_v2_int4_ord encrypted values to aggregate
--! @return eql_v2_int4_ord minimum of the group, or NULL if all inputs are NULL
-- combinefunc = sfunc: min/max are associative, so merging two partial
-- extrema is the same comparison. PARALLEL SAFE enables partial and
-- parallel aggregation on large GROUP BY workloads, with no decryption.
CREATE AGGREGATE eql_v2.min(eql_v2_int4_ord) (
  sfunc = eql_v2.min_sfunc,
  stype = eql_v2_int4_ord,
  combinefunc = eql_v2.min_sfunc,
  parallel = safe
);

--! @brief State function for max aggregate on eql_v2_int4_ord.
--! @internal
--!
--! @param state eql_v2_int4_ord running extremum
--! @param value eql_v2_int4_ord next non-NULL value
--! @return eql_v2_int4_ord the maximum of state and value
-- LANGUAGE plpgsql, not sql: aggregate state functions are not index
-- expressions, so opacity to the planner is fine, and a multi-statement
-- BEGIN/IF/END body is the natural shape. (A LANGUAGE sql CASE would
-- also work, but the procedural form mirrors the blocker convention.)
CREATE FUNCTION eql_v2.max_sfunc(state eql_v2_int4_ord, value eql_v2_int4_ord)
RETURNS eql_v2_int4_ord
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

--! @brief Find the maximum encrypted value in a group of eql_v2_int4_ord values.
--!
--! Comparison routes through the domain's `>` operator, which uses the ORE block term — no decryption.
--!
--! @param input eql_v2_int4_ord encrypted values to aggregate
--! @return eql_v2_int4_ord maximum of the group, or NULL if all inputs are NULL
-- combinefunc = sfunc: min/max are associative, so merging two partial
-- extrema is the same comparison. PARALLEL SAFE enables partial and
-- parallel aggregation on large GROUP BY workloads, with no decryption.
CREATE AGGREGATE eql_v2.max(eql_v2_int4_ord) (
  sfunc = eql_v2.max_sfunc,
  stype = eql_v2_int4_ord,
  combinefunc = eql_v2.max_sfunc,
  parallel = safe
);
