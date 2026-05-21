# eql-types (prototype)

Canonical wire types for EQL payloads — **one Rust definition per payload
shape**, intended as the single source of truth for:

- **Rust** — consumed directly by `cipherstash-client` / `protect-ffi`
- **TypeScript** — generated via [`ts-rs`] into [`bindings/`](bindings/)
- **JSON Schema** — generated via [`schemars`] into [`schema/`](schema/)

> **Status: prototype / draft for discussion.** Not wired into the EQL build
> or CI. See the pull request description for full context.

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
| [`src/int4.rs`](src/int4.rs) | `eql_v2_int4` variant family (#225) | **Design freedom** — capability-encoded types |

## Capability-encoded types

`eql_v2_encrypted` is one type with every index term optional, so consumers
must guess at runtime which terms are present. The `int4` family instead has
one type per capability — `Int4` / `Int4Eq` / `Int4Ord` — each carrying its
index terms as **required** fields. The capability is the type identity;
`Option` never appears.

## Develop

```sh
cargo test
```

Runs the conformance round-trip tests and regenerates `bindings/` (TypeScript)
and `schema/` (JSON Schema). Both directories are checked in so reviewers can
see the codegen output without running anything.

[`ts-rs`]: https://github.com/Aleph-Alpha/ts-rs
[`schemars`]: https://graham.cool/schemars/
