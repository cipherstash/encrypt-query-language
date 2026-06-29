//! The Rust payload-bindings emitter: renders `eql_domains::CATALOG` to the
//! committed `crates/eql-bindings/src/v3/<family>.rs` structs + `DomainType`
//! impls and the generated `inventory.rs` (`all()`), the same generate-to-
//! committed-source mechanism `generate.rs` uses for SQL. Token stream via
//! `quote!`, formatted by `prettyplease::unparse` then the repo's stable
//! `rustfmt` (prettyplease is rustfmt-clean but not rustfmt-identical), with
//! the `// @generated` ownership marker prepended as line 1.

use proc_macro2::TokenStream;

use crate::consts::RUST_GENERATED_MARKER;

/// Format a token stream into committed Rust source. `prettyplease::unparse`
/// gives deterministic, parseable output; the `@generated` marker is prepended
/// as line 1 (syn/prettyplease drop free-standing line comments, so it cannot
/// live inside the token stream); then the whole file is run through `rustfmt`
/// so it is byte-for-byte what `cargo fmt --check` (`mise run test:crates`)
/// expects.
pub fn format_rs(tokens: TokenStream) -> String {
    let file: syn::File = syn::parse2(tokens).expect("emit syntactically valid Rust");
    let body = prettyplease::unparse(&file);
    let with_marker = format!("{RUST_GENERATED_MARKER}\n{body}");
    rustfmt(&with_marker)
}

/// Pipe Rust source through the repo's `rustfmt` (stdin → stdout). Fails loudly:
/// codegen is a dev-time tool and `rustfmt` is always present where `cargo fmt`
/// runs. `rustfmt` preserves the leading `// @generated` line comment, so the
/// marker stays exactly line 1.
fn rustfmt(src: &str) -> String {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("rustfmt")
        .args(["--edition", "2021"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn rustfmt (is the Rust toolchain on PATH?)");
    child
        .stdin
        .take()
        .expect("rustfmt stdin")
        .write_all(src.as_bytes())
        .expect("write to rustfmt");
    let out = child.wait_with_output().expect("wait for rustfmt");
    assert!(
        out.status.success(),
        "rustfmt failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    String::from_utf8(out.stdout).expect("rustfmt output is UTF-8")
}

#[cfg(test)]
mod tests {
    use super::*;
    use quote::quote;

    #[test]
    fn format_rs_prepends_marker_and_is_rustfmt_clean() {
        // Deliberately mis-spaced input: rustfmt must normalize it, proving the
        // rustfmt pass runs (prettyplease alone would not re-sort imports).
        let out = format_rs(quote! { use b::B; use a::A; pub struct Foo { pub v: u16 } });
        assert_eq!(out.lines().next().unwrap(), RUST_GENERATED_MARKER);
        assert!(out.contains("pub struct Foo"));
        assert!(out.contains("pub v: u16"));
        // rustfmt sorts `use a::A;` before `use b::B;`
        assert!(out.find("use a::A;").unwrap() < out.find("use b::B;").unwrap());
        // Idempotent: re-running rustfmt over the output changes nothing.
        assert_eq!(rustfmt(&out), out);
    }
}
