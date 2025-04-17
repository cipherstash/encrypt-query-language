
DO $$
BEGIN
 EXECUTE format('ALTER TABLE IF EXISTS %I RENAME TO %I_%s', 'eql_v1_configuration','eql_v1_configuration_', to_char(current_date,'YYYYMMDD')::TEXT);
END
$$;

DROP SCHEMA IF EXISTS eql_v1 CASCADE;