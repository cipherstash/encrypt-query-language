-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/decimal/decimal_functions.sql
--! @brief Functions for public.decimal.

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param selector text
--! @return public.decimal
CREATE FUNCTION eql_v3_internal."->"(a public.decimal, selector text)
RETURNS public.decimal IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param selector integer
--! @return public.decimal
CREATE FUNCTION eql_v3_internal."->"(a public.decimal, selector integer)
RETURNS public.decimal IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param selector public.decimal
--! @return public.decimal
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.decimal)
RETURNS public.decimal IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.decimal, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.decimal, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param selector public.decimal
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.decimal)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.decimal, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.decimal, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.decimal, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.decimal, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.decimal, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.decimal, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.decimal, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.decimal, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.decimal, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.decimal, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.decimal, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.decimal
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal, b public.decimal)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a jsonb
--! @param b public.decimal
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.decimal)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal'; END; $$
LANGUAGE plpgsql;
