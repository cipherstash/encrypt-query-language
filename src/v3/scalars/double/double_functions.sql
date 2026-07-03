-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/double/double_functions.sql
--! @brief Functions for eql_v3.double.

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.double, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.double, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param selector text
--! @return eql_v3.double
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.double, selector text)
RETURNS eql_v3.double IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param selector integer
--! @return eql_v3.double
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.double, selector integer)
RETURNS eql_v3.double IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param selector eql_v3.double
--! @return eql_v3.double
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.double)
RETURNS eql_v3.double IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.double, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.double, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param selector eql_v3.double
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.double)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.double, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.double, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.double, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.double, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.double, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.double, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.double, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.double, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.double, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.double, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.double, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b eql_v3.double
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.double, b eql_v3.double)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a eql_v3.double
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.double, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.double.
--! @param a jsonb
--! @param b eql_v3.double
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.double)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.double'; END; $$
LANGUAGE plpgsql;
