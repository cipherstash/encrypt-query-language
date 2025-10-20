-- Configuration migration and activation functions
--
-- Depends on: config/types.sql (for eql_v2_configuration table)

-- Stub for ready_for_encryption (POC only)
CREATE FUNCTION eql_v2.ready_for_encryption()
  RETURNS boolean
AS $$
BEGIN
  -- POC: Always return true
  -- Real implementation would validate all configured columns exist
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Marks the currently pending configuration as encrypting
CREATE FUNCTION eql_v2.migrate_config()
  RETURNS boolean
AS $$
BEGIN
    IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'encrypting') THEN
      RAISE EXCEPTION 'An encryption is already in progress';
    END IF;

    IF NOT EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'pending') THEN
      RAISE EXCEPTION 'No pending configuration exists to encrypt';
    END IF;

    IF NOT eql_v2.ready_for_encryption() THEN
      RAISE EXCEPTION 'Some pending columns do not have an encrypted target';
    END IF;

    UPDATE public.eql_v2_configuration SET state = 'encrypting' WHERE state = 'pending';
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Activates the currently encrypting configuration
CREATE FUNCTION eql_v2.activate_config()
  RETURNS boolean
AS $$
BEGIN
    IF EXISTS (SELECT FROM public.eql_v2_configuration c WHERE c.state = 'encrypting') THEN
      UPDATE public.eql_v2_configuration SET state = 'inactive' WHERE state = 'active';
      UPDATE public.eql_v2_configuration SET state = 'active' WHERE state = 'encrypting';
      RETURN true;
    ELSE
      RAISE EXCEPTION 'No encrypting configuration exists to activate';
    END IF;
END;
$$ LANGUAGE plpgsql;
