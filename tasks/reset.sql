-- !!! Only used during tests !!
-- Fully clean out the database between test runs

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

DROP SCHEMA eql_v2 CASCADE;
CREATE SCHEMA eql_v2;
GRANT ALL ON SCHEMA eql_v2 TO postgres;
GRANT ALL ON SCHEMA eql_v2 TO public;
