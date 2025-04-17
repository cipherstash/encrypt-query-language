# Developing CipherStash EQL

## Table of Contents

- [How this project is organised](#how-this-project-is-organised)
- [Set up a local development environment](#set-up-a-local-development-environment)
  - [Installing mise](#installing-mise)
- [Testing](#testing)
  - [Running tests locally](#running-tests-locally)
- [Releasing](#releasing)

### How this project is organised

Development is managed through [mise](https://mise.jdx.dev/), both locally and [in CI](https://github.com/cipherstash/encrypt-query-language/actions).

mise has tasks for:

- Building EQL install and uninstall scripts (`build`)
- Starting and stopping PostgreSQL containers (`postgres:up`, `postgres:down`)
- Running unit and integration tests (`test`, `reset`)

These are the important files in the repo:

```
.
├── mise.toml              <-- the main config file for mise
├── tasks/                 <-- mise tasks
├── sql/                   <-- The individual SQL components that make up EQL
├── docs/                  <-- Tutorial, reference, and concept documentation
├── tests/                 <-- Unit and integration tests
│   ├── docker-compose.yml <-- Docker configuration for running PostgreSQL instances
│   └── *.sql              <-- Individual unit and integration tests
├── release/               <-- Build artifacts produced by the `build` task
├── examples/              <-- Example uses of EQL in different languages
└── playground/            <-- Playground enviroment for experimenting with EQL and CipherStash Proxy
```

## Set up a local development environment

> [!IMPORTANT]
> **Before you follow this how-to** you need to have this software installed:
>  - [mise](https://mise.jdx.dev/) — see the [installing mise](#installing-mise) instructions
>  - [Docker](https://www.docker.com/) — see Docker's [documentation for installing](https://docs.docker.com/get-started/get-docker/)

Local development quickstart:

``` shell
# Clone the repo
git clone https://github.com/cipherstash/encrypt-query-language
cd encrypt-query-language

# Install dependencies
mise trust --yes

# Build EQL installer and uninstaller, outputting to release/
mise run build

# Start a postgres instance (defaults to PostgreSQL 17)
mise run postgres:up --extra-args "--detach --wait"

# Run the tests (defaults to PostgreSQL 17)
mise run test

# Stop and remove all containers and networks
mise run postgres:down
```

### Installing mise

> [!IMPORTANT]
> You must complete this step to set up a local development environment.

Local development and task running in CI is managed through [mise](https://mise.jdx.dev/).

To install mise:

- If you're on macOS, run `brew install mise`
- If you're on another platform, check out the mise [installation methods documentation](https://mise.jdx.dev/installing-mise.html#installation-methods)

Then add mise to your shell:

```shell
# If you're running Bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc

# If you're running Zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

We use [`cargo-binstall`](https://github.com/cargo-bins/cargo-binstall) for faster installation of tools installed via `mise` and Cargo.
We install `cargo-binstall` via `mise` when installing development and testing dependencies.

> [!TIP]
> We provide abbreviations for most of the commands that follow.
> For example, `mise run postgres:setup` can be abbreviated to `mise r s`.
> Run `mise tasks --extended` to see the task shortcuts.

## Testing

There are tests for checking EQL against PostgreSQL versions 14–17, that verify:

- Adding, removing, and modifying encrypted data and indexes
- Validating, applying, and removing configuration for encrypted data and encrypted indexes
- Validating schemas for EQL configuration, encrypted data, and encrypted indexes
- Using PostgreSQL operators on encrypted data and indexes (`=`, `<>`, `@>`)

The easiest way to run the tests [is in GitHub Actions](./.github/workflows/test-eql.yml):

- Automatically whenever there are changes in the `sql/`, `tests/`, or `tasks/` directories
- By manually running [the workflow](https://github.com/cipherstash/encrypt-query-language/actions/workflows/test-eql.yml)

This is how the `test-eql.yml` workflow functions:

```mermaid
---
title: Testing EQL
---
stateDiagram-v2
    direction LR
    classDef code font-family:monospace;


    state "🧍 Human makes changes to EQL sources" as changes
    state sources_fork <<fork>>
    state sources_join <<join>>
    state "sql/*.sql" as source_sql
    state "tasks/**/*" as source_tasks
    state "tests/**/*" as source_tests
    state sources_changed <<choice>>

    state "🛠️ Trigger GitHub Actions workflow test-eql.yml" as build_triggered
    state "Matrix: Test EQL SQL components" as matrix
    state "Test with Postgres 14" as pg14
    state "Test with Postgres 15" as pg15
    state "Test with Postgres 16" as pg16
    state "Test with Postgres 17" as pg17
    state "Check build results" as check
    state if_state <<choice>>

    changes --> sources_fork
    sources_fork --> source_sql:::code
    sources_fork --> source_tests:::code
    sources_fork --> source_tasks:::code
    source_sql --> sources_join
    source_tests --> sources_join
    source_tasks --> sources_join
    sources_join --> source_changed_check
    source_changed_check --> sources_changed
    sources_changed --> build_triggered : Some changes
    sources_changed --> [*]: No changes

    state "Check source changes" as source_changed_check

    [*] --> changes

    build_triggered --> matrix

    state fork_state <<fork>>
        matrix --> fork_state
        fork_state --> pg14
        fork_state --> pg15
        fork_state --> pg16
        fork_state --> pg17

    state join_state <<join>>
        pg14 --> join_state
        pg15 --> join_state
        pg16 --> join_state
        pg17 --> join_state

    state "✅ Pass build" as build_pass
    state "❌ Fail build" as build_fail
    join_state --> check
    check --> if_state
    if_state --> build_pass: All success
    if_state --> build_fail : Any failures
    build_pass --> [*]
    build_fail --> [*]
```

You can also [run the tests locally](#running-tests-locally) when doing local development.

### Running tests locally

> [!IMPORTANT]
> **Before you run the tests locally** you need to [set up a local dev environment](#set-up-a-local-development-environment).

To run tests locally with PostgreSQL 17:

``` shell
# Start a postgres instance (defaults to PostgreSQL 17)
mise run postgres:up --extra-args "--detach --wait"

# Run the tests (defaults to PostgreSQL 17)
mise run test

# Stop and remove all containers and networks
mise run postgres:down
```

You can run the same tasks for Postgres 14, 15, 16, and 17 by specifying arguments:

```shell
# Start a postgres 14 instance
mise run postgres:up postgres-14 --extra-args "--detach --wait"

# Run the tests against postgres 14
mise run test --postgres 14

# Stop postgres and remove all containers and networks
mise run postgres:down
```

The configuration for the Postgres containers in `tests/docker-compose.yml`.

Limitations:

- **Volumes for Postgres containers are not persistent.**
  If you need to look at data in the container, uncomment a volume in
  `tests/docker-compose.yml`
- **You can't run multiple Postgres containers at the same time.**
  All the containers bind to the same port (`7543`). If you want to run
  multiple containers at the same time, you have to change the ports by
  editing `tests/docker-compose.yml`

## Releasing

To cut a [release](https://github.com/cipherstash/encrypt-query-language/releases) of EQL:

1. Draft a [new release](https://github.com/cipherstash/encrypt-query-language/releases/new) on GitHub.
1. Choose a tag, and create a new one with the prefix `eql-` followed by a [semver](https://semver.org/) (for example, `eql-1.2.3`).
1. Generate the release notes.
1. Optionally set the release to be the latest (you can set a release to be latest later on if you are testing out a release first).
1. Click `Publish release`.

This will trigger the [Release EQL](https://github.com/cipherstash/encrypt-query-language/actions/workflows/release-eql.yml) workflow, which will build and attach artifacts to [the release](https://github.com/cipherstash/encrypt-query-language/releases/).


====


###

EQL is installed into the `eql_v1` schema.


## Types

### `public.eql_v1_encrypted`

Core column type, defined as PostgreSQL composite type.
In public schema as once used in customer tables it cannot be dropped without dropping data.

### Index terms

Each type of encrypted indexing has an associated type and functions

- `eql_v1.unique_index`
- `eql_v1.match`
- `eql_v1.ore_64_8_v1`
- `eql_v1.ore_64_8_v1_term`


## Operators

Operators are provided for the `eql_v1_encrypted` column type and `jsonb`.

```
eql_v1_encrypted - eql_v1_encrypted
jsonb - eql_v1_encrypted
eql_v1_encrypted - jsonb
```

The index types and functions are internal implementation details and should not need to be exposed as operators on the `eql_v1_encrypted` type.


--      eql_v1_encrypted = eql_v1_encrypted
--      eql_v1_encrypted = jsonb
--      jsonb = eql_v1_encrypted
--      ore_64_8_v1 = ore_64_8_v1

The jsonb comparison is handy as it automates casting.
Comparing ore_64_8_v1 index values requires that sides are functionalated:
eql_v1.ore_64_8_v1(...) = eql_v1.ore_64_8_v1(...)
In the spirit of aggressive simplification, however, I am not going to add operators to compare eql_v1_encrypted with the ore_64_8_v1 type.
In an operator world,  the index types and functions are internal implementation details.
Customers should never need to think about the internals.
I can't think of a reason to need it that isn't a version of "holding it wrong". (edited)




## Working without operators


### Equality

```sql
eql_v1.eq(a eql_v1_encrypted, b eql_v1_encrypted);
```





## Organisation

Break SQL into small modules, aligned with the core domains and types where possible

 - types.sql
 - casts.sql
 - constraints.sql
 - functions.sql
 - operators.sql

Operators are also functions, so some judgement is required.
The intent is to reduce file size and cognitive load.

In general, operator functions should be thin wrappers around a larger function that does the work.
Put the wrapper functions in `operators.sql` and the "heavy lifting" functions in `functions.sql`.

Tests should follow a similar pattern.



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



EQL Design Note
Experimenting with using a Composite type instead of a Domain type for the encrypted column.
Composite types are a bit more capable. Domain types are more like an alias for the underlying type (in this case jsonb)
The consequence of using a Composite type is that the data is stored in the column as a Tuple - effectively the data is wrapped in ()
This means
on insert/update the data needs to be cast to eql_v1_encrypted (proxy mapping will handle)
on read the data needs to be cast back to jsonb if a customer needs the raw json (for data lake transfer etc etc)
Already built cast helpers so syntax is something like
    INSERT INTO encrypted (e) VALUES (
        eql_v1.to_encrypted('{}')
    );

    INSERT INTO encrypted (e) VALUES (
        '{}'::jsonb::eql_v1_encrypted
    );

