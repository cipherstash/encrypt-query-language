-- Stub for check_encrypted function (minimal implementation for POC)
-- Full implementation would validate encrypted data structure

CREATE FUNCTION eql_v2.check_encrypted(val eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
  -- For POC: Just check that the data field is JSONB
  RETURN (val).data IS NOT NULL;
END;
$$ LANGUAGE plpgsql;
