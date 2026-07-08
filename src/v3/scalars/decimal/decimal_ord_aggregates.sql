-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_types.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_ord_functions.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_ord_operators.sql

--! @file encrypted_domain/decimal/decimal_ord_aggregates.sql
--! @brief Aggregates for public.decimal_ord.

--! @brief State function for min on public.decimal_ord.
--! @param state public.decimal_ord
--! @param value public.decimal_ord
--! @return public.decimal_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.decimal_ord, value public.decimal_ord)
RETURNS public.decimal_ord
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

--! @brief min aggregate for public.decimal_ord.
--! @param input public.decimal_ord
--! @return public.decimal_ord
CREATE AGGREGATE eql_v3.min(public.decimal_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.decimal_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.decimal_ord.
--! @param state public.decimal_ord
--! @param value public.decimal_ord
--! @return public.decimal_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.decimal_ord, value public.decimal_ord)
RETURNS public.decimal_ord
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

--! @brief max aggregate for public.decimal_ord.
--! @param input public.decimal_ord
--! @return public.decimal_ord
CREATE AGGREGATE eql_v3.max(public.decimal_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.decimal_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
