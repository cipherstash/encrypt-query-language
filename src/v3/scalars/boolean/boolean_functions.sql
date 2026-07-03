-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/boolean/boolean_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/boolean/boolean_functions.sql
--! @brief Functions for eql_v3.boolean.

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.boolean, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param selector text
--! @return eql_v3.boolean
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.boolean, selector text)
RETURNS eql_v3.boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param selector integer
--! @return eql_v3.boolean
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.boolean, selector integer)
RETURNS eql_v3.boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param selector eql_v3.boolean
--! @return eql_v3.boolean
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.boolean)
RETURNS eql_v3.boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.boolean, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.boolean, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param selector eql_v3.boolean
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.boolean)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.boolean, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.boolean, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.boolean, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.boolean, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.boolean, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.boolean, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.boolean, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.boolean, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b eql_v3.boolean
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.boolean, b eql_v3.boolean)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a eql_v3.boolean
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.boolean, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.boolean.
--! @param a jsonb
--! @param b eql_v3.boolean
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.boolean)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.boolean'; END; $$
LANGUAGE plpgsql;
