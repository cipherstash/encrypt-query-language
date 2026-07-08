-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/float8/float8_types.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_ore_operators.sql

--! @file encrypted_domain/float8/float8_ord_ore_aggregates.sql
--! @brief Aggregates for public.float8_ord_ore.

--! @brief State function for min on public.float8_ord_ore.
--! @param state public.float8_ord_ore
--! @param value public.float8_ord_ore
--! @return public.float8_ord_ore
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.float8_ord_ore, value public.float8_ord_ore)
RETURNS public.float8_ord_ore
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

--! @brief min aggregate for public.float8_ord_ore.
--! @param input public.float8_ord_ore
--! @return public.float8_ord_ore
CREATE AGGREGATE eql_v3.min(public.float8_ord_ore) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.float8_ord_ore,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.float8_ord_ore.
--! @param state public.float8_ord_ore
--! @param value public.float8_ord_ore
--! @return public.float8_ord_ore
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.float8_ord_ore, value public.float8_ord_ore)
RETURNS public.float8_ord_ore
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

--! @brief max aggregate for public.float8_ord_ore.
--! @param input public.float8_ord_ore
--! @return public.float8_ord_ore
CREATE AGGREGATE eql_v3.max(public.float8_ord_ore) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.float8_ord_ore,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
