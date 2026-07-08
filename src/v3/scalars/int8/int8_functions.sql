-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int8/int8_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/int8/int8_functions.sql
--! @brief Functions for public.int8.

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param selector text
--! @return public.int8
CREATE FUNCTION eql_v3_internal."->"(a public.int8, selector text)
RETURNS public.int8 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param selector integer
--! @return public.int8
CREATE FUNCTION eql_v3_internal."->"(a public.int8, selector integer)
RETURNS public.int8 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param selector public.int8
--! @return public.int8
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.int8)
RETURNS public.int8 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.int8, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.int8, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param selector public.int8
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.int8)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.int8, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.int8, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.int8, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.int8, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.int8, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.int8, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.int8, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int8, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int8, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int8, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.int8, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.int8
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8, b public.int8)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a jsonb
--! @param b public.int8
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.int8)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8'; END; $$
LANGUAGE plpgsql;
