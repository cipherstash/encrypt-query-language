DROP TABLE IF EXISTS cs_configuration_v1 CASCADE;
ALTER DOMAIN cs_configuration_data_v1 DROP CONSTRAINT IF EXISTS cs_configuration_data_v1_check;
ALTER DOMAIN cs_encrypted_v1 DROP CONSTRAINT IF EXISTS cs_encrypted_v1_check;
