-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_functions.sql

--! @file encrypted_domain/int4/int4_operators.sql
--! @brief Storage-only int4 variant — operator declarations. All bool operators raise.
--!
--! eql_v2_int4 accepts the storage of an encrypted int4 column with
--! ciphertext (`c`) only. Every comparison, containment, LIKE, and path
--! operator is a blocker so callers cannot accidentally fall through to
--! native jsonb semantics. Payload-term assumption: `c` only.

-- Operator declarations (10 symmetric ops × 3 shapes + 2 path ops × 3 asymmetric shapes)

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
