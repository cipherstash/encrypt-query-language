-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_query_types.sql
-- REQUIRE: src/v3/scalars/text/text_match_query_functions.sql

--! @file encrypted_domain/text/text_match_query_operators.sql
--! @brief Operators for public.text_match_query.

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = public.text_match, RIGHTARG = public.text_match_query,
  COMMUTATOR = <@, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3.contains,
  LEFTARG = public.text_match_query, RIGHTARG = public.text_match,
  COMMUTATOR = <@, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = public.text_match, RIGHTARG = public.text_match_query,
  COMMUTATOR = @>, RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3.contained_by,
  LEFTARG = public.text_match_query, RIGHTARG = public.text_match,
  COMMUTATOR = @>, RESTRICT = contsel, JOIN = contjoinsel
);
