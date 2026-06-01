-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema-v3.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_functions.sql

--! @file encrypted_domain/int4/int4_operators.sql
--! @brief Storage-only domain of the int4 encrypted-domain family — operator declarations.

-- Placeholder: this domain's term set does not support =; the backing function always raises.
CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support =; the backing function always raises.
CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support =; the backing function always raises.
CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <>; the backing function always raises.
CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <>; the backing function always raises.
CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <>; the backing function always raises.
CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <; the backing function always raises.
CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <; the backing function always raises.
CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <; the backing function always raises.
CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <=; the backing function always raises.
CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <=; the backing function always raises.
CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <=; the backing function always raises.
CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support >; the backing function always raises.
CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support >; the backing function always raises.
CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support >; the backing function always raises.
CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support >=; the backing function always raises.
CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support >=; the backing function always raises.
CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support >=; the backing function always raises.
CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.int4, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.int4, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.int4, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.int4, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support ?; the backing function always raises.
CREATE OPERATOR ? (
  FUNCTION = eql_v3."?",
  LEFTARG = eql_v3.int4, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ?|; the backing function always raises.
CREATE OPERATOR ?| (
  FUNCTION = eql_v3."?|",
  LEFTARG = eql_v3.int4, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support ?&; the backing function always raises.
CREATE OPERATOR ?& (
  FUNCTION = eql_v3."?&",
  LEFTARG = eql_v3.int4, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support @?; the backing function always raises.
CREATE OPERATOR @? (
  FUNCTION = eql_v3."@?",
  LEFTARG = eql_v3.int4, RIGHTARG = jsonpath
);

-- Placeholder: this domain's term set does not support @@; the backing function always raises.
CREATE OPERATOR @@ (
  FUNCTION = eql_v3."@@",
  LEFTARG = eql_v3.int4, RIGHTARG = jsonpath
);

-- Placeholder: this domain's term set does not support #>; the backing function always raises.
CREATE OPERATOR #> (
  FUNCTION = eql_v3."#>",
  LEFTARG = eql_v3.int4, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support #>>; the backing function always raises.
CREATE OPERATOR #>> (
  FUNCTION = eql_v3."#>>",
  LEFTARG = eql_v3.int4, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.int4, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.int4, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.int4, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support #-; the backing function always raises.
CREATE OPERATOR #- (
  FUNCTION = eql_v3."#-",
  LEFTARG = eql_v3.int4, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.int4, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4
);
