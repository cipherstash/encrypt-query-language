-- REQUIRE: src/schema.sql
-- REQUIRE: src/config/tables.sql


--! @file config/indexes.sql
--! @brief Configuration state uniqueness indexes
--!
--! Creates partial unique indexes to enforce that only one configuration
--! can be in 'active', 'pending', or 'encrypting' state at any time.
--! Multiple 'inactive' configurations are allowed.
--!
--! @note Uses partial indexes (WHERE clauses) for efficiency
--! @note Prevents conflicting configurations from being active simultaneously
--! @see config/types.sql for state definitions


--! @brief Unique active configuration constraint
--! @note Only one configuration can be 'active' at once
CREATE UNIQUE INDEX ON public.eql_v2_configuration (state) WHERE state = 'active';

--! @brief Unique pending configuration constraint
--! @note Only one configuration can be 'pending' at once
CREATE UNIQUE INDEX ON public.eql_v2_configuration (state) WHERE state = 'pending';

--! @brief Unique encrypting configuration constraint
--! @note Only one configuration can be 'encrypting' at once
CREATE UNIQUE INDEX ON public.eql_v2_configuration (state) WHERE state = 'encrypting';

