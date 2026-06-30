-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/numeric/numeric_functions.sql
--! @brief Functions for eql_v3.numeric.

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.numeric, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.numeric, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param selector text
--! @return eql_v3.numeric
CREATE FUNCTION eql_v3."->"(a eql_v3.numeric, selector text)
RETURNS eql_v3.numeric IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param selector integer
--! @return eql_v3.numeric
CREATE FUNCTION eql_v3."->"(a eql_v3.numeric, selector integer)
RETURNS eql_v3.numeric IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param selector eql_v3.numeric
--! @return eql_v3.numeric
CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.numeric)
RETURNS eql_v3.numeric IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.numeric, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3."->>"(a eql_v3.numeric, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param selector eql_v3.numeric
--! @return text
CREATE FUNCTION eql_v3."->>"(a jsonb, selector eql_v3.numeric)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3."?"(a eql_v3.numeric, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?|"(a eql_v3.numeric, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3."?&"(a eql_v3.numeric, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@?"(a eql_v3.numeric, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3."@@"(a eql_v3.numeric, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#>"(a eql_v3.numeric, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3."#>>"(a eql_v3.numeric, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.numeric, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.numeric, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."-"(a eql_v3.numeric, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3."#-"(a eql_v3.numeric, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b eql_v3.numeric
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.numeric, b eql_v3.numeric)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a eql_v3.numeric
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a eql_v3.numeric, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.numeric.
--! @param a jsonb
--! @param b eql_v3.numeric
--! @return jsonb
CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.numeric)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.numeric'; END; $$
LANGUAGE plpgsql;
