-- REQUIRE: src/schema.sql

-- eql_v1_encrypted is a column type
--  defined as jsonb for maximum portability of encrypted data
--  defined in the public schema as it cannot be dropped if in use
DO $$
  BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v1_encrypted') THEN
        CREATE DOMAIN public.eql_v1_encrypted AS jsonb;
    END IF;
  END
$$;


-- eql_v1.encrypted is an internal composite type
-- eql_v1_encrypted data is cast to eql_v1.encrypted for use in EQL functions
DROP TYPE IF EXISTS eql_v1.encrypted;
CREATE TYPE eql_v1.encrypted AS (
  data jsonb
);




