-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/encrypted/compare.sql
-- REQUIRE: src/operators/<.sql
-- REQUIRE: src/operators/<=.sql
-- REQUIRE: src/operators/=.sql
-- REQUIRE: src/operators/>=.sql
-- REQUIRE: src/operators/>.sql

--! @brief PostgreSQL operator class definitions for encrypted value indexing
--!
--! Defines the operator family and operator class required for btree indexing
--! of encrypted values. This enables PostgreSQL to use encrypted columns in:
--! - CREATE INDEX statements
--! - ORDER BY clauses
--! - Range queries
--! - Primary key constraints
--!
--! The operator class maps the five comparison operators (<, <=, =, >=, >)
--! to the eql_v2.compare() support function for btree index operations.
--!
--! @note This is the default operator class for eql_v2_encrypted type
--! @see eql_v2.compare
--! @see PostgreSQL documentation on operator classes

--------------------

CREATE OPERATOR FAMILY eql_v2.encrypted_operator_family USING btree;

CREATE OPERATOR CLASS eql_v2.encrypted_operator_class DEFAULT FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator_family AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted);


--------------------

-- CREATE OPERATOR FAMILY eql_v2.encrypted_operator_ordered USING btree;

-- CREATE OPERATOR CLASS eql_v2.encrypted_operator_ordered FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator_ordered AS
--   OPERATOR 1 <,
--   OPERATOR 2 <=,
--   OPERATOR 3 =,
--   OPERATOR 4 >=,
--   OPERATOR 5 >,
--   FUNCTION 1 eql_v2.compare_ore_block_u64_8_256(a eql_v2_encrypted, b eql_v2_encrypted);

--------------------

-- CREATE OPERATOR FAMILY eql_v2.encrypted_hmac_256_operator USING btree;

-- CREATE OPERATOR CLASS eql_v2.encrypted_hmac_256_operator FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_hmac_256_operator AS
--   OPERATOR 1 <,
--   OPERATOR 2 <=,
--   OPERATOR 3 =,
--   OPERATOR 4 >=,
--   OPERATOR 5 >,
--   FUNCTION 1 eql_v2.compare_hmac(a eql_v2_encrypted, b eql_v2_encrypted);

