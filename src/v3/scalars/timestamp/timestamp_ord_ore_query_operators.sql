-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_query_types.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_ord_ore_query_functions.sql

--! @file encrypted_domain/timestamp/timestamp_ord_ore_query_operators.sql
--! @brief Operators for public.timestamp_ord_ore_query.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.timestamp_ord_ore, RIGHTARG = public.timestamp_ord_ore_query,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.timestamp_ord_ore_query, RIGHTARG = public.timestamp_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.timestamp_ord_ore, RIGHTARG = public.timestamp_ord_ore_query,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.timestamp_ord_ore_query, RIGHTARG = public.timestamp_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.timestamp_ord_ore, RIGHTARG = public.timestamp_ord_ore_query,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.timestamp_ord_ore_query, RIGHTARG = public.timestamp_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.timestamp_ord_ore, RIGHTARG = public.timestamp_ord_ore_query,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.timestamp_ord_ore_query, RIGHTARG = public.timestamp_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.timestamp_ord_ore, RIGHTARG = public.timestamp_ord_ore_query,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.timestamp_ord_ore_query, RIGHTARG = public.timestamp_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.timestamp_ord_ore, RIGHTARG = public.timestamp_ord_ore_query,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.timestamp_ord_ore_query, RIGHTARG = public.timestamp_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);
