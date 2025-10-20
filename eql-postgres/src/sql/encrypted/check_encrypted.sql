-- Stub for check_encrypted function (minimal implementation for POC)
-- Full implementation would validate encrypted data structure

CREATE FUNCTION eql_v2.check_encrypted(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
  -- For POC: Just check that it's a JSONB object
  RETURN jsonb_typeof(val) = 'object';
END;
$$ LANGUAGE plpgsql;
