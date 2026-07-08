-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/integer_types.sql
-- REQUIRE: src/v3/scalars/integer/integer_functions.sql
-- REQUIRE: src/v3/scalars/integer/integer_eq_functions.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_functions.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/int4/int4_types.sql
-- REQUIRE: src/v3/scalars/int4/int4_functions.sql
-- REQUIRE: src/v3/scalars/int4/int4_eq_functions.sql
-- REQUIRE: src/v3/scalars/int4/int4_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/int4/int4_ord_functions.sql
-- REQUIRE: src/v3/scalars/int4/int4_ord_ope_functions.sql

--! @file encrypted_domain/integer/integer__int4_cross.sql
--! @brief Cross-name operators between integer and int4.

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer, b public.int4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer.
--! @param a public.integer
--! @param b public.int4
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer, b public.int4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_eq, b public.int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_eq, b public.int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.integer_eq, b public.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.integer_eq, b public.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.integer_eq, b public.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.integer_eq, b public.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer_eq, b public.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer_eq, b public.int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_eq.
--! @param a public.integer_eq
--! @param b public.int4_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer_eq, b public.int4_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_ord_ore.
--! @param a public.integer_ord_ore
--! @param b public.int4_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer_ord_ore, b public.int4_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.integer_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.integer_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.integer_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.integer_ord, b public.int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer_ord, b public.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer_ord, b public.int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_ord.
--! @param a public.integer_ord
--! @param b public.int4_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer_ord, b public.int4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.integer_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.integer_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.integer_ord_ope.
--! @param a public.integer_ord_ope
--! @param b public.int4_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.integer_ord_ope, b public.int4_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.integer_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4, b public.integer)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4.
--! @param a public.int4
--! @param b public.integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4, b public.integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int4_eq, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int4_eq, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int4_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int4_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int4_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int4_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4_eq, b public.integer_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_eq.
--! @param a public.int4_eq
--! @param b public.integer_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4_eq, b public.integer_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord_ore.
--! @param a public.int4_ord_ore
--! @param b public.integer_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4_ord_ore, b public.integer_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int4_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int4_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int4_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int4_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int4_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int4_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4_ord, b public.integer_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4_ord, b public.integer_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord.
--! @param a public.int4_ord
--! @param b public.integer_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4_ord, b public.integer_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int4_ord_ope.
--! @param a public.int4_ord_ope
--! @param b public.integer_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int4_ord_ope, b public.integer_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int4_ord_ope'; END; $$
LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.integer, RIGHTARG = public.int4
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.integer_eq, RIGHTARG = public.int4_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.integer_ord_ore, RIGHTARG = public.int4_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.integer_ord, RIGHTARG = public.int4_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.integer_ord_ope, RIGHTARG = public.int4_ord_ope
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int4, RIGHTARG = public.integer
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int4_eq, RIGHTARG = public.integer_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int4_ord_ore, RIGHTARG = public.integer_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int4_ord, RIGHTARG = public.integer_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int4_ord_ope, RIGHTARG = public.integer_ord_ope
);
