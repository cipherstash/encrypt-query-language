-- Install pgTAP extension for testing
CREATE EXTENSION IF NOT EXISTS pgtap;

-- Verify pgTAP installation
SELECT * FROM pg_available_extensions WHERE name = 'pgtap';
