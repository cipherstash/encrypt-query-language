-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/int4/int4_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/operators.sql

--! @file encrypted_domain/int4/int4_ord_functions.sql
--! @brief Functions for public.int4_ord.

--! @brief Index extractor for public.int4_ord.
--! @param a public.int4_ord
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.int4_ord)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int4_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b::public.int4_ord) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.int4_ord) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int4_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b::public.int4_ord) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.int4_ord) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int4_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::public.int4_ord) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.int4_ord) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int4_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::public.int4_ord) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.int4_ord) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int4_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::public.int4_ord) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.int4_ord) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int4_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::public.int4_ord) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.int4_ord) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4_ord, b public.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4_ord, b public.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param selector text
--! @return public.int4_ord
CREATE FUNCTION eql_v3_internal."->"(a public.int4_ord, selector text)
RETURNS public.int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param selector integer
--! @return public.int4_ord
CREATE FUNCTION eql_v3_internal."->"(a public.int4_ord, selector integer)
RETURNS public.int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a jsonb
--! @param selector public.int4_ord
--! @return public.int4_ord
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.int4_ord)
RETURNS public.int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.int4_ord, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.int4_ord, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a jsonb
--! @param selector public.int4_ord
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.int4_ord)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.int4_ord, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.int4_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.int4_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.int4_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.int4_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.int4_ord, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int4_ord, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int4_ord, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.int4_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.int4_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4_ord, b public.int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4_ord, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a jsonb
--! @param b public.int4_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;
