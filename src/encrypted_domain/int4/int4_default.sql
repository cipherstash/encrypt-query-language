-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/compare.sql
-- REQUIRE: src/encrypted/casts.sql

--! @file encrypted_domain/int4/int4_default.sql
--! @brief Default int4 variant. Operator surface identical to
--!        eql_v2_int4_ord_ore (HMAC equality + ORE-block ordering;
--!        range is seq-scan). Provided as the unqualified
--!        eql_v2_int4 name for callers that don't need to call out
--!        the variant explicitly. Payload-term assumption: `hm`, `ob`.
--!
--! Wrapper bodies are duplicated from int4_ord_ore.sql; the
--! INLINEABLE_DOMAIN_FUNCTIONS test and
--! encrypted_int4_default_tests.rs EXPLAIN-equivalence assertion
--! together detect structural and behavioural drift.

-- = / <> (HMAC equality wrappers, 3 shapes each)

--! @brief Equality wrapper for eql_v2_int4. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Equality wrapper for eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq(a eql_v2_int4, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b) $$;

--! @brief Equality wrapper for eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq(a jsonb, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_neq(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_neq(a eql_v2_int4, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b) $$;

--! @brief Inequality wrapper for eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_neq(a jsonb, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) <> eql_v2.hmac_256(b::jsonb) $$;

-- <, <=, >, >= (ORE-block range wrappers, 3 shapes each)
-- Range is seq-scan: compare_ore_block_u64_8_256 is PL/pgSQL and does not
-- inline. Wrappers stay LANGUAGE sql for parity with _ord_ore. See U-001.

--! @brief Less-than wrapper for eql_v2_int4. Reduces to compare_ore_block_u64_8_256 < 0.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_lt(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) < 0 $$;

--! @brief Less-than wrapper for eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_lt(a eql_v2_int4, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) < 0 $$;

--! @brief Less-than wrapper for eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_lt(a jsonb, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) < 0 $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_lte(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) <= 0 $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_lte(a eql_v2_int4, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) <= 0 $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_lte(a jsonb, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) <= 0 $$;

--! @brief Greater-than wrapper for eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_gt(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) > 0 $$;

--! @brief Greater-than wrapper for eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_gt(a eql_v2_int4, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) > 0 $$;

--! @brief Greater-than wrapper for eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_gt(a jsonb, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) > 0 $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4.
--! @param a eql_v2_int4
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_gte(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) >= 0 $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4 (domain, jsonb).
--! @param a eql_v2_int4
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_gte(a eql_v2_int4, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) >= 0 $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4 (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_gte(a jsonb, b eql_v2_int4)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) >= 0 $$;

-- ~~, ~~*, @>, <@ (blockers, 3 shapes each)

CREATE FUNCTION eql_v2.eql_v2_int4_like(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '~~'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_like(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '~~'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_like(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '~~'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_ilike(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '~~*'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_ilike(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '~~*'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_ilike(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '~~*'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_contains(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '@>'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_contains(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '@>'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_contains(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '@>'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_contained_by(a eql_v2_int4, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<@'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_contained_by(a eql_v2_int4, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<@'); END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_contained_by(a jsonb, b eql_v2_int4)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

CREATE FUNCTION eql_v2.eql_v2_int4_arrow(a eql_v2_int4, selector text)
RETURNS eql_v2_int4 IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_arrow(a eql_v2_int4, selector integer)
RETURNS eql_v2_int4 IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_arrow(a jsonb, selector eql_v2_int4)
RETURNS eql_v2_int4 IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_arrow_text(a eql_v2_int4, selector text)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_arrow_text(a eql_v2_int4, selector integer)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

CREATE FUNCTION eql_v2.eql_v2_int4_arrow_text(a jsonb, selector eql_v2_int4)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4'; END; $$
LANGUAGE plpgsql;

-- Operator declarations

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_eq,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_eq,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_neq,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_neq,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_lt,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_lt,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_lte,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_lte,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_gt,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_gt,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_gte,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_gte,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_like,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_like,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ilike,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ilike,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_contains,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_contains,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_contained_by,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_contained_by,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_arrow,
  LEFTARG = eql_v2_int4, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_arrow,
  LEFTARG = eql_v2_int4, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_arrow_text,
  LEFTARG = eql_v2_int4, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_arrow_text,
  LEFTARG = eql_v2_int4, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);
