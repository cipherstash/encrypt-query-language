-- Fixture for config tests

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY,
    name eql_v2_encrypted,
    PRIMARY KEY(id)
);

DROP TABLE IF EXISTS blah CASCADE;
CREATE TABLE blah (
    id bigint GENERATED ALWAYS AS IDENTITY,
    vtha eql_v2_encrypted,
    PRIMARY KEY(id)
);
