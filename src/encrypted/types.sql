-- REQUIRE: src/schema.sql

--! @brief Composite type for encrypted column data
--!
--! Core type used for all encrypted columns in EQL. Stores encrypted data as JSONB
--! with the following structure:
--! - `c`: ciphertext (base64-encoded encrypted value)
--! - `i`: index terms (searchable metadata for encrypted searches)
--! - `k`: key ID (identifier for encryption key)
--! - `m`: metadata (additional encryption metadata)
--!
--! Created in public schema to persist independently of eql_v2 schema lifecycle.
--! Customer data columns use this type, so it must not be dropped if data exists.
--!
--! @note DO NOT DROP this type unless absolutely certain no encrypted data uses it
--! @see eql_v2.ciphertext
--! @see eql_v2.meta_data
--! @see eql_v2.add_column
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v2_encrypted') THEN
      CREATE DOMAIN public.eql_v2_encrypted AS jsonb;
    END IF;
  END
$$;









