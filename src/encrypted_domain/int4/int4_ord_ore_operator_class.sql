-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore.sql
-- REQUIRE: src/ore_block_u64_8_256/compare.sql
-- REQUIRE: src/encrypted/casts.sql

--! @file encrypted_domain/int4/int4_ord_ore_operator_class.sql
--! @brief btree operator class for eql_v2_int4_ord_ore range indexing.
--!
--! Range operators on eql_v2_int4_ord_ore reduce to PL/pgSQL
--! (compare_ore_block_u64_8_256), so the operator wrappers do not
--! inline and no *functional* btree on the ORE extractor can engage.
--! A btree *operator class* is the correct mechanism: the index
--! access method calls the FUNCTION 1 support comparator directly,
--! per-comparison — inlining is irrelevant. This mirrors the core
--! eql_v2.encrypted_operator_class in src/operators/operator_class.sql.
--!
--! The operator class must be named explicitly in CREATE INDEX:
--!   CREATE INDEX t_idx ON t
--!     USING btree (col eql_v2.eql_v2_int4_ord_ore_operator_class);
--! A bare `USING btree (col)` does NOT pick this class — col is a
--! DOMAIN over jsonb, and PostgreSQL resolves the default opclass of
--! a domain column via its base type (jsonb_ops), never a
--! domain-specific class. Naming the class is required, by design.
--!
--! With the named index in place, `WHERE col < $1` / `<=` / `>` /
--! `>=` engage it (verified: Bitmap Index Scan).
--!
--! @note This file is excluded from the Supabase build variant
--!       (tasks/build.sh strips **/*operator_class.sql — operator
--!       classes are unsupported on Supabase). On Supabase, range
--!       queries on eql_v2_int4_ord_ore fall back to seq-scan; use
--!       eql_v2_int4_ord_ope for Supabase-compatible indexed range.
--! @see eql_v2.compare_ore_block_u64_8_256
--! @see src/operators/operator_class.sql

--! @brief btree support comparator for eql_v2_int4_ord_ore.
--!
--! Casts both domain operands to eql_v2_encrypted and delegates to
--! eql_v2.compare_ore_block_u64_8_256. A dedicated (domain, domain)
--! function is required because compare_ore_block_u64_8_256 accepts
--! eql_v2_encrypted and jsonb->eql_v2_encrypted is a WITH FUNCTION
--! cast (not binary-coercible), so the core comparator cannot serve
--! the domain type directly.
--!
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return integer (-1, 0, 1 — ORE-block ordering of the plaintexts)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_compare(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS integer LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) $$;

CREATE OPERATOR FAMILY eql_v2.eql_v2_int4_ord_ore_operator_family USING btree;

CREATE OPERATOR CLASS eql_v2.eql_v2_int4_ord_ore_operator_class
  FOR TYPE eql_v2_int4_ord_ore USING btree
  FAMILY eql_v2.eql_v2_int4_ord_ore_operator_family AS
    OPERATOR 1 <,
    OPERATOR 2 <=,
    OPERATOR 3 =,
    OPERATOR 4 >=,
    OPERATOR 5 >,
    FUNCTION 1 eql_v2.eql_v2_int4_ord_ore_compare(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore);
