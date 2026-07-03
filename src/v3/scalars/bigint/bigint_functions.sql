-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/bigint/bigint_functions.sql
--! @brief Functions for eql_v3.bigint.

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.bigint, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.bigint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param selector text
--! @return eql_v3.bigint
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.bigint, selector text)
RETURNS eql_v3.bigint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param selector integer
--! @return eql_v3.bigint
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.bigint, selector integer)
RETURNS eql_v3.bigint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param selector eql_v3.bigint
--! @return eql_v3.bigint
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.bigint)
RETURNS eql_v3.bigint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.bigint, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.bigint, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param selector eql_v3.bigint
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.bigint)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.bigint, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.bigint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.bigint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.bigint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.bigint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.bigint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.bigint, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.bigint, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.bigint, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.bigint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.bigint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b eql_v3.bigint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.bigint, b eql_v3.bigint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a eql_v3.bigint
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.bigint, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.bigint.
--! @param a jsonb
--! @param b eql_v3.bigint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.bigint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.bigint'; END; $$
LANGUAGE plpgsql;
