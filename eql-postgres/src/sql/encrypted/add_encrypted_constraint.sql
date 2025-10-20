-- Add constraint to verify encrypted column structure
--
-- Depends on: check_encrypted function

CREATE FUNCTION eql_v2.add_encrypted_constraint(table_name TEXT, column_name TEXT)
  RETURNS void
AS $$
BEGIN
  EXECUTE format(
    'ALTER TABLE %I ADD CONSTRAINT eql_v2_encrypted_check_%I CHECK (eql_v2.check_encrypted(%I))',
    table_name,
    column_name,
    column_name
  );
END;
$$ LANGUAGE plpgsql;
