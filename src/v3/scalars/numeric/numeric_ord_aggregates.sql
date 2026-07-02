-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_types.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_functions.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_operators.sql

--! @file encrypted_domain/numeric/numeric_ord_aggregates.sql
--! @brief Aggregates for eql_v3.numeric_ord.

--! @brief State function for min on eql_v3.numeric_ord.
--! @param state eql_v3.numeric_ord
--! @param value eql_v3.numeric_ord
--! @return eql_v3.numeric_ord
CREATE FUNCTION eql_v3_internal.min_sfunc(state eql_v3.numeric_ord, value eql_v3.numeric_ord)
RETURNS eql_v3.numeric_ord
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

--! @brief min aggregate for eql_v3.numeric_ord.
--! @param input eql_v3.numeric_ord
--! @return eql_v3.numeric_ord
CREATE AGGREGATE eql_v3.min(eql_v3.numeric_ord) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = eql_v3.numeric_ord,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on eql_v3.numeric_ord.
--! @param state eql_v3.numeric_ord
--! @param value eql_v3.numeric_ord
--! @return eql_v3.numeric_ord
CREATE FUNCTION eql_v3_internal.max_sfunc(state eql_v3.numeric_ord, value eql_v3.numeric_ord)
RETURNS eql_v3.numeric_ord
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

--! @brief max aggregate for eql_v3.numeric_ord.
--! @param input eql_v3.numeric_ord
--! @return eql_v3.numeric_ord
CREATE AGGREGATE eql_v3.max(eql_v3.numeric_ord) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = eql_v3.numeric_ord,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
