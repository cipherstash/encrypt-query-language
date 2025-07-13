# dbdev

We publish a Trusted Language Extension for PostgreSQL for use on [dbdev](https://database.dev/).
You can find the extension on [dbdev's extension catalog](https://database.dev/cipherstash/eql).

## Publishing

**DISCLAIMER:** At the moment, we are manually publishing the extension to dbdev and the versions might not be in sync with the releases on GitHub until we automate this process.

### Steps to publish

> [!NOTE]
> Make sure you have the [dbdev CLI](https://supabase.github.io/dbdev/cli/) installed and logged in using the `dbdev shared token` in 1Password.

1. Run `mise run build` to build the extension which will create the following file in the `dbdev` directory. (Note: this release artifact is built from the Supabase release artifact).
2. After the build is complete, you will have a file in the `dbdev` directory called `eql--0.0.0.sql`.
3. Update the file name from `eql--0.0.0.sql` replacing `0.0.0` with the version number of the release.
4. Also update the `eql.control` file with the new version number.
5. Run `dbdev publish` to publish the extension to dbdev.

Reach out to @calvinbrewer if you need help.