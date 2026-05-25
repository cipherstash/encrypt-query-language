//! `FixtureSpec<T>` — the type-checked fixture plug-in contract.
//!
//! `T` is the Rust plaintext type, inferred from `.with_values()`. Everything
//! not derivable — the indexes, the committed `payload` column type, the
//! data — is explicit. The fixture name drives every path by convention:
//!   - table        `fixtures.<name>`
//!   - working table `public._fixture_<name>`
//!   - script        `tests/sqlx/fixtures/<name>.sql`
//!   - SQLx ref      `scripts("<name>")`
//!
//! Token-safety is enforced **at construction**: `new`, `.with_index`, and
//! `.with_column_type` each validate via the newtype `TryFrom` and **panic**
//! on a violation, so the builder stays a fluent chain (no `Result`, no
//! `?`). Because the spec stores validated newtypes (`FixtureIdentifier`,
//! `ColumnType`) and uses them via `Display` in the SQL renderers, an
//! unvalidated `&str` cannot reach a generated SQL string. `T::CAST` /
//! `T::PLAINTEXT_SQL_TYPE` are typed const newtypes (`Cast`,
//! `PlaintextSqlType`) — their allowlists are structural, so no runtime
//! check is needed. `check_complete()` covers only the completeness checks
//! (non-empty indexes/values) that the builder cannot make until the chain
//! is finished.

use super::eql_plaintext::EqlPlaintext;
use super::validation::{ColumnType, FixtureIdentifier};

/// A fully specified fixture, ready to `.run()`.
pub struct FixtureSpec<'a, T> {
    name: FixtureIdentifier,
    indexes: Vec<FixtureIdentifier>,
    column_type: ColumnType,
    values: &'a [T],
}

impl<'a, T> FixtureSpec<'a, T> {
    /// Start a spec. `name` must match `^[a-z][a-z0-9_]*$` — it becomes a SQL
    /// identifier and a filename. Other fields take defaults until set:
    /// `column_type` defaults to `"jsonb"`, `indexes`/`values` to empty.
    ///
    /// # Panics
    /// Panics if `name` is not a valid identifier.
    pub fn new(name: &str) -> Self {
        let name = FixtureIdentifier::try_from(name).unwrap_or_else(|e| panic!("fixture name: {e}"));
        let column_type = ColumnType::try_from("jsonb")
            .expect("default column type \"jsonb\" must be in the allowlist");
        Self {
            name,
            indexes: Vec::new(),
            column_type,
            values: &[],
        }
    }

    /// Add a search index (`"unique"`, `"ore"`, ...). Chainable.
    ///
    /// # Panics
    /// Panics if `index_name` is not a valid identifier.
    pub fn with_index(mut self, index_name: &str) -> Self {
        let id = FixtureIdentifier::try_from(index_name).unwrap_or_else(|e| panic!("index name: {e}"));
        self.indexes.push(id);
        self
    }

    /// Set the committed `payload` column SQL type. Defaults to `"jsonb"`.
    ///
    /// # Panics
    /// Panics if `column_type` is not in `validation::ALLOWED_COLUMN_TYPES`.
    pub fn with_column_type(mut self, column_type: &str) -> Self {
        self.column_type =
            ColumnType::try_from(column_type).unwrap_or_else(|e| panic!("column type: {e}"));
        self
    }

    /// Set the plaintext value list. `T` is inferred and bound here, so this
    /// is where `T::CAST` and `T::PLAINTEXT_SQL_TYPE` become known. Their
    /// allowlists are structural (typed-const newtypes), so no runtime
    /// validation is needed at this point.
    pub fn with_values(mut self, values: &'a [T]) -> Self
    where
        T: EqlPlaintext,
    {
        self.values = values;
        self
    }

    // ----- accessors used by SQL rendering / the driver -----

    pub fn name(&self) -> &str {
        self.name.as_str()
    }

    pub fn indexes(&self) -> &[FixtureIdentifier] {
        &self.indexes
    }

    pub fn column_type(&self) -> &ColumnType {
        &self.column_type
    }

    /// The plaintext value slice.
    pub fn values(&self) -> &[T] {
        self.values
    }

    /// `fixtures.<name>` — the committed fixture table.
    pub fn fixture_table(&self) -> String {
        format!("fixtures.{}", self.name)
    }

    /// `_fixture_<name>` — the transient working table (unqualified `public`).
    pub fn working_table(&self) -> String {
        format!("_fixture_{}", self.name)
    }

    /// `<name>.sql` — the generated script filename (relative to fixtures dir).
    pub fn script_filename(&self) -> String {
        format!("{}.sql", self.name)
    }

    /// SQL for the transient working table on the generation database.
    /// `id BIGINT PRIMARY KEY`, `plaintext` as the SQL type for `T`, and
    /// `payload eql_v2_encrypted` so Proxy encrypts inserts. Per index:
    /// an idempotent `remove_search_config` guarded by `WHERE EXISTS`, then
    /// `add_search_config`. Every `add_search_config` argument is a quoted
    /// string literal — the table/column names are fixed literals, and the
    /// index name and cast are validated tokens (`FixtureIdentifier` / `Cast`).
    ///
    /// The leading `DROP TABLE IF EXISTS` is belt-and-suspenders: a normal run
    /// drops the working table itself at the end of `run()`, so this only
    /// matters when a prior run crashed before its own teardown.
    pub fn working_schema_sql(&self) -> String
    where
        T: EqlPlaintext,
    {
        let working = self.working_table();
        let mut sql = format!(
            "DROP TABLE IF EXISTS public.{working};\n\
             CREATE TABLE public.{working} (\n    \
             id BIGINT PRIMARY KEY,\n    \
             plaintext {plaintext_type} NOT NULL,\n    \
             payload eql_v2_encrypted\n);\n",
            plaintext_type = T::PLAINTEXT_SQL_TYPE,
        );
        for ix in &self.indexes {
            sql.push_str(&format!(
                "SELECT eql_v2.remove_search_config('{working}', 'payload', '{ix}')\n  \
                 WHERE EXISTS (\n    \
                 SELECT 1 FROM public.eql_v2_configuration c\n    \
                 WHERE c.data #> '{{tables,{working},payload,indexes,{ix}}}' IS NOT NULL\n  );\n",
            ));
            sql.push_str(&format!(
                "SELECT eql_v2.add_search_config('{working}', 'payload', '{ix}', '{cast}');\n",
                cast = T::CAST,
            ));
        }
        sql
    }

    /// The committed fixture script's header + schema + DDL, up to (not
    /// including) the rendered INSERT rows. The driver appends the INSERTs.
    /// `payload` uses the committed `column_type` (`jsonb` for #224), not
    /// `eql_v2_encrypted`; `plaintext` uses the SQL type for `T`.
    pub fn fixture_script_preamble(&self) -> String
    where
        T: EqlPlaintext,
    {
        format!(
            "-- AUTO-GENERATED by `mise run fixture:generate {name}`.\n\
             -- DO NOT EDIT BY HAND. Re-run the generator to refresh.\n\
             --\n\
             -- Encrypted via CipherStash Proxy (HMAC + ORE block terms).\n\
             -- A SQLx fixture script: opt in with\n\
             --   #[sqlx::test(fixtures(path = \"../fixtures\", scripts(\"{name}\")))]\n\
             \n\
             CREATE SCHEMA IF NOT EXISTS fixtures;\n\
             DROP TABLE IF EXISTS {table};\n\
             CREATE TABLE {table} (\n    \
             id BIGINT PRIMARY KEY,\n    \
             plaintext {plaintext_type} NOT NULL,\n    \
             payload {column_type} NOT NULL\n);\n\n",
            name = self.name,
            table = self.fixture_table(),
            plaintext_type = T::PLAINTEXT_SQL_TYPE,
            column_type = self.column_type,
        )
    }

    /// SQL run on the *direct* connection to render each working-table row as
    /// a committed INSERT. `format('%L', ...)` does server-side literal
    /// escaping; row values never pass through Rust string interpolation.
    /// `(payload).data::text` unwraps the `eql_v2_encrypted` composite to the
    /// JSONB text that the committed `jsonb` column stores.
    pub fn render_rows_sql(&self) -> String {
        format!(
            "SELECT format(\n  \
             'INSERT INTO {table} (id, plaintext, payload) VALUES (%L, %L, %L::{column_type});',\n  \
             id, plaintext, (payload).data::text\n) \
             FROM public.{working} ORDER BY id",
            table = self.fixture_table(),
            column_type = self.column_type,
            working = self.working_table(),
        )
    }

    /// Check the spec is *complete*: it has at least one index and at least
    /// one value. These cannot be checked at construction — the builder does
    /// not know when the chain is finished — so the driver calls this before
    /// generating any SQL. Token safety is already guaranteed by the
    /// `FixtureIdentifier`/`ColumnType` newtypes; this method covers only what
    /// construction cannot.
    pub fn check_complete(&self) -> anyhow::Result<()> {
        if self.indexes.is_empty() {
            anyhow::bail!("fixture {:?} declares no indexes", self.name.as_str());
        }
        if self.values.is_empty() {
            anyhow::bail!("fixture {:?} has no values", self.name.as_str());
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn int4_spec() -> FixtureSpec<'static, i32> {
        const VALUES: &[i32] = &[-1, 1, 42];
        FixtureSpec::new("eql_v2_int4")
            .with_index("unique")
            .with_index("ore")
            .with_column_type("jsonb")
            .with_values(VALUES)
    }

    #[test]
    fn derives_paths_from_the_name() {
        let s = int4_spec();
        assert_eq!(s.fixture_table(), "fixtures.eql_v2_int4");
        assert_eq!(s.working_table(), "_fixture_eql_v2_int4");
        assert_eq!(s.script_filename(), "eql_v2_int4.sql");
    }

    #[test]
    fn records_indexes_in_order() {
        let s = int4_spec();
        let names: Vec<&str> = s.indexes().iter().map(FixtureIdentifier::as_str).collect();
        assert_eq!(names, vec!["unique", "ore"]);
    }

    #[test]
    fn column_type_defaults_to_jsonb() {
        const V: &[i32] = &[1];
        let s = FixtureSpec::new("x").with_index("unique").with_values(V);
        assert_eq!(s.column_type().as_str(), "jsonb");
    }

    #[test]
    fn valid_spec_passes_completeness_check() {
        assert!(int4_spec().check_complete().is_ok());
    }

    #[test]
    #[should_panic(expected = "is not a valid identifier")]
    fn validation_rejects_a_bad_name() {
        // A bad name panics at construction, before the chain continues.
        let _ = FixtureSpec::<'static, i32>::new("Bad-Name");
    }

    #[test]
    #[should_panic(expected = "is not in the allowlist")]
    fn validation_rejects_a_non_allowlisted_column_type() {
        // A non-allowlisted column type panics in `.with_column_type()`.
        let _ = FixtureSpec::<'static, i32>::new("x").with_column_type("text");
    }

    #[test]
    #[should_panic(expected = "is not a valid identifier")]
    fn validation_rejects_a_bad_index_name() {
        // A bad index name panics in `.with_index()`.
        let _ = FixtureSpec::<'static, i32>::new("x").with_index("BAD IX");
    }

    #[test]
    fn completeness_rejects_a_spec_with_no_indexes() {
        const V: &[i32] = &[1];
        let s = FixtureSpec::new("x").with_values(V);
        assert!(s.check_complete().is_err());
    }

    #[test]
    fn completeness_rejects_a_spec_with_no_values() {
        const V: &[i32] = &[];
        let s = FixtureSpec::new("x").with_index("unique").with_values(V);
        assert!(s.check_complete().is_err());
    }

    #[test]
    fn working_schema_sql_drops_and_creates_the_working_table() {
        let sql = int4_spec().working_schema_sql();
        assert!(sql.contains("DROP TABLE IF EXISTS public._fixture_eql_v2_int4;"));
        assert!(sql.contains("CREATE TABLE public._fixture_eql_v2_int4 ("));
        assert!(sql.contains("id BIGINT PRIMARY KEY"));
        assert!(sql.contains("plaintext integer NOT NULL"));
        // The working table's payload is eql_v2_encrypted so Proxy encrypts inserts.
        assert!(sql.contains("payload eql_v2_encrypted"));
    }

    #[test]
    fn working_schema_sql_configures_each_index_idempotently() {
        let sql = int4_spec().working_schema_sql();
        // remove first (idempotent), then add, for both indexes.
        assert!(sql
            .contains("eql_v2.remove_search_config('_fixture_eql_v2_int4', 'payload', 'unique')"));
        assert!(sql.contains(
            "eql_v2.add_search_config('_fixture_eql_v2_int4', 'payload', 'unique', 'int')"
        ));
        assert!(
            sql.contains("eql_v2.remove_search_config('_fixture_eql_v2_int4', 'payload', 'ore')")
        );
        assert!(sql
            .contains("eql_v2.add_search_config('_fixture_eql_v2_int4', 'payload', 'ore', 'int')"));
    }

    #[test]
    fn working_schema_sql_uses_the_t_cast_not_the_column_type() {
        // payload column-type is jsonb, but the EQL cast is i32::CAST = "int".
        let sql = int4_spec().working_schema_sql();
        assert!(sql.contains("'int')")); // cast_as argument
        assert!(!sql.contains("'jsonb')")); // jsonb is the committed type, not the cast
    }

    #[test]
    fn fixture_script_preamble_renders_the_committed_table() {
        let preamble = int4_spec().fixture_script_preamble();
        // header
        assert!(preamble.contains("AUTO-GENERATED"));
        assert!(preamble.contains("DO NOT EDIT BY HAND"));
        assert!(preamble.contains("mise run fixture:generate eql_v2_int4"));
        assert!(preamble.contains("HMAC + ORE block terms"));
        // schema + table in the fixtures schema, jsonb payload
        assert!(preamble.contains("CREATE SCHEMA IF NOT EXISTS fixtures;"));
        assert!(preamble.contains("DROP TABLE IF EXISTS fixtures.eql_v2_int4;"));
        assert!(preamble.contains("CREATE TABLE fixtures.eql_v2_int4 ("));
        assert!(preamble.contains("id BIGINT PRIMARY KEY"));
        assert!(preamble.contains("plaintext integer NOT NULL"));
        assert!(preamble.contains("payload jsonb NOT NULL"));
    }

    #[test]
    fn fixture_script_preamble_uses_the_committed_column_type() {
        // The committed table uses .with_column_type(), NOT eql_v2_encrypted.
        let preamble = int4_spec().fixture_script_preamble();
        assert!(!preamble.contains("eql_v2_encrypted"));
    }

    #[test]
    fn render_rows_sql_projects_format_l_over_the_working_table() {
        let sql = int4_spec().render_rows_sql();
        assert!(sql.contains("INSERT INTO fixtures.eql_v2_int4 (id, plaintext, payload) VALUES"));
        assert!(sql.contains("%L, %L, %L::jsonb"));
        assert!(sql.contains("FROM public._fixture_eql_v2_int4"));
        assert!(sql.contains("(payload).data::text"));
        assert!(sql.contains("ORDER BY id"));
    }
}
