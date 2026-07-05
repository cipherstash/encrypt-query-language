-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_operators.sql

--! @file encrypted_domain/bigint/bigint_ord_aggregates.sql
--! @brief Aggregates for public.bigint_ord.

--! @brief State function for min on public.bigint_ord.
--! @param state public.bigint_ord
--! @param value public.bigint_ord
--! @return public.bigint_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.bigint_ord, value public.bigint_ord)
RETURNS public.bigint_ord
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

--! @brief min aggregate for public.bigint_ord.
--! @param input public.bigint_ord
--! @return public.bigint_ord
CREATE AGGREGATE eql_v3.min(public.bigint_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.bigint_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.bigint_ord.
--! @param state public.bigint_ord
--! @param value public.bigint_ord
--! @return public.bigint_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.bigint_ord, value public.bigint_ord)
RETURNS public.bigint_ord
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

--! @brief max aggregate for public.bigint_ord.
--! @param input public.bigint_ord
--! @return public.bigint_ord
CREATE AGGREGATE eql_v3.max(public.bigint_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.bigint_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
