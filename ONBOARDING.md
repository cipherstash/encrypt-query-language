# Ideal CipherStash onboarding

CipherStash makes sure sensitive data is accessible only to the right people at the right time. 
Implement robust data security without sacrificing performance or usability.

Implement trusted data access in your PostgreSQL database by following the steps below.

## 1. Create an account

Create an account at [https://dashboard.cipherstash.com](https://dashboard.cipherstash.com).

## 2. Initialize your configuration

Initialize your configuration by following the guide that's initially displayed in the dashboard.
You will need your PostgreSQL database connection string, which looks like this:

```bash
postgres://[username]:[password]@database.server.com:5432/[database]
```

Click **Download** to download the configuration file.

## 3. Clone the EQL repo

Clone the EQL repo to your local machine.

```bash
git clone https://github.com/cipherstash/encrypt-query-language.git
```

## 4. Start CipherStash Proxy

Copy your `cipherstash-proxy.toml` file that you just downloaded to the `encrypt-query-language/cipherstash-proxy` directory.

Start CipherStash Proxy by running the following command:

```bash
docker compose up
```

This will start CipherStash Proxy and connect to your database.

## 5. Install the EQL extension

By default, CipherStash Proxy will not install the EQL extension.
To install the EQL extension, you can do one of the following:

- Install the EQL extension manually by running the following command:

```bash
psql -U postgres -d postgres -f release/cipherstash-encrypt-dsl.sql
```

- Install the EQL extension through CipherStash Proxy by running the following command:

```bash
docker exec -it eql-cipherstash-proxy eql-install
```

## 6. Start using EQL

You are now ready to start using EQL in your PostgreSQL database.
To get started, see the [README.md](README.md) file.