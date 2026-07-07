-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_query_types.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_eq_query_functions.sql

--! @file encrypted_domain/timestamp/timestamp_eq_query_operators.sql
--! @brief Operators for public.timestamp_eq_query.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.timestamp_eq, RIGHTARG = public.timestamp_eq_query,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.timestamp_eq_query, RIGHTARG = public.timestamp_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.timestamp_eq, RIGHTARG = public.timestamp_eq_query,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.timestamp_eq_query, RIGHTARG = public.timestamp_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
