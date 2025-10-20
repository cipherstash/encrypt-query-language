-- REQUIRE: src/config/types.sql

--
--
-- CREATE the eql_v2_configuration TABLE
--
CREATE TABLE IF NOT EXISTS public.eql_v2_configuration
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    state eql_v2_configuration_state NOT NULL DEFAULT 'pending',
    data jsonb,
    created_at timestamptz not null default current_timestamp,
    PRIMARY KEY(id)
);

