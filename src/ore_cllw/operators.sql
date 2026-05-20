-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ore_cllw/functions.sql

--! @file src/ore_cllw/operators.sql
--! @brief Comparison operators on the `eql_v2.ore_cllw` composite type
--!
--! Same-type comparison operators backing the btree operator class on the
--! composite `eql_v2.ore_cllw` type. Each operator reduces to a single SELECT
--! over `eql_v2.compare_ore_cllw_term(a, b)`, which is the canonical CLLW
--! per-byte comparator (`y + 1 == x` mod 256). The operator wrappers are
--! inlinable `LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE` so the planner can
--! fold them into the calling query — that's what lets a functional btree
--! index on `eql_v2.ore_cllw(col)` engage for both `WHERE eql_v2.ore_cllw(col)
--! < eql_v2.ore_cllw($1)` and `ORDER BY eql_v2.ore_cllw(col)` shapes.
--!
--! The inner `eql_v2.compare_ore_cllw_term` is `LANGUAGE plpgsql` (it has a
--! per-byte loop) and is NOT inlined. That's fine for index *match* (the
--! planner only needs the outer operator function call to fold so the
--! predicate's expression tree matches the index's expression tree); only the
--! per-comparison cost is the plpgsql call overhead. That's the cost the
--! functional index avoids by walking the btree in order rather than calling
--! compare on every row.
--!
--! @note Deliberately no `HASHES` / `MERGES` flags on the operator
--!       declarations. HASHES requires a registered hash function on the type
--!       (the CLLW protocol gives ordering, not a sensible hashing); MERGES
--!       requires an equivalent merge-joinable operator class on both sides.
--!
--! @see src/ore_cllw/operator_class.sql
--! @see src/ore_cllw/functions.sql

--! @brief Equality operator backing function for `eql_v2.ore_cllw`
--! @internal
--!
--! @param a eql_v2.ore_cllw Left operand
--! @param b eql_v2.ore_cllw Right operand
--! @return boolean True if the CLLW terms compare equal
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.ore_cllw_eq(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_cllw_term(a, b) = 0
$$;

--! @brief Inequality operator backing function for `eql_v2.ore_cllw`
--! @internal
--!
--! @param a eql_v2.ore_cllw Left operand
--! @param b eql_v2.ore_cllw Right operand
--! @return boolean True if the CLLW terms compare unequal
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.ore_cllw_neq(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_cllw_term(a, b) <> 0
$$;

--! @brief Less-than operator backing function for `eql_v2.ore_cllw`
--! @internal
--!
--! @param a eql_v2.ore_cllw Left operand
--! @param b eql_v2.ore_cllw Right operand
--! @return boolean True if `a` orders before `b`
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.ore_cllw_lt(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_cllw_term(a, b) = -1
$$;

--! @brief Less-than-or-equal operator backing function for `eql_v2.ore_cllw`
--! @internal
--!
--! @param a eql_v2.ore_cllw Left operand
--! @param b eql_v2.ore_cllw Right operand
--! @return boolean True if `a` orders before or equal to `b`
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.ore_cllw_lte(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_cllw_term(a, b) <> 1
$$;

--! @brief Greater-than operator backing function for `eql_v2.ore_cllw`
--! @internal
--!
--! @param a eql_v2.ore_cllw Left operand
--! @param b eql_v2.ore_cllw Right operand
--! @return boolean True if `a` orders after `b`
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.ore_cllw_gt(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_cllw_term(a, b) = 1
$$;

--! @brief Greater-than-or-equal operator backing function for `eql_v2.ore_cllw`
--! @internal
--!
--! @param a eql_v2.ore_cllw Left operand
--! @param b eql_v2.ore_cllw Right operand
--! @return boolean True if `a` orders after or equal to `b`
--!
--! @see eql_v2.compare_ore_cllw_term
CREATE FUNCTION eql_v2.ore_cllw_gte(a eql_v2.ore_cllw, b eql_v2.ore_cllw)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.compare_ore_cllw_term(a, b) <> -1
$$;


CREATE OPERATOR = (
  FUNCTION = eql_v2.ore_cllw_eq,
  LEFTARG = eql_v2.ore_cllw,
  RIGHTARG = eql_v2.ore_cllw,
  COMMUTATOR = =,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.ore_cllw_neq,
  LEFTARG = eql_v2.ore_cllw,
  RIGHTARG = eql_v2.ore_cllw,
  COMMUTATOR = <>,
  NEGATOR = =,
  RESTRICT = neqsel,
  JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.ore_cllw_lt,
  LEFTARG = eql_v2.ore_cllw,
  RIGHTARG = eql_v2.ore_cllw,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.ore_cllw_lte,
  LEFTARG = eql_v2.ore_cllw,
  RIGHTARG = eql_v2.ore_cllw,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v2.ore_cllw_gt,
  LEFTARG = eql_v2.ore_cllw,
  RIGHTARG = eql_v2.ore_cllw,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.ore_cllw_gte,
  LEFTARG = eql_v2.ore_cllw,
  RIGHTARG = eql_v2.ore_cllw,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalargesel,
  JOIN = scalargejoinsel
);
