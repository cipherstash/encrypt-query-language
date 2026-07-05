-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/double/double_ord_functions.sql
-- REQUIRE: src/v3/scalars/double/double_ord_operators.sql

--! @file encrypted_domain/double/double_ord_aggregates.sql
--! @brief Aggregates for public.double_ord.

--! @brief State function for min on public.double_ord.
--! @param state public.double_ord
--! @param value public.double_ord
--! @return public.double_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.double_ord, value public.double_ord)
RETURNS public.double_ord
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

--! @brief min aggregate for public.double_ord.
--! @param input public.double_ord
--! @return public.double_ord
CREATE AGGREGATE eql_v3.min(public.double_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.double_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.double_ord.
--! @param state public.double_ord
--! @param value public.double_ord
--! @return public.double_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.double_ord, value public.double_ord)
RETURNS public.double_ord
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

--! @brief max aggregate for public.double_ord.
--! @param input public.double_ord
--! @return public.double_ord
CREATE AGGREGATE eql_v3.max(public.double_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.double_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
