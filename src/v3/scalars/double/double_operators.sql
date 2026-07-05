-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/double/double_functions.sql

--! @file encrypted_domain/double/double_operators.sql
--! @brief Operators for public.double.

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.double, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.double, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.double, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.double, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = jsonb, RIGHTARG = public.double
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal."?",
  LEFTARG = public.double, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal."?|",
  LEFTARG = public.double, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal."?&",
  LEFTARG = public.double, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal."@?",
  LEFTARG = public.double, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal."@@",
  LEFTARG = public.double, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal."#>",
  LEFTARG = public.double, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal."#>>",
  LEFTARG = public.double, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.double, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.double, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.double, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal."#-",
  LEFTARG = public.double, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double, RIGHTARG = public.double
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = jsonb, RIGHTARG = public.double
);
