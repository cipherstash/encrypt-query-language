-- REQUIRE: src/schema.sql

--! @file crypto.sql
--! @brief PostgreSQL pgcrypto extension enablement
--!
--! Enables the pgcrypto extension which provides cryptographic functions
--! used by EQL for hashing and other cryptographic operations.
--!
--! @note pgcrypto provides functions like digest(), hmac(), gen_random_bytes()
--! @note IF NOT EXISTS prevents errors if extension already enabled

--! @brief Enable pgcrypto extension
--! @note Provides cryptographic functions for hashing and random number generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

