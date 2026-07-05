-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/text/text_functions.sql
--! @brief Functions for public.text.

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.text, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param selector text
--! @return public.text
CREATE FUNCTION eql_v3_internal."->"(a public.text, selector text)
RETURNS public.text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param selector integer
--! @return public.text
CREATE FUNCTION eql_v3_internal."->"(a public.text, selector integer)
RETURNS public.text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param selector public.text
--! @return public.text
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.text)
RETURNS public.text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.text, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.text, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param selector public.text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.text, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.text, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.text, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.text, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.text, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.text, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.text, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.text, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.text, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.text, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.text, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b public.text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.text, b public.text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a public.text
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.text, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.text.
--! @param a jsonb
--! @param b public.text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.text'; END; $$
LANGUAGE plpgsql;
