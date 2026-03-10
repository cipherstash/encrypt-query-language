-- Drop operator classes and operators to simulate Supabase environment
-- The Supabase build excludes all operator classes AND the ore_block_u64_8_256
-- operators/operator class. This means neither ORDER BY e nor
-- ORDER BY eql_v2.order_by(e) can use ORE-aware sorting.

-- Drop btree operator class for eql_v2_encrypted
DROP OPERATOR CLASS IF EXISTS eql_v2.encrypted_operator_class USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS eql_v2.encrypted_operator_family USING btree CASCADE;

-- Drop hash operator class for eql_v2_encrypted
DROP OPERATOR CLASS IF EXISTS eql_v2.encrypted_hash_operator_class USING hash CASCADE;
DROP OPERATOR FAMILY IF EXISTS eql_v2.encrypted_hash_operator_family USING hash CASCADE;

-- Drop btree operator class for ore_block_u64_8_256
-- This is excluded from the Supabase build and is what makes ORDER BY eql_v2.order_by(e) work
DROP OPERATOR CLASS IF EXISTS eql_v2.ore_block_u64_8_256_operator_class USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS eql_v2.ore_block_u64_8_256_operator_family USING btree CASCADE;

-- Drop ore_block_u64_8_256 operators (also excluded from Supabase build)
DROP OPERATOR IF EXISTS = (eql_v2.ore_block_u64_8_256, eql_v2.ore_block_u64_8_256) CASCADE;
DROP OPERATOR IF EXISTS <> (eql_v2.ore_block_u64_8_256, eql_v2.ore_block_u64_8_256) CASCADE;
DROP OPERATOR IF EXISTS < (eql_v2.ore_block_u64_8_256, eql_v2.ore_block_u64_8_256) CASCADE;
DROP OPERATOR IF EXISTS <= (eql_v2.ore_block_u64_8_256, eql_v2.ore_block_u64_8_256) CASCADE;
DROP OPERATOR IF EXISTS > (eql_v2.ore_block_u64_8_256, eql_v2.ore_block_u64_8_256) CASCADE;
DROP OPERATOR IF EXISTS >= (eql_v2.ore_block_u64_8_256, eql_v2.ore_block_u64_8_256) CASCADE;
