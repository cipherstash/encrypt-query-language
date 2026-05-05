-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/hash.sql
-- REQUIRE: src/operators/compare.sql
-- REQUIRE: src/operators/operator_class.sql
-- REQUIRE: src/operators/hash_operator_class.sql
-- REQUIRE: src/operators/<.sql
-- REQUIRE: src/operators/<=.sql
-- REQUIRE: src/operators/=.sql
-- REQUIRE: src/operators/>=.sql
-- REQUIRE: src/operators/>.sql

--! @file cross_type_opfamily.sql
--!
--! @brief Register cross-type (eql_v2_encrypted ↔ jsonb) operators with the
--!        btree and hash opfamilies so the planner uses encrypted-column
--!        indexes for queries with bare-jsonb operands.
--!
--! @details
--!
--! EQL declares 18 comparison operators on `eql_v2_encrypted` (six per
--! type-pair combination), but the same-type variants are the only ones
--! the original `CREATE OPERATOR CLASS` statements register with the
--! opfamilies. Without this file the cross-type operators exist as
--! standalone user-defined functions and the planner can't recognise them
--! as opclass-eligible — `WHERE encrypted_col = '...'::jsonb` falls back
--! to a sequential scan even when a btree index on the column is present.
--!
--! Registering the cross-type operators here makes the planner treat the
--! `(eql_v2_encrypted, jsonb)` and `(jsonb, eql_v2_encrypted)` operators
--! as full members of the opfamily, with cross-type support functions
--! (`compare` for btree, `hash_encrypted` for hash) that delegate to the
--! same-type implementation via the existing implicit cast.
--!
--! @note This pattern (cross-type opfamily entries with a delegating support
--!       function) is the standard PostgreSQL approach — same shape used by
--!       `integer_ops` to make `int4 = int8` index-eligible.

--! @brief Cross-type btree compare: eql_v2_encrypted vs jsonb
--! @internal
--!
--! Delegates to the same-type compare via the implicit jsonb→eql_v2_encrypted
--! cast. Used as `FUNCTION 1` in the cross-type btree opfamily entry.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b jsonb Right operand (cast to eql_v2_encrypted internally)
--! @return integer −1 / 0 / 1 per PostgreSQL btree compare contract
--! @see eql_v2.compare(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b jsonb)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

--! @brief Cross-type btree compare: jsonb vs eql_v2_encrypted
--! @internal
--! @param a jsonb Left operand (cast to eql_v2_encrypted internally)
--! @param b eql_v2_encrypted Right operand
--! @return integer −1 / 0 / 1 per PostgreSQL btree compare contract
--! @see eql_v2.compare(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2.compare(a jsonb, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.compare(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;

--! @brief Cross-type hash for jsonb operands in the encrypted hash family
--! @internal
--!
--! The hash opfamily needs both type members to hash equal values to the same
--! bucket. This delegates to `hash_encrypted(eql_v2_encrypted)` after the
--! implicit cast so a `jsonb` operand and its corresponding `eql_v2_encrypted`
--! produce identical hashes — a requirement for cross-type hash join /
--! GROUP BY correctness.
--!
--! @param val jsonb JSONB value (cast to eql_v2_encrypted internally)
--! @return integer Hash, identical to hash_encrypted(val::eql_v2_encrypted)
--! @see eql_v2.hash_encrypted(eql_v2_encrypted)
CREATE FUNCTION eql_v2.hash_encrypted(val jsonb)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.hash_encrypted(val::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

--------------------
-- Btree opfamily: register cross-type strategies + compare support functions
--------------------

ALTER OPERATOR FAMILY eql_v2.encrypted_operator_family USING btree ADD
  OPERATOR 1 < (eql_v2_encrypted, jsonb),
  OPERATOR 2 <= (eql_v2_encrypted, jsonb),
  OPERATOR 3 = (eql_v2_encrypted, jsonb),
  OPERATOR 4 >= (eql_v2_encrypted, jsonb),
  OPERATOR 5 > (eql_v2_encrypted, jsonb),
  OPERATOR 1 < (jsonb, eql_v2_encrypted),
  OPERATOR 2 <= (jsonb, eql_v2_encrypted),
  OPERATOR 3 = (jsonb, eql_v2_encrypted),
  OPERATOR 4 >= (jsonb, eql_v2_encrypted),
  OPERATOR 5 > (jsonb, eql_v2_encrypted),
  FUNCTION 1 (eql_v2_encrypted, jsonb) eql_v2.compare(eql_v2_encrypted, jsonb),
  FUNCTION 1 (jsonb, eql_v2_encrypted) eql_v2.compare(jsonb, eql_v2_encrypted);

--------------------
-- Hash opfamily: register cross-type equality + hash support function for jsonb
--------------------

ALTER OPERATOR FAMILY eql_v2.encrypted_hash_operator_family USING hash ADD
  OPERATOR 1 = (eql_v2_encrypted, jsonb),
  OPERATOR 1 = (jsonb, eql_v2_encrypted),
  FUNCTION 1 (jsonb) eql_v2.hash_encrypted(jsonb);
