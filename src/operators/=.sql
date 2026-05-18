-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql

--! @brief Equality helper for encrypted values
--! @internal
--!
--! Inlinable SQL helper mirroring the `=` operator's body: reduces to
--! `hmac_256(a) = hmac_256(b)`. Kept for callers that invoked the
--! pre-#193 form (`eql_v2.eq`); equivalent to using the `=` operator
--! directly.
--!
--! Equality on `eql_v2_encrypted` is strictly hmac-based (see U-002).
--! Returns NULL when either side lacks an `hm` term — matching the
--! `=` operator's behaviour.
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return Boolean True if hmac terms match
--!
--! @see eql_v2."="
--! @see eql_v2.hmac_256
CREATE FUNCTION eql_v2.eq(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b)
$$;

--! @brief Equality operator for encrypted values
--!
--! Implements the = operator for comparing two encrypted values using their
--! encrypted index terms (hmac_256). Enables WHERE clause comparisons
--! without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if encrypted values are equal
--!
--! @example
--! -- Compare encrypted columns
--! SELECT * FROM users WHERE encrypted_email = other_encrypted_email;
--!
--! -- Search using encrypted literal
--! SELECT * FROM users
--! WHERE encrypted_email = '{"c":"...","i":{"unique":"..."}}'::eql_v2_encrypted;
--!
--! @see eql_v2.compare
--! @see eql_v2.add_search_config
-- Inlinable: `LANGUAGE sql IMMUTABLE` with a single SELECT body and no
-- `SET` clause. The Postgres planner inlines the body into the calling
-- query during planning, so `WHERE col = val` reduces to
-- `WHERE eql_v2.hmac_256(col) = eql_v2.hmac_256(val)` and matches a
-- functional hash index built on `eql_v2.hmac_256(col)`. Bare equality
-- queries (including those issued by PostgREST and ORMs that don't
-- wrap columns themselves) become fast on Supabase and any
-- --exclude-operator-family install.
--
-- Behaviour change vs the previous dispatcher-based impl: the old
-- `eql_v2.eq` walked `eql_v2.compare`, which fell back to ORE / Blake3 /
-- literal comparison when HMAC wasn't present. Now `=` requires the
-- column to have `equality` configured (i.e. carry an `hm` field).
-- Calling `=` on an ORE-only column will return NULL where it
-- previously returned a Boolean. This is intentional — it surfaces
-- config errors loudly. See the predicate/extractor RFC for context.
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b)
$$;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief Equality operator for encrypted value and JSONB
--!
--! Overload of = operator accepting JSONB on the right side. Automatically
--! casts JSONB to eql_v2_encrypted for comparison. Useful for comparing
--! against JSONB literals or columns.
--!
--! @param eql_v2_encrypted Left operand (encrypted value)
--! @param b JSONB Right operand (will be cast to eql_v2_encrypted)
--! @return Boolean True if values are equal
--!
--! @example
--! -- Compare encrypted column to JSONB literal
--! SELECT * FROM users
--! WHERE encrypted_email = '{"c":"...","i":{"unique":"..."}}'::jsonb;
--!
--! @see eql_v2."="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b::eql_v2_encrypted)
$$;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  MERGES
);

--! @brief Equality operator for JSONB and encrypted value
--!
--! Overload of = operator accepting JSONB on the left side. Automatically
--! casts JSONB to eql_v2_encrypted for comparison. Enables commutative
--! equality comparisons.
--!
--! @param a JSONB Left operand (will be cast to eql_v2_encrypted)
--! @param eql_v2_encrypted Right operand (encrypted value)
--! @return Boolean True if values are equal
--!
--! @example
--! -- Compare JSONB literal to encrypted column
--! SELECT * FROM users
--! WHERE '{"c":"...","i":{"unique":"..."}}'::jsonb = encrypted_email;
--!
--! @see eql_v2."="(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."="(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.hmac_256(a::eql_v2_encrypted) = eql_v2.hmac_256(b)
$$;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  MERGES
);

