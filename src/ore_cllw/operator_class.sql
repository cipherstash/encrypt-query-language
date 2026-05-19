-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_cllw/types.sql
-- REQUIRE: src/ore_cllw/functions.sql
-- REQUIRE: src/ore_cllw/operators.sql


-- ============================================================================
-- Btree operator class on `eql_v2.ore_cllw`
-- ============================================================================
--
-- Registers the CLLW per-byte comparison operators as a btree opclass for
-- the `eql_v2.ore_cllw` composite type. With `DEFAULT FOR TYPE`, a functional
-- btree index on `eql_v2.ore_cllw(col)` (or any expression returning the
-- composite) automatically picks up this opclass — no annotation needed at
-- index creation time.
--
-- Why this matters. After the consolidation in #219, ordered comparison on
-- sv-element values (via `eql_v2.ore_cllw(value -> '<selector>'::text)`)
-- has correct semantics through the operator backing functions (each
-- reduces to `compare_ore_cllw_term <op> 0`), but PostgreSQL won't engage
-- a functional index for `ORDER BY ...` or `WHERE ... < $1` unless the
-- type has a registered btree opclass that the planner can structurally
-- match. Without this opclass, `field_order/*` queries on sv-element CLLW
-- columns fall back to seq scan + Top-N sort (measured 20s+ on 1M rows).
-- With it, the same queries become Index Scan + LIMIT — milliseconds.
--
-- FUNCTION 1 is the three-way comparator that btree's internal sort uses
-- (returns -1 / 0 / +1). We point it at `compare_ore_cllw_term` directly:
-- that's plpgsql by design (the per-byte CLLW protocol needs iteration),
-- and btree calls it once per index entry pair during build / search —
-- not per-row in the outer query.
--
-- Deliberately no operator family registration beyond the opclass itself
-- (no cross-type operators on `eql_v2.ore_cllw` × `jsonb`, no hash
-- support — see operators.sql for the rationale).

CREATE OPERATOR FAMILY eql_v2.ore_cllw_ops USING btree;

CREATE OPERATOR CLASS eql_v2.ore_cllw_ops
  DEFAULT FOR TYPE eql_v2.ore_cllw
  USING btree FAMILY eql_v2.ore_cllw_ops AS
    OPERATOR 1 <  (eql_v2.ore_cllw, eql_v2.ore_cllw),
    OPERATOR 2 <= (eql_v2.ore_cllw, eql_v2.ore_cllw),
    OPERATOR 3 =  (eql_v2.ore_cllw, eql_v2.ore_cllw),
    OPERATOR 4 >= (eql_v2.ore_cllw, eql_v2.ore_cllw),
    OPERATOR 5 >  (eql_v2.ore_cllw, eql_v2.ore_cllw),
    FUNCTION 1 eql_v2.compare_ore_cllw_term(eql_v2.ore_cllw, eql_v2.ore_cllw);
