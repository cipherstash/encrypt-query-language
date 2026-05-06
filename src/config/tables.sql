-- REQUIRE: src/config/types.sql

--! @file config/tables.sql
--! @brief Encryption configuration storage table
--!
--! Defines the main table for storing EQL v2 encryption configurations.
--! Each row represents a configuration specifying which tables/columns to encrypt
--! and what index types to use. Configurations progress through lifecycle states.
--!
--! @see config/types.sql for state ENUM definition
--! @see config/indexes.sql for state uniqueness constraints
--! @see config/constraints.sql for data validation


--! @brief Encryption configuration table
--!
--! Stores encryption configurations with their state and metadata.
--! The 'data' JSONB column contains the full configuration structure including
--! table/column mappings, index types, and casting rules.
--!
--! @note Only one configuration can be 'active', 'pending', or 'encrypting' at once
--! @note 'id' is auto-generated identity column
--! @note 'state' defaults to 'pending' for new configurations
--! @note 'data' validated by CHECK constraint (see config/constraints.sql)
CREATE TABLE IF NOT EXISTS public.eql_v2_configuration
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    state eql_v2_configuration_state NOT NULL DEFAULT 'pending',
    data jsonb,
    created_at timestamptz not null default current_timestamp,
    PRIMARY KEY(id)
);

