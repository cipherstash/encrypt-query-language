-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ope_cllw_var_8/types.sql


--! @brief Extract variable-width CLLW OPE index term from JSONB payload
--!
--! Extracts the variable-width CLLW OPE ciphertext from the 'opv' field of an
--! encrypted data payload. Used internally for range query comparisons.
--!
--! @param val jsonb encrypted EQL payload
--! @return eql_v2.ope_cllw_var_8 Variable-width CLLW OPE ciphertext
--! @throws Exception if 'opv' field is missing when ope index is expected
--!
--! @see eql_v2.has_ope_cllw_var_8
--! @see eql_v2.compare_ope_cllw_var_8
CREATE FUNCTION eql_v2.ope_cllw_var_8(val jsonb)
  RETURNS eql_v2.ope_cllw_var_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    IF NOT (eql_v2.has_ope_cllw_var_8(val)) THEN
        RAISE 'Expected a ope_cllw_var_8 index (opv) value in json: %', val;
    END IF;

    RETURN ROW(decode(val->>'opv', 'hex'));
  END;
$$ LANGUAGE plpgsql;


--! @brief Extract variable-width CLLW OPE index term from encrypted column value
--!
--! Extracts the variable-width CLLW OPE ciphertext from an encrypted column value
--! by accessing its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return eql_v2.ope_cllw_var_8 Variable-width CLLW OPE ciphertext
--!
--! @see eql_v2.ope_cllw_var_8(jsonb)
CREATE FUNCTION eql_v2.ope_cllw_var_8(val eql_v2_encrypted)
  RETURNS eql_v2.ope_cllw_var_8
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ope_cllw_var_8(val.data);
$$ LANGUAGE sql;


--! @brief Check if JSONB payload contains variable-width CLLW OPE index term
--!
--! Tests whether the encrypted data payload includes an 'opv' field,
--! indicating a variable-width CLLW OPE ciphertext is available for range queries.
--!
--! @param val jsonb encrypted EQL payload
--! @return Boolean True if 'opv' field is present and non-null
--!
--! @see eql_v2.ope_cllw_var_8
CREATE FUNCTION eql_v2.has_ope_cllw_var_8(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT val ->> 'opv' IS NOT NULL;
$$ LANGUAGE sql;


--! @brief Check if encrypted column value contains variable-width CLLW OPE index term
--!
--! Tests whether an encrypted column value includes a variable-width CLLW OPE
--! ciphertext by checking its underlying JSONB data field.
--!
--! @param val eql_v2_encrypted Encrypted column value
--! @return Boolean True if variable-width CLLW OPE ciphertext is present
--!
--! @see eql_v2.has_ope_cllw_var_8(jsonb)
CREATE FUNCTION eql_v2.has_ope_cllw_var_8(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.has_ope_cllw_var_8(val.data);
$$ LANGUAGE sql;
