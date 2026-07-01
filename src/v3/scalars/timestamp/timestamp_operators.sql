-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_types.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_functions.sql

--! @file encrypted_domain/timestamp/timestamp_operators.sql
--! @brief Operators for eql_v3.timestamp.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.timestamp, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.timestamp, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3."?",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3."?|",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3."?&",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3."@?",
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3."@@",
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3."#>",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3."#>>",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.timestamp, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3."#-",
  LEFTARG = eql_v3.timestamp, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.timestamp, RIGHTARG = eql_v3.timestamp
);

CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.timestamp, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = jsonb, RIGHTARG = eql_v3.timestamp
);
