-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int4/int4_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/int4/int4_functions.sql
--! @brief Functions for public.int4.

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param selector text
--! @return public.int4
CREATE FUNCTION eql_v3_internal."->"(a public.int4, selector text)
RETURNS public.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param selector integer
--! @return public.int4
CREATE FUNCTION eql_v3_internal."->"(a public.int4, selector integer)
RETURNS public.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param selector public.int4
--! @return public.int4
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.int4)
RETURNS public.int4 IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.int4, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.int4, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param selector public.int4
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.int4)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.int4, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.int4, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.int4, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.int4, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.int4, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.int4, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int4, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int4, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.int4, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.int4
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4, b public.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a jsonb
--! @param b public.int4
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4'; END; $$
LANGUAGE plpgsql;
