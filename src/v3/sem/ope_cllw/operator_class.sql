-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ope_cllw/types.sql
-- REQUIRE: src/v3/sem/ope_cllw/functions.sql
-- REQUIRE: src/v3/sem/ope_cllw/operators.sql

--! @file v3/sem/ope_cllw/operator_class.sql
--! @brief Btree operator class on the eql_v3.ope_cllw composite type.
--!
--! DEFAULT FOR TYPE so a functional btree index on eql_v3.ord_ope_term(col)
--! engages without an explicit opclass annotation. FUNCTION 1 is the
--! three-way comparator btree's internal sort uses — a native bytea
--! comparison of the decoded OPE terms (the ciphertext is order-preserving
--! under plain byte comparison, unlike the CLLW ORE protocol).
--!
--! @see eql_v3.compare_ope_cllw_term
CREATE OPERATOR FAMILY eql_v3.ope_cllw_ops USING btree;

CREATE OPERATOR CLASS eql_v3.ope_cllw_ops
  DEFAULT FOR TYPE eql_v3.ope_cllw
  USING btree FAMILY eql_v3.ope_cllw_ops AS
    OPERATOR 1 <  (eql_v3.ope_cllw, eql_v3.ope_cllw),
    OPERATOR 2 <= (eql_v3.ope_cllw, eql_v3.ope_cllw),
    OPERATOR 3 =  (eql_v3.ope_cllw, eql_v3.ope_cllw),
    OPERATOR 4 >= (eql_v3.ope_cllw, eql_v3.ope_cllw),
    OPERATOR 5 >  (eql_v3.ope_cllw, eql_v3.ope_cllw),
    FUNCTION 1 eql_v3.compare_ope_cllw_term(eql_v3.ope_cllw, eql_v3.ope_cllw);
