-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql

--! @file encrypted_domain/functions.sql
--! @brief Shared blocker helper for the eql_v2_int4 variant family.
--!
--! Per-variant wrapper functions live in src/encrypted_domain/int4/.
--! Blockers in those files delegate to encrypted_domain_unsupported_bool
--! so every variant raises a uniform variant-specific error rather than
--! letting an unsupported operator fall through to native jsonb
--! behaviour.

--! @brief Shared blocker helper. Raises 'operator X is not supported
--!        for TYPE' so unsupported domain operators surface a clear
--!        error rather than fall through to native jsonb behaviour.
--! @param type_name Domain type name (eql_v2_int4*)
--! @param operator_name Operator symbol (=, <, ~~, @>, ->, etc.)
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_domain_unsupported_bool(type_name text, operator_name text)
RETURNS boolean
IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RAISE EXCEPTION 'operator % is not supported for %', operator_name, type_name;
END;
$$ LANGUAGE plpgsql;
