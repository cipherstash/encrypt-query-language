-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/boolean/boolean_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/boolean/boolean_functions.sql
--! @brief Functions for public.eql_v3_boolean.

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_boolean, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.eql_v3_boolean)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param selector text
--! @return public.eql_v3_boolean
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_boolean, selector text)
RETURNS public.eql_v3_boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param selector integer
--! @return public.eql_v3_boolean
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_boolean, selector integer)
RETURNS public.eql_v3_boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param selector public.eql_v3_boolean
--! @return public.eql_v3_boolean
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_boolean)
RETURNS public.eql_v3_boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_boolean, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_boolean, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param selector public.eql_v3_boolean
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_boolean)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_boolean, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_boolean, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_boolean, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_boolean, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_boolean, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_boolean, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_boolean, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_boolean, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_boolean, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b public.eql_v3_boolean
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_boolean, b public.eql_v3_boolean)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a public.eql_v3_boolean
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_boolean, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_boolean.
--! @param a jsonb
--! @param b public.eql_v3_boolean
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_boolean)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_boolean'; END; $$
LANGUAGE plpgsql;
