-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/real/query_real_types.sql
-- REQUIRE: src/v3/scalars/real/query_real_ord_functions.sql

--! @file encrypted_domain/real/query_real_ord_operators.sql
--! @brief Operators for eql_v3.query_real_ord.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.real_ord, RIGHTARG = eql_v3.query_real_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.query_real_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.real_ord, RIGHTARG = eql_v3.query_real_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.query_real_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.real_ord, RIGHTARG = eql_v3.query_real_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.query_real_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.real_ord, RIGHTARG = eql_v3.query_real_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.query_real_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.real_ord, RIGHTARG = eql_v3.query_real_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.query_real_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.real_ord, RIGHTARG = eql_v3.query_real_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.query_real_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);
