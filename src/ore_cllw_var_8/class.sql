-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_cllw_var_8/types.sql
-- REQUIRE: src/ore_cllw_var_8/functions.sql
-- REQUIRE: src/ore_cllw_var_8/operators.sql


DROP OPERATOR FAMILY IF EXISTS eql_v1.ore_cllw_var_8_variable_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ore_cllw_var_8_variable_btree_ops USING btree;

DROP OPERATOR CLASS IF EXISTS eql_v1.ore_cllw_var_8_variable_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_cllw_var_8_variable_btree_ops DEFAULT FOR TYPE eql_v1.ore_cllw_var_8 USING btree FAMILY eql_v1.ore_cllw_var_8_variable_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ore_cllw_var_8(a eql_v1.ore_cllw_var_8, b eql_v1.ore_cllw_var_8);
