-- DANGEROUS
-- DROP TABLE IF EXISTS cs_configuration_v1 CASCADE;
-- ALTER TABLE cs_configuration_v1 RENAME TO cs_configuration_v1_;

DO $$
BEGIN
 EXECUTE format('ALTER TABLE IF EXISTS %I RENAME TO %I_%s', 'cs_configuration_v1','cs_configuration_v1_', to_char(current_date,'YYYYMMDD')::TEXT);
END
$$;

