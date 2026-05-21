-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_eq_functions.sql

--! @file encrypted_domain/int4/int4_eq_operators.sql
--! @brief Equality-only int4 variant — operator declarations. Supports = and <> via HMAC-256.
--!
--! eql_v2_int4_eq carries `c`, `hm` and supports HMAC equality. The
--! functional btree on ((eql_v2.hmac_256(col::jsonb))) engages for `=`.
--! `<>` is supported but is a seq-scan (btree supports only equality).
--! All other operators raise. Payload-term assumption: `c`, `hm`.

-- Operator declarations

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_eq_eq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_eq_eq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_eq_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_eq_neq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_eq_neq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_eq_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_eq_lt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_eq_lt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_eq_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_eq_lte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_eq_lte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_eq_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_eq_gt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_eq_gt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_eq_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_eq_gte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_eq_gte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_eq_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_eq_like,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_eq_like,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_eq_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_eq_ilike,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_eq_ilike,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_eq_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_eq_contains,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_eq_contains,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_eq_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_eq_contained_by,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_eq_contained_by,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_eq_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_eq_arrow,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_eq_arrow,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_eq_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_eq_arrow_text,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_eq_arrow_text,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_eq_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);
