-- DANGEROUS
-- DROP TABLE IF EXISTS eql_v1_configuration CASCADE;
-- ALTER TABLE eql_v1_configuration RENAME TO eql_v1_configuration_;

DO $$
BEGIN
 EXECUTE format('ALTER TABLE IF EXISTS %I RENAME TO %I_%s', 'eql_v1_configuration','eql_v1_configuration_', to_char(current_date,'YYYYMMDD')::TEXT);
END
$$;

