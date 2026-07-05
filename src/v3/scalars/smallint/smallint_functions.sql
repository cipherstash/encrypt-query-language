-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/smallint/smallint_functions.sql
--! @brief Functions for public.smallint.

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param selector text
--! @return public.smallint
CREATE FUNCTION eql_v3_internal."->"(a public.smallint, selector text)
RETURNS public.smallint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param selector integer
--! @return public.smallint
CREATE FUNCTION eql_v3_internal."->"(a public.smallint, selector integer)
RETURNS public.smallint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param selector public.smallint
--! @return public.smallint
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.smallint)
RETURNS public.smallint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.smallint, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.smallint, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param selector public.smallint
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.smallint)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.smallint, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.smallint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.smallint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.smallint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.smallint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.smallint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.smallint, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.smallint, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.smallint, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.smallint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.smallint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.smallint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint, b public.smallint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a jsonb
--! @param b public.smallint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.smallint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint'; END; $$
LANGUAGE plpgsql;
