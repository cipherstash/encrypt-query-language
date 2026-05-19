-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql

--! @file encrypted_domain/int4/int4_ct.sql
--! @brief Storage-only int4 variant. All bool operators raise.
--!
--! eql_v2_int4_ct accepts the storage of an encrypted int4 column with
--! ciphertext (`c`) only. Every comparison, containment, LIKE, and path
--! operator is a blocker so callers cannot accidentally fall through to
--! native jsonb semantics. Payload-term assumption: `c` only.

-- =, <> (blockers, 3 shapes each)

--! @brief Blocker for = on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_eq(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for = on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_eq(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for = on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_eq(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <> on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_neq(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <> on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_neq(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <> on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_neq(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<>'); END; $$
LANGUAGE plpgsql;

-- <, <=, >, >= (blockers, 3 shapes each)

--! @brief Blocker for < on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_lt(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_lt(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_lt(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_lte(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_lte(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_lte(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_gt(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_gt(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_gt(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_gte(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_gte(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_gte(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '>='); END; $$
LANGUAGE plpgsql;

-- ~~, ~~*, @>, <@ (blockers, 3 shapes each)

--! @brief Blocker for ~~ on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_like(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_like(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_like(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_ilike(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_ilike(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_ilike(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_contains(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_contains(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_contains(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ct.
--! @param a eql_v2_int4_ct
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_contained_by(a eql_v2_int4_ct, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ct (domain, jsonb).
--! @param a eql_v2_int4_ct
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_contained_by(a eql_v2_int4_ct, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ct
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_contained_by(a jsonb, b eql_v2_int4_ct)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ct', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4_ct (domain, text).
--! @param a eql_v2_int4_ct
--! @param selector text
--! @return eql_v2_int4_ct (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_arrow(a eql_v2_int4_ct, selector text)
RETURNS eql_v2_int4_ct IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ct'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ct (domain, integer).
--! @param a eql_v2_int4_ct
--! @param selector integer
--! @return eql_v2_int4_ct (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_arrow(a eql_v2_int4_ct, selector integer)
RETURNS eql_v2_int4_ct IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ct'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ct
--! @return eql_v2_int4_ct (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_arrow(a jsonb, selector eql_v2_int4_ct)
RETURNS eql_v2_int4_ct IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ct'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ct (domain, text).
--! @param a eql_v2_int4_ct
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_arrow_text(a eql_v2_int4_ct, selector text)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ct'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ct (domain, integer).
--! @param a eql_v2_int4_ct
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_arrow_text(a eql_v2_int4_ct, selector integer)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ct'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ct (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ct
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ct_arrow_text(a jsonb, selector eql_v2_int4_ct)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ct'; END; $$
LANGUAGE plpgsql;

-- Operator declarations (10 symmetric ops × 3 shapes + 2 path ops × 3 asymmetric shapes)

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ct_eq,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ct_eq,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ct_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ct_neq,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ct_neq,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ct_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ct_lt,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ct_lt,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ct_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ct_lte,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ct_lte,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ct_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ct_gt,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ct_gt,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ct_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ct_gte,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ct_gte,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ct_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ct_like,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ct_like,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ct_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ct_ilike,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ct_ilike,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ct_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ct_contains,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ct_contains,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ct_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ct_contained_by,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = eql_v2_int4_ct);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ct_contained_by,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ct_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ct_arrow,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ct_arrow,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ct_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ct_arrow_text,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ct_arrow_text,
  LEFTARG = eql_v2_int4_ct, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ct_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ct);
