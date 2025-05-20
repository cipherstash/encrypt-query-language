-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql
-- REQUIRE: src/ore/operators.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/operators.sql

-- order_by function for ordering when operators are not available.
--
-- There are multiple index terms that provide equality comparisons
--   - ore_cllw_u64_8
--   - ore_cllw_var_8
--   - ore_64_8_v1
--
-- We check these index terms in this order and use the first one that exists for both parameters
--
--


CREATE FUNCTION eql_v1.order_by(a eql_v1_encrypted)
  RETURNS eql_v1.ore_64_8_v1
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    BEGIN
      RETURN eql_v1.ore_64_8_v1(a);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_64_8_v1 index');
    END;

    RETURN false;
  END;
$$ LANGUAGE plpgsql;

-- TODO: make this work
--       fails with jsonb format issue, which I think is due to the type casting
--
CREATE FUNCTION eql_v1.order_by_any(a anyelement)
  RETURNS anyelement
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    e eql_v1_encrypted;
    result ALIAS FOR $0;
  BEGIN

    e := a::eql_v1_encrypted;

    BEGIN
      result := eql_v1.ore_cllw_u64_8(e);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_cllw_u64_8 index');
    END;

    BEGIN
      result := eql_v1.ore_cllw_var_8(e);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_cllw_u64_8 index');
    END;

    BEGIN
      result := eql_v1.ore_64_8_v1(e);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v1.log('No ore_64_8_v1 index');
    END;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;

