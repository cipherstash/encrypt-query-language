-- REQUIRE: src/v3/schema.sql

--! @file v3/common.sql
--! @brief Common utility functions for the self-contained eql_v3 surface.
--!
--! Forked from src/common.sql (design D7) so the eql_v3 ORE constructor owns the
--! one transitive helper it needs without reaching into another schema. The
--! eql_v2 original is unchanged.

--! @brief Convert JSONB hex array to bytea array
--! @internal
--!
--! Converts a JSONB array of hex-encoded strings into a PostgreSQL bytea array.
--! Used for deserializing binary data (like ORE terms) from JSONB storage.
--!
--! @param val jsonb JSONB array of hex-encoded strings
--! @return bytea[] Array of decoded binary values
--!
--! @note Returns NULL if input is JSON null
--! @note Each array element is hex-decoded to bytea
--! @note Inlinable `LANGUAGE sql` IMMUTABLE form (no `SET search_path`) so the
--!   planner can fold this per-encrypted-value helper into the calling query.
--!   This deliberately diverges from the v2 plpgsql equivalent (intentionally
--!   left unchanged): the `CASE WHEN jsonb_typeof(val) = 'array'` guard only
--!   evaluates the set-returning `jsonb_array_elements_text` for an array, so a
--!   non-array JSON scalar returns NULL here instead of raising "cannot extract
--!   elements from a scalar". Both callers only ever pass an array or JSON null
--!   (`val->'ob'`), so the divergence is unreachable in practice; JSON null and
--!   empty array still return NULL exactly as before.
CREATE FUNCTION eql_v3.jsonb_array_to_bytea_array(val jsonb)
RETURNS bytea[]
  IMMUTABLE
AS $$
  SELECT CASE WHEN jsonb_typeof(val) = 'array'
    THEN (
      SELECT array_agg(decode(value::text, 'hex')::bytea)
      FROM jsonb_array_elements_text(val) AS value
    )
    ELSE NULL
  END;
$$ LANGUAGE sql;

--! @internal Mark this hand-written helper inline-critical so the post-install
--! pin_search_path pass leaves it unpinned (no `SET search_path`), preserving
--! SQL-function inlining. It takes a bare `jsonb` arg (not a jsonb-backed
--! encrypted DOMAIN), so the structural skip in tasks/pin_search_path.sql does
--! not recognise it; this marker is the documented manual opt-in.
COMMENT ON FUNCTION eql_v3.jsonb_array_to_bytea_array(jsonb) IS
  'eql-inline-critical: per-encrypted-value ORE helper; must stay inlinable (unpinned search_path)';
