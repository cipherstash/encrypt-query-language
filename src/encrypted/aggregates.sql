-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql

-- Aggregate functions for ORE

--! @brief State transition function for min aggregate
--! @internal
--!
--! Returns the smaller of two encrypted values for use in MIN aggregate.
--! Comparison uses ORE index terms without decryption.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return eql_v2_encrypted The smaller of the two values
--!
--! @see eql_v2.min(eql_v2_encrypted)
CREATE FUNCTION eql_v2.min(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS eql_v2_encrypted
STRICT
AS $$
  BEGIN
    IF a < b THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
$$ LANGUAGE plpgsql;


--! @brief Find minimum encrypted value in a group
--!
--! Aggregate function that returns the minimum encrypted value in a group
--! using ORE index term comparisons without decryption.
--!
--! @param input eql_v2_encrypted Encrypted values to aggregate
--! @return eql_v2_encrypted Minimum value in the group
--!
--! @example
--! -- Find minimum age per department
--! SELECT department, eql_v2.min(encrypted_age)
--! FROM employees
--! GROUP BY department;
--!
--! @note Requires 'ore' index configuration on the column
--! @see eql_v2.min(eql_v2_encrypted, eql_v2_encrypted)
CREATE AGGREGATE eql_v2.min(eql_v2_encrypted)
(
  sfunc = eql_v2.min,
  stype = eql_v2_encrypted
);


--! @brief State transition function for max aggregate
--! @internal
--!
--! Returns the larger of two encrypted values for use in MAX aggregate.
--! Comparison uses ORE index terms without decryption.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return eql_v2_encrypted The larger of the two values
--!
--! @see eql_v2.max(eql_v2_encrypted)
CREATE FUNCTION eql_v2.max(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS eql_v2_encrypted
STRICT
AS $$
  BEGIN
    IF a > b THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
$$ LANGUAGE plpgsql;


--! @brief Find maximum encrypted value in a group
--!
--! Aggregate function that returns the maximum encrypted value in a group
--! using ORE index term comparisons without decryption.
--!
--! @param input eql_v2_encrypted Encrypted values to aggregate
--! @return eql_v2_encrypted Maximum value in the group
--!
--! @example
--! -- Find maximum salary per department
--! SELECT department, eql_v2.max(encrypted_salary)
--! FROM employees
--! GROUP BY department;
--!
--! @note Requires 'ore' index configuration on the column
--! @see eql_v2.max(eql_v2_encrypted, eql_v2_encrypted)
CREATE AGGREGATE eql_v2.max(eql_v2_encrypted)
(
  sfunc = eql_v2.max,
  stype = eql_v2_encrypted
);
