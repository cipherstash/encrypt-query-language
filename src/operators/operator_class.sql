-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/encrypted/compare.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/compare.sql
-- REQUIRE: src/operators/<.sql
-- REQUIRE: src/operators/<=.sql
-- REQUIRE: src/operators/=.sql
-- REQUIRE: src/operators/>=.sql
-- REQUIRE: src/operators/>.sql

--! @file src/operators/operator_class.sql
--! @brief Btree operator class for the `eql_v2_encrypted` composite type
--!
--! `eql_v2_encrypted` is a composite type. PostgreSQL gives every composite
--! type an implicit row-wise btree comparison (`record_ops`) — but that
--! compares the raw ciphertext byte-for-byte, so two encryptions of the same
--! plaintext (same `hm`, different `c`) would sort and group as *distinct*.
--! `eql_v2.encrypted_operator_class` is registered `DEFAULT ... USING btree`
--! specifically to override `record_ops` with a comparison that is correct
--! for encrypted data: `GROUP BY`, `DISTINCT`, `ORDER BY`, sort-merge joins
--! and `ANALYZE` on a bare `eql_v2_encrypted` column all route through
--! FUNCTION 1 below.
--!
--! @note FUNCTION 1 is `eql_v2.encrypted_btree_compare`, NOT the strict
--!       `eql_v2.compare`. A btree support function must be total and must
--!       never raise — `ANALYZE` calls it to build column statistics on
--!       every encrypted column. `eql_v2.compare` is deliberately strict
--!       (it raises without a Block-ORE `ob` term — see U-005); it backs
--!       the `<` / `>` range operators, not this opclass.
--!
--! @note Functional indexes are the canonical recipe for *building* indexes
--!       on encrypted columns (see U-001 and docs/reference/database-indexes.md).
--!       This opclass exists to keep the composite type's built-in
--!       comparison correct — not as an index-building recommendation.
--!
--! @see eql_v2.encrypted_hash_operator_class (hash — GROUP BY / hash joins)
--! @see eql_v2.compare

--------------------

--! @brief Total, non-raising btree comparator for `eql_v2_encrypted`
--!
--! Three-way comparison (`-1` / `0` / `1`) used as FUNCTION 1 of
--! `eql_v2.encrypted_operator_class`. Unlike `eql_v2.compare`, it never
--! raises: a btree support function is invoked by `ANALYZE`, sort, and
--! `GROUP BY` on every value, so raising is not an option.
--!
--! Comparison priority:
--!   1. Both operands carry `ob` (Block ORE) — order-preserving comparison
--!      via `eql_v2.compare_ore_block_u64_8_256`.
--!   2. Both operands carry `hm` (HMAC-256) — a total order on the hmac
--!      bytes. Not order-preserving on plaintext (hmac is not), but
--!      deterministic, total, and `= 0` exactly when the hmac terms match
--!      — consistent with the `=` operator, so `GROUP BY` / `DISTINCT`
--!      deduplicate correctly.
--!   3. Otherwise — a deterministic order on the raw payload. Reached only
--!      for term-less / mixed payloads; present so the function stays total.
--!
--! @param a eql_v2_encrypted First value
--! @param b eql_v2_encrypted Second value
--! @return integer -1, 0, or 1
--!
--! @internal
--! @see eql_v2.encrypted_operator_class
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.encrypted_btree_compare(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    hm_a text;
    hm_b text;
  BEGIN
    -- Block ORE on both sides: order-preserving comparison.
    IF eql_v2.has_ore_block_u64_8_256(a) AND eql_v2.has_ore_block_u64_8_256(b) THEN
      RETURN eql_v2.compare_ore_block_u64_8_256(a, b);
    END IF;

    -- HMAC on both sides: total order on the hmac bytes. `= 0` iff the hmac
    -- terms match, consistent with the `=` operator and the hash opclass.
    hm_a := eql_v2.hmac_256(a)::text;
    hm_b := eql_v2.hmac_256(b)::text;
    IF hm_a IS NOT NULL AND hm_b IS NOT NULL THEN
      RETURN CASE
        WHEN hm_a < hm_b THEN -1
        WHEN hm_a > hm_b THEN 1
        ELSE 0
      END;
    END IF;

    -- Fallback for term-less / mixed payloads: a deterministic, non-raising
    -- total order on the raw payload. Not a normal column shape — this
    -- branch only keeps the btree FUNCTION 1 contract (total, never raises).
    RETURN CASE
      WHEN (a).data::text < (b).data::text THEN -1
      WHEN (a).data::text > (b).data::text THEN 1
      ELSE 0
    END;
  END;
$$ LANGUAGE plpgsql;

--------------------

CREATE OPERATOR FAMILY eql_v2.encrypted_operator_family USING btree;

CREATE OPERATOR CLASS eql_v2.encrypted_operator_class DEFAULT FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator_family AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 eql_v2.encrypted_btree_compare(a eql_v2_encrypted, b eql_v2_encrypted);
