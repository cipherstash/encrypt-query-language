-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/functions.sql
-- REQUIRE: src/v3/sem/ore_block_256/operators.sql

--! @file encrypted_domain/double/double_ord_functions.sql
--! @brief Functions for public.double_ord.

--! @brief Index extractor for public.double_ord.
--! @param a public.double_ord
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.double_ord)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b::public.double_ord) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.double_ord) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b::public.double_ord) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.double_ord) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.double_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.double_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::public.double_ord) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.double_ord) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.double_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.double_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::public.double_ord) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.double_ord) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.double_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.double_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::public.double_ord) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.double_ord) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.double_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.double_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::public.double_ord) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.double_ord) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_ord, b public.double_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.double_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_ord, b public.double_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.double_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param selector text
--! @return public.double_ord
CREATE FUNCTION eql_v3_internal."->"(a public.double_ord, selector text)
RETURNS public.double_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param selector integer
--! @return public.double_ord
CREATE FUNCTION eql_v3_internal."->"(a public.double_ord, selector integer)
RETURNS public.double_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a jsonb
--! @param selector public.double_ord
--! @return public.double_ord
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.double_ord)
RETURNS public.double_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.double_ord, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.double_ord, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a jsonb
--! @param selector public.double_ord
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.double_ord)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.double_ord, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.double_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.double_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.double_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.double_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.double_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.double_ord, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double_ord, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double_ord, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.double_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b public.double_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_ord, b public.double_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_ord, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a jsonb
--! @param b public.double_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.double_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_ord'; END; $$
LANGUAGE plpgsql;
