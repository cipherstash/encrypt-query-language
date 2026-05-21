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
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.gte,
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

CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4);
CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4);
CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);

CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4);
