-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/float8/float8_types.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_operators.sql

--! @file encrypted_domain/float8/float8_ord_aggregates.sql
--! @brief Aggregates for public.float8_ord.

--! @brief State function for min on public.float8_ord.
--! @param state public.float8_ord
--! @param value public.float8_ord
--! @return public.float8_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.float8_ord, value public.float8_ord)
RETURNS public.float8_ord
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

--! @brief min aggregate for public.float8_ord.
--! @param input public.float8_ord
--! @return public.float8_ord
CREATE AGGREGATE eql_v3.min(public.float8_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.float8_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.float8_ord.
--! @param state public.float8_ord
--! @param value public.float8_ord
--! @return public.float8_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.float8_ord, value public.float8_ord)
RETURNS public.float8_ord
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

--! @brief max aggregate for public.float8_ord.
--! @param input public.float8_ord
--! @return public.float8_ord
CREATE AGGREGATE eql_v3.max(public.float8_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.float8_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
