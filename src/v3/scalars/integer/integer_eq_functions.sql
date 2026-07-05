-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/integer_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/hmac_256/functions.sql

--! @file encrypted_domain/integer/integer_eq_functions.sql
--! @brief Functions for public.integer_eq.

--! @brief Index extractor for public.integer_eq.
--! @param a public.integer_eq
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.integer_eq)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_eq, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b::public.integer_eq) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::public.integer_eq) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_eq, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b::public.integer_eq) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::public.integer_eq) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.integer_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.integer_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.integer_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.integer_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.integer_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.integer_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.integer_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.integer_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param selector text
--! @return public.integer_eq
CREATE FUNCTION eql_v3_internal."->"(a public.integer_eq, selector text)
RETURNS public.integer_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param selector integer
--! @return public.integer_eq
CREATE FUNCTION eql_v3_internal."->"(a public.integer_eq, selector integer)
RETURNS public.integer_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param selector public.integer_eq
--! @return public.integer_eq
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.integer_eq)
RETURNS public.integer_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.integer_eq, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.integer_eq, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param selector public.integer_eq
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.integer_eq)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.integer_eq, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.integer_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.integer_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.integer_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.integer_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.integer_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.integer_eq, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.integer_eq, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.integer_eq, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.integer_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.integer_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.integer_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer_eq, b public.integer_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer_eq, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a jsonb
--! @param b public.integer_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.integer_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;
