-- NOTE FILE IS DISABLED
-- REPLACE `!REQUIRE` with `REQUIRE` to enable in the build

-- !REQUIRE: src/schema.sql
-- !REQUIRE: src/ore_block_u64_8_256/types.sql


CREATE OPERATOR FAMILY eql_v2.ore_block_u64_8_256_operator_family USING btree;

CREATE OPERATOR CLASS eql_v2.ore_block_u64_8_256_operator_class DEFAULT FOR TYPE eql_v2.ore_block_u64_8_256 USING btree FAMILY eql_v2.ore_block_u64_8_256_operator_family  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v2.compare_ore_block_u64_8_256_terms(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256);
