-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_ope_operators.sql

--! @file encrypted_domain/bigint/bigint_ord_ope_aggregates.sql
--! @brief Aggregates for public.bigint_ord_ope.

--! @brief State function for min on public.bigint_ord_ope.
--! @param state public.bigint_ord_ope
--! @param value public.bigint_ord_ope
--! @return public.bigint_ord_ope
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.bigint_ord_ope, value public.bigint_ord_ope)
RETURNS public.bigint_ord_ope
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

--! @brief min aggregate for public.bigint_ord_ope.
--! @param input public.bigint_ord_ope
--! @return public.bigint_ord_ope
CREATE AGGREGATE eql_v3.min(public.bigint_ord_ope) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.bigint_ord_ope,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.bigint_ord_ope.
--! @param state public.bigint_ord_ope
--! @param value public.bigint_ord_ope
--! @return public.bigint_ord_ope
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.bigint_ord_ope, value public.bigint_ord_ope)
RETURNS public.bigint_ord_ope
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

--! @brief max aggregate for public.bigint_ord_ope.
--! @param input public.bigint_ord_ope
--! @return public.bigint_ord_ope
CREATE AGGREGATE eql_v3.max(public.bigint_ord_ope) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.bigint_ord_ope,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
