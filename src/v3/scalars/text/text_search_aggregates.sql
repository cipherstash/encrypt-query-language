-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/text/text_search_functions.sql
-- REQUIRE: src/v3/scalars/text/text_search_operators.sql

--! @file encrypted_domain/text/text_search_aggregates.sql
--! @brief Aggregates for public.text_search.

--! @brief State function for min on public.text_search.
--! @param state public.text_search
--! @param value public.text_search
--! @return public.text_search
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.text_search, value public.text_search)
RETURNS public.text_search
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

--! @brief min aggregate for public.text_search.
--! @param input public.text_search
--! @return public.text_search
CREATE AGGREGATE eql_v3.min(public.text_search) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.text_search,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.text_search.
--! @param state public.text_search
--! @param value public.text_search
--! @return public.text_search
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.text_search, value public.text_search)
RETURNS public.text_search
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

--! @brief max aggregate for public.text_search.
--! @param input public.text_search
--! @return public.text_search
CREATE AGGREGATE eql_v3.max(public.text_search) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.text_search,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
