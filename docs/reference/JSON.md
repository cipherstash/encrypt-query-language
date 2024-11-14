# EQL with JSON and JSONB

EQL supports encrypting, decrypting, and searching JSON and JSONB objects.

## Table of contents

- [Configuring the Index](#configuring-the-index)
  - [Inserting JSON Data](#inserting-json-data)
  - [Reading JSON Data](#reading-json-data)
- [Querying JSONB Data with EQL](#querying-jsonb-data-with-eql)
  - [Containment Queries (`cs_ste_vec_v1`)](#containment-queries-cs_ste_vec_v1)
  - [Field Extraction (`cs_ste_vec_value_v1`)](#field-extraction-cs_ste_vec_value_v1)
  - [Field Comparison (`cs_ste_vec_term_v1`)](#field-comparison-cs_ste_vec_term_v1)
  - [Grouping Data](#grouping-data)
- [Reference](#reference)
  - [EQL Functions for JSONB and `ste_vec`](#eql-functions-for-jsonb-and-ste_vec)
  - [EJSON Paths](#ejson-paths)
- [Native PostgreSQL JSON(B) Compared to EQL](#native-postgresql-jsonb-compared-to-eql)
  - [`json ->> text` → `text` and `json -> text` → `jsonb`/`json`](#json--text--text-and-json---text--jsonbjson)
    - [Decryption Example](#decryption-example)
    - [Comparison Example](#comparison-example)
  - [`json ->> int` → `text` and `json -> int` → `jsonb`/`json`](#json--int--text-and-json--int--jsonbjson)
    - [Decryption Example](#decryption-example-1)
    - [Comparison Example](#comparison-example-1)
  - [`json #>> text[]` → `text` and `json #> text[]` → `jsonb`/`json`](#json--text--text-and-json---text--jsonbjson-1)
    - [Decryption Example](#decryption-example-2)
    - [Comparison Example](#comparison-example-2)
  - [`@>` and `<@`](#and)
  - [`json_array_elements`, `jsonb_array_elements`, `json_array_elements_text`, and `jsonb_array_elements_text`](#json_array_elements-jsonb_array_elements-json_array_elements_text-and-jsonb_array_elements_text)
    - [Decryption Example](#decryption-example-3)
    - [Comparison Example](#comparison-example-3)
  - [`json_array_length` and `jsonb_array_length`](#json_array_length-and-jsonb_array_length)

## Configuring the index

Similar to how you configure indexes for text data, you can configure indexes for JSON and JSONB data.
The only difference is that you need to specify the `cast_as` parameter as `json` or `jsonb`.

```sql
SELECT cs_add_index_v1(
  'users', 
  'encrypted_json', 
  'ste_vec',
  'jsonb',
  '{"prefix": "users/encrypted_json"}' -- The prefix is in the form of "table/column"
);
```

You can read more about the index configuration options [here](https://github.com/cipherstash/encrypt-query-language/blob/main/docs/reference/INDEX.md).

### Inserting JSON data

When inserting JSON data, this works the same as inserting text data. 
You need to wrap the JSON data in the appropriate EQL payload.
CipherStash Proxy will **encrypt** the data automatically.

**Example:**

Assuming you want to store the following JSON data:

```json
{
  "name": "John Doe",
  "metadata": {
    "age": 42,
  }
}
```

The EQL payload would be:

```sql
INSERT INTO users (encrypted_json) VALUES (
  '{"v":1,"k":"pt","p":"{\"name\":\"John Doe\",\"metadata\":{\"age\":42}}","i":{"t":"users","c":"encrypted_json"}}'
);
```

Data is stored in the database as:

```json
{
  "i": {
    "c": "encrypted_json",
    "t": "users"
  },
  "k": "sv",
  "v": 1,
  "sv": [
    ["ciphertext"]
  ]
}
```

### Reading JSON data

When querying data, select the encrypted column. CipherStash Proxy will **decrypt** the data automatically.

**Example:**

```sql
SELECT encrypted_json FROM users;
```

Data is returned as:

```json
{
  "k": "pt",
  "p": "{\"metadata\":{\"age\":42},\"name\":\"John Doe\"}",
  "i": {
    "t": "users",
    "c": "encrypted_json"
  },
  "v": 1,
  "q": null
}
```

## Querying JSONB Data with EQL

EQL provides specialized functions to interact with encrypted JSONB data, supporting operations like containment queries, field extraction, and comparisons.

### Containment Queries (`cs_ste_vec_v1`)

Retrieve the Structured Encryption Vector for JSONB containment queries.

**Example: Containment Query**

Suppose we have the following encrypted JSONB data:

```json
{
  "top": {
    "nested": ["a", "b", "c"]
  }
}
```

We can query records that contain a specific structure.

**SQL Query:**

```sql
SELECT * FROM examples
WHERE cs_ste_vec_v1(encrypted_json) @> cs_ste_vec_v1(
  '{
    "v":1,
    "k":"pt",
    "p":{"top":{"nested":["a"]}},
    "i":{"t":"examples","c":"encrypted_json"}
  }'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM examples
WHERE jsonb_column @> '{"top":{"nested":["a"]}}';
```

**Note:** The `@>` operator checks if the left JSONB value contains the right JSONB value.

**Negative Example:**

If we query for a value that does not exist in the data:

**SQL Query:**

```sql
SELECT * FROM examples
WHERE cs_ste_vec_v1(encrypted_json) @> cs_ste_vec_v1(
  '{
    "v":1,
    "k":"pt",
    "p":{"top":{"nested":["d"]}},
    "i":{"t":"examples","c":"encrypted_json"}
  }'
);
```

This query would return no results, as the value `"d"` is not present in the `"nested"` array.

### Field Extraction (`cs_ste_vec_value_v1`)

Extract a field from an encrypted JSONB object.

**Example:**

Suppose we have the following encrypted JSONB data:

```json
{
  "top": {
    "nested": ["a", "b", "c"]
  }
}
```

We can extract the value of the `"top"` key.

**SQL Query:**

```sql
SELECT cs_ste_vec_value_v1(encrypted_json, 
  '{
    "v":1,
    "k":"pt",
    "p":"$.top",
    "i":{"t":"examples","c":"encrypted_json"},
    "q":"ejson_path"
  }'
) AS value
FROM examples;
```

Equivalent plaintext query:

```sql
SELECT jsonb_column->'top' AS value
FROM examples;
```

**Result:**

```json
{
  "nested": ["a", "b", "c"]
}
```

### Field Comparison (`cs_ste_vec_term_v1`)

Select rows based on a field value in an encrypted JSONB object.

**Example:**

Suppose we have encrypted JSONB data with a numeric field:

```json
{
  "num": 3
}
```

We can query records where the `"num"` field is greater than `2`.

**SQL Query:**

```sql
SELECT * FROM examples
WHERE cs_ste_vec_term_v1(encrypted_json, 
  '{
    "v":1,
    "k":"pt",
    "p":"$.num",
    "i":{"t":"examples","c":"encrypted_json"},
    "q":"ejson_path"
  }'
) > cs_ste_vec_term_v1(
  '{
    "v":1,
    "k":"pt",
    "p":2,
    "i":{"t":"examples","c":"encrypted_json"}
  }'
);
```

Equivalent plaintext query:

```sql
SELECT * FROM examples
WHERE (jsonb_column->>'num')::int > 2;
```

### Grouping Data

Use `cs_ste_vec_term_v1` along with `cs_grouped_value_v1` to group by a field in an encrypted JSONB column.

**Example:**

Suppose we have records with a `"color"` field:

```json
{"color": "blue"}
{"color": "blue"}
{"color": "green"}
{"color": "blue"}
{"color": "red"}
{"color": "green"}
```

We can group the data by the `"color"` field and count occurrences.

**SQL Query:**

```sql
SELECT cs_grouped_value_v1(cs_ste_vec_value_v1(encrypted_json, 
  '{
    "v":1,
    "k":"pt",
    "p":"$.color",
    "i":{"t":"examples","c":"encrypted_json"},
    "q":"ejson_path"
  }'
)) AS color, COUNT(*)
FROM examples
GROUP BY cs_ste_vec_term_v1(encrypted_json, 
  '{
    "v":1,
    "k":"pt",
    "p":"$.color",
    "i":{"t":"examples","c":"encrypted_json"},
    "q":"ejson_path"
  }'
);
```

Equivalent plaintext query:

```sql
SELECT jsonb_column->>'color' AS color, COUNT(*)
FROM examples
GROUP BY jsonb_column->>'color';
```

**Result:**

| color | count |
|-------|-------|
| blue  |   3   |
| green |   2   |
| red   |   1   |

## Reference

### EQL Functions for JSONB and `ste_vec`

- **Index Management**

  - `cs_add_index_v1(table_name text, column_name text, 'ste_vec', 'jsonb', opts jsonb)`: Adds an `ste_vec` index configuration.
    - `opts` must include the `"context"` key.
  
- **Query Functions**

  - `cs_ste_vec_v1(val jsonb)`: Retrieves the STE vector for JSONB containment queries.
  - `cs_ste_vec_term_v1(val jsonb, epath jsonb)`: Retrieves the encrypted term associated with an encrypted JSON path.
  - `cs_ste_vec_value_v1(val jsonb, epath jsonb)`: Retrieves the decrypted value associated with an encrypted JSON path.
  - `cs_ste_vec_terms_v1(val jsonb, epath jsonb)`: Retrieves an array of encrypted terms for elements in an array at the given JSON path (used for comparisons).
  - `cs_grouped_value_v1(val jsonb)`: Used with `ste_vec` indexes for grouping.

### EJSON Paths

EQL uses an extended JSONPath syntax called EJSONPath for specifying paths in JSONB data.

- Root selector: `$`
- Dot notation for keys: `$.key`
- Bracket notation for keys with special characters: `$['key.with.special*chars']`
- Wildcards are supported: `$.some_array_field[*]`
- Array indexing is **not** supported: `$.some_array_field[0]`

**Example Paths:**

- `$.top.nested` selects the `"nested"` key within the `"top"` object.
- `$.array[*]` selects all elements in the `"array"` array.

---

## Native PostgreSQL JSON(B) compared to EQL

EQL supports a subset of functionality supported by the native PostgreSQL JSON(B) functions and operators.
The following examples compare native PostgreSQL JSON(B) functions and operators to the related functionality in EQL.

### `json ->> text` → `text` and `json -> text` → `jsonb`/`json`

**Native PostgreSQL JSON(B) example**

```sql
-- `->` (returns JSON(B))
SELECT plaintext_jsonb->'field_a' FROM examples;

-- `->>` (returns text)
SELECT plaintext_jsonb->>'field_a' FROM examples;
```

**EQL example**

EQL JSONB functions accept an [eJSONPath](#ejson-paths) as an argument (instead of using `->`/`->>`) for lookups.

#### Decryption example

`cs_ste_vec_value_v1` returns the plaintext EQL payload to the client.

```sql
SELECT cs_ste_vec_value_v1(encrypted_json, $1) FROM examples;
```

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "field_a": 100
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ejson_path"
}
```

#### Comparison example

`cs_ste_vec_term_v1` returns an ORE term for comparison.

```sql
SELECT * FROM examples
WHERE cs_ste_vec_term_v1(examples.encrypted_json, $1) > cs_ste_vec_term_v1($2)
```

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "field_a": 100
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ste_vec"
}
```

### `json ->> int` → `text` and `json -> int` → `jsonb`/`json`

**Native PostgreSQL JSON(B) example**

```sql
-- `->` (returns JSON(B))
SELECT plaintext_jsonb->0 FROM examples;

-- `->>` (returns text)
SELECT plaintext_jsonb->>0 FROM examples;
```

**EQL example**

EQL JSONB functions accept an [eJSONPath](#ejson-paths) as an argument (instead of using `->`/`->>`) for lookups.

#### Decryption example

EQL currently doesn't support returning a specific array element for decryption, but `cs_ste_vec_value_v1` can be used to return an array to the client to process.

The query:

```sql
SELECT cs_ste_vec_value_v1(encrypted_json, $1) AS val FROM examples;
```

With the params:    

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "field_a": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
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
    "c": "encrypted_json"
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

The following query compares the first item in the array at the eJSONPath in `$1` to the value in `$2`.

```sql
SELECT * FROM examples
WHERE (cs_ste_vec_terms_v1(examples.encrypted_json, $1))[1] > cs_ste_vec_term_v1($2)
```

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "field_a": [4, 5, 6]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a[*]`:
{
  "k": "pt",
  "p": "$.field_a[*]",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ste_vec"
}
```

### `json #>> text[]` → `text` and `json #> text[]` → `jsonb`/`json`

**Native PostgreSQL JSON(B) example**

```sql
-- `#>` (returns JSON(B))
SELECT plaintext_jsonb#>'{field_a,field_b}' FROM examples;

-- `#>>` (returns text)
SELECT plaintext_jsonb#>>'{field_a,field_b}' FROM examples;
```

**EQL example**

EQL JSONB functions accept an [eJSONPath](#ejson-paths) as an argument (instead of using `#>`/`#>>`) for lookups.

Note that these are similar to the examples for `->`/`->>`.
The difference in these examples is that the path does a lookup multiple levels deep.

#### Decryption example

`cs_ste_vec_value_v1` returns the plaintext EQL payload to the client.

```sql
SELECT cs_ste_vec_value_v1(encrypted_json, $1) FROM examples;
```

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ejson_path"
}
```

#### Comparison example

`cs_ste_vec_term_v1` returns an ORE term for comparison.

```sql
SELECT * FROM examples
WHERE cs_ste_vec_term_v1(examples.encrypted_json, $1) > cs_ste_vec_term_v1($2)
```

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
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
    "c": "encrypted_json"
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ste_vec"
}
```

### `@>` and `<@`

**Native PostgreSQL JSON(B) example**

```sql
-- Checks if the left arg contains the right arg (returns `true` in this example).
SELECT '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb;

-- Checks if the right arg contains the left arg (returns `true` in this example).
SELECT '{"b":2}'::jsonb <@ '{"a":1, "b":2}'::jsonb;
```

**EQL example**

EQL uses the same operators for containment (`@>` and `<@`) queries, but the args need to be wrapped in `cs_ste_vec_v1`.

Example query:

```sql
-- Checks if the left arg (the `examples.encrypted_json` column) contains the right arg ($1).
-- Would return `true` for the example data and param below.
SELECT * WHERE cs_ste_vec_v1(encrypted_json) @> cs_ste_vec_v1($1) FROM examples;

-- Checks if the the right arg ($1) contains left arg (the `examples.encrypted_json` column).
-- Would return `false` for the example data and param below.
SELECT * WHERE cs_ste_vec_v1(encrypted_json) <@ cs_ste_vec_v1($1) FROM examples;
```

Example params:

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ste_vec"
}
```

### `json_array_elements`, `jsonb_array_elements`, `json_array_elements_text`, and `jsonb_array_elements_text`

**Native PostgreSQL JSON(B) example**

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

**EQL example**

#### Decryption example

EQL currently doesn't support returning a `SETOF` values for decryption (for returning a row per item in an array), but `cs_ste_vec_value_v1` can be used to return an array to the client to process.

The query:

```sql
SELECT cs_ste_vec_value_v1(encrypted_json, $1) AS val FROM examples;
```

With the params:

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "field_a": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a`:
{
  "k": "pt",
  "p": "$.field_a",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": null
}
```

#### Comparison example

`cs_ste_vec_terms_v1` (note that terms is plural) can be used to return an array of ORE terms for comparison.
The array can be `unnest`ed to work with a `SETOF` ORE terms for comparison.

The eJSONPath used with `cs_ste_vec_terms_v1` needs to end with `[*]` (`$.some_array_field[*]` for example).

Example query:

```sql
SELECT id FROM examples e
WHERE EXISTS (
  SELECT 1
  FROM  unnest(cs_ste_vec_terms_v1(e.encrypted_json, $1)) AS term
  WHERE term > cs_ste_vec_term_v1($2)
);
```

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "field_a": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.field_a[*]`:
{
  "k": "pt",
  "p": "$.field_a[*]",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
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
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ste_vec"
}
```

### `json_array_length` and `jsonb_array_length`

**Native PostgreSQL JSON(B) example**

```sql
-- Both of these examples return the int `3`.
-- The only difference is the input type.
SELECT json_array_length('[1, 2, 3]');
SELECT jsonb_array_length('[1, 2, 3]');
```

**EQL example**

The PostgreSQL `array_length` function can be used with `cs_ste_vec_terms_v1` to find the length of an array.

The eJSONPath used with `cs_ste_vec_terms_v1` needs to end with `[*]` (`$.some_array_field[*]` for example).

> [!IMPORTANT]
> Determining array length with `cs_ste_vec_terms_v1` only works when the given eJSONPath only matches a single array.
> Attempting to determine array length using `cs_ste_vec_terms_v1` when the eJSONPath matches multiple arrays (for example, when there are nested arrays or multiple arrays at the same depth) can return unexpected results.

Example query:

```sql
SELECT COALESCE( -- We `COALESCE` because cs_ste_vec_terms_v1 will return `NULL` for empty arrays.
  array_length( -- `cs_ste_vec_terms_v1` returns an array type (not JSON(B)), so we use `array_length`.
    cs_ste_vec_terms_v1(encrypted_json, $1), -- Pluck out the array of terms at the path in $1.
    1 -- The array dimension to find the length of (term array are flat, so this should always be 1).
  ),
  0 -- Assume a length of `0` when `cs_ste_vec_terms_v1` returns `NULL`.
) AS len FROM examples;
```

Example data and params:

```javascript
// Assume that examples.encrypted_json has JSON objects with the shape:
{
  "val": [1, 2, 3]
}

// `$1` is the EQL plaintext payload for the eJSONPath `$.val[*]`:
{
  "k": "pt",
  "p": "$.val[*]",
  "i": {
    "t": "examples",
    "c": "encrypted_json"
  },
  "v": 1,
  "q": "ejson_path"
}
```
