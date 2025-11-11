-- AUTOMATICALLY GENERATED FILE
-- REQUIRE: src/schema.sql

--! @file common.sql
--! @brief Common utility functions
--!
--! Provides general-purpose utility functions used across EQL:
--! - Constant-time bytea comparison for security
--! - JSONB to bytea array conversion
--! - Logging helpers for debugging and testing


--! @brief Constant-time comparison of bytea values
--! @internal
--!
--! Compares two bytea values in constant time to prevent timing attacks.
--! Always checks all bytes even after finding differences, maintaining
--! consistent execution time regardless of where differences occur.
--!
--! @param a bytea First value to compare
--! @param b bytea Second value to compare
--! @return boolean True if values are equal
--!
--! @note Returns false immediately if lengths differ (length is not secret)
--! @note Used for secure comparison of cryptographic values
CREATE FUNCTION eql_v2.bytea_eq(a bytea, b bytea) RETURNS boolean AS $$
DECLARE
    result boolean;
    differing bytea;
BEGIN

    -- Check if the bytea values are the same length
    IF LENGTH(a) != LENGTH(b) THEN
        RETURN false;
    END IF;

    -- Compare each byte in the bytea values
    result := true;
    FOR i IN 1..LENGTH(a) LOOP
        IF SUBSTRING(a FROM i FOR 1) != SUBSTRING(b FROM i FOR 1) THEN
            result := result AND false;
        END IF;
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


--! @brief Convert JSONB hex array to bytea array
--! @internal
--!
--! Converts a JSONB array of hex-encoded strings into a PostgreSQL bytea array.
--! Used for deserializing binary data (like ORE terms) from JSONB storage.
--!
--! @param jsonb JSONB array of hex-encoded strings
--! @return bytea[] Array of decoded binary values
--!
--! @note Returns NULL if input is JSON null
--! @note Each array element is hex-decoded to bytea
CREATE FUNCTION eql_v2.jsonb_array_to_bytea_array(val jsonb)
RETURNS bytea[] AS $$
DECLARE
  terms_arr bytea[];
BEGIN
  IF jsonb_typeof(val) = 'null' THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(decode(value::text, 'hex')::bytea)
    INTO terms_arr
  FROM jsonb_array_elements_text(val) AS value;

  RETURN terms_arr;
END;
$$ LANGUAGE plpgsql;


--! @brief Log message for debugging
--!
--! Convenience function to emit log messages during testing and debugging.
--! Uses RAISE NOTICE to output messages to PostgreSQL logs.
--!
--! @param text Message to log
--!
--! @note Primarily used in tests and development
--! @see eql_v2.log(text, text) for contextual logging
CREATE FUNCTION eql_v2.log(s text)
    RETURNS void
AS $$
  BEGIN
    RAISE NOTICE '[LOG] %', s;
END;
$$ LANGUAGE plpgsql;


--! @brief Log message with context
--!
--! Overload of log function that includes context label for better
--! log organization during testing.
--!
--! @param ctx text Context label (e.g., test name, module name)
--! @param s text Message to log
--!
--! @note Format: "[LOG] {ctx} {message}"
--! @see eql_v2.log(text)
CREATE FUNCTION eql_v2.log(ctx text, s text)
    RETURNS void
AS $$
  BEGIN
    RAISE NOTICE '[LOG] % %', ctx, s;
END;
$$ LANGUAGE plpgsql;
