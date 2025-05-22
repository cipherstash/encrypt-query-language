-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql


CREATE OPERATOR FAMILY eql_v2.ore_block_u64_8_256_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v2.ore_block_u64_8_256_btree_ops DEFAULT FOR TYPE eql_v2.ore_block_u64_8_256 USING btree FAMILY eql_v2.ore_block_u64_8_256_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v2.compare_ore_block_u64_8_256(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256);
