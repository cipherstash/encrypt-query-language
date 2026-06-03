-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ore_block_u64_8_256/types.sql
-- REQUIRE: src/v3/sem/ore_block_u64_8_256/functions.sql

--! @file v3/sem/ore_block_u64_8_256/operator_class.sql
--! @brief B-tree operator family + default class on eql_v3.ore_block_u64_8_256.
--!
--! Gives the composite type its DEFAULT btree opclass so the recommended
--! functional index `CREATE INDEX ON t (eql_v3.ord_term(col))` engages without
--! an explicit opclass annotation (design D4). Excluded from the Supabase build
--! variant by the `**/*operator_class.sql` glob.

--! @brief B-tree operator family for ORE block types
CREATE OPERATOR FAMILY eql_v3.ore_block_u64_8_256_operator_family USING btree;

--! @brief B-tree operator class for ORE block encrypted values
--!
--! Supports operators: <, <=, =, >=, >. Uses comparison function
--! compare_ore_block_u64_8_256_terms.
CREATE OPERATOR CLASS eql_v3.ore_block_u64_8_256_operator_class DEFAULT FOR TYPE eql_v3.ore_block_u64_8_256 USING btree FAMILY eql_v3.ore_block_u64_8_256_operator_family  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v3.compare_ore_block_u64_8_256_terms(a eql_v3.ore_block_u64_8_256, b eql_v3.ore_block_u64_8_256);
