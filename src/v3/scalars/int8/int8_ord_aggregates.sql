-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int8/int8_types.sql
-- REQUIRE: src/v3/scalars/int8/int8_ord_functions.sql
-- REQUIRE: src/v3/scalars/int8/int8_ord_operators.sql

--! @file encrypted_domain/int8/int8_ord_aggregates.sql
--! @brief Aggregates for public.int8_ord.

--! @brief State function for min on public.int8_ord.
--! @param state public.int8_ord
--! @param value public.int8_ord
--! @return public.int8_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.int8_ord, value public.int8_ord)
RETURNS public.int8_ord
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

--! @brief min aggregate for public.int8_ord.
--! @param input public.int8_ord
--! @return public.int8_ord
CREATE AGGREGATE eql_v3.min(public.int8_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.int8_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.int8_ord.
--! @param state public.int8_ord
--! @param value public.int8_ord
--! @return public.int8_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.int8_ord, value public.int8_ord)
RETURNS public.int8_ord
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

--! @brief max aggregate for public.int8_ord.
--! @param input public.int8_ord
--! @return public.int8_ord
CREATE AGGREGATE eql_v3.max(public.int8_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.int8_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
