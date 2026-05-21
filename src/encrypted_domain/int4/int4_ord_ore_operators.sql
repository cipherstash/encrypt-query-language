-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore_functions.sql

--! @file encrypted_domain/int4/int4_ord_ore_operators.sql
--! @brief Concrete ordered int4 variant — operator declarations
--!        (equality + ORE-block ordering).
--!
--! eql_v2_int4_ord_ore carries `c`, `ob`. It is the scheme-explicit
--! ordered domain: it carries the eql_v2.ord_term() extractor, the six
--! comparison wrappers, the operator declarations, and the blockers.
--! eql_v2_int4_ord — the recommended ordered name — is a separate
--! concrete domain (int4_ord.sql) carrying its own copy of this
--! operator surface; the §8 spike showed a domain-over-domain alias
--! does not transparently inherit the operator surface (D-E fallback).

-- Operator declarations.
--
-- COMMUTATOR lets the planner normalise `$1 < col` to `col > $1`;
-- NEGATOR drives `NOT (...)` simplification. These wrappers inline to
-- the ORE-block composite operators before index matching, so the
-- metadata is for plan-quality completeness, not index engagement.

CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = >, NEGATOR = >=,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  COMMUTATOR = >, NEGATOR = >=,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (
  FUNCTION = eql_v2.lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = >, NEGATOR = >=,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = >=, NEGATOR = >,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);
CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  COMMUTATOR = >=, NEGATOR = >,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);
CREATE OPERATOR <= (
  FUNCTION = eql_v2.lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = >=, NEGATOR = >,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = <, NEGATOR = <=,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  COMMUTATOR = <, NEGATOR = <=,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (
  FUNCTION = eql_v2.gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = <, NEGATOR = <=,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = <=, NEGATOR = <,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);
CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  COMMUTATOR = <=, NEGATOR = <,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);
CREATE OPERATOR >= (
  FUNCTION = eql_v2.gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  COMMUTATOR = <=, NEGATOR = <,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_like,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_like,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ore_ilike,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ore_ilike,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ore_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2."->",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2."->>",
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);
