-- REQUIRE: src/v3/schema.sql

--! @file v3/sem/bloom_filter/types.sql
--! @brief Self-contained eql_v3 Bloom-filter SEM index-term type.

--! @brief Bloom-filter index term: a bit array stored as smallint[].
--!
--! Backs the `match` capability (`@>` / `<@`) on `eql_v3_internal.text_match`. The
--! filter is read from the `bf` field of an encrypted jsonb payload. Native
--! `smallint[]` array-containment (`@>`/`<@`) is inherited through the domain,
--! so this type needs no custom operators.
--!
--! @note Self-contained: references no eql_v2 symbol.
CREATE DOMAIN eql_v3_internal.bloom_filter AS smallint[];
