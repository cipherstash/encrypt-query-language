-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/json/types.sql
-- REQUIRE: src/v3/json/functions.sql
-- REQUIRE: src/v3/scalars/date/query_date_types.sql
-- REQUIRE: src/v3/scalars/date/query_date_eq_functions.sql
-- REQUIRE: src/v3/scalars/date/query_date_ord_functions.sql
-- REQUIRE: src/v3/scalars/date/query_date_ord_ope_functions.sql

--! @file encrypted_domain/date/json_entry_date_functions.sql
--! @brief Functions for public.eql_v3_json_entry.

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_json_entry, b eql_v3.query_date_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_eq
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.query_date_eq, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_json_entry, b eql_v3.query_date_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_eq
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.query_date_eq, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_json_entry, b eql_v3.query_date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.query_date_ord, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_json_entry, b eql_v3.query_date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.query_date_ord, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_json_entry, b eql_v3.query_date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.query_date_ord, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_json_entry, b eql_v3.query_date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.query_date_ord, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_json_entry, b eql_v3.query_date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.query_date_ord, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_json_entry, b eql_v3.query_date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.query_date_ord, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_json_entry, b eql_v3.query_date_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord_ope
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.query_date_ord_ope, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_json_entry, b eql_v3.query_date_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord_ope
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.query_date_ord_ope, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_json_entry, b eql_v3.query_date_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord_ope
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.query_date_ord_ope, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_json_entry, b eql_v3.query_date_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord_ope
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.query_date_ord_ope, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_json_entry, b eql_v3.query_date_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord_ope
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.query_date_ord_ope, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a public.eql_v3_json_entry
--! @param b eql_v3.query_date_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_json_entry, b eql_v3.query_date_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_json_entry.
--! @param a eql_v3.query_date_ord_ope
--! @param b public.eql_v3_json_entry
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.query_date_ord_ope, b public.eql_v3_json_entry)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
