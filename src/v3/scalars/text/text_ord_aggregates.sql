-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/text/text_ord_functions.sql
-- REQUIRE: src/v3/scalars/text/text_ord_operators.sql

--! @file encrypted_domain/text/text_ord_aggregates.sql
--! @brief Aggregates for public.text_ord.

--! @brief State function for min on public.text_ord.
--! @param state public.text_ord
--! @param value public.text_ord
--! @return public.text_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.text_ord, value public.text_ord)
RETURNS public.text_ord
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

--! @brief min aggregate for public.text_ord.
--! @param input public.text_ord
--! @return public.text_ord
CREATE AGGREGATE eql_v3.min(public.text_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.text_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.text_ord.
--! @param state public.text_ord
--! @param value public.text_ord
--! @return public.text_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.text_ord, value public.text_ord)
RETURNS public.text_ord
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

--! @brief max aggregate for public.text_ord.
--! @param input public.text_ord
--! @return public.text_ord
CREATE AGGREGATE eql_v3.max(public.text_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.text_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
