-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/text/text_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/text/text_ord_ope_operators.sql

--! @file encrypted_domain/text/text_ord_ope_aggregates.sql
--! @brief Aggregates for public.text_ord_ope.

--! @brief State function for min on public.text_ord_ope.
--! @param state public.text_ord_ope
--! @param value public.text_ord_ope
--! @return public.text_ord_ope
CREATE FUNCTION eql_v3_internal.min_sfunc(state public.text_ord_ope, value public.text_ord_ope)
RETURNS public.text_ord_ope
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

--! @brief min aggregate for public.text_ord_ope.
--! @param input public.text_ord_ope
--! @return public.text_ord_ope
CREATE AGGREGATE eql_v3.min(public.text_ord_ope) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = public.text_ord_ope,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.text_ord_ope.
--! @param state public.text_ord_ope
--! @param value public.text_ord_ope
--! @return public.text_ord_ope
CREATE FUNCTION eql_v3_internal.max_sfunc(state public.text_ord_ope, value public.text_ord_ope)
RETURNS public.text_ord_ope
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

--! @brief max aggregate for public.text_ord_ope.
--! @param input public.text_ord_ope
--! @return public.text_ord_ope
CREATE AGGREGATE eql_v3.max(public.text_ord_ope) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = public.text_ord_ope,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
