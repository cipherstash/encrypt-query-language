-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema-v3.sql
-- REQUIRE: src/encrypted_domain/int4/int4_types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_functions.sql

--! @file encrypted_domain/int4/int4_ord_operators.sql
--! @brief Ordered domain of the int4 encrypted-domain family — operator declarations.

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support @>; the backing function always raises.
CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support <@; the backing function always raises.
CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support ->; the backing function always raises.
CREATE OPERATOR -> (
  FUNCTION = eql_v3."->",
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support ->>; the backing function always raises.
CREATE OPERATOR ->> (
  FUNCTION = eql_v3."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support ?; the backing function always raises.
CREATE OPERATOR ? (
  FUNCTION = eql_v3."?",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support ?|; the backing function always raises.
CREATE OPERATOR ?| (
  FUNCTION = eql_v3."?|",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support ?&; the backing function always raises.
CREATE OPERATOR ?& (
  FUNCTION = eql_v3."?&",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support @?; the backing function always raises.
CREATE OPERATOR @? (
  FUNCTION = eql_v3."@?",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonpath
);

-- Placeholder: this domain's term set does not support @@; the backing function always raises.
CREATE OPERATOR @@ (
  FUNCTION = eql_v3."@@",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonpath
);

-- Placeholder: this domain's term set does not support #>; the backing function always raises.
CREATE OPERATOR #> (
  FUNCTION = eql_v3."#>",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support #>>; the backing function always raises.
CREATE OPERATOR #>> (
  FUNCTION = eql_v3."#>>",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = integer
);

-- Placeholder: this domain's term set does not support -; the backing function always raises.
CREATE OPERATOR - (
  FUNCTION = eql_v3."-",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support #-; the backing function always raises.
CREATE OPERATOR #- (
  FUNCTION = eql_v3."#-",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = text[]
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = eql_v3.int4_ord
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = eql_v3.int4_ord, RIGHTARG = jsonb
);

-- Placeholder: this domain's term set does not support ||; the backing function always raises.
CREATE OPERATOR || (
  FUNCTION = eql_v3."||",
  LEFTARG = jsonb, RIGHTARG = eql_v3.int4_ord
);
