-- REQUIRE: src/config/tables.sql


--
-- Define partial indexes to ensure that there is only one active, pending and encrypting config at a time
--
CREATE UNIQUE INDEX IF NOT EXISTS configuration_index_active ON public.eql_v1_configuration (state) WHERE state = 'active';
CREATE UNIQUE INDEX IF NOT EXISTS configuration_index_pending ON public.eql_v1_configuration (state) WHERE state = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS configuration_index_encrypting ON public.eql_v1_configuration (state) WHERE state = 'encrypting';

