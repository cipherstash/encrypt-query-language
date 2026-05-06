-- REQUIRE: src/schema.sql

--! @file crypto.sql
--! @brief PostgreSQL pgcrypto extension enablement
--!
--! Enables the pgcrypto extension which provides cryptographic functions
--! used by EQL for hashing and other cryptographic operations.
--!
--! Installs pgcrypto into the `extensions` schema (Supabase convention) to
--! avoid the `extension_in_public` lint. Every EQL function that uses
--! pgcrypto has `pg_catalog, extensions, public` on its `search_path`, so a
--! pre-existing install in `public` keeps working — and a pre-existing
--! install anywhere else will be rejected at install time rather than
--! failing later inside an encrypted comparison.
--!
--! @note pgcrypto provides functions like digest(), hmac(), gen_random_bytes()
--! @note If pgcrypto is already installed in `public`, EQL works but emits
--!       a NOTICE recommending `ALTER EXTENSION pgcrypto SET SCHEMA extensions`.
--! @note If pgcrypto is already installed in any other schema, install
--!       fails. Relocate it first with `ALTER EXTENSION pgcrypto SET SCHEMA
--!       extensions` (or move it into `public` if compatibility with other
--!       consumers requires it).

--! @brief Create extensions schema (Supabase convention)
CREATE SCHEMA IF NOT EXISTS extensions;

--! @brief Enable pgcrypto extension and validate its schema
DO $$
DECLARE
  pgcrypto_schema name;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION pgcrypto WITH SCHEMA extensions;
  END IF;

  SELECT n.nspname INTO pgcrypto_schema
  FROM pg_extension e
  JOIN pg_namespace n ON n.oid = e.extnamespace
  WHERE e.extname = 'pgcrypto';

  IF pgcrypto_schema = 'extensions' THEN
    -- expected location, nothing to say
    NULL;
  ELSIF pgcrypto_schema = 'public' THEN
    RAISE NOTICE
      'pgcrypto is installed in the `public` schema. EQL works against this layout, '
      'but Supabase splinter will flag it as `extension_in_public`. Move it with: '
      'ALTER EXTENSION pgcrypto SET SCHEMA extensions';
  ELSE
    RAISE EXCEPTION
      'pgcrypto is installed in schema `%`, which is not on the EQL function search_path '
      '(pg_catalog, extensions, public). EQL cryptographic operations would fail at '
      'runtime. Relocate the extension before installing EQL: '
      'ALTER EXTENSION pgcrypto SET SCHEMA extensions',
      pgcrypto_schema;
  END IF;
END $$;
