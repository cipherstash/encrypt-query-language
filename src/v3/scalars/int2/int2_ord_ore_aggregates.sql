-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int2/int2_types.sql
-- REQUIRE: src/v3/scalars/int2/int2_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/int2/int2_ord_ore_operators.sql

--! @file encrypted_domain/int2/int2_ord_ore_aggregates.sql
--! @brief Aggregates for eql_v3.int2_ord_ore.

--! @brief State function for min on eql_v3.int2_ord_ore.
--! @param state eql_v3.int2_ord_ore
--! @param value eql_v3.int2_ord_ore
--! @return eql_v3.int2_ord_ore
CREATE FUNCTION eql_v3.min_sfunc(state eql_v3.int2_ord_ore, value eql_v3.int2_ord_ore)
RETURNS eql_v3.int2_ord_ore
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

--! @brief min aggregate for eql_v3.int2_ord_ore.
--! @param input eql_v3.int2_ord_ore
--! @return eql_v3.int2_ord_ore
CREATE AGGREGATE eql_v3.min(eql_v3.int2_ord_ore) (
  sfunc = eql_v3.min_sfunc,
  stype = eql_v3.int2_ord_ore,
  combinefunc = eql_v3.min_sfunc,
  parallel = safe
);

--! @brief State function for max on eql_v3.int2_ord_ore.
--! @param state eql_v3.int2_ord_ore
--! @param value eql_v3.int2_ord_ore
--! @return eql_v3.int2_ord_ore
CREATE FUNCTION eql_v3.max_sfunc(state eql_v3.int2_ord_ore, value eql_v3.int2_ord_ore)
RETURNS eql_v3.int2_ord_ore
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

--! @brief max aggregate for eql_v3.int2_ord_ore.
--! @param input eql_v3.int2_ord_ore
--! @return eql_v3.int2_ord_ore
CREATE AGGREGATE eql_v3.max(eql_v3.int2_ord_ore) (
  sfunc = eql_v3.max_sfunc,
  stype = eql_v3.int2_ord_ore,
  combinefunc = eql_v3.max_sfunc,
  parallel = safe
);
