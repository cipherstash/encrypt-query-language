-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int4/int4_types.sql
-- REQUIRE: src/v3/scalars/int4/int4_ord_functions.sql
-- REQUIRE: src/v3/scalars/int4/int4_ord_operators.sql

--! @file encrypted_domain/int4/int4_ord_aggregates.sql
--! @brief Aggregates for public.int4_ord.

--! @brief State function for min on public.int4_ord.
--! @param state public.int4_ord
--! @param value public.int4_ord
--! @return public.int4_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.int4_ord, value public.int4_ord)
RETURNS public.int4_ord
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

--! @brief min aggregate for public.int4_ord.
--! @param input public.int4_ord
--! @return public.int4_ord
CREATE AGGREGATE eql_v3.min(public.int4_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.int4_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.int4_ord.
--! @param state public.int4_ord
--! @param value public.int4_ord
--! @return public.int4_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.int4_ord, value public.int4_ord)
RETURNS public.int4_ord
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

--! @brief max aggregate for public.int4_ord.
--! @param input public.int4_ord
--! @return public.int4_ord
CREATE AGGREGATE eql_v3.max(public.int4_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.int4_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
