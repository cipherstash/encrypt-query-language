-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_types.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_functions.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_eq_functions.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_functions.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_types.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_functions.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_eq_functions.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_ord_functions.sql
-- REQUIRE: src/v3/scalars/decimal/decimal_ord_ope_functions.sql

--! @file encrypted_domain/numeric/numeric__decimal_cross.sql
--! @brief Cross-name operators between numeric and decimal.

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric, b public.decimal)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric.
--! @param a public.numeric
--! @param b public.decimal
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric, b public.decimal)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric_eq, b public.decimal_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_eq.
--! @param a public.numeric_eq
--! @param b public.decimal_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric_eq, b public.decimal_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_ord_ore.
--! @param a public.numeric_ord_ore
--! @param b public.decimal_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric_ord_ore, b public.decimal_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric_ord, b public.decimal_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_ord.
--! @param a public.numeric_ord
--! @param b public.decimal_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric_ord, b public.decimal_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.numeric_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.numeric_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.numeric_ord_ope.
--! @param a public.numeric_ord_ope
--! @param b public.decimal_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.numeric_ord_ope, b public.decimal_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.numeric_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal, b public.numeric)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal.
--! @param a public.decimal
--! @param b public.numeric
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal, b public.numeric)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal_eq, b public.numeric_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_eq.
--! @param a public.decimal_eq
--! @param b public.numeric_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal_eq, b public.numeric_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_ord_ore.
--! @param a public.decimal_ord_ore
--! @param b public.numeric_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal_ord_ore, b public.numeric_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal_ord, b public.numeric_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_ord.
--! @param a public.decimal_ord
--! @param b public.numeric_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal_ord, b public.numeric_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.decimal_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.decimal_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.decimal_ord_ope.
--! @param a public.decimal_ord_ope
--! @param b public.numeric_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.decimal_ord_ope, b public.numeric_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.decimal_ord_ope'; END; $$
LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.numeric, RIGHTARG = public.decimal
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.numeric_eq, RIGHTARG = public.decimal_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.numeric_ord_ore, RIGHTARG = public.decimal_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.numeric_ord, RIGHTARG = public.decimal_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.numeric_ord_ope, RIGHTARG = public.decimal_ord_ope
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.decimal, RIGHTARG = public.numeric
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.decimal_eq, RIGHTARG = public.numeric_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.decimal_ord_ore, RIGHTARG = public.numeric_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.decimal_ord, RIGHTARG = public.numeric_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.decimal_ord_ope, RIGHTARG = public.numeric_ord_ope
);
