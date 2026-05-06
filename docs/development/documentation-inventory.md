# SQL Documentation Inventory

Generated: Mon 27 Oct 2025 11:39:50 AEDT

## src/blake3/compare.sql

- CREATE FUNCTION eql_v2.compare_blake3(a eql_v2_encrypted, b eql_v2_encrypted)

## src/blake3/functions.sql

- CREATE FUNCTION eql_v2.blake3(val jsonb)
- CREATE FUNCTION eql_v2.blake3(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.has_blake3(val jsonb)
- CREATE FUNCTION eql_v2.has_blake3(val eql_v2_encrypted)

## src/blake3/types.sql

- CREATE DOMAIN eql_v2.blake3 AS text;

## src/bloom_filter/functions.sql

- CREATE FUNCTION eql_v2.bloom_filter(val jsonb)
- CREATE FUNCTION eql_v2.bloom_filter(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.has_bloom_filter(val jsonb)
- CREATE FUNCTION eql_v2.has_bloom_filter(val eql_v2_encrypted)

## src/bloom_filter/types.sql

- CREATE DOMAIN eql_v2.bloom_filter AS smallint[];

## src/common.sql

- CREATE FUNCTION eql_v2.bytea_eq(a bytea, b bytea) RETURNS boolean AS $$
- CREATE FUNCTION eql_v2.jsonb_array_to_bytea_array(val jsonb)
- CREATE FUNCTION eql_v2.log(s text)
- CREATE FUNCTION eql_v2.log(ctx text, s text)

## src/config/constraints.sql

- CREATE FUNCTION eql_v2.config_get_indexes(val jsonb)
- CREATE FUNCTION eql_v2.config_check_indexes(val jsonb)
- CREATE FUNCTION eql_v2.config_check_cast(val jsonb)
- CREATE FUNCTION eql_v2.config_check_tables(val jsonb)
- CREATE FUNCTION eql_v2.config_check_version(val jsonb)

## src/config/functions.sql

- CREATE FUNCTION eql_v2.add_search_config(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}', migrating boolean DEFAULT false)
- CREATE FUNCTION eql_v2.remove_search_config(table_name text, column_name text, index_name text, migrating boolean DEFAULT false)
- CREATE FUNCTION eql_v2.modify_search_config(table_name text, column_name text, index_name text, cast_as text DEFAULT 'text', opts jsonb DEFAULT '{}', migrating boolean DEFAULT false)
- CREATE FUNCTION eql_v2.migrate_config()
- CREATE FUNCTION eql_v2.activate_config()
- CREATE FUNCTION eql_v2.discard()
- CREATE FUNCTION eql_v2.add_column(table_name text, column_name text, cast_as text DEFAULT 'text', migrating boolean DEFAULT false)
- CREATE FUNCTION eql_v2.remove_column(table_name text, column_name text, migrating boolean DEFAULT false)
- CREATE FUNCTION eql_v2.reload_config()
- CREATE FUNCTION eql_v2.config() RETURNS TABLE (

## src/config/functions_private.sql

- CREATE FUNCTION eql_v2.config_default(config jsonb)
- CREATE FUNCTION eql_v2.config_add_table(table_name text, config jsonb)
- CREATE FUNCTION eql_v2.config_add_column(table_name text, column_name text, config jsonb)
- CREATE FUNCTION eql_v2.config_add_cast(table_name text, column_name text, cast_as text, config jsonb)
- CREATE FUNCTION eql_v2.config_add_index(table_name text, column_name text, index_name text, opts jsonb, config jsonb)
- CREATE FUNCTION eql_v2.config_match_default()

## src/config/indexes.sql


## src/config/tables.sql


## src/config/types.sql


## src/crypto.sql


## src/encrypted/aggregates.sql

- CREATE FUNCTION eql_v2.min(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE AGGREGATE eql_v2.min(eql_v2_encrypted)
- CREATE FUNCTION eql_v2.max(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE AGGREGATE eql_v2.max(eql_v2_encrypted)

## src/encrypted/casts.sql

- CREATE FUNCTION eql_v2.to_encrypted(data jsonb)
- CREATE FUNCTION eql_v2.to_encrypted(data text)
- CREATE FUNCTION eql_v2.to_jsonb(e public.eql_v2_encrypted)

## src/encrypted/compare.sql

- CREATE FUNCTION eql_v2.compare_literal(a eql_v2_encrypted, b eql_v2_encrypted)

## src/encrypted/constraints.sql

- CREATE FUNCTION eql_v2._encrypted_check_i(val jsonb)
- CREATE FUNCTION eql_v2._encrypted_check_i_ct(val jsonb)
- CREATE FUNCTION eql_v2._encrypted_check_v(val jsonb)
- CREATE FUNCTION eql_v2._encrypted_check_c(val jsonb)
- CREATE FUNCTION eql_v2.check_encrypted(val jsonb)
- CREATE FUNCTION eql_v2.check_encrypted(val eql_v2_encrypted)

## src/encrypted/functions.sql

- CREATE FUNCTION eql_v2.ciphertext(val jsonb)
- CREATE FUNCTION eql_v2.ciphertext(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2._first_grouped_value(jsonb, jsonb)
- CREATE AGGREGATE eql_v2.grouped_value(jsonb) (
- CREATE FUNCTION eql_v2.add_encrypted_constraint(table_name TEXT, column_name TEXT)
- CREATE FUNCTION eql_v2.remove_encrypted_constraint(table_name TEXT, column_name TEXT)
- CREATE FUNCTION eql_v2.meta_data(val jsonb)
- CREATE FUNCTION eql_v2.meta_data(val eql_v2_encrypted)

## src/encrypted/types.sql


## src/encryptindex/functions.sql

- CREATE FUNCTION eql_v2.diff_config(a JSONB, b JSONB)
- CREATE FUNCTION eql_v2.select_pending_columns()
- CREATE FUNCTION eql_v2.select_target_columns()
- CREATE FUNCTION eql_v2.ready_for_encryption()
- CREATE FUNCTION eql_v2.create_encrypted_columns()
- CREATE FUNCTION eql_v2.rename_encrypted_columns()
- CREATE FUNCTION eql_v2.count_encrypted_with_active_config(table_name TEXT, column_name TEXT)

## src/hmac_256/compare.sql

- CREATE FUNCTION eql_v2.compare_hmac_256(a eql_v2_encrypted, b eql_v2_encrypted)

## src/hmac_256/functions.sql

- CREATE FUNCTION eql_v2.hmac_256(val jsonb)
- CREATE FUNCTION eql_v2.has_hmac_256(val jsonb)
- CREATE FUNCTION eql_v2.has_hmac_256(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.hmac_256(val eql_v2_encrypted)

## src/hmac_256/types.sql

- CREATE DOMAIN eql_v2.hmac_256 AS text;

## src/jsonb/functions.sql

- CREATE FUNCTION eql_v2.jsonb_path_query(val jsonb, selector text)
- CREATE FUNCTION eql_v2.jsonb_path_query(val eql_v2_encrypted, selector eql_v2_encrypted)
- CREATE FUNCTION eql_v2.jsonb_path_query(val eql_v2_encrypted, selector text)
- CREATE FUNCTION eql_v2.jsonb_path_exists(val jsonb, selector text)
- CREATE FUNCTION eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector eql_v2_encrypted)
- CREATE FUNCTION eql_v2.jsonb_path_exists(val eql_v2_encrypted, selector text)
- CREATE FUNCTION eql_v2.jsonb_path_query_first(val jsonb, selector text)
- CREATE FUNCTION eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector eql_v2_encrypted)
- CREATE FUNCTION eql_v2.jsonb_path_query_first(val eql_v2_encrypted, selector text)
- CREATE FUNCTION eql_v2.jsonb_array_length(val jsonb)
- CREATE FUNCTION eql_v2.jsonb_array_length(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.jsonb_array_elements(val jsonb)
- CREATE FUNCTION eql_v2.jsonb_array_elements(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.jsonb_array_elements_text(val jsonb)
- CREATE FUNCTION eql_v2.jsonb_array_elements_text(val eql_v2_encrypted)

## src/operators/->.sql

- CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector text)
- CREATE OPERATOR ->(
- CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector eql_v2_encrypted)
- CREATE OPERATOR ->(
- CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector integer)
- CREATE OPERATOR ->(

## src/operators/->>.sql

- CREATE FUNCTION eql_v2."->>"(e eql_v2_encrypted, selector text)
- CREATE OPERATOR ->> (
- CREATE FUNCTION eql_v2."->>"(e eql_v2_encrypted, selector eql_v2_encrypted)
- CREATE OPERATOR ->> (

## src/operators/<.sql

- CREATE FUNCTION eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2."<"(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR <(
- CREATE FUNCTION eql_v2."<"(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR <(
- CREATE FUNCTION eql_v2."<"(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR <(

## src/operators/<=.sql

- CREATE FUNCTION eql_v2.lte(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2."<="(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR <=(
- CREATE FUNCTION eql_v2."<="(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR <=(
- CREATE FUNCTION eql_v2."<="(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR <=(

## src/operators/<>.sql

- CREATE FUNCTION eql_v2.neq(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2."<>"(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR <> (
- CREATE FUNCTION eql_v2."<>"(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR <> (
- CREATE FUNCTION eql_v2."<>"(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR <> (

## src/operators/<@.sql

- CREATE FUNCTION eql_v2."<@"(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR <@(

## src/operators/=.sql

- CREATE FUNCTION eql_v2.eq(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR = (
- CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR = (
- CREATE FUNCTION eql_v2."="(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR = (

## src/operators/>.sql

- CREATE FUNCTION eql_v2.gt(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2.">"(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR >(
- CREATE FUNCTION eql_v2.">"(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR >(
- CREATE FUNCTION eql_v2.">"(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR >(

## src/operators/>=.sql

- CREATE FUNCTION eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR >=(
- CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR >=(
- CREATE FUNCTION eql_v2.">="(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR >=(

## src/operators/@>.sql

- CREATE FUNCTION eql_v2."@>"(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR @>(

## src/operators/compare.sql

- CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted)

## src/operators/operator_class.sql

- CREATE OPERATOR FAMILY eql_v2.encrypted_operator_family USING btree;
- CREATE OPERATOR CLASS eql_v2.encrypted_operator_class DEFAULT FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator_family AS

## src/operators/order_by.sql

- CREATE FUNCTION eql_v2.order_by(a eql_v2_encrypted)

## src/operators/~~.sql

- CREATE FUNCTION eql_v2.like(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2.ilike(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE FUNCTION eql_v2."~~"(a eql_v2_encrypted, b eql_v2_encrypted)
- CREATE OPERATOR ~~(
- CREATE OPERATOR ~~*(
- CREATE FUNCTION eql_v2."~~"(a eql_v2_encrypted, b jsonb)
- CREATE OPERATOR ~~(
- CREATE OPERATOR ~~*(
- CREATE FUNCTION eql_v2."~~"(a jsonb, b eql_v2_encrypted)
- CREATE OPERATOR ~~(
- CREATE OPERATOR ~~*(

## src/ore_block_u64_8_256/casts.sql

- CREATE FUNCTION eql_v2.text_to_ore_block_u64_8_256_term(t text)

## src/ore_block_u64_8_256/compare.sql

- CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256(a eql_v2_encrypted, b eql_v2_encrypted)

## src/ore_block_u64_8_256/functions.sql

- CREATE FUNCTION eql_v2.jsonb_array_to_ore_block_u64_8_256(val jsonb)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256(val jsonb)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.has_ore_block_u64_8_256(val jsonb)
- CREATE FUNCTION eql_v2.has_ore_block_u64_8_256(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256_term(a eql_v2.ore_block_u64_8_256_term, b eql_v2.ore_block_u64_8_256_term)
- CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256_terms(a eql_v2.ore_block_u64_8_256_term[], b eql_v2.ore_block_u64_8_256_term[])
- CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256_terms(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)

## src/ore_block_u64_8_256/operator_class.sql

- CREATE OPERATOR FAMILY eql_v2.ore_block_u64_8_256_operator_family USING btree;
- CREATE OPERATOR CLASS eql_v2.ore_block_u64_8_256_operator_class DEFAULT FOR TYPE eql_v2.ore_block_u64_8_256 USING btree FAMILY eql_v2.ore_block_u64_8_256_operator_family  AS

## src/ore_block_u64_8_256/operators.sql

- CREATE FUNCTION eql_v2.ore_block_u64_8_256_eq(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256_neq(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256_lt(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256_lte(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256_gt(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
- CREATE FUNCTION eql_v2.ore_block_u64_8_256_gte(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256)
- CREATE OPERATOR = (
- CREATE OPERATOR <> (
- CREATE OPERATOR > (
- CREATE OPERATOR < (
- CREATE OPERATOR <= (
- CREATE OPERATOR >= (

## src/ore_block_u64_8_256/types.sql

- CREATE TYPE eql_v2.ore_block_u64_8_256_term AS (
- CREATE TYPE eql_v2.ore_block_u64_8_256 AS (

## src/ore_cllw_u64_8/compare.sql

- CREATE FUNCTION eql_v2.compare_ore_cllw_u64_8(a eql_v2_encrypted, b eql_v2_encrypted)

## src/ore_cllw_u64_8/functions.sql

- CREATE FUNCTION eql_v2.ore_cllw_u64_8(val jsonb)
- CREATE FUNCTION eql_v2.ore_cllw_u64_8(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.has_ore_cllw_u64_8(val jsonb)
- CREATE FUNCTION eql_v2.has_ore_cllw_u64_8(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.compare_ore_cllw_term_bytes(a bytea, b bytea)

## src/ore_cllw_u64_8/types.sql

- CREATE TYPE eql_v2.ore_cllw_u64_8 AS (

## src/ore_cllw_var_8/compare.sql

- CREATE FUNCTION eql_v2.compare_ore_cllw_var_8(a eql_v2_encrypted, b eql_v2_encrypted)

## src/ore_cllw_var_8/functions.sql

- CREATE FUNCTION eql_v2.ore_cllw_var_8(val jsonb)
- CREATE FUNCTION eql_v2.ore_cllw_var_8(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.has_ore_cllw_var_8(val jsonb)
- CREATE FUNCTION eql_v2.has_ore_cllw_var_8(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.compare_ore_cllw_var_8_term(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8)

## src/ore_cllw_var_8/types.sql

- CREATE TYPE eql_v2.ore_cllw_var_8 AS (

## src/schema.sql


## src/ste_vec/functions.sql

- CREATE FUNCTION eql_v2.ste_vec(val jsonb)
- CREATE FUNCTION eql_v2.ste_vec(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.is_ste_vec_value(val jsonb)
- CREATE FUNCTION eql_v2.is_ste_vec_value(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.to_ste_vec_value(val jsonb)
- CREATE FUNCTION eql_v2.to_ste_vec_value(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.selector(val jsonb)
- CREATE FUNCTION eql_v2.selector(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.is_ste_vec_array(val jsonb)
- CREATE FUNCTION eql_v2.is_ste_vec_array(val eql_v2_encrypted)
- CREATE FUNCTION eql_v2.ste_vec_contains(a eql_v2_encrypted[], b eql_v2_encrypted)
- CREATE FUNCTION eql_v2.ste_vec_contains(a eql_v2_encrypted, b eql_v2_encrypted)

## Summary

- Total files: 52
- Total CREATE statements: 219
