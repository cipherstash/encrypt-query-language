-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/integer_types.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_functions.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_operators.sql

--! @file encrypted_domain/integer/integer_ord_aggregates.sql
--! @brief Aggregates for public.integer_ord.

--! @brief State function for min on public.integer_ord.
--! @param state public.integer_ord
--! @param value public.integer_ord
--! @return public.integer_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.integer_ord, value public.integer_ord)
RETURNS public.integer_ord
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

--! @brief min aggregate for public.integer_ord.
--! @param input public.integer_ord
--! @return public.integer_ord
CREATE AGGREGATE eql_v3.min(public.integer_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.integer_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.integer_ord.
--! @param state public.integer_ord
--! @param value public.integer_ord
--! @return public.integer_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.integer_ord, value public.integer_ord)
RETURNS public.integer_ord
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

--! @brief max aggregate for public.integer_ord.
--! @param input public.integer_ord
--! @return public.integer_ord
CREATE AGGREGATE eql_v3.max(public.integer_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.integer_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
