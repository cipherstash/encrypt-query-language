-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/integer_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/integer/integer_functions.sql
--! @brief Functions for public.integer.

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param selector text
--! @return public.integer
CREATE FUNCTION eql_v3_internal."->"(a public.integer, selector text)
RETURNS public.integer IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param selector integer
--! @return public.integer
CREATE FUNCTION eql_v3_internal."->"(a public.integer, selector integer)
RETURNS public.integer IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param selector public.integer
--! @return public.integer
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.integer)
RETURNS public.integer IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.integer, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.integer, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param selector public.integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.integer, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.integer, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.integer, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.integer, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.integer, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.integer, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.integer, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.integer, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.integer, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.integer, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.integer, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer, b public.integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a jsonb
--! @param b public.integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer'; END; $$
LANGUAGE plpgsql;
