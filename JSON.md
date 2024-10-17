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

JSONB objects can be encrypted in EQL using a Structured Encryption Vec (`ste_vec`).
An `ste_vec` is an array of 2-element arrays containing a "Posting" and a "ciphertext".

```
[
  [POSTING, CIPHERTEXT]
]
```

A _Posting_ comprises a selector and a _Term_.

``
POSTING = SELECTOR <> TERM
```

And a term comprises a `<TYPE>` byte and either a `MAC` or an `ORE` term
represented by `TYPE=0` and `TYPE=1` respectively.
Other types may be supported in the future.

```
TERM = <TYPE> <> (ORE | MAC)
```

Each of these types are described in the following sections.

## Selectors

A selector represents an encryption of a [eJSON Path](#ejsonpath) for a leaf node in the JSON tree (**not including** the leaf node itself).

Given:

* An index key, `ki`
* An `INFO` string representing storage context (e.g the table and column name)
* A path `P` made up of segments `P(0)..P(N)`
* The length (in bytes) of `x` defined by `len(x)`
* A secure Message Authenticated Code function, `MAC` (such as Blake3 or SHA2-512)
* A length parameter `L` which, when passed to `TRUNCATE(x, L)` will truncate X to `L` bytes
* `+` means string concatenation

The selector, `S` is defined as:

```
S = TRUNCATE(MAC(ki, <INFO> + len(<INFO>) + {P(0) + len(P(0))} + ... {P(N) + len(P(N))}), L)
```

### Examples

* `INFO`: `customers/attrs`
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
S1 = TRUNCATE(MAC(ki, "customers/attrs" + 15 + "." + 1 + "firstName" + 9), 16)
```

The selector, `S2` for the path `$.scores[*]` is:

```
S2 = TRUNCATE(MAC(ki, "customers/attrs" + 15 + "." + 1 + "scores" + 6 + "[*]" + 3), 16)
```

## Terms

### MAC

A MAC term is the output of a secure MAC (such as HMAC-SHA256 or a keyed Blake3 hash),
truncated to `L` bytes.

The input to the MAC should be:

* the _Selector_ associated with the term
* an _info_ string representing the type
* an optional value

The MAC should be keyed with an index key, `ki`.

Given a selector, `S`:

| Type    | Info String | Value                | Example                      |
|---------|-------------|----------------------|------------------------------|
| `bool`  | `"BOOL"`    | Byte: `0` or `1`     | `MAC(ki, S + "BOOL" + 0)`    |
| `null`  | `"NULL"`    | -                    | `MAC(ki, S + "NULL")`        |
| `map`   | `"MAP0"`    | Empty literal `"{}"` | `MAC(ki, S + "MAP0" + "{}")` |
| `array` | `"ARRY"`    | Empty literal `"[]"` | `MAC(ki, S + "ARRY" + "[]")` |

Note that all valid INFO strings are padded to the same length to avoid ambiguous encoding.

> [!NOTE]
> Map and Array types only encode empty literals for reasons that are explained in [Vector Generation](#vector-generation).

### ORE

TODO

## Ciphertexts

Ciphertexts in EQL JSONB are the encryptions of the leaf values of a plaintext JSONB object.

Given:

* A [Selector](#selectors), `S`,
* A plaintext value, `V` (at the position defined by `S`)
* A data key `k`
* Authenticated Associated Data, `AAD` (e.g. a _descriptor_)
* And a block cipher `AES256SIV` (AES in SIV mode with 256-bit keys)

The ciphertext, `C` with tag `T` is defined as:

```
IV = TRUNCATE(S, 12)
(C, T) = AES256SIV(IV, k, V, AAD)
```

Where `IV` is the 12-byte used for the block-cipher.


## Vector Generation

Generation of an `ste_vec` follows the below process:

Given:

* A data encryption key, `k`
* An indexing key, `ki`
* A JSON input, `J`

1. Flatten `J` into an array of 3-element tuples.

Each tuple comprises:

* a plaintext JSON path
* a literal or sentinel
* and the JSON object representing the child of the node

If the path describes a branch node, the literal must be set to a sentinel value of either:

* `[]` representing a branch who's child is an array
* `{}` representing a branch who's child is a map

If the path describes a leaf node, the final element of the tuple must be set to the value of the node.

The array can be generated using a post-order traversal of the input object.
A tuple is output for each node in the JSON (as described above).

> [!NOTE]
> Paths containing array elements should use `[]` to represent each value and must not include the
> position of the element in the array (e.g. `[2]`).

Example:

Given `J`:

```json
x = {"foo": [1, 2]}
```

The flattened form should be:

```js
["$", "{}", {"foo": [1, 2]}],
["$.foo", "[]", [1, 2]],
["$.foo[]", 1, 1],
["$.foo[]", 2, 2]
```

2. Generate the [Selector](#selectors) values coresponding with the first element of each tuple

Given a function `S(x)` which generates a selector as defined [above](#selectors):

The array from step 1 is transformed by passing the first element of each tuple
into `S`.
`S` is assumed to be keyed by `ki` but is not showed for brevity.

The example output is:

```js
[S("$"), "{}", {"foo": [1, 2]}],
[S("$.foo"), "[]", [1, 2]],
[S("$.foo[]"), 1, 1],
[S("$.foo[]"), 2, 2]
```

3. Generate terms

Given a MAC function `M(x)` and an ORE function `ORE(x)` as defined above (once again with `ki` omitted for brevity):

The second element of each tuple array is passed to either `M` or `ORE` based on the following rules:

* If value is a map (`"{}"`), the term is `M({})`
* If node is an array (`"[]"`), the term is `M([])`
* If node is a literal (string or number), the term is `ORE(x)`
* If node is a bool, the term is `M(x)`
* If node is null the term is `M(null)`

The example output is:

```js
[S("$"), M("{}"), {"foo": [1, 2]}],
[S("$.foo"), M("[]"), [1, 2]],
[S("$.foo[]"), ORE(1), 1],
[S("$.foo[]"), ORE(2), 2]
```

4. Encrypt the last element of each tuple

Given a function `E(k, x, iv, aad)` which encrypts a value `x` as described [above](#ciphertexts):

Encrypt the last element of each tuple, using the selector, denoted `s0..sn` where n is 1 less than the
number of tuples, as the IV for each encryption.
Authenticated Associated Data, `aad` is optional but is recommended and should be set to the storage location
intended for the resuling output (such as the table and column name).

The example output is:

```js
[S("$"), M("{}"), E(k, {"foo": [1, 2]}, s0, aad)],
[S("$.foo"), M("[]"), E(k, [1, 2], s1, aad)],
[S("$.foo[]"), ORE(1), E(k, 1, s2, aad)],
[S("$.foo[]"), ORE(2), E(k, 2, s3, aad)]
```

The plaintext values passed to `E` may be serialized into a more compact form before encryption to reduce the final output size.

> [!NOTE]
> Future versions of this specification will not require the entire child tree to be encrypted at each node.


## Operations

The following subsections describe operations over an `ste_vec`.

### Containment

TODO: The 2-element tuples in this section should be described as the postings of an ste_vec (maybe even define a postings function first)

Given an `ste_vec`, `V` representing the JSON encryption of a plaintext JSON `J`,
and a plaintext query JSON value, `Jq` we wish to generate an `ste_vec`, `Vq` such that
we can determine if `Jq` is contained within `J`.

Generate `Vq` from `Jq` using the process described in [Vector Generation](#vector-generation)
but retain _only_ the "most specific tuples".
Additionally, the last element of each tuple (the ciphertext) can be ignored.

The most specific tuple(s) will be:

* A tuple coresponding with a leaf-node
* A tuple coresponding with a branch who's node is an empty array (`[]`)
* A tuple coresponding with a branch who's node is an empty map (`{}`)

To verify if `Vq` is contained within `V`, we must check that `V` contains a tuple who's first and second terms
match the first and second terms of `Vq`.

Example:

```json
J = {
	"foo": {
		"bar": "baz"
	}
}
```

Which has output (ignoring the ciphertext terms for brevity), `V`:

```js
[S("$"), M("{}")],
[S("$.foo"), M("{}")],
[S("$.foo.bar"), ORE("baz")],
```

A query, `Jq` is:

```json
Jq = {
    "foo": {}
}
```

Which coresponds to an `ste_vec` (ignoring ciphertexts):

```js
[S('$'), M({})],
[S('$.foo'), M({})]
```

The most specific tuple is the last tuple, coresponding with the path `$.foo`.
Therefore:

```js
Vq = [S('$.foo'), M({})]
```

To check if `Jq` is contained within `J`, we assert that `V` contains the 2-element tuple `[S('$.foo'), M({})]`.


### Extraction

There are 4 possible extraction operations for an `ste_vec`:

1. Extract a ciphertext which should be interpreted as JSON when decrypted
2. Extract a ciphertext which should be intepreted as a string when decrypted
3. Extract a term of either type
4. Extract a term of a specific type

#### Extract ciphertext as JSON

This function is analogous to the plaintext JSONB operator, `->` which returns a JSONB value.

Given:

* a JSON object `J`
* its `ste_vec`, `V`,
* a plaintext path `p`

To extract a ciphertext `C`, representing the element at `p`:

1. Generate the selector `s0=S(p)`
2. Find the tuple in `V` who's first element is equal to `s0`
3. `C` is the last element in the tuple if such a tuple exists or `null` otherwise
4. Output a JSON object containing `C`, `sn` coresponding to `C` and a sentinel value indicating that the result should be interpreted as JSON

Example:

An SQL query uses chained extraction operations to extract a nested value within a JSON object:

```sql
j->'foo'->'bar'
```

This can be converted into a jsonpath value, `$.foo.bar`.

Assuming our input, `J` is:

```json
J = {
	"foo": {
		"bar": "baz"
	}
}
```

Then `V` will be:

```js
[S("$"), M("{}"), E(k, {"foo": {"bar": "baz"}}, s0, aad)],
[S("$.foo"), M("{}"), E(k, {"bar": "baz"}, s1, aad)],
[S("$.foo.bar"), ORE("baz"), E(k, "baz", s2, aad)]
```

The generated selector for the jsonpath is:

```js
s2 = S("$.foo.bar")
```

Therefore, we return:

```js
{
    "c" = E(k, "baz", s2, aad),
    "s" = S("$.foo.bar"),
    "type": "json"
}
```

Which can be decrypted as follows:

```
IV = TRUNCATE(s, 12)
P = D(k, c, iv, aad) as JSON
```

Where `aad` is the same as that which was provided during encryption and `D` is the `AES-256-SIV` decryption function
coresponding to the encryption function described above.

The output JSON here is called the _Annotated Ciphertext_.

#### Extract ciphertext as TEXT

This process is identical to extracting a ciphertext intended for `JSON`, as described in the previous
section, except for the following:

1. The final result will have the `type` field set to `text`
2. The plaintext should be interpreted as `text` after decryption takes place

```js
{
    "c" = E(k, "baz", s2, aad),
    "s" = S("$.foo.bar"),
    "type": "text"
}
```

Which can be decrypted as follows:

```
IV = TRUNCATE(s, 12)
P = D(k, c, iv, aad) as TEXT
```

#### Extract a term of any type

The process is the same as the extraction methods described above, except:

1. The _Term_ element of the relevant tuple in `V` is returned (rather than the ciphertext)
2. The _Term_ is output directly instead of as a structured type

#### Extract a term of a specific type

The process is the same as the extraction method described in the previous section, except:

1. A target _Term_ type is specified
1. The _Term_ element of the relevant tuple in `V` is returned only if `TYPE` matches the value specified
2. The _Term_ is output directly but with the `TYPE` byte removed


### Enumeration

An `ste_vec` defined the following enumerations:

1. Enumerate the _Selectors_
2. Enumerate the _Terms_ (of any type)
3. Enumerate the _Terms_ (of a specific type)
4. Enumerate the `_Ciphertext_ values as _Annotated Ciphertexts_ which should be interpreted as a specific type

#### Enumerate the _Selectors_

Selectors are enumerated by returning a vector containing the first element of each tuple.

#### Enumerate the _Terms_

Terms are enumerated by returning a vector containing the second element of each tuple.

#### Enumerate the _Terms_ of a specific type

Terms of a specific type are enumerated by returning a vector containing the second element of each tuple
where the `TYPE` byte matches the specified type and is removed.

#### Enumerate the _Annotated Ciphertexts_

Annotated Ciphertexts are enumerated by constructing a vector of JSON objects of the following form:

```js
{
    "c" = Ci,
    "s" = si,
    "type": <specified-type>
}
```

Where `Ci` and `si` are the Ciphertext and selector of the `ith` tuple respectively.

This function is the EQL analogue of `jsonb_array_elements` where the specified type is `JSON`
and `jsonb_array_elements_text` where the specified type is `TEXT`.



