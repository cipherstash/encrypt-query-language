
DO $$
BEGIN
 EXECUTE format('ALTER TABLE IF EXISTS %I RENAME TO %I_%s', 'eql_v2_configuration','eql_v2_configuration_', to_char(current_date,'YYYYMMDD')::TEXT);
END
$$;

ALTER TABLE public.eql_v2_configuration DROP CONSTRAINT IF EXISTS eql_v2_configuration_data_check;

DROP SCHEMA IF EXISTS eql_v2 CASCADE;
