# Native PostgreSQL JSON(B) Compared to EQL

EQL supports a subset of functionality supported by the native Postgres JSON(B) functions and operators. The following examples compare native Postres JSON(B) functions and operators to the related functionality in EQL.

## `json ->> text` → `text` and `json -> text` → `jsonb`/`json`

### Native PostgreSQL JSON(B)

```sql
-- `->` (returns JSON(B))
SELECT plaintext_jsonb->'field_a' FROM examples;

-- `->>` (returns text)
SELECT plaintext_jsonb->>'field_a' FROM examples;
```

### EQL

EQL JSONB functions accept an eJSONPath as an argument (instead of using `->`/`->>`) for lookups.

#### Decryption example

`cs_ste_vec_value_v1` returns the Plaintext EQL payload to the client.

```sql
SELECT cs_ste_vec_value_v1(encrypted_jsonb, $1) FROM examples;
```

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": 100
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}
```

#### Comparison example

`cs_ste_vec_term_v1` returns an ORE term for comparison.

```sql
SELECT * FROM examples
WHERE cs_ste_vec_term_v1(examples.encrypted_jsonb, $1) > cs_ste_vec_term_v1($2)
```

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": 100
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}

// `$2` is the EQL plaintext payload for the ORE term to compare against (in this case, the ORE term for the integer `123`):
{
  "k": "pt",
  "p": "123",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ste_vec"
}
```

## `json ->> int` → `text` and `json -> int` → `jsonb`/`json`

### Native PostgreSQL JSON(B)

```sql
-- `->` (returns JSON(B))
SELECT plaintext_jsonb->0 FROM examples;

-- `->>` (returns text)
SELECT plaintext_jsonb->>0 FROM examples;
```

### EQL

EQL JSONB functions accept an eJSONPath as an argument (instead of using `->`/`->>`) for lookups.

#### Decryption example

EQL currently doesn't support returning a specific array element for decryption, but `cs_ste_vec_value_v1` can be used to return an array to the client to process.

The query:

```sql
SELECT cs_ste_vec_value_v1(encrypted_jsonb, $1) AS val FROM examples;
```

With the params:

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}
```

Would return the EQL plaintext payload with an array (`[1, 2, 3]` for example):

```javascript
// Example result for a single row
{
  "k": "pt",
  "p": "[1, 2, 3]",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": null
}
```

#### Comparison example

`cs_ste_vec_terms_v1` can be used with the native PostgreSQL array access operator to get a term for comparison by array index.

The eJSONPath used with `cs_ste_vec_terms_v1` needs to end with `[*]` (`$.some_array_field[*]` for example).

> [!IMPORTANT]
> Array access with `cs_ste_vec_terms_v1` only works when the given eJSONPath only matches a single array.
> Accessing array elements from `cs_ste_vec_terms_v1` when the eJSONPath matches multiple arrays (for example, when there are nested arrays or multiple arrays at the same depth) can return unexpected results.

The following query compares the first item in the array at the eJSONPath in $1 to the value in $2.

```sql
SELECT * FROM examples
WHERE (cs_ste_vec_terms_v1(examples.encrypted_jsonb, $1))[1] > cs_ste_vec_term_v1($2)
```

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": [4, 5, 6]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a[*]`:
{
  "k": "pt",
  "p": "$.field_a[*]",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}

// `$2` is the EQL plaintext payload for the ORE term to compare against (in this case, the ORE term for the integer `3`):
{
  "k": "pt",
  "p": "3",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ste_vec"
}
```

## `json #>> text[]` → `text` and `json #> text[]` → `jsonb`/`json`

### Native PostgreSQL JSON(B)

```sql
-- `#>` (returns JSON(B))
SELECT plaintext_jsonb#>'{field_a,field_b}' FROM examples;

-- `#>>` (returns text)
SELECT plaintext_jsonb#>>'{field_a,field_b}' FROM examples;
```

### EQL

EQL JSONB functions accept an eJSONPath as an argument (instead of using `#>`/`#>>`) for lookups.

Note that these are similar to the examples for `->`/`->>`. The difference in these examples is that the path does a lookup multiple levels deep.

#### Decryption example

`cs_ste_vec_value_v1` returns the Plaintext EQL payload to the client.

```sql
SELECT cs_ste_vec_value_v1(encrypted_jsonb, $1) FROM examples;
```

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": {
    "field_b": 100
  }
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a.field_b`:
{
  "k": "pt",
  "p": "$.field_a.field_b",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}
```

#### Comparison example

`cs_ste_vec_term_v1` returns an ORE term for comparison.

```sql
SELECT * FROM examples
WHERE cs_ste_vec_term_v1(examples.encrypted_jsonb, $1) > cs_ste_vec_term_v1($2)
```

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": {
    "field_b": 100
  }
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a.field_b`:
{
  "k": "pt",
  "p": "$.field_a.field_b",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}

// `$2` is the EQL plaintext payload for the ORE term to compare against (in this case, the ORE term for the integer `123`):
{
  "k": "pt",
  "p": "123",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ste_vec"
}
```

## `@>` and `<@`

### Native PostgreSQL JSON(B)

```sql
-- Checks if the left arg contains the right arg (returns `true` in this example).
SELECT '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb;

-- Checks if the right arg contains the left arg (returns `true` in this example).
SELECT '{"b":2}'::jsonb <@ '{"a":1, "b":2}'::jsonb;
```

### EQL

EQL uses the same operators for containment (`@>` and `<@`) queries, but the args need to be wrapped in `cs_ste_vec_v1`.

Example query:

```sql
-- Checks if the left arg (the `examples.encrypted_jsonb` column) contains the right arg ($1).
-- Would return `true` for the example data and param below.
SELECT * WHERE cs_ste_vec_v1(encrypted_jsonb) @> cs_ste_vec_v1($1) FROM examples;

-- Checks if the the right arg ($1) contains left arg (the `examples.encrypted_jsonb` column).
-- Would return `false` for the example data and param below.
SELECT * WHERE cs_ste_vec_v1(encrypted_jsonb) <@ cs_ste_vec_v1($1) FROM examples;
```

Example params:

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": {
    "field_b": [1, 2, 3]
  }
}

// `$1` is the EQL plaintext payload for the JSON object `{"field_b": [1, 2, 3]}`:
{
  "k": "pt",
  "p": "{\"field_b\": [1, 2, 3]}",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ste_vec"
}
```

## `json_array_elements`, `jsonb_array_elements`, `json_array_elements_text`, and `jsonb_array_elements_text`

### Native PostgreSQL JSON(B)

```sql
-- Each returns the results...
--
-- Value
-- _____
-- a
-- b
--
-- The only difference is that the input is either json or jsonb (depending
-- on the prefix of the function name) and the output is either json,
-- jsonb, or text (depending on both the prefix and the suffix).

SELECT * from json_array_elements('["a", "b"]');
SELECT * from jsonb_array_elements('["a", "b"]');
SELECT * from json_array_elements_text('["a", "b"]');
SELECT * from jsonb_array_elements_text('["a", "b"]');
```

### EQL

#### Decryption example

EQL currently doesn't support returning a `SETOF` values for decryption (for returning a row per item in an array), but `cs_ste_vec_value_v1` can be used to return an array to the client to process.

The query:

```sql
SELECT cs_ste_vec_value_v1(encrypted_jsonb, $1) AS val FROM examples;
```

With the params:

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}
```

Would return the EQL plaintext payload with an array (`[1, 2, 3]` for example):

```javascript
// Example result for a single row
{
  "k": "pt",
  "p": "[1, 2, 3]",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": null
}
```

#### Comparison example

`cs_ste_vec_terms_v1` (note that terms is plural) can be used to return an array of ORE terms for comparison. The array can be `unnest`ed to work with a `SETOF` ORE terms for comparison.

The eJSONPath used with `cs_ste_vec_terms_v1` needs to end with `[*]` (`$.some_array_field[*]` for example).

Example query:

```sql
SELECT id FROM examples e
WHERE EXISTS (
  SELECT 1
  FROM  unnest(cs_ste_vec_terms_v1(e.encrypted_jsonb, $1)) AS term
  WHERE term > cs_ste_vec_term_v1($2)
);
```

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "field_a": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a[*]`:
{
  "k": "pt",
  "p": "$.field_a[*]",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}

// `$2` is the EQL plaintext payload for the ORE term to compare against  (in this case, the ORE term for the integer `2`):
{
  "k": "pt",
  "p": "2",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ste_vec"
}
```

## `json_array_length` and `jsonb_array_length`

### Native PostgreSQL JSON(B)

```sql
-- Both of these examples return the int `3`.
-- The only difference is the input type.
SELECT json_array_length('[1, 2, 3]');
SELECT jsonb_array_length('[1, 2, 3]');
```

### EQL

The PostgreSQL `array_length` function can be used with `cs_ste_vec_terms_v1` to find the length of an array.

The eJSONPath used with `cs_ste_vec_terms_v1` needs to end with `[*]` (`$.some_array_field[*]` for example).

> [!IMPORTANT]
> Determining array length with `cs_ste_vec_terms_v1` only works when the given eJSONPath only matches a single array.
> Attempting to determine array length using `cs_ste_vec_terms_v1` when the eJSONPath matches multiple arrays (for example, when there are nested arrays or multiple arrays at the same depth) can return unexpected results.

Example query:

```sql
SELECT COALESCE( -- We `COALESCE` because cs_ste_vec_terms_v1 will return `NULL` for empty arrays.
  array_length( -- `cs_ste_vec_terms_v1` returns an array type (not JSON(B)), so we use `array_length`.
    cs_ste_vec_terms_v1(encrypted_jsonb, $1), -- Pluck out the array of terms at the path in $1.
    1 -- The array dimension to find the length of (term array are flat, so this should always be 1).
  ),
  0 -- Assume a length of `0` when `cs_ste_vec_terms_v1` returns `NULL`.
) AS len FROM examples;
```

Example data and params:

```javascript
// Assume that examples.encrypted_jsonb has JSON objects with the shape:
{
  "val": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.val[*]`:
{
  "k": "pt",
  "p": "$.val[*]",
  "i": {
    "t": "examples",
    "c": "encrypted_jsonb"
  },
  "v": 1,
  "q": "ejson_path"
}
```
