-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/boolean/boolean_types.sql
-- REQUIRE: src/v3/scalars/boolean/boolean_functions.sql

--! @file encrypted_domain/boolean/boolean_operators.sql
--! @brief Operators for public.boolean.

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.boolean, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.boolean, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.boolean, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.boolean, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = jsonb, RIGHTARG = public.boolean
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal."?",
  LEFTARG = public.boolean, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal."?|",
  LEFTARG = public.boolean, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal."?&",
  LEFTARG = public.boolean, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal."@?",
  LEFTARG = public.boolean, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal."@@",
  LEFTARG = public.boolean, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal."#>",
  LEFTARG = public.boolean, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal."#>>",
  LEFTARG = public.boolean, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.boolean, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.boolean, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.boolean, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal."#-",
  LEFTARG = public.boolean, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.boolean, RIGHTARG = public.boolean
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.boolean, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = jsonb, RIGHTARG = public.boolean
);
