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

## 3. Run Proxy

At the end of the guide in dashboard, you will be presented with a few different options for running CipherStash Proxy.

1. Download the binary for your operating system and either run with environment variables or config file.
2. Copy the following docker run command:

```bash
docker run -p 6432:6432 -e CS_WORKSPACE_ID=123 -e CS_CLIENT_ACCESS_KEY=abc -e CS_CLIENT_ID=123 -e CS_CLIENT_KEY=123 -e CS_DATABASE_URL=... cipherstash/proxy:0.1.1
```

These processes will also install Encrypt Query Language (EQL) extention in your database by default.
If you wish to disable the initial installation, pass the following environment variable to the start commands `-e CS_INSTALL_EQL=false`

## 4. Start using EQL

You are now ready to start using EQL in your PostgreSQL database.
To get started, see the [README.md](README.md) file.
