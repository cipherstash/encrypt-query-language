# JSON Encrypted Indexing

> [!NOTE]
> This section is under construction

## Operations over encrypted JSONB

EQL aims to support a useful subset of the JSONB operations possible in PostgreSQL.

### Containment

Test if a JSONB value is contained within another.

:abc: Plaintext
```sql
SELECT * FROM users WHERE attrs @> '{"field": "value"}`;
```

:white_check_mark: EQL
```sql
SELECT * FROM users WHERE cs_ste_vec_v1(attrs) @> '53T8dtvW4HhofDp9BJnUkw';
```

### Extraction (in SELECT)

Extract a field from a JSONB object for use in a `SELECT` statement.

:abc: Plaintext
```sql
SELECT attrs->'login_count' FROM users;
```

:white_check_mark: EQL
```sql
SELECT cs_ste_value_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') FROM users;
```

### Extraction (in WHERE, ORDER BY)

:abc: Plaintext
```sql
SELECT * FROM users WHERE attrs->'login_count' > 10; 
```

:white_check_mark: EQL
```sql
SELECT * FROM users WHERE cs_ste_term_v1(attrs, 'DQ1rbhWJXmmqi/+niUG6qw') > 'QAJ3HezijfTHaKrhdKxUEg';
```

## eJSONPath

CipherStash EQL supports a simplified JSONPath syntax, called `eJSONPath`.
It is a subset of the [SQL/JSONPath](https://www.postgresql.org/docs/16/datatype-json.html#DATATYPE-JSONPATH) scheme provided by Postgres
and supports the following expressions:

| Expression | Description |
|------------|-------------|
| `$`        | The root object or array. |
| `.property` | Selects the specified property in a parent object. |
| `[n]`  | Selects the n-th element from an array. Indexes are 0-based. |
| `[*]`  | Matches any array element |

### Examples

Given the following JSON:

```json
{
    "firstName": "John",
    "lastName": "doe",
    "scores": [1, 2, 3]
}
```

`$.firstName` returns `[John]`
`$.scores` returns `[[1, 2, 3]]`
`$[0]` returns nothing
`$.scores[0]` returns `[1]`
`$.scores[*]` returns `[1, 2, 3]`
`$.` returns the entire object

### Path Segments

A Simplified JSON Path can be tokenized into segments where each segment is one of:

* `.`
* A property
* `[*]`
* `[n]`

Below are some paths along with their segment tokenizations:

* `$.firstName` -> `[".", "firstName"]`
* `$.scores[0]` -> `[".", "scores", "[0]"]`
* `$.` -> `["."]`
* `$` -> `["."]` 

## Index Structure

JSONB objects can be encrypted in EQL using a Structured Encryption Map (`ste_map`).

```json
{
    <selector>: <term | ciphertext>
}
```

An `ste_map` maps [Selectors](#selectors) to either a [Term](#terms) or a [Ciphertext](#ciphertexts).
Each of these elements is described in the next sections.

## Selectors

A selector represents an encryption of a Simplied JSON Path for a leaf node in the JSON tree (*including* the leaf node itself),
along with information about what type it selects (i.e. a `term` or a `ciphertext`).

Given:

* An `INFO` string representing storage context (e.g the table and column name)
* A `TYPE` - either `T` (term) or `C` (ciphertext)
* A sub-type, `t`, comprising *exactly* 1-byte (set to 0 for the default sub-type)
* A path `P` made up of segments `P(0)..P(N)`
* The length (in bytes) of `x` defined by `len(x)`
* A secure Message Authenticated Code function, `MAC` (such as Blake3 or SHA2-512)
* A length parameter `L` which, when passed to `TRUNCATE(x, L)` will truncate X to `L` bytes
* `+` means string concatenation

The selector, `S` is defined as:

```
S = TRUNCATE(MAC(<TYPE> + <INFO> + len(<INFO>) + {P(0) + len(P(0))} + ... {P(N) + len(P(N))}), L)
```

## Examples

* `INFO`: `customers/attrs`
* `TYPE`: `T`
* `t` : `0`
* `L`: `16`

A given input:

```json
{
    "firstName": "John",
    "lastName": "doe",
    "scores" []
}
```

The selector, `S1` for the path `$.firstName` is:

```
S1 = TRUNCATE(MAC("T" + 0 + "customers/attrs" + 15 + "." + 1 + "firstName" + 9), 16)
```

The selector, `S2` for the path `$.scores[*]` is:

```
S2 = TRUNCATE(MAC("T" + 0 + "customers/attrs" + 15 + "." + 1 + "scores" + 6 + "[*]" + 3), 16)
```


## Terms



## Ciphertexts

Ciphertexts in EQL JSONB are the encryptions of the leaf values of a plaintext JSONB object.

Given:

* A [Selector](#selectors), `S`,
* A plaintext value, `V` (at the position defined by `S`)
* A data key `k`
* Authenticated Associated Data, `AAD` (e.g. a _descriptor_)
* And a block cipher `AES256SIV` (AES in SIV mode with 256-bit keys)

The ciphertext, `C` is defined as:

```
IV = TRUNCATE(S, 12)
C = AES256SIV(IV, k, V, AAD)
```

Where `IV` is the 12-byte used for the block-cipher.


## Operations

## Generate

TODO

### Extract

A ciphertext value, `C` can be extracted from an `ste_map`.

Given:

* An `ste_map`, `M`
* A `TYPE`
* A sub-type, `t`
* And a selector, `S` generated using `TYPE` and `t`

A _type annotated_ ciphertext `Ct` can be extracted using standard plaintext extraction on `M`.
The result is an [Encrypted Payload](../README.md#data-format).

Extractions where the result is JSON (using `->`):

```
Ct = M->S
```

Returns:
```json
// Type annotated ciphertext
{
  "iv": "<IV>",
  "ct": "<C>",
  "t": "jsonb",
}
```

Extractions where the result is TEXT (using `->>`):

```
Ct = M->>S
```

Returns:
```json
// Type annotated ciphertext
{
  "iv": "<IV>",
  "ct": "<C>",
  // Target type is text
  "t": "text",
}
```


Examples:




For arrays we could do:
```
$.scores[0]
```

Or (if position is not important)
```
$.scores[]
```

