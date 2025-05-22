-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/operators.sql

-- order_by function for ordering when operators are not available.
--
-- There are multiple index terms that provide equality comparisons
--   - ore_cllw_u64_8
--   - ore_cllw_var_8
--   - ore_block_u64_8_256
--
-- We check these index terms in this order and use the first one that exists for both parameters
--
--


CREATE FUNCTION eql_v2.order_by(a eql_v2_encrypted)
  RETURNS eql_v2.ore_block_u64_8_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    BEGIN
      RETURN eql_v2.ore_block_u64_8_256(a);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('No ore_block_u64_8_256 index');
    END;

    RETURN false;
  END;
$$ LANGUAGE plpgsql;

-- TODO: make this work
--       fails with jsonb format issue, which I think is due to the type casting
--
CREATE FUNCTION eql_v2.order_by_any(a anyelement)
  RETURNS anyelement
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    e eql_v2_encrypted;
    result ALIAS FOR $0;
  BEGIN

    e := a::eql_v2_encrypted;

    BEGIN
      result := eql_v2.ore_cllw_u64_8(e);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('No ore_cllw_u64_8 index');
    END;

    BEGIN
      result := eql_v2.ore_cllw_var_8(e);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('No ore_cllw_u64_8 index');
    END;

    BEGIN
      result := eql_v2.ore_block_u64_8_256(e);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('No ore_block_u64_8_256 index');
    END;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;

