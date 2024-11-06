# Native Postgres JSON(B) Compared to EQL

EQL supports a subset of functionality supported by the native Postgres JSON(B) functions and operators. The following examples compare native Postres JSON(B) functions and operators to the related functionality in EQL.

## `json ->> text` → `text` and `json -> text` → `jsonb`/`json`

### Native Postgres JSON(B)

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

### Native Postgres JSON(B)

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

The query...

```sql
SELECT cs_ste_vec_value_v1(encrypted_jsonb, $1) AS val FROM examples;
```

With the params...

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

`cs_ste_vec_terms_v1` can be used with the native Postgres array access operator to get a term for comparison by array index.

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

### Native Postgres JSON(B)

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

## `json_array_elements`, `jsonb_array_elements`, `json_array_elements_text`, and `jsonb_array_elements_text`

### Native Postgres JSON(B)

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

The query...

```sql
SELECT cs_ste_vec_value_v1(encrypted_jsonb, $1) AS val FROM examples;
```

With the params...

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
