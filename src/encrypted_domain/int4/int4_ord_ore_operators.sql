-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/int4/int4_ord_ore_functions.sql

--! @file encrypted_domain/int4/int4_ord_ore_operators.sql
--! @brief Concrete ordered int4 variant — operator declarations
--!        (equality + ORE-block ordering).
--!
--! eql_v2_int4_ord_ore carries `c`, `ob`. It is the scheme-explicit
--! ordered domain: it carries the eql_v2.ord() extractor, the six
--! comparison wrappers, the operator declarations, and the blockers.
--! eql_v2_int4_ord — the recommended ordered name — is a separate
--! concrete domain (int4_ord.sql) carrying its own copy of this
--! operator surface; the §8 spike showed a domain-over-domain alias
--! does not transparently inherit the operator surface (D-E fallback).

-- Operator declarations

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_eq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_eq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_neq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_neq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_lt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_lte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_gt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_gte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

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

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contains,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contains,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contained_by,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contained_by,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow_text,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow_text,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);
