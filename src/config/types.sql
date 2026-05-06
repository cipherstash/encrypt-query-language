--! @file config/types.sql
--! @brief Configuration state type definition
--!
--! Defines the ENUM type for tracking encryption configuration lifecycle states.
--! The configuration table uses this type to manage transitions between states
--! during setup, activation, and encryption operations.
--!
--! @note CREATE TYPE does not support IF NOT EXISTS, so wrapped in DO block
--! @note Configuration data stored as JSONB directly, not as DOMAIN
--! @see config/tables.sql


--! @brief Configuration lifecycle state
--!
--! Defines valid states for encryption configurations in the eql_v2_configuration table.
--! Configurations transition through these states during setup and activation.
--!
--! @note Only one configuration can be in 'active', 'pending', or 'encrypting' state at once
--! @see config/indexes.sql for uniqueness enforcement
--! @see config/tables.sql for usage in eql_v2_configuration table
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'eql_v2_configuration_state') THEN
      CREATE TYPE public.eql_v2_configuration_state AS ENUM ('active', 'inactive', 'encrypting', 'pending');
    END IF;
  END
$$;

