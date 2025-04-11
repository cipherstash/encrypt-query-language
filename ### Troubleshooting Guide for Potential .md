### Troubleshooting Guide for Potential Constraint Failures



This guide provides information on potential constraint failures related to the encrypted json payload of EQL.
It explains what the current errors mean and what you can do to fix them.


The database constraint cs_configuration_data_v1_check

1. _cs_config_check_v(VALUE)
Error Message:

Meaning: This error indicates that the version value in the configuration is not valid.

Fix: Ensure that the version value in the configuration JSON is correct and matches the expected format. The version should be a valid integer or string that the function _cs_config_check_v can recognize.

2. _cs_config_check_tables(VALUE)
Error Message:

Meaning: This error indicates that the table structure in the configuration JSON is not valid.

Fix: Verify that the table structure in the configuration JSON is correctly defined. Ensure that all required fields are present and that the structure adheres to the expected schema. The function _cs_config_check_tables checks for the presence and correctness of table definitions.

3. _cs_config_check_cast(VALUE)
Error Message:

Meaning: This error indicates that the cast value in the configuration JSON is not valid.

Fix: Check the cast values in the configuration JSON to ensure they are valid. The function _cs_config_check_cast validates the cast values against a predefined list of acceptable values. Ensure that the cast values are correctly specified and match the expected types.

4. _cs_config_check_indexes(VALUE)
Error Message:

Meaning: This error indicates that the index structure in the configuration JSON is not valid.

Fix: Review the index structure in the configuration JSON to ensure it is correctly defined. The function _cs_config_check_indexes checks for the presence and correctness of index definitions. Ensure that all indexes are either empty or contain only keys from a list of valid values ({match, ore, unique, ste_vec}).

General Steps to Fix Configuration Errors
Validate JSON Structure:

Ensure that the JSON structure is well-formed and adheres to the expected schema.
Use JSON validation tools to check for syntax errors.
Check Required Fields:

Verify that all required fields are present in the configuration JSON.
Ensure that the field names and types match the expected values.
Review Function Definitions:

Review the definitions of the functions _cs_config_check_v, _cs_config_check_tables, _cs_config_check_cast, and _cs_config_check_indexes to understand the validation logic.
Ensure that the configuration JSON meets the criteria defined in these functions.
Test with Sample Data:

Test the configuration JSON with sample data to identify and fix errors.
Use known valid configurations as a reference to compare and correct the current configuration.
By following this troubleshooting guide, you can identify and fix potential constraint failures related to the configuration checks in the 020-config-schema.sql file.