-- Uninstall the standalone eql_v3 surface. CASCADE removes the domains, SEM
-- types, operators, opclass, and any columns typed with the eql_v3 domains.
DROP SCHEMA IF EXISTS eql_v3 CASCADE;
