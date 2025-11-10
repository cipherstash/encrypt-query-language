-- Fixture for encryptindex tests
-- Referenced by: tests/sqlx/tests/encryptindex_tests.rs
--
-- Creates a users table with plaintext columns for testing encrypted column
-- creation and management operations

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    email INT,
    PRIMARY KEY(id)
);
