# JSON Encrypted Indexing

> [!NOTE]
> This section is under construction


JSONB objects can be encrypted in EQL using a Structured Encryption Vec (`ste_vec`)
or a Structured Encryption Map, `ste_map`.

```json
{
    <selector>: <term | ciphertext>
}
```


## eJSONPath

CipherStash EQL supports a simplified JSONPath syntax, called `eJSONPath`.
It is a subset of the [SQL/JSONPath](https://www.postgresql.org/docs/16/datatype-json.html#DATATYPE-JSONPATH) scheme provided by Postgres and supports the following expressions:

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

The selector is defined as:

```
TRUNCATE(MAC(<TYPE> + <INFO> + len(<INFO>) + {P(0) + len(P(0))} + ... {P(N) + len(P(N))}), L)
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






For arrays we could do:
```
$.scores[0]
```

Or (if position is not important)
```
$.scores[]
```

