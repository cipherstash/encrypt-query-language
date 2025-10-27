--! @file schema.sql
--! @brief EQL v2 schema creation
--!
--! Creates the eql_v2 schema which contains all Encrypt Query Language
--! functions, types, and tables. Drops existing schema if present to
--! support clean reinstallation.
--!
--! @warning DROP SCHEMA CASCADE will remove all objects in the schema
--! @note All EQL objects (functions, types, tables) reside in eql_v2 schema

--! @brief Drop existing EQL v2 schema
--! @warning CASCADE will drop all dependent objects
DROP SCHEMA IF EXISTS eql_v2 CASCADE;

--! @brief Create EQL v2 schema
--! @note All EQL functions and types will be created in this schema
CREATE SCHEMA eql_v2;
