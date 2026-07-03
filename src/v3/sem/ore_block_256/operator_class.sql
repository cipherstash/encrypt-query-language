-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ore_block_256/types.sql
-- REQUIRE: src/v3/sem/ore_block_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/operators.sql

--! @file v3/sem/ore_block_256/operator_class.sql
--! @brief B-tree operator family + default class on eql_v3_internal.ore_block_256.
--!
--! Gives the composite type its DEFAULT btree opclass so the recommended
--! functional index `CREATE INDEX ON t (eql_v3_internal.ord_term(col))` engages without
--! an explicit opclass annotation (design D4). Excluded from the Supabase build
--! variant by the `**/*operator_class.sql` glob.

--! @brief B-tree operator family for ORE block types
CREATE OPERATOR FAMILY eql_v3_internal.ore_block_256_operator_family USING btree;

--! @brief B-tree operator class for ORE block encrypted values
--!
--! Supports operators: <, <=, =, >=, >. Uses comparison function
--! compare_ore_block_256_terms.
CREATE OPERATOR CLASS eql_v3_internal.ore_block_256_operator_class DEFAULT FOR TYPE eql_v3_internal.ore_block_256 USING btree FAMILY eql_v3_internal.ore_block_256_operator_family  AS
        OPERATOR 1 public.<,
        OPERATOR 2 public.<=,
        OPERATOR 3 public.=,
        OPERATOR 4 public.>=,
        OPERATOR 5 public.>,
        FUNCTION 1 eql_v3_internal.compare_ore_block_256_terms(a eql_v3_internal.ore_block_256, b eql_v3_internal.ore_block_256);
