-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql

--! @file encrypted_domain/operators.sql
--! @brief Prototype exact operators for high-level encrypted domain types
--!
--! Operators are declared in all three type-pair shapes — (domain, domain),
--! (domain, jsonb), (jsonb, domain) — so the planner always finds an
--! exact match before falling back to native jsonb operators. The cross-type
--! shapes share the same proname as the same-domain function so that the
--! pin_search_path allowlist (matched by proname) covers all three.

-- =, <> (HMAC equality)

CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_text_eq,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_text_eq,
  LEFTARG = encrypted_text, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_text_eq,
  LEFTARG = jsonb, RIGHTARG = encrypted_text,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_text_neq,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_text_neq,
  LEFTARG = encrypted_text, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_text_neq,
  LEFTARG = jsonb, RIGHTARG = encrypted_text,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

-- ~~, ~~* (bloom_filter LIKE)

CREATE OPERATOR ~~ (
  FUNCTION = eql_v2.encrypted_text_like,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text,
  RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR ~~ (
  FUNCTION = eql_v2.encrypted_text_like,
  LEFTARG = encrypted_text, RIGHTARG = jsonb,
  RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR ~~ (
  FUNCTION = eql_v2.encrypted_text_like,
  LEFTARG = jsonb, RIGHTARG = encrypted_text,
  RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR ~~* (
  FUNCTION = eql_v2.encrypted_text_like,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text,
  RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR ~~* (
  FUNCTION = eql_v2.encrypted_text_like,
  LEFTARG = encrypted_text, RIGHTARG = jsonb,
  RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR ~~* (
  FUNCTION = eql_v2.encrypted_text_like,
  LEFTARG = jsonb, RIGHTARG = encrypted_text,
  RESTRICT = eqsel, JOIN = eqjoinsel
);

-- Range blockers (<, <=, >, >=) in all three shapes.

CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_text_lt,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text);
CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_text_lt,
  LEFTARG = encrypted_text, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_text_lt,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_text_lte,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text);
CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_text_lte,
  LEFTARG = encrypted_text, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_text_lte,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_text_gt,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text);
CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_text_gt,
  LEFTARG = encrypted_text, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_text_gt,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_text_gte,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text);
CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_text_gte,
  LEFTARG = encrypted_text, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_text_gte,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

-- Containment blockers (@>, <@) in all three shapes.

CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_text_contains,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text);
CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_text_contains,
  LEFTARG = encrypted_text, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_text_contains,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_text_contained_by,
  LEFTARG = encrypted_text, RIGHTARG = encrypted_text);
CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_text_contained_by,
  LEFTARG = encrypted_text, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_text_contained_by,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

-- Path operator blockers. Text RHS, integer RHS (to block native
-- jsonb -> integer array access), and (jsonb, encrypted_text) symmetric form.

CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_text_arrow,
  LEFTARG = encrypted_text, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_text_arrow,
  LEFTARG = encrypted_text, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_text_arrow,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_text_arrow_text,
  LEFTARG = encrypted_text, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_text_arrow_text,
  LEFTARG = encrypted_text, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_text_arrow_text,
  LEFTARG = jsonb, RIGHTARG = encrypted_text);

-- encrypted_int4 operators

-- =, <> (all three shapes)

CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_int4_eq,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_int4_eq,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_int4_eq,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_int4_neq,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_int4_neq,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_int4_neq,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

-- <, <=, >, >= (same-domain keeps selectivity; cross-type omits)

CREATE OPERATOR < (
  FUNCTION = eql_v2.encrypted_int4_lt,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_int4_lt,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_int4_lt,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.encrypted_int4_lte,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_int4_lte,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_int4_lte,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR > (
  FUNCTION = eql_v2.encrypted_int4_gt,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_int4_gt,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_int4_gt,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.encrypted_int4_gte,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_int4_gte,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_int4_gte,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

-- Blockers: ~~, ~~*, @>, <@

CREATE OPERATOR ~~ (FUNCTION = eql_v2.encrypted_int4_like,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.encrypted_int4_like,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.encrypted_int4_like,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.encrypted_int4_ilike,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.encrypted_int4_ilike,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.encrypted_int4_ilike,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_int4_contains,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4);
CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_int4_contains,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_int4_contains,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_int4_contained_by,
  LEFTARG = encrypted_int4, RIGHTARG = encrypted_int4);
CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_int4_contained_by,
  LEFTARG = encrypted_int4, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_int4_contained_by,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

-- Path operators: text RHS, integer RHS, (jsonb, encrypted_int4) symmetric

CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_int4_arrow,
  LEFTARG = encrypted_int4, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_int4_arrow,
  LEFTARG = encrypted_int4, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_int4_arrow,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_int4_arrow_text,
  LEFTARG = encrypted_int4, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_int4_arrow_text,
  LEFTARG = encrypted_int4, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_int4_arrow_text,
  LEFTARG = jsonb, RIGHTARG = encrypted_int4);

-- encrypted_jsonb operators

-- =, <> (HMAC equality)

CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_jsonb_eq,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_jsonb_eq,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.encrypted_jsonb_eq,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_jsonb_neq,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_jsonb_neq,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.encrypted_jsonb_neq,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

-- @>, <@ (STE-vec array containment)

CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_jsonb_contains,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_jsonb_contains,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.encrypted_jsonb_contains,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_jsonb_contained_by,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_jsonb_contained_by,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.encrypted_jsonb_contained_by,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

-- Range blockers (<, <=, >, >=)

CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_jsonb_lt,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_jsonb_lt,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.encrypted_jsonb_lt,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_jsonb_lte,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_jsonb_lte,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.encrypted_jsonb_lte,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_jsonb_gt,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_jsonb_gt,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.encrypted_jsonb_gt,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_jsonb_gte,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_jsonb_gte,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.encrypted_jsonb_gte,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

-- Blockers: ~~, ~~*, and path operators

CREATE OPERATOR ~~ (FUNCTION = eql_v2.encrypted_jsonb_like,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.encrypted_jsonb_like,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.encrypted_jsonb_like,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.encrypted_jsonb_ilike,
  LEFTARG = encrypted_jsonb, RIGHTARG = encrypted_jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.encrypted_jsonb_ilike,
  LEFTARG = encrypted_jsonb, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.encrypted_jsonb_ilike,
  LEFTARG = jsonb, RIGHTARG = encrypted_jsonb);

-- Path operators (->, ->>): text RHS and integer RHS, encrypted_jsonb on LHS
-- only. Native pg_catalog `-> (jsonb, text|integer)` handles plain-jsonb
-- documents unchanged. The reverse "(jsonb document) -> (encrypted selector)"
-- is not a meaningful query pattern; if a caller writes it, PG raises
-- "operator does not exist".

CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_jsonb_arrow,
  LEFTARG = encrypted_jsonb, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.encrypted_jsonb_arrow_int,
  LEFTARG = encrypted_jsonb, RIGHTARG = integer);

CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_jsonb_arrow_text,
  LEFTARG = encrypted_jsonb, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.encrypted_jsonb_arrow_text_int,
  LEFTARG = encrypted_jsonb, RIGHTARG = integer);
