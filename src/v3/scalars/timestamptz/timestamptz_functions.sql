-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamptz/timestamptz_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/timestamptz/timestamptz_functions.sql
--! @brief Functions for eql_v3.timestamptz.

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.timestamptz, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.timestamptz)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param selector text
--! @return eql_v3.timestamptz
CREATE FUNCTION eql_v3."->"(a eql_v3.timestamptz, selector text)
RETURNS eql_v3.timestamptz IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param selector integer
--! @return eql_v3.timestamptz
CREATE FUNCTION eql_v3."->"(a eql_v3.timestamptz, selector integer)
RETURNS eql_v3.timestamptz IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param selector eql_v3.timestamptz
--! @return eql_v3.timestamptz
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.timestamptz)
RETURNS eql_v3.timestamptz IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.timestamptz, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.timestamptz, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param selector eql_v3.timestamptz
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.timestamptz)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.timestamptz, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.timestamptz, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.timestamptz, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.timestamptz, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.timestamptz, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.timestamptz, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.timestamptz, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.timestamptz, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.timestamptz, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.timestamptz, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.timestamptz, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b eql_v3.timestamptz
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.timestamptz, b eql_v3.timestamptz)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a eql_v3.timestamptz
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.timestamptz, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.timestamptz.
--! @param a jsonb
--! @param b eql_v3.timestamptz
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.timestamptz)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.timestamptz'; END; $$
LANGUAGE plpgsql;
