-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_types.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_functions.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_eq_functions.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_ord_functions.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/int2/int2_types.sql
-- REQUIRE: src/v3/scalars/int2/int2_functions.sql
-- REQUIRE: src/v3/scalars/int2/int2_eq_functions.sql
-- REQUIRE: src/v3/scalars/int2/int2_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/int2/int2_ord_functions.sql
-- REQUIRE: src/v3/scalars/int2/int2_ord_ope_functions.sql

--! @file encrypted_domain/smallint/smallint__int2_cross.sql
--! @brief Cross-name operators between smallint and int2.

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint, b public.int2)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint.
--! @param a public.smallint
--! @param b public.int2
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint, b public.int2)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_eq, b public.int2_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_eq, b public.int2_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.smallint_eq, b public.int2_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.smallint_eq, b public.int2_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.smallint_eq, b public.int2_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.smallint_eq, b public.int2_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint_eq, b public.int2_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint_eq, b public.int2_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_eq.
--! @param a public.smallint_eq
--! @param b public.int2_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint_eq, b public.int2_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_ord_ore.
--! @param a public.smallint_ord_ore
--! @param b public.int2_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint_ord_ore, b public.int2_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord, b public.int2_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord, b public.int2_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord, b public.int2_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord, b public.int2_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord, b public.int2_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord, b public.int2_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint_ord, b public.int2_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint_ord, b public.int2_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_ord.
--! @param a public.smallint_ord
--! @param b public.int2_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint_ord, b public.int2_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.smallint_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.smallint_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.int2_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.smallint_ord_ope, b public.int2_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.smallint_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int2, b public.smallint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2.
--! @param a public.int2
--! @param b public.smallint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int2, b public.smallint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int2'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int2_eq, b public.smallint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int2_eq, b public.smallint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int2_eq, b public.smallint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int2_eq, b public.smallint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int2_eq, b public.smallint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int2_eq, b public.smallint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int2_eq, b public.smallint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int2_eq, b public.smallint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_eq.
--! @param a public.int2_eq
--! @param b public.smallint_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int2_eq, b public.smallint_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int2_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int2_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int2_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_ord_ore.
--! @param a public.int2_ord_ore
--! @param b public.smallint_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int2_ord_ore, b public.smallint_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int2_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int2_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int2_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int2_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int2_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int2_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int2_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int2_ord, b public.smallint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int2_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int2_ord, b public.smallint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int2_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_ord.
--! @param a public.int2_ord
--! @param b public.smallint_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int2_ord, b public.smallint_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int2_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int2_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int2_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int2_ord_ope.
--! @param a public.int2_ord_ope
--! @param b public.smallint_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int2_ord_ope, b public.smallint_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int2_ord_ope'; END; $$
LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.smallint, RIGHTARG = public.int2
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.smallint_eq, RIGHTARG = public.int2_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.smallint_ord_ore, RIGHTARG = public.int2_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.smallint_ord, RIGHTARG = public.int2_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.smallint_ord_ope, RIGHTARG = public.int2_ord_ope
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int2, RIGHTARG = public.smallint
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int2_eq, RIGHTARG = public.smallint_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int2_ord_ore, RIGHTARG = public.smallint_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int2_ord, RIGHTARG = public.smallint_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int2_ord_ope, RIGHTARG = public.smallint_ord_ope
);
