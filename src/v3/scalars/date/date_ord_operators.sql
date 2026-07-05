-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/date/date_types.sql
-- REQUIRE: src/v3/scalars/date/date_ord_functions.sql

--! @file encrypted_domain/date/date_ord_operators.sql
--! @brief Operators for public.date_ord.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.date_ord, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = jsonb, RIGHTARG = public.date_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.date_ord, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = jsonb, RIGHTARG = public.date_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.date_ord, RIGHTARG = jsonb,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = jsonb, RIGHTARG = public.date_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.date_ord, RIGHTARG = jsonb,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = jsonb, RIGHTARG = public.date_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.date_ord, RIGHTARG = jsonb,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = jsonb, RIGHTARG = public.date_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.date_ord, RIGHTARG = jsonb,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = jsonb, RIGHTARG = public.date_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.date_ord, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = jsonb, RIGHTARG = public.date_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.date_ord, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = jsonb, RIGHTARG = public.date_ord
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.date_ord, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.date_ord, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = jsonb, RIGHTARG = public.date_ord
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.date_ord, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.date_ord, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = jsonb, RIGHTARG = public.date_ord
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal."?",
  LEFTARG = public.date_ord, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal."?|",
  LEFTARG = public.date_ord, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal."?&",
  LEFTARG = public.date_ord, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal."@?",
  LEFTARG = public.date_ord, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal."@@",
  LEFTARG = public.date_ord, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal."#>",
  LEFTARG = public.date_ord, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal."#>>",
  LEFTARG = public.date_ord, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.date_ord, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.date_ord, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.date_ord, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal."#-",
  LEFTARG = public.date_ord, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.date_ord, RIGHTARG = public.date_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.date_ord, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = jsonb, RIGHTARG = public.date_ord
);
