# EQL Go/Xorm example

## Prerequisites

- Go
- Docker
- Docker compose
- CipherStash account
- CipherStash CLI

## Running / Development

Create an [account](https://cipherstash.com/signup).

Install the CLI:

```shell
brew install cipherstash/tap/stash
```

Login:

```shell
stash login
```

Create a [dataset](https://cipherstash.com/docs/how-to/creating-datasets) and [client](https://cipherstash.com/docs/how-to/creating-clients), and record them as `CS_CLIENT_ID` and `CS_CLIENT_KEY`.

```shell
stash datasets create xorm
# grab dataset ID and export CS_DATASET_ID=

stash clients create xorm --dataset-id $CS_DATASET_ID
# grab the client ID and export CS_CLIENT_ID=
# grab the client key and export CS_CLIENT_KEY=
```

Upload the `dataset.yml` file in this directory.

```shell
stash datasets config upload --file dataset.yml --client-id $CS_CLIENT_ID --client-key $CS_CLIENT_KEY --assume-yes
```

Create an [access key](https://cipherstash.com/docs/how-to/creating-access-keys) for CipherStash Proxy:

```shell
stash workspaces
# grab the workspace ID and export CS_WORKSPACE_ID=
stash access-keys create --workspace-id $CS_WORKSPACE_ID xorm
# grab the client access key and export CS_CLIENT_ACCESS_KEY=
```

Copy over the example `.envrc` file:

```shell
cp .envrc.example .envrc
```

Update the `.envrc` file with these environment variables `CS_WORKSPACE_ID`, `CS_CLIENT_ACCESS_KEY`, `CS_CLIENT_ID` and `CS_CLIENT_KEY`:

```shell
source .envrc
```

Start Postgres and CipherStash Proxy and install EQL:

```shell
./run.sh setup
```

Run examples:

```shell
./run.sh examples
```

Run tests:

```shell
./run.sh tests
```
