



====


###

EQL is installed into the `eql_v1` schema.


## Types

### `public.eql_v1_encrypted`

Core column type, defined as PostgreSQL composite type.
In public schema as once used in customer tables it cannot be dropped without dropping data.

### Index terms

Each type of encrypted indexing has an associated type and functions

- `eql_v1.unique_index`
- `eql_v1.match`
- `eql_v1.ore_64_8_v1`
- `eql_v1.ore_64_8_v1_term`


## Operators

Operators are provided for the `eql_v1_encrypted` column type and `jsonb`.

```
eql_v1_encrypted - eql_v1_encrypted
jsonb - eql_v1_encrypted
eql_v1_encrypted - jsonb
```

The index types and functions are internal implementation details and should not need to be exposed as operators on the `eql_v1_encrypted` type.


--      eql_v1_encrypted = eql_v1_encrypted
--      eql_v1_encrypted = jsonb
--      jsonb = eql_v1_encrypted
--      ore_64_8_v1 = ore_64_8_v1

The jsonb comparison is handy as it automates casting.
Comparing ore_64_8_v1 index values requires that sides are functionalated:
eql_v1.ore_64_8_v1(...) = eql_v1.ore_64_8_v1(...)
In the spirit of aggressive simplification, however, I am not going to add operators to compare eql_v1_encrypted with the ore_64_8_v1 type.
In an operator world,  the index types and functions are internal implementation details.
Customers should never need to think about the internals.
I can't think of a reason to need it that isn't a version of "holding it wrong". (edited)




## Working without operators


### Equality

```sql
eql_v1.eq(a eql_v1_encrypted, b eql_v1_encrypted);
```





## Organisation

Break SQL into small modules, aligned with the core domains and types where possible

 - types.sql
 - casts.sql
 - constraints.sql
 - functions.sql
 - operators.sql

Operators are also functions, so some judgement is required.
The intent is to reduce file size and cognitive load.

In general, operator functions should be thin wrappers around a larger function that does the work.
Put the wrapper functions in `operators.sql` and the "heavy lifting" functions in `functions.sql`.

Tests should follow a similar pattern.



### Dependencies

SQL sources are split into smaller files.
Dependencies are resolved at build time to construct a single SQL file with the correct ordering.

Dependencies between files are declared in a comment at the top of the file.
All SQL files should `REQUIRE` the source file of any other object they reference.

All files must have at least one declaration, and the default is to reference the schema

```
-- REQUIRE: src/schema.sql
```



### Tables

### Configuration


`public.eql_v1_configuration`



EQL Design Note
Experimenting with using a Composite type instead of a Domain type for the encrypted column.
Composite types are a bit more capable. Domain types are more like an alias for the underlying type (in this case jsonb)
The consequence of using a Composite type is that the data is stored in the column as a Tuple - effectively the data is wrapped in ()
This means
on insert/update the data needs to be cast to eql_v1_encrypted (proxy mapping will handle)
on read the data needs to be cast back to jsonb if a customer needs the raw json (for data lake transfer etc etc)
Already built cast helpers so syntax is something like
    INSERT INTO encrypted (e) VALUES (
        eql_v1.to_encrypted('{}')
    );

    INSERT INTO encrypted (e) VALUES (
        '{}'::jsonb::eql_v1_encrypted
    );

