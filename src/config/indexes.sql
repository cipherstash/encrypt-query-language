-- REQUIRE: src/schema.sql
-- REQUIRE: src/config/tables.sql


--
-- Define partial indexes to ensure that there is only one active, pending and encrypting config at a time
--
CREATE UNIQUE INDEX ON public.eql_v1_configuration (state) WHERE state = 'active';
CREATE UNIQUE INDEX ON public.eql_v1_configuration (state) WHERE state = 'pending';
CREATE UNIQUE INDEX ON public.eql_v1_configuration (state) WHERE state = 'encrypting';

