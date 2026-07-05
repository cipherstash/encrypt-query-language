-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/real/real_types.sql
-- REQUIRE: src/v3/scalars/real/real_ord_functions.sql
-- REQUIRE: src/v3/scalars/real/real_ord_operators.sql

--! @file encrypted_domain/real/real_ord_aggregates.sql
--! @brief Aggregates for public.real_ord.

--! @brief State function for min on public.real_ord.
--! @param state public.real_ord
--! @param value public.real_ord
--! @return public.real_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.real_ord, value public.real_ord)
RETURNS public.real_ord
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

--! @brief min aggregate for public.real_ord.
--! @param input public.real_ord
--! @return public.real_ord
CREATE AGGREGATE eql_v3.min(public.real_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.real_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.real_ord.
--! @param state public.real_ord
--! @param value public.real_ord
--! @return public.real_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.real_ord, value public.real_ord)
RETURNS public.real_ord
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

--! @brief max aggregate for public.real_ord.
--! @param input public.real_ord
--! @return public.real_ord
CREATE AGGREGATE eql_v3.max(public.real_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.real_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
