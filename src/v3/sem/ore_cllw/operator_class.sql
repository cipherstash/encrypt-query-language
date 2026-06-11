-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ore_cllw/types.sql
-- REQUIRE: src/v3/sem/ore_cllw/functions.sql
-- REQUIRE: src/v3/sem/ore_cllw/operators.sql

--! @file v3/sem/ore_cllw/operator_class.sql
--! @brief Btree operator class on the eql_v3.ore_cllw composite type.
--!
--! DEFAULT FOR TYPE so a functional btree index on eql_v3.ore_cllw(expr)
--! engages without an explicit opclass annotation. FUNCTION 1 is the three-way
--! comparator btree's internal sort uses; it is plpgsql by design (per-byte
--! CLLW protocol needs iteration) and is called once per index-entry pair
--! during build / search, not per-row in the outer query.
--!
--! @note Excluded from the Supabase build variant by the build glob
--!       `**/*operator_class.sql`.
--! @see eql_v3.compare_ore_cllw_term

CREATE OPERATOR FAMILY eql_v3.ore_cllw_ops USING btree;

CREATE OPERATOR CLASS eql_v3.ore_cllw_ops
  DEFAULT FOR TYPE eql_v3.ore_cllw
  USING btree FAMILY eql_v3.ore_cllw_ops AS
    OPERATOR 1 <  (eql_v3.ore_cllw, eql_v3.ore_cllw),
    OPERATOR 2 <= (eql_v3.ore_cllw, eql_v3.ore_cllw),
    OPERATOR 3 =  (eql_v3.ore_cllw, eql_v3.ore_cllw),
    OPERATOR 4 >= (eql_v3.ore_cllw, eql_v3.ore_cllw),
    OPERATOR 5 >  (eql_v3.ore_cllw, eql_v3.ore_cllw),
    FUNCTION 1 eql_v3.compare_ore_cllw_term(eql_v3.ore_cllw, eql_v3.ore_cllw);
