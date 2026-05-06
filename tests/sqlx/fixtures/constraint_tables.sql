-- Fixture for constraint tests
DROP TABLE IF EXISTS constrained CASCADE;
CREATE TABLE constrained (
    id bigint GENERATED ALWAYS AS IDENTITY,
    unique_field eql_v2_encrypted UNIQUE,
    not_null_field eql_v2_encrypted NOT NULL,
    check_field eql_v2_encrypted CHECK (check_field IS NOT NULL),
    PRIMARY KEY(id)
);
