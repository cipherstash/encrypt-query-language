-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/sem/ore_cllw/types.sql
-- REQUIRE: src/v3/sem/ore_cllw/functions.sql
-- REQUIRE: src/v3/sem/ore_cllw/operators.sql

--! @file v3/sem/ore_cllw/operator_class.sql
--! @brief Btree operator class on the eql_v3_internal.ore_cllw composite type.
--!
--! DEFAULT FOR TYPE so a functional btree index on eql_v3_internal.ore_cllw(expr)
--! engages without an explicit opclass annotation. FUNCTION 1 is the three-way
--! comparator btree's internal sort uses; it is plpgsql by design (per-byte
--! CLLW protocol needs iteration) and is called once per index-entry pair
--! during build / search, not per-row in the outer query.
--!
--! @note Creating an operator family/class requires superuser: Postgres forbids
--!       CREATE OPERATOR FAMILY / CLASS to non-superusers to protect index
--!       integrity. Managed platforms (Supabase, and most hosted Postgres) run
--!       the installer as a non-superuser role, so the DO block below ATTEMPTS
--!       the creation and skips it on insufficient_privilege (SQLSTATE 42501),
--!       letting the single installer run everywhere. When the class is absent,
--!       ORE ordered scans over eql_v3_internal.ore_cllw are unavailable, but
--!       the order-preserving (OPE) ordering domains — whose extractor return
--!       types carry a native btree opclass — still index without it. On
--!       superuser installs (self-managed Postgres, the SQLx test matrix) the
--!       class is created normally. Any non-privilege error still propagates.
--! @see eql_v3_internal.compare_ore_cllw_term

DO $do$
BEGIN
  EXECUTE 'CREATE OPERATOR FAMILY eql_v3_internal.ore_cllw_ops USING btree';

  EXECUTE $ddl$
    CREATE OPERATOR CLASS eql_v3_internal.ore_cllw_ops
      DEFAULT FOR TYPE eql_v3_internal.ore_cllw
      USING btree FAMILY eql_v3_internal.ore_cllw_ops AS
        OPERATOR 1 public.<  (eql_v3_internal.ore_cllw, eql_v3_internal.ore_cllw),
        OPERATOR 2 public.<= (eql_v3_internal.ore_cllw, eql_v3_internal.ore_cllw),
        OPERATOR 3 public.=  (eql_v3_internal.ore_cllw, eql_v3_internal.ore_cllw),
        OPERATOR 4 public.>= (eql_v3_internal.ore_cllw, eql_v3_internal.ore_cllw),
        OPERATOR 5 public.>  (eql_v3_internal.ore_cllw, eql_v3_internal.ore_cllw),
        FUNCTION 1 eql_v3_internal.compare_ore_cllw_term(eql_v3_internal.ore_cllw, eql_v3_internal.ore_cllw)
  $ddl$;

  RAISE NOTICE 'EQL: created btree operator class eql_v3_internal.ore_cllw_ops';
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE 'EQL: skipped operator class eql_v3_internal.ore_cllw_ops (requires superuser); ORE ordered indexes on ore_cllw unavailable, OPE ordering domains unaffected';
END;
$do$;
