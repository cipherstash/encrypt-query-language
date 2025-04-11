



====


###

EQL is installed into the `eql_v1` schema.





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