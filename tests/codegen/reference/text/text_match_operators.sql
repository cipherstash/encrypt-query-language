-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/text/text_match_functions.sql

--! @file encrypted_domain/text/text_match_operators.sql
--! @brief Operators for eql_v3.text_match.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match,
  COMMUTATOR = <@, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb,
  COMMUTATOR = <@, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match,
  COMMUTATOR = <@, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match,
  COMMUTATOR = @>, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb,
  COMMUTATOR = @>, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match,
  COMMUTATOR = @>, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.text_match, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.text_match, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.text_match, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.text_match, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3."?",
  LEFTARG = eql_v3.text_match, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3."?|",
  LEFTARG = eql_v3.text_match, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3."?&",
  LEFTARG = eql_v3.text_match, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3."@?",
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3."@@",
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3."#>",
  LEFTARG = eql_v3.text_match, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3."#>>",
  LEFTARG = eql_v3.text_match, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.text_match, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.text_match, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.text_match, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3."#-",
  LEFTARG = eql_v3.text_match, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.text_match, RIGHTARG = eql_v3.text_match
);

CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.text_match, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = jsonb, RIGHTARG = eql_v3.text_match
);
