-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_functions.sql

--! @file encrypted_domain/int4/int4_ord_operators.sql
--! @brief Concrete ordered int4 variant (D-E fallback) — operator
--!        declarations. The recommended ordered name.
--!
--! eql_v2_int4_ord carries `c`, `ob`. It is a full concrete mirror of
--! int4_ord_ore.sql: the §8 verification spike showed the pure-alias
--! form (a domain over eql_v2_int4_ord_ore) does not transparently
--! inherit the operator surface — PostgreSQL resolves operators against
--! the ultimate base type (jsonb), so ordered operators fall through to
--! native jsonb comparison and the blockers do not engage.
--! eql_v2_int4_ord therefore carries its own eql_v2.ord_term() overload,
--! comparison wrappers, operator declarations, and blockers.
--! eql_v2_int4_ord_ore is the scheme-explicit ordered domain with the
--! identical operator surface.

-- Operator declarations.
--
-- COMMUTATOR lets the planner normalise `$1 < col` to `col > $1`;
-- NEGATOR drives `NOT (...)` simplification. These wrappers inline to
-- the ORE-block composite operators before index matching, so the
-- metadata is for plan-quality completeness, not index engagement.

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_eq,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_eq,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_neq,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_neq,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ord_lt,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = >, NEGATOR = >=,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ord_lt,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = >, NEGATOR = >=,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ord_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = >, NEGATOR = >=,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ord_lte,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = >=, NEGATOR = >,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);
CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ord_lte,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = >=, NEGATOR = >,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);
CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ord_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = >=, NEGATOR = >,
  RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ord_gt,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = <, NEGATOR = <=,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ord_gt,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = <, NEGATOR = <=,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ord_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = <, NEGATOR = <=,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ord_gte,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = <=, NEGATOR = <,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);
CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ord_gte,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb,
  COMMUTATOR = <=, NEGATOR = <,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);
CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ord_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord,
  COMMUTATOR = <=, NEGATOR = <,
  RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_like,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_like,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ilike,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ilike,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord);

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_contains,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_contains,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_contained_by,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = eql_v2_int4_ord);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_contained_by,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_arrow,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_arrow,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_arrow_text,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_arrow_text,
  LEFTARG = eql_v2_int4_ord, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord);
