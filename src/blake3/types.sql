-- REQUIRE: src/schema.sql

--! @brief Blake3 hash index term type
--!
--! Domain type representing Blake3 cryptographic hash values.
--! Used for exact-match encrypted searches via the 'unique' index type.
--! The hash is stored in the 'b3' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @note This is a transient type used only during query execution
CREATE DOMAIN eql_v2.blake3 AS text;
