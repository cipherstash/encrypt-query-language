# eql-types

Canonical wire types for EQL payloads — **one Rust definition per payload
shape**, intended as the single source of truth for:

- **Rust** — consumed directly by `cipherstash-client` / `protect-ffi`
- **TypeScript** — generated via [`ts-rs`] into [`bindings/`](bindings/)
- **JSON Schema** — generated via [`schemars`] into [`schema/`](schema/)

## Why

Type information is lost at every hop of `EQL → cipherstash-client →
protect-ffi → stack`. protect-ffi hand-writes its TypeScript types; they drift
from the Rust they describe; stack widens them further. The result is bugs
like the `protect-dynamodb` search-term check that validates a payload shape
EQL v2.3 never actually defined. A generated, single-source crate removes the
hand-copying.

## Two tiers

| Module | Tier | Rule |
|--------|------|------|
| [`src/v2_3.rs`](src/v2_3.rs) | `eql_v2_encrypted` v2.3 wire contract | **FROZEN** — in production; mirrors `eql-payload-v2.3.schema.json`; must not change |
| [`src/v3/`](src/v3/) | `eql_v3` encrypted-domain families | One struct per SQL domain, parity-tested against `eql-scalars::CATALOG` |

## Capability-encoded types (the v3 tier)

`eql_v2_encrypted` is one type with every index term optional, so consumers
must guess at runtime which terms are present. The v3 tier instead has one
type per **SQL domain** — `Int4` / `Int4Eq` / `Int4Ord` / `Int4OrdOre`, and
likewise for `int2`, `int8`, `date`, `timestamptz` (eq-only), and `text`
(which adds `TextMatch`) — each carrying its index terms as **required**
fields. The capability is the type identity; `Option` never appears.

Shared wire fields are reusable newtypes in
[`src/v3/terms.rs`](src/v3/terms.rs):

| Newtype | Wire key | Inner | Backs |
|---------|----------|-------|-------|
| `Ciphertext` | `c` | `String` | every domain (envelope) |
| `Hmac256` | `hm` | `String` | `_eq` domains |
| `OreBlockU64_8_256` | `ob` | `Vec<String>` | `_ord` / `_ord_ore` domains |
| `BloomFilter` | `bf` | `Vec<i16>` (signed!) | `_match` domains |

Note "v3" names the SQL schema generation (`eql_v3.*`); the JSON envelope
version is still `v: 2` — the generated domain CHECKs assert it, and the wire
field names are unchanged from v2 (the purpose-named rename in
`docs/plans/eql-payload-scheme-discipline-rfc.md` is deferred).

### Drift protection

`tests/catalog_parity.rs` asserts the [`v3::registry`](src/v3/registry.rs)
exactly covers `eql-scalars::CATALOG` (every domain, in order) and that each
type's required JSON keys equal the envelope keys plus the catalog's term
keys. Adding a scalar to the catalog without adding its types here fails the
build; so does accidentally making a term field `Option`.

## Develop

```sh
mise run types:generate   # clean-regenerate bindings/ and schema/
mise run types:check      # regenerate + fail if checked-in outputs are stale
```

Both wrap `cargo test -p eql-types`, which runs the conformance round-trip
tests and regenerates `bindings/` (TypeScript, via ts-rs) and `schema/`
(JSON Schema, via `tests/export.rs`). Both directories are checked in so
reviewers can see the codegen output without running anything; CI runs
`types:check` to keep them fresh.

## Future direction: self-describing payloads

On the wire, a v3 payload is discriminated only by *which key is present*
(`hm` vs `ob` vs `bf`) — the SQL domain name carries the rest. Once the JSON
leaves SQL (into protect-ffi, into TypeScript, into a log line) that
information is gone, and a consumer is back to sniffing keys: the untagged
failure mode that produced the original protect-dynamodb bug. An earlier
prototype here carried an `Int4Tagged` enum with a one-field capability tag
(`"x": "int4_eq"`), which generates a clean TypeScript discriminated union
and a JSON Schema `oneOf` with per-branch `const`s. It was removed because
the tag is not part of the v3 wire contract (the generated domain CHECKs
know no `x` key) — but it remains the recommended shape if a future payload
revision adds a discriminator. See
`docs/plans/eql-payload-scheme-discipline-rfc.md` for the wider payload
evolution plan.

[`ts-rs`]: https://github.com/Aleph-Alpha/ts-rs
[`schemars`]: https://graham.cool/schemars/
