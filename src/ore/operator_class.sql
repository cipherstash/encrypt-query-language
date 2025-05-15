-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore/types.sql


CREATE OPERATOR FAMILY eql_v1.ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_64_8_v1_btree_ops DEFAULT FOR TYPE eql_v1.ore_64_8_v1 USING btree FAMILY eql_v1.ore_64_8_v1_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);
