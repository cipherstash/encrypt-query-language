-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_functions.sql

--! @file encrypted_domain/int4/int4_operators.sql
--! @brief storage domain of the int4 encrypted-domain family — operator declarations.

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR @> (
  FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR @> (
  FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v2.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v2.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR -> (
  FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v2."->",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v2."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR ? (
  FUNCTION = eql_v2."?",
  LEFTARG = eql_v2_int4, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v2."?|",
  LEFTARG = eql_v2_int4, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v2."?&",
  LEFTARG = eql_v2_int4, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v2."@?",
  LEFTARG = eql_v2_int4, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v2."@@",
  LEFTARG = eql_v2_int4, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v2."#>",
  LEFTARG = eql_v2_int4, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v2."#>>",
  LEFTARG = eql_v2_int4, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v2."-",
  LEFTARG = eql_v2_int4, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v2."-",
  LEFTARG = eql_v2_int4, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v2."-",
  LEFTARG = eql_v2_int4, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v2."#-",
  LEFTARG = eql_v2_int4, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v2."||",
  LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4
);

CREATE OPERATOR || (
  FUNCTION = eql_v2."||",
  LEFTARG = eql_v2_int4, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v2."||",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4
);
