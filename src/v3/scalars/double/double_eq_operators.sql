-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/double/double_eq_functions.sql

--! @file encrypted_domain/double/double_eq_operators.sql
--! @brief Operators for public.double_eq.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.double_eq, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = jsonb, RIGHTARG = public.double_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.double_eq, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = jsonb, RIGHTARG = public.double_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.double_eq, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.double_eq, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.double_eq, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.double_eq, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal."?",
  LEFTARG = public.double_eq, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal."?|",
  LEFTARG = public.double_eq, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal."?&",
  LEFTARG = public.double_eq, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal."@?",
  LEFTARG = public.double_eq, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal."@@",
  LEFTARG = public.double_eq, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal."#>",
  LEFTARG = public.double_eq, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal."#>>",
  LEFTARG = public.double_eq, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.double_eq, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.double_eq, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.double_eq, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal."#-",
  LEFTARG = public.double_eq, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double_eq, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = jsonb, RIGHTARG = public.double_eq
);
