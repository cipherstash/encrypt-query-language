-- REQUIRE: src/encrypted_domain/int4/int4_default.sql
-- REQUIRE: src/ore_block_u64_8_256/compare.sql
-- REQUIRE: src/encrypted/casts.sql

--! @file encrypted_domain/int4/int4_default_operator_class.sql
--! @brief btree operator class for the default eql_v2_int4 range indexing.
--!
--! Line-for-line mirror of int4_ord_ore_operator_class.sql with the
--! domain identifier swapped — the default eql_v2_int4 variant is a
--! mirror of eql_v2_int4_ord_ore and must keep operator-class parity.
--!
--! Range operators on eql_v2_int4 reduce to PL/pgSQL
--! (compare_ore_block_u64_8_256), so the operator wrappers do not
--! inline and no *functional* btree on the ORE extractor can engage.
--! A btree *operator class* is the correct mechanism: the index
--! access method calls the FUNCTION 1 support comparator directly,
--! per-comparison — inlining is irrelevant.
--!
--! The operator class must be named explicitly in CREATE INDEX:
--!   CREATE INDEX t_idx ON t
--!     USING btree (col eql_v2.eql_v2_int4_operator_class);
--! A bare `USING btree (col)` does NOT pick this class — col is a
--! DOMAIN over jsonb and PostgreSQL resolves a domain column's
--! default opclass via its base type (jsonb_ops). Naming the class
--! is required, by design.
--!
--! @note This file is excluded from the Supabase build variant
--!       (tasks/build.sh strips **/*operator_class.sql). On Supabase,
--!       range queries on eql_v2_int4 fall back to seq-scan; use
--!       eql_v2_int4_ord_ope for Supabase-compatible indexed range.
--! @see eql_v2.compare_ore_block_u64_8_256
--! @see src/encrypted_domain/int4/int4_ord_ore_operator_class.sql

--! @brief btree support comparator for the default eql_v2_int4.
--!
--! Casts both domain operands to eql_v2_encrypted and delegates to
--! eql_v2.compare_ore_block_u64_8_256. A dedicated (domain, domain)
--! function is required because compare_ore_block_u64_8_256 accepts
--! eql_v2_encrypted and jsonb->eql_v2_encrypted is a WITH FUNCTION
--! cast (not binary-coercible).
--!
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return integer (-1, 0, 1 — ORE-block ordering of the plaintexts)
CREATE FUNCTION eql_v2.eql_v2_int4_compare(a eql_v2_int4, b eql_v2_int4)
RETURNS integer LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) $$;

CREATE OPERATOR FAMILY eql_v2.eql_v2_int4_operator_family USING btree;

CREATE OPERATOR CLASS eql_v2.eql_v2_int4_operator_class
  FOR TYPE eql_v2_int4 USING btree
  FAMILY eql_v2.eql_v2_int4_operator_family AS
    OPERATOR 1 <,
    OPERATOR 2 <=,
    OPERATOR 3 =,
    OPERATOR 4 >=,
    OPERATOR 5 >,
    FUNCTION 1 eql_v2.eql_v2_int4_compare(a eql_v2_int4, b eql_v2_int4);
