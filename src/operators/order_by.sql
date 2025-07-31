-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql

-- order_by function for ordering when operators are not available.
--
--
CREATE FUNCTION eql_v2.order_by(a eql_v2_encrypted)
  RETURNS eql_v2.ore_block_u64_8_256
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.ore_block_u64_8_256(a);
  END;
$$ LANGUAGE plpgsql;



