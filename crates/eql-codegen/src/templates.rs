//! Rust fixture-const renderer. The SQL surface is rendered from minijinja
//! templates (see `context.rs`); this file emits only the committed
//! `<T>_values.rs` consts, which stay byte-exact.

use eql_scalars::ScalarSpec;

/// Body for tests/sqlx/src/fixtures/<T>_values.rs. The writer prepends the
/// AUTO-GENERATED Rust header, so the body carries none.
/// Port of templates.py `render_fixture_values_rs`.
pub fn render_fixture_values_rs(spec: &ScalarSpec) -> String {
    let token = spec.token;
    let rust_type = spec.kind.rust_type();
    let mut literals = String::new();
    for &f in spec.fixtures {
        literals.push_str(&format!("    {},\n", f.render_literal(spec.kind)));
    }
    format!(
        "//! Fixture plaintext values for the {token} encrypted-domain family.\n\
         //!\n\
         //! Generated from tasks/codegen/types/{token}.toml `[fixture] values` —\n\
         //! the single source of truth shared by the fixture generator\n\
         //! (`fixtures::eql_v2_{token}`) and the matrix oracle\n\
         //! (`ScalarType::FIXTURE_VALUES`).\n\n\
         /// Distinct plaintext values present in the `eql_v2_{token}` fixture.\n\
         pub const VALUES: &[{rust_type}] = &[\n\
         {literals}\
         ];\n"
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use eql_scalars::CATALOG;

    fn spec(token: &str) -> &'static ScalarSpec {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .expect("catalog token")
    }

    #[test]
    fn fixture_values_rs_emits_typed_const_for_int4() {
        let body = render_fixture_values_rs(spec("int4"));
        assert!(body.contains("pub const VALUES: &[i32] = &["));
        assert!(body.contains("tasks/codegen/types/int4.toml"));
        assert!(body.contains("    i32::MIN,\n"));
        assert!(body.contains("    i32::MAX,\n"));
        assert!(body.contains("    -1,\n"));
        assert!(body.contains("    0,\n"));
        assert!(body.contains("    1,\n"));
        assert!(!body.contains("AUTO-GENERATED"));
    }

    #[test]
    fn fixture_values_rs_preserves_catalog_order() {
        let body = render_fixture_values_rs(spec("int4"));
        let min = body.find("i32::MIN").unwrap();
        let zero = body.find("    0,").unwrap();
        let max = body.find("i32::MAX").unwrap();
        assert!(min < zero && zero < max);
    }

    // Adapted from the plan's `fixture_values_rs_int8_uses_i64`: the shipped
    // CATALOG has no int8 (deliberately reserved for a later branch), so this
    // exercises the second committed non-i32 type — int2 (i16).
    #[test]
    fn fixture_values_rs_int2_uses_i16() {
        let body = render_fixture_values_rs(spec("int2"));
        assert!(body.contains("pub const VALUES: &[i16] = &["));
        assert!(body.contains("    i16::MIN,\n"));
        assert!(body.contains("    -30000,\n"));
    }
}
