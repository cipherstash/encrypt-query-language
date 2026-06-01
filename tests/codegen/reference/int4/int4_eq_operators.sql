-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_eq_functions.sql

--! @file encrypted_domain/int4/int4_eq_operators.sql
--! @brief Equality-only domain of the int4 encrypted-domain family — operator declarations.

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

-- Placeholder: this domain's term set does not support <; the backing function always raises.
CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support <; the backing function always raises.
CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <; the backing function always raises.
CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support <=; the backing function always raises.
CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support <=; the backing function always raises.
CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <=; the backing function always raises.
CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support >; the backing function always raises.
CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support >; the backing function always raises.
CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support >; the backing function always raises.
CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support >=; the backing function always raises.
CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support >=; the backing function always raises.
CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support >=; the backing function always raises.
CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v2.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v2.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v2."->",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v2."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support ?; the backing function always raises.
CREATE OPERATOR ? (
  FUNCTION = eql_v2."?",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ?|; the backing function always raises.
CREATE OPERATOR ?| (
  FUNCTION = eql_v2."?|",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support ?&; the backing function always raises.
CREATE OPERATOR ?& (
  FUNCTION = eql_v2."?&",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support @?; the backing function always raises.
CREATE OPERATOR @? (
  FUNCTION = eql_v2."@?",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonpath
);

-- Placeholder: this domain's term set does not support @@; the backing function always raises.
CREATE OPERATOR @@ (
  FUNCTION = eql_v2."@@",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonpath
);

-- Placeholder: this domain's term set does not support #>; the backing function always raises.
CREATE OPERATOR #> (
  FUNCTION = eql_v2."#>",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support #>>; the backing function always raises.
CREATE OPERATOR #>> (
  FUNCTION = eql_v2."#>>",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v2."-",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v2."-",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v2."-",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support #-; the backing function always raises.
CREATE OPERATOR #- (
  FUNCTION = eql_v2."#-",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v2."||",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v2."||",
  LEFTARG = eql_v2_int4_eq, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v2."||",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_eq
);
