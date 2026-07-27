-- REQUIRE: src/v3/schema.sql

--! @file v3/aggregates.sql
--! @brief Schema-generic aggregates over the eql_v3 encrypted-domain surface.
--!
--! Re-creates the eql_v2 `grouped_value` aggregate on the self-contained eql_v3
--! surface. Unlike the per-type `min`/`max` aggregates (generated into
--! src/v3/scalars/<T>/ from the catalog, one per ORD-term domain), this one is
--! hand-written and generic: every eql_v3 encrypted-domain column type is a
--! jsonb-backed domain, so a single aggregate over `jsonb` accepts any of them
--! (a domain value implicitly casts to its base type) and returns a value
--! unchanged. There is nothing type-specific to generate.
--!
--! ## Why this aggregate exists
--!
--! To group rows by an encrypted value you must `GROUP BY` its equality index
--! term — `eql_v3.eq_term(col)` (the HMAC) — because the ciphertext envelope
--! itself is not equality-comparable and two encryptions of the same plaintext
--! produce different ciphertexts. But once you group by the term, you cannot
--! also project the encrypted column directly:
--!
--!   SELECT encrypted_foo, ...
--!   FROM some_table
--!   GROUP BY eql_v3.eq_term(encrypted_foo);
--!   -- ERROR: column "encrypted_foo" must appear in the GROUP BY clause or be
--!   --        used in an aggregate function
--!
--! PostgreSQL tracks functional dependency only through a table's primary key,
--! so it cannot prove that `encrypted_foo` is constant within each
--! `eql_v3.eq_term(encrypted_foo)` group (it is, since the HMAC is deterministic
--! in the plaintext) and refuses to project it. `grouped_value` is the
--! aggregate that resolves this: wrap the encrypted column in it to return one
--! representative encrypted value per group, satisfying the GROUP BY rule
--! without decrypting or comparing ciphertext.

--! @brief State transition function for the grouped_value aggregate.
--! @internal
--!
--! Returns the running state so the first value the aggregate sees in a group
--! wins. Declared STRICT: PostgreSQL seeds the null initial state with the first
--! non-null input (without calling this function) and skips subsequent nulls, so
--! the aggregate resolves to the first non-null value in the group — the same
--! result the eql_v2 `COALESCE($1, $2)` state function produced.
--!
--! Per the encrypted-domain footgun rules this is `LANGUAGE plpgsql` with a
--! pinned `search_path`, matching the generated `min`/`max` state functions; an
--! aggregate state function is never a predicate the planner could inline, but
--! keeping the convention uniform avoids surprises.
--!
--! @param state jsonb Accumulated state (the first non-null value seen).
--! @param value jsonb New value from the current row.
--! @return jsonb The running state (first non-null value).
--!
--! @see eql_v3.grouped_value
CREATE FUNCTION eql_v3_internal.grouped_value_sfunc(state jsonb, value jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN state;
END;
$$;

--! @brief Return a representative (first non-null) encrypted value per group.
--!
--! Aggregate that returns the first non-null value encountered within a
--! `GROUP BY` group. Its primary use is projecting an encrypted column while
--! grouping by that column's equality term: `GROUP BY eql_v3.eq_term(col)`
--! groups rows by encrypted equality, but PostgreSQL will not let you also
--! `SELECT col` directly (it cannot prove `col` is constant within each group).
--! Wrapping the column in `grouped_value` returns one representative encrypted
--! value per group and satisfies the GROUP BY rule. Also useful for
--! deduplication. Accepts any eql_v3 encrypted-domain value (each is a
--! jsonb-backed domain) and returns it unchanged — it performs no decryption or
--! comparison. `PARALLEL SAFE` with a combine function so partial/parallel
--! aggregation is available on large `GROUP BY` workloads, matching the shape of
--! the generated `min`/`max` aggregates.
--!
--! @param input jsonb Encrypted values to aggregate.
--! @return jsonb The first non-null value in the group.
--!
--! @note Which value is "first" is arbitrary in the absence of an ordering, and
--!   is not deterministic under parallel aggregation. That is exactly what is
--!   wanted for the group-by-eq_term case (every value in a group is an
--!   encryption of the same plaintext, so any one represents the group) and it
--!   matches the eql_v2 original.
--!
--! @example
--! -- Group encrypted rows by encrypted equality and project the encrypted
--! -- column. GROUP BY eql_v3.eq_term(...) groups by the HMAC equality term;
--! -- grouped_value(...) returns a representative ciphertext for each group so
--! -- PostgreSQL does not reject the bare column reference.
--! SELECT eql_v3.grouped_value(encrypted_foo) AS encrypted_foo,
--!        count(*)
--! FROM some_table
--! GROUP BY eql_v3.eq_term(encrypted_foo);
--!
--! @see eql_v3_internal.grouped_value_sfunc
--! @see eql_v3.eq_term
CREATE AGGREGATE eql_v3.grouped_value(jsonb) (
  sfunc = eql_v3_internal.grouped_value_sfunc,
  stype = jsonb,
  combinefunc = eql_v3_internal.grouped_value_sfunc,
  parallel = safe
);
