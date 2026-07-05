-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_ore_operators.sql

--! @file encrypted_domain/bigint/bigint_ord_ore_aggregates.sql
--! @brief Aggregates for public.bigint_ord_ore.

--! @brief State function for min on public.bigint_ord_ore.
--! @param state public.bigint_ord_ore
--! @param value public.bigint_ord_ore
--! @return public.bigint_ord_ore
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.bigint_ord_ore, value public.bigint_ord_ore)
RETURNS public.bigint_ord_ore
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

--! @brief min aggregate for public.bigint_ord_ore.
--! @param input public.bigint_ord_ore
--! @return public.bigint_ord_ore
CREATE AGGREGATE eql_v3.min(public.bigint_ord_ore) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.bigint_ord_ore,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.bigint_ord_ore.
--! @param state public.bigint_ord_ore
--! @param value public.bigint_ord_ore
--! @return public.bigint_ord_ore
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.bigint_ord_ore, value public.bigint_ord_ore)
RETURNS public.bigint_ord_ore
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

--! @brief max aggregate for public.bigint_ord_ore.
--! @param input public.bigint_ord_ore
--! @return public.bigint_ord_ore
CREATE AGGREGATE eql_v3.max(public.bigint_ord_ore) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.bigint_ord_ore,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
