-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/bigint/bigint_functions.sql
--! @brief Functions for public.bigint.

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param selector text
--! @return public.bigint
CREATE FUNCTION eql_v3_internal."->"(a public.bigint, selector text)
RETURNS public.bigint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param selector integer
--! @return public.bigint
CREATE FUNCTION eql_v3_internal."->"(a public.bigint, selector integer)
RETURNS public.bigint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param selector public.bigint
--! @return public.bigint
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.bigint)
RETURNS public.bigint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.bigint, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.bigint, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param selector public.bigint
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.bigint)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.bigint, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.bigint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.bigint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.bigint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.bigint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.bigint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.bigint, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.bigint, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.bigint, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.bigint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.bigint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.bigint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint, b public.bigint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a jsonb
--! @param b public.bigint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.bigint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint'; END; $$
LANGUAGE plpgsql;
