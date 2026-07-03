-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/real/real_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/real/real_functions.sql
--! @brief Functions for eql_v3.real.

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.real, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.real, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param selector text
--! @return eql_v3.real
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.real, selector text)
RETURNS eql_v3.real IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param selector integer
--! @return eql_v3.real
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.real, selector integer)
RETURNS eql_v3.real IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param selector eql_v3.real
--! @return eql_v3.real
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.real)
RETURNS eql_v3.real IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.real, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.real, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param selector eql_v3.real
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.real)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.real, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.real, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.real, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.real, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.real, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.real, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.real, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.real, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.real, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.real, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.real, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b eql_v3.real
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.real, b eql_v3.real)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a eql_v3.real
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.real, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.real.
--! @param a jsonb
--! @param b eql_v3.real
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.real)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.real'; END; $$
LANGUAGE plpgsql;
