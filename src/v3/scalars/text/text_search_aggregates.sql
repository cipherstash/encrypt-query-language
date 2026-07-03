-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/text/text_search_functions.sql
-- REQUIRE: src/v3/scalars/text/text_search_operators.sql

--! @file encrypted_domain/text/text_search_aggregates.sql
--! @brief Aggregates for eql_v3.text_search.

--! @brief State function for min on eql_v3.text_search.
--! @param state eql_v3.text_search
--! @param value eql_v3.text_search
--! @return eql_v3.text_search
CREATE FUNCTION eql_v3_internal.min_sfunc(state eql_v3.text_search, value eql_v3.text_search)
RETURNS eql_v3.text_search
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

--! @brief min aggregate for eql_v3.text_search.
--! @param input eql_v3.text_search
--! @return eql_v3.text_search
CREATE AGGREGATE eql_v3.min(eql_v3.text_search) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = eql_v3.text_search,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on eql_v3.text_search.
--! @param state eql_v3.text_search
--! @param value eql_v3.text_search
--! @return eql_v3.text_search
CREATE FUNCTION eql_v3_internal.max_sfunc(state eql_v3.text_search, value eql_v3.text_search)
RETURNS eql_v3.text_search
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

--! @brief max aggregate for eql_v3.text_search.
--! @param input eql_v3.text_search
--! @return eql_v3.text_search
CREATE AGGREGATE eql_v3.max(eql_v3.text_search) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = eql_v3.text_search,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
