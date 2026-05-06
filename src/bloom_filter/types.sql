-- REQUIRE: src/schema.sql

--! @brief Bloom filter index term type
--!
--! Domain type representing Bloom filter bit arrays stored as smallint arrays.
--! Used for pattern-match encrypted searches via the 'match' index type.
--! The filter is stored in the 'bf' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2."~~"
--! @note This is a transient type used only during query execution
CREATE DOMAIN eql_v2.bloom_filter AS smallint[];

