-- REQUIRE: src/schema.sql

--! @brief HMAC-SHA256 index term type
--!
--! Domain type representing HMAC-SHA256 hash values.
--! Used for exact-match encrypted searches via the 'unique' index type.
--! The hash is stored in the 'hm' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @note This is a transient type used only during query execution
CREATE DOMAIN eql_v2.hmac_256 AS text;
