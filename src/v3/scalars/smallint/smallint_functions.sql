-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/smallint/smallint_functions.sql
--! @brief Functions for eql_v3.smallint.

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.smallint, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.smallint, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param selector text
--! @return eql_v3.smallint
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.smallint, selector text)
RETURNS eql_v3.smallint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param selector integer
--! @return eql_v3.smallint
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.smallint, selector integer)
RETURNS eql_v3.smallint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param selector eql_v3.smallint
--! @return eql_v3.smallint
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.smallint)
RETURNS eql_v3.smallint IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.smallint, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.smallint, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param selector eql_v3.smallint
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.smallint)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.smallint, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.smallint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.smallint, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.smallint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.smallint, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.smallint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.smallint, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.smallint, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.smallint, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.smallint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.smallint, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b eql_v3.smallint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.smallint, b eql_v3.smallint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a eql_v3.smallint
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.smallint, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.smallint.
--! @param a jsonb
--! @param b eql_v3.smallint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.smallint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.smallint'; END; $$
LANGUAGE plpgsql;
