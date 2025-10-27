# SQL Documentation Templates

## Template: Public Function

```sql
--! @brief [One sentence description]
--!
--! [Detailed description paragraph explaining purpose,
--! behavior, and any important context]
--!
--! @param param_name [Type] [Description]
--! @param param_name [Type] [Description with default: DEFAULT value]
--! @return [Return type] [Description of return value structure]
--! @throws [Condition that triggers exception]
--!
--! @example
--! -- [Example description]
--! SELECT eql_v2.function_name('value1', 'value2');
--!
--! @see eql_v2.related_function
CREATE FUNCTION eql_v2.function_name(...)
```

## Template: Private/Internal Function

```sql
--! @brief [One sentence description]
--! @internal
--! @param param_name [Type] [Description]
--! @return [Return type] [Description]
CREATE FUNCTION eql_v2._internal_function(...)
```

## Template: Operator Implementation

```sql
--! @brief [Operator symbol] operator for encrypted values
--!
--! Implements the [operator] operator using [index type] for
--! [operation description] without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean [Result description]
--!
--! @example
--! -- [Specific example showing operator usage]
--! SELECT * FROM table WHERE encrypted_col [operator] value;
--!
--! @see eql_v2.[related_function]
CREATE FUNCTION eql_v2."[operator]"(...)
```

## Template: Domain Type

```sql
--! @brief [Type name] index term type
--!
--! Domain type representing [description of what this type represents].
--! Used for [use case] via the '[index_name]' index type.
--!
--! @see eql_v2.add_search_config
--! @note This is a transient type used only during query execution
CREATE DOMAIN eql_v2.[type_name] AS [base_type];
```

## Template: Composite Type

```sql
--! @brief [Brief description of composite type]
--!
--! [Detailed description including structure/fields]
--!
--! @see [related functions]
CREATE TYPE eql_v2.[type_name] AS (
  field_name field_type
);
```

## Template: Aggregate Function

```sql
--! @brief [State function description]
--! @internal
--! @param $1 [State type] [State description]
--! @param $2 [Input type] [Input description]
--! @return [State type] [Updated state description]
CREATE FUNCTION eql_v2._state_function(...)

--! @brief [Aggregate behavior description]
--!
--! [Detailed description of what aggregate computes]
--!
--! @param input [Input type] [Input description]
--! @return [Return type] [Return description]
--!
--! @example
--! -- [Example query using aggregate]
--!
--! @see eql_v2._state_function
CREATE AGGREGATE eql_v2.aggregate_name(...) (...)
```

## Template: Operator Class

```sql
--! @brief [Operator class purpose description]
--!
--! Defines the operator class required for creating [index type] indexes
--! on encrypted columns. Enables [capabilities description].
--!
--! @example
--! -- Create index using this operator class:
--! CREATE INDEX ON table USING [index_method] (column [opclass_name]);
--!
--! @see CREATE OPERATOR CLASS in PostgreSQL documentation
CREATE OPERATOR CLASS [opclass_name] ...
```

## Template: Constraint Function

```sql
--! @brief [Constraint check description]
--!
--! [What the constraint validates]
--!
--! @param value [Type] [Value being checked]
--! @return Boolean True if constraint satisfied
--! @throws Exception if [constraint violation condition]
CREATE FUNCTION eql_v2.[constraint_function](...)
```
