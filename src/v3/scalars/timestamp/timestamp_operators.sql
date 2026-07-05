-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_types.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_functions.sql

--! @file encrypted_domain/timestamp/timestamp_operators.sql
--! @brief Operators for public.timestamp.

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.timestamp, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.timestamp, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.timestamp, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.timestamp, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal."?",
  LEFTARG = public.timestamp, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal."?|",
  LEFTARG = public.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal."?&",
  LEFTARG = public.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal."@?",
  LEFTARG = public.timestamp, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal."@@",
  LEFTARG = public.timestamp, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal."#>",
  LEFTARG = public.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal."#>>",
  LEFTARG = public.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.timestamp, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.timestamp, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal."#-",
  LEFTARG = public.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.timestamp, RIGHTARG = public.timestamp
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = jsonb, RIGHTARG = public.timestamp
);
