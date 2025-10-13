# EQL index configuration for CipherStash Proxy

> [!NOTE]
> This guide is for CipherStash Proxy.
> If you are using Protect.js, see the [Protect.js schema](https://github.com/cipherstash/protectjs/blob/main/docs/reference/schema.md).

The following functions allow you to configure indexes for encrypted columns.
All these functions modify the `eql_v2_configuration` table in your database, and are added during the EQL installation.

> **IMPORTANT:** When you modify or add search configuration  index, you must re-encrypt data that's already been stored in the database.
> The CipherStash encryption solution will encrypt the data based on the current state of the configuration.

### Configuring search (`eql_v2.add_search_config`)

Add an index to an encrypted column.

```sql
SELECT eql_v2.add_search_config(
  'table_name',       -- Name of the table
  'column_name',      -- Name of the column
  'index_name',       -- Index kind ('unique', 'match', 'ore', 'ste_vec')
  'cast_as',          -- PostgreSQL type to cast decrypted data ('text', 'int', etc.)
  'opts'              -- Index options as JSONB (optional)
);
```

| Parameter     | Description                                        | Notes                                                                    |
| ------------- | -------------------------------------------------- | ------------------------------------------------------------------------ |
| `table_name`  | Name of target table                               | Required                                                                 |
| `column_name` | Name of target column                              | Required                                                                 |
| `index_name`  | The index kind                                     | Required                                                                 |
| `cast_as`     | The PostgreSQL type decrypted data will be cast to | Optional. Defaults to `text`                                             |
| `opts`        | Index options                                      | Optional for `match` indexes, required for `ste_vec` indexes (see below) |

#### Option (`cast_as`)

Supported types:

- `text`
- `int`
- `small_int`
- `big_int`
- `real`
- `double`
- `boolean`
- `date`
- `jsonb`

#### Options for match indexes (`opts`)

A match index enables full text search across one or more text fields in queries.

The default match index options are:

```json
  {
    "k": 6,
    "bf": 2048,
    "include_original": true,
    "tokenizer": {
      "kind": "ngram",
      "token_length": 3
    }
    "token_filters": {
      "kind": "downcase"
    }
  }
```

- `tokenFilters`: a list of filters to apply to normalize tokens before indexing.
- `tokenizer`: determines how input text is split into tokens.
- `m`: The size of the backing [bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) in bits. Defaults to `2048`.
- `k`: The maximum number of bits set in the bloom filter per term. Defaults to `6`.

**Token filters**

There are currently only two token filters available: `downcase` and `upcase`. These are used to normalise the text before indexing and are also applied to query terms. An empty array can also be passed to `tokenFilters` if no normalisation of terms is required.

**Tokenizer**

There are two `tokenizer`s provided: `standard` and `ngram`.
`standard` simply splits text into tokens using this regular expression: `/[ ,;:!]/`.
`ngram` splits the text into n-grams and accepts a configuration object that allows you to specify the `tokenLength`.

**m** and **k**

`k` and `m` are optional fields for configuring [bloom filters](https://en.wikipedia.org/wiki/Bloom_filter) that back full text search.

`m` is the size of the bloom filter in bits. `filterSize` must be a power of 2 between `32` and `65536` and defaults to `2048`.

`k` is the number of hash functions to use per term.
This determines the maximum number of bits that will be set in the bloom filter per term.
`k` must be an integer from `3` to `16` and defaults to `6`.

**Caveats around n-gram tokenization**

While using n-grams as a tokenization method allows greater flexibility when doing arbitrary substring matches, it is important to bear in mind the limitations of this approach.
Specifically, searching for strings _shorter_ than the `tokenLength` parameter will not _generally_ work.

If you're using n-gram as a token filter, then a token that is already shorter than the `tokenLength` parameter will be kept as-is when indexed, and so a search for that short token will match that record.
However, if that same short string only appears as a part of a larger token, then it will not match that record.
Try to ensure that the string you search for is at least as long as the `tokenLength` of the index, except in the specific case where you know that there are shorter tokens to match, _and_ you are explicitly OK with not returning records that have that short string as part of a larger token.

#### Options for ste_vec indexes (`opts`)

An ste_vec index on a encrypted JSONB column enables the use of PostgreSQL's `@>` and `<@` [containment operators](https://www.postgresql.org/docs/16/functions-json.html#FUNCTIONS-JSONB-OP-TABLE).

An ste_vec index requires one piece of configuration: the `prefix` (a string) which is passed as an info string to a MAC (Message Authenticated Code).
This ensures that all of the encrypted values are unique to that prefix.
We recommend that you use the table and column name as the prefix (e.g. `users/name`).

**Example:**
```json
{"prefix": "users/encrypted_json"}
```

Within a dataset, encrypted columns indexed using an `ste_vec` that use different prefixes can't be compared.
Containment queries that manage to mix index terms from multiple columns will never return a positive result.
This is by design.

The index is generated from a JSONB document by first flattening the structure of the document so that a hash can be generated for each unique path prefix to a node.

The complete set of JSON types is supported by the indexer.
Null values are ignored by the indexer.

- Object `{ ... }`
- Array `[ ... ]`
- String `"abc"`
- Boolean `true`
- Number `123.45`

For a document like this:

```json
{
  "account": {
    "email": "alice@example.com",
    "name": {
      "first_name": "Alice",
      "last_name": "McCrypto"
    },
    "roles": ["admin", "owner"]
  }
}
```

Hashes would be produced from the following list of entries:

```js
[
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")],
  [
    Obj,
    Key("account"),
    Obj,
    Key("name"),
    Obj,
    Key("first_name"),
    String("Alice"),
  ],
  [
    Obj,
    Key("account"),
    Obj,
    Key("name"),
    Obj,
    Key("last_name"),
    String("McCrypto"),
  ],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("admin")],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("owner")],
];
```

Using the first entry to illustrate how an entry is converted to hashes:

```js
[Obj, Key("account"), Obj, Key("email"), String("alice@example.com")];
```

The hashes would be generated for all prefixes of the full path to the leaf node.

```js
[
  [Obj],
  [Obj, Key("account")],
  [Obj, Key("account"), Obj],
  [Obj, Key("account"), Obj, Key("email")],
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")],
  // (remaining leaf nodes omitted)
];
```

Query terms are processed in the same manner as the input document.

A query prior to encrypting and indexing looks like a structurally similar subset of the encrypted document. For example:

```json
{
  "account": {
    "email": "alice@example.com",
    "roles": "admin"
  }
}
```

The expression `cs_ste_vec_v2(encrypted_account) @> cs_ste_vec_v2($query)` would match all records where the `encrypted_account` column contains a JSONB object with an "account" key containing an object with an "email" key where the value is the string "alice@example.com".

When reduced to a prefix list, it would look like this:

```js
[
  [Obj],
  [Obj, Key("account")],
  [Obj, Key("account"), Obj],
  [Obj, Key("account"), Obj, Key("email")],
  [Obj, Key("account"), Obj, Key("email"), String("alice@example.com")][
    (Obj, Key("account"), Obj, Key("roles"))
  ],
  [Obj, Key("account"), Obj, Key("roles"), Array],
  [Obj, Key("account"), Obj, Key("roles"), Array, String("admin")],
];
```

Which is then turned into an ste_vec of hashes which can be directly queries against the index.

### Modifying an index (`eql_v2.modify_search_config`)

Modifies an existing index configuration.
Accepts the same parameters as `eql_v2.add_search_config`

```sql
SELECT eql_v2.modify_search_config(
  table_name text,
  column_name text,
  index_name text,
  cast_as text DEFAULT 'text',
  opts jsonb DEFAULT '{}',
  migrating boolean DEFAULT false
);
```

### Removing an index (`eql_v2.remove_search_config`)

Removes an index configuration from the column.

```sql
SELECT eql_v2.remove_search_config(
  table_name text,
  column_name text,
  index_name text,
  migrating boolean DEFAULT false
);
```

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20INDEX.md)
