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

-- Operator declarations.
--
-- COMMUTATOR lets the planner normalise `$1 = col` to `col = $1`;
-- NEGATOR drives `NOT (...)` simplification. These wrappers inline to
-- the hmac-256 equality before index matching, so the metadata is for
-- plan-quality completeness, not index engagement.

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq);
CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq);
CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);

CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq);
