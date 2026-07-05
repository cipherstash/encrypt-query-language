-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/hmac_256/functions.sql

--! @file encrypted_domain/bigint/bigint_eq_functions.sql
--! @brief Functions for public.bigint_eq.

--! @brief Index extractor for public.bigint_eq.
--! @param a public.bigint_eq
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.bigint_eq)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b::public.bigint_eq) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::public.bigint_eq) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b::public.bigint_eq) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::public.bigint_eq) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.bigint_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.bigint_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.bigint_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.bigint_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param selector text
--! @return public.bigint_eq
CREATE FUNCTION eql_v3_internal."->"(a public.bigint_eq, selector text)
RETURNS public.bigint_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param selector integer
--! @return public.bigint_eq
CREATE FUNCTION eql_v3_internal."->"(a public.bigint_eq, selector integer)
RETURNS public.bigint_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param selector public.bigint_eq
--! @return public.bigint_eq
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.bigint_eq)
RETURNS public.bigint_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.bigint_eq, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.bigint_eq, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param selector public.bigint_eq
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.bigint_eq)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.bigint_eq, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.bigint_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.bigint_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.bigint_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.bigint_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.bigint_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.bigint_eq, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.bigint_eq, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.bigint_eq, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.bigint_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.bigint_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.bigint_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint_eq, b public.bigint_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint_eq, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a jsonb
--! @param b public.bigint_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.bigint_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;
