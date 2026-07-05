-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_types.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_ord_functions.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_ord_operators.sql

--! @file encrypted_domain/timestamp/timestamp_ord_aggregates.sql
--! @brief Aggregates for public.timestamp_ord.

--! @brief State function for min on public.timestamp_ord.
--! @param state public.timestamp_ord
--! @param value public.timestamp_ord
--! @return public.timestamp_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.timestamp_ord, value public.timestamp_ord)
RETURNS public.timestamp_ord
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

--! @brief min aggregate for public.timestamp_ord.
--! @param input public.timestamp_ord
--! @return public.timestamp_ord
CREATE AGGREGATE eql_v3.min(public.timestamp_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.timestamp_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.timestamp_ord.
--! @param state public.timestamp_ord
--! @param value public.timestamp_ord
--! @return public.timestamp_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.timestamp_ord, value public.timestamp_ord)
RETURNS public.timestamp_ord
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

--! @brief max aggregate for public.timestamp_ord.
--! @param input public.timestamp_ord
--! @return public.timestamp_ord
CREATE AGGREGATE eql_v3.max(public.timestamp_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.timestamp_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
