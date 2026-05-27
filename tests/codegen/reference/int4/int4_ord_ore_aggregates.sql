-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore_functions.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore_operators.sql

--! @file encrypted_domain/int4/int4_ord_ore_aggregates.sql
--! @brief Ordered domain of the int4 encrypted-domain family — MIN/MAX aggregates.

--! @brief State function for min aggregate on eql_v2_int4_ord_ore.
--! @internal
--!
--! @param state eql_v2_int4_ord_ore running extremum
--! @param value eql_v2_int4_ord_ore next non-NULL value
--! @return eql_v2_int4_ord_ore the minimum of state and value
CREATE FUNCTION eql_v2.min_sfunc(state eql_v2_int4_ord_ore, value eql_v2_int4_ord_ore)
RETURNS eql_v2_int4_ord_ore
LANGUAGE plpgsql IMMUTABLE STRICT
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF value < state THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief Find the minimum encrypted value in a group of eql_v2_int4_ord_ore values.
--!
--! Comparison routes through the domain's `<` operator, which uses the ORE block term — no decryption.
--!
--! @param input eql_v2_int4_ord_ore encrypted values to aggregate
--! @return eql_v2_int4_ord_ore minimum of the group, or NULL if all inputs are NULL
CREATE AGGREGATE eql_v2.min(eql_v2_int4_ord_ore) (
  sfunc = eql_v2.min_sfunc,
  stype = eql_v2_int4_ord_ore
);

--! @brief State function for max aggregate on eql_v2_int4_ord_ore.
--! @internal
--!
--! @param state eql_v2_int4_ord_ore running extremum
--! @param value eql_v2_int4_ord_ore next non-NULL value
--! @return eql_v2_int4_ord_ore the maximum of state and value
CREATE FUNCTION eql_v2.max_sfunc(state eql_v2_int4_ord_ore, value eql_v2_int4_ord_ore)
RETURNS eql_v2_int4_ord_ore
LANGUAGE plpgsql IMMUTABLE STRICT
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF value > state THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief Find the maximum encrypted value in a group of eql_v2_int4_ord_ore values.
--!
--! Comparison routes through the domain's `>` operator, which uses the ORE block term — no decryption.
--!
--! @param input eql_v2_int4_ord_ore encrypted values to aggregate
--! @return eql_v2_int4_ord_ore maximum of the group, or NULL if all inputs are NULL
CREATE AGGREGATE eql_v2.max(eql_v2_int4_ord_ore) (
  sfunc = eql_v2.max_sfunc,
  stype = eql_v2_int4_ord_ore
);
