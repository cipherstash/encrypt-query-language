--
-- cs_configuration_data_v2 is a jsonb column that stores the actual configuration
--
-- For some reason CREATE DOMAIN and CREATE TYPE do not support IF NOT EXISTS
-- Types cannot be dropped if used by a table, and we never drop the configuration table
-- DOMAIN constraints are added separately and not tied to DOMAIN creation
--
-- DO $$
--   BEGIN
--     IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'configuration_data') THEN
--       CREATE DOMAIN eql_v2.configuration_data AS JSONB;
--     END IF;
--   END
-- $$;

--
-- cs_configuration_state_v2 is an ENUM that defines the valid configuration states
-- --
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v2_configuration_state') THEN
      CREATE TYPE public.eql_v2_configuration_state AS ENUM ('active', 'inactive', 'encrypting', 'pending');
    END IF;
  END
$$;

