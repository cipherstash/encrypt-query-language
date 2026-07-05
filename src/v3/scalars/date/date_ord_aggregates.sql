-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/date/date_types.sql
-- REQUIRE: src/v3/scalars/date/date_ord_functions.sql
-- REQUIRE: src/v3/scalars/date/date_ord_operators.sql

--! @file encrypted_domain/date/date_ord_aggregates.sql
--! @brief Aggregates for public.date_ord.

--! @brief State function for min on public.date_ord.
--! @param state public.date_ord
--! @param value public.date_ord
--! @return public.date_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.date_ord, value public.date_ord)
RETURNS public.date_ord
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

--! @brief min aggregate for public.date_ord.
--! @param input public.date_ord
--! @return public.date_ord
CREATE AGGREGATE eql_v3.min(public.date_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.date_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.date_ord.
--! @param state public.date_ord
--! @param value public.date_ord
--! @return public.date_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.date_ord, value public.date_ord)
RETURNS public.date_ord
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

--! @brief max aggregate for public.date_ord.
--! @param input public.date_ord
--! @return public.date_ord
CREATE AGGREGATE eql_v3.max(public.date_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.date_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
