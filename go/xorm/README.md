# EQL Go/Xorm example

## Prerequisites

- Go
- Docker
- Docker compose
- CipherStash account
- CipherStash CLI

## Running / Development

Create an [account](https://cipherstash.com/signup).

- Install the CLI:

```shell
brew install cipherstash/tap/stash
```

- Login:

```shell
stash login
```

- Create a [dataset](https://cipherstash.com/docs/how-to/creating-datasets) and [client](https://cipherstash.com/docs/how-to/creating-clients).

- Upload the dataset.yml file in this directory.

```shell
stash datasets config upload --file dataset.yml --client-id $CS_CLIENT_ID --client-key $CS_CLIENT_KEY
```

- Create an [access key](https://cipherstash.com/docs/how-to/creating-access-keys) for programattic access to the proxy.

Copy over the example .envrc file:

```shell
cp -R .envrc.example .envrc
```

Update the .envrc file with you workspaceId, client_access_key, client_id and client_key.

```shell
source .envrc
```

Start Postgres and CipherStash Proxy and install EQL

```shell
./run.sh setup
```

Run examples

```shell
./run.sh examples
```
