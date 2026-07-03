-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_types.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_ope_operators.sql

--! @file encrypted_domain/numeric/numeric_ord_ope_aggregates.sql
--! @brief Aggregates for eql_v3.numeric_ord_ope.

--! @brief State function for min on eql_v3.numeric_ord_ope.
--! @param state eql_v3.numeric_ord_ope
--! @param value eql_v3.numeric_ord_ope
--! @return eql_v3.numeric_ord_ope
CREATE FUNCTION eql_v3_internal.min_sfunc(state eql_v3.numeric_ord_ope, value eql_v3.numeric_ord_ope)
RETURNS eql_v3.numeric_ord_ope
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

--! @brief min aggregate for eql_v3.numeric_ord_ope.
--! @param input eql_v3.numeric_ord_ope
--! @return eql_v3.numeric_ord_ope
CREATE AGGREGATE eql_v3.min(eql_v3.numeric_ord_ope) (
  sfunc = eql_v3_internal.min_sfunc,
  stype = eql_v3.numeric_ord_ope,
  combinefunc = eql_v3_internal.min_sfunc,
  parallel = safe
);

--! @brief State function for max on eql_v3.numeric_ord_ope.
--! @param state eql_v3.numeric_ord_ope
--! @param value eql_v3.numeric_ord_ope
--! @return eql_v3.numeric_ord_ope
CREATE FUNCTION eql_v3_internal.max_sfunc(state eql_v3.numeric_ord_ope, value eql_v3.numeric_ord_ope)
RETURNS eql_v3.numeric_ord_ope
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

--! @brief max aggregate for eql_v3.numeric_ord_ope.
--! @param input eql_v3.numeric_ord_ope
--! @return eql_v3.numeric_ord_ope
CREATE AGGREGATE eql_v3.max(eql_v3.numeric_ord_ope) (
  sfunc = eql_v3_internal.max_sfunc,
  stype = eql_v3.numeric_ord_ope,
  combinefunc = eql_v3_internal.max_sfunc,
  parallel = safe
);
