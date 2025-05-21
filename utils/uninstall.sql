-- Drop constraints on domains
ALTER DOMAIN cs_encrypted_v2 DROP CONSTRAINT IF EXISTS cs_encrypted_v2_check;
ALTER DOMAIN cs_configuration_data_v2 DROP CONSTRAINT IF EXISTS cs_configuration_data_v2_check;

-- Drop functions
DROP FUNCTION IF EXISTS cs_count_encrypted_with_active_config_v2(text, text);
DROP FUNCTION IF EXISTS cs_rename_encrypted_columns_v2();
DROP FUNCTION IF EXISTS cs_create_encrypted_columns_v2();
DROP FUNCTION IF EXISTS cs_ready_for_encryption_v2();
DROP FUNCTION IF EXISTS cs_select_target_columns_v2();
DROP FUNCTION IF EXISTS cs_select_pending_columns_v2();
DROP FUNCTION IF EXISTS _cs_diff_config_v2(jsonb, jsonb);
DROP FUNCTION IF EXISTS cs_add_column_v2(text, text);
DROP FUNCTION IF EXISTS cs_remove_column_v2(text, text);
DROP FUNCTION IF EXISTS cs_add_index_v2(text, text, text, text, jsonb);
DROP FUNCTION IF EXISTS cs_remove_index_v2(text, text, text);
DROP FUNCTION IF EXISTS cs_modify_index_v2(text, text, text, text, jsonb);
DROP FUNCTION IF EXISTS cs_encrypt_v2();
DROP FUNCTION IF EXISTS cs_activate_v2();
DROP FUNCTION IF EXISTS cs_discard_v2();
DROP FUNCTION IF EXISTS cs_refresh_encrypt_config();
DROP FUNCTION IF EXISTS _cs_config_default(jsonb);
DROP FUNCTION IF EXISTS _cs_config_match_default();
DROP FUNCTION IF EXISTS _cs_config_add_table(text, jsonb);
DROP FUNCTION IF EXISTS _cs_config_add_column(text, text, jsonb);
DROP FUNCTION IF EXISTS _cs_config_add_cast(text, text, text, jsonb);
DROP FUNCTION IF EXISTS _cs_config_add_index(text, text, text, jsonb, jsonb);
DROP FUNCTION IF EXISTS cs_ciphertext_v2(jsonb);
DROP FUNCTION IF EXISTS cs_ciphertext_v2_v0(jsonb);
DROP FUNCTION IF EXISTS cs_ciphertext_v2_v0_0(jsonb);
DROP FUNCTION IF EXISTS cs_match_v2(jsonb);
DROP FUNCTION IF EXISTS cs_match_v2_v0(jsonb);
DROP FUNCTION IF EXISTS cs_match_v2_v0_0(jsonb);
DROP FUNCTION IF EXISTS cs_unique_v2(jsonb);
DROP FUNCTION IF EXISTS cs_unique_v2_v0(jsonb);
DROP FUNCTION IF EXISTS cs_unique_v2_v0_0(jsonb);
DROP FUNCTION IF EXISTS cs_ste_vec_v2(jsonb);
DROP FUNCTION IF EXISTS cs_ste_vec_v2_v0(jsonb);
DROP FUNCTION IF EXISTS cs_ste_vec_v2_v0_0(jsonb);
DROP FUNCTION IF EXISTS cs_ore_64_8_v2(jsonb);
DROP FUNCTION IF EXISTS cs_ore_64_8_v2_v0(jsonb);
DROP FUNCTION IF EXISTS cs_ore_64_8_v2_v0_0(jsonb);
DROP FUNCTION IF EXISTS _cs_text_to_ore_64_8_v2_term_v2_0(text) CASCADE;
DROP FUNCTION IF EXISTS cs_check_encrypted_v2(jsonb);
DROP FUNCTION IF EXISTS _cs_encrypted_check_kind(jsonb);
DROP FUNCTION IF EXISTS _cs_config_check_indexes(jsonb);
DROP FUNCTION IF EXISTS _cs_config_check_cast(jsonb);

-- Drop cast
DROP CAST IF EXISTS (text AS ore_64_8_v2_term);

-- Drop indexes
DROP INDEX IF EXISTS cs_configuration_v2_index_active;
DROP INDEX IF EXISTS cs_configuration_v2_index_pending;
DROP INDEX IF EXISTS cs_configuration_v2_index_encrypting;

-- Drop table
DROP TABLE IF EXISTS cs_configuration_v2;

-- Drop domains
DROP DOMAIN IF EXISTS cs_match_index_v2;
DROP DOMAIN IF EXISTS cs_unique_index_v2;
DROP DOMAIN IF EXISTS cs_ste_vec_index_v2;
DROP DOMAIN IF EXISTS cs_encrypted_v2;  -- Note: This domain cannot be dropped if it's in use
DROP DOMAIN IF EXISTS cs_configuration_data_v2;

-- Drop type
DROP TYPE IF EXISTS cs_configuration_state_v2;
