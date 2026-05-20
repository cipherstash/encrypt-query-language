-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql

--! @brief Less-than comparison helper for encrypted values
--! @internal
--! @deprecated Slated for removal in EQL 3.0. Use the `<` operator instead.
--!
--! Internal helper that delegates to `eql_v2.compare` for less-than
--! testing. The `<` operator wrappers no longer call this helper — they
--! inline a direct `ore_block_u64_8_256` comparison instead (see the
--! inlinable bodies below).
--!
--! @warning Behaviour now diverges from the `<` operator: this helper
--!   still walks `eql_v2.compare`'s priority list (ore_block → ore_cllw
--!   → hm), whereas `<` goes straight to `ore_block_u64_8_256` and raises
--!   on missing `ob`. Callers relying on the dispatcher fallback should
--!   migrate to the extractor form: `eql_v2.ore_cllw(col) <
--!   eql_v2.ore_cllw($1::jsonb)`. See U-005.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if a < b (compare result = -1)
--!
--! @see eql_v2.compare
--! @see eql_v2."<"
CREATE FUNCTION eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) = -1;
  END;
$$ LANGUAGE plpgsql;

--! @brief Less-than operator for encrypted values
--!
--! Implements the < operator for comparing two encrypted values via their
--! `ob` (ore_block_u64_8_256) ORE term. Enables range queries and sorting
--! without decryption. Requires the column to carry an `ob` term (configured
--! via the `ore` index in the EQL schema).
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if a is less than b
--!
--! @example
--! -- Range query on encrypted timestamps
--! SELECT * FROM events
--! WHERE encrypted_timestamp < '2024-01-01'::timestamp::text::eql_v2_encrypted;
--!
--! -- Compare encrypted numeric columns
--! SELECT * FROM products WHERE encrypted_price < encrypted_discount_price;
--!
--! @see eql_v2.ore_block_u64_8_256
--! @see eql_v2.add_search_config
-- Inlinable: `LANGUAGE sql IMMUTABLE` with a single SELECT body and no
-- `SET` clause. The Postgres planner inlines the body into the calling
-- query during planning, so `WHERE col < val` reduces to
-- `WHERE eql_v2.ore_block_u64_8_256(col) < eql_v2.ore_block_u64_8_256(val)`
-- and matches a functional btree index built on
-- `eql_v2.ore_block_u64_8_256(col)` (using the DEFAULT
-- `eql_v2.ore_block_u64_8_256_operator_class`). Bare range queries
-- (`WHERE col < $1`) engage the functional ORE index on Supabase and any
-- install that doesn't ship `eql_v2.encrypted_operator_class`.
--
-- Behaviour change vs the previous dispatcher-based impl: the old
-- `eql_v2."<"` walked `eql_v2.compare`, which dispatched through
-- ore_block / ore_cllw_u64 / ore_cllw_var / ope. Now `<` requires the
-- column to have `ore_block_u64_8_256` configured (i.e. carry an `ob`
-- field). Calling `<` on a column with only `ore_cllw_*` or OPE terms
-- now raises from the `ore_block_u64_8_256(jsonb)` extractor
-- (`Expected an ore index (ob) value in json: ...`) where it
-- previously returned a Boolean. Loud failure surfaces config errors
-- rather than silently producing zero rows — see U-005.
CREATE FUNCTION eql_v2."<"(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) < eql_v2.ore_block_u64_8_256(b)
$$;

CREATE OPERATOR <(
  FUNCTION=eql_v2."<",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

--! @brief Less-than operator for encrypted value and JSONB
--!
--! Overload of < operator accepting JSONB on the right side. Reduces to a
--! direct comparison of the `ob` ORE term on both sides; the jsonb
--! extractor `eql_v2.ore_block_u64_8_256(jsonb)` reads `b->'ob'` directly.
--!
--! @param eql_v2_encrypted Left operand (encrypted value)
--! @param b JSONB Right operand
--! @return Boolean True if a < b
--!
--! @example
--! SELECT * FROM events WHERE encrypted_age < '{"ob":[...]}'::jsonb;
--!
--! @see eql_v2."<"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."<"(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) < eql_v2.ore_block_u64_8_256(b)
$$;

CREATE OPERATOR <(
  FUNCTION=eql_v2."<",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

--! @brief Less-than operator for JSONB and encrypted value
--!
--! Overload of < operator accepting JSONB on the left side. Reduces to a
--! direct comparison of the `ob` ORE term on both sides.
--!
--! @param a JSONB Left operand
--! @param eql_v2_encrypted Right operand (encrypted value)
--! @return Boolean True if a < b
--!
--! @example
--! SELECT * FROM events WHERE '{"ob":[...]}'::jsonb < encrypted_date;
--!
--! @see eql_v2."<"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."<"(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ore_block_u64_8_256(a) < eql_v2.ore_block_u64_8_256(b)
$$;


CREATE OPERATOR <(
  FUNCTION=eql_v2."<",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);
