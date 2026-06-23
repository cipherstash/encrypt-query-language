//! minijinja environment + serde context structs + relocated logic helpers.

use crate::consts::*;
use crate::operator_surface::Operator;
use eql_scalars::{DomainSpec, Term};

/// Build the minijinja environment with the embedded templates: one whole-file
/// template per output file (`types`/`functions`/`operators`/`aggregates`) plus
/// the per-kind function-body partials that `functions.sql` dynamically
/// `{% include %}`s. Templates are compiled in via `include_str!` — no runtime
/// file IO.
pub fn environment() -> minijinja::Environment<'static> {
    let mut env = minijinja::Environment::new();
    // Preserve each template file's trailing newline so generated SQL files end
    // with one (minijinja strips it by default).
    env.set_keep_trailing_newline(true);
    env.add_template("types.sql", include_str!("../templates/types.sql.j2"))
        .expect("types.sql template");
    env.add_template(
        "functions.sql",
        include_str!("../templates/functions.sql.j2"),
    )
    .expect("functions.sql template");
    // Per-kind function bodies, dynamically `{% include %}`d by the parent
    // `functions.sql` template based on each entry's `kind` tag
    // (Extractor/Wrapper/Unsupported -> extractor/wrapper/unsupported).
    env.add_template(
        "functions/extractor.sql.j2",
        include_str!("../templates/functions/extractor.sql.j2"),
    )
    .expect("functions/extractor.sql.j2 template");
    env.add_template(
        "functions/wrapper.sql.j2",
        include_str!("../templates/functions/wrapper.sql.j2"),
    )
    .expect("functions/wrapper.sql.j2 template");
    env.add_template(
        "functions/unsupported.sql.j2",
        include_str!("../templates/functions/unsupported.sql.j2"),
    )
    .expect("functions/unsupported.sql.j2 template");
    env.add_template(
        "operators.sql",
        include_str!("../templates/operators.sql.j2"),
    )
    .expect("operators.sql template");
    env.add_template(
        "aggregates.sql",
        include_str!("../templates/aggregates.sql.j2"),
    )
    .expect("aggregates.sql template");
    env.add_global("schema", SCHEMA);
    env
}

/// One idempotent CREATE DOMAIN block, with SQL-required values precomputed.
#[derive(serde::Serialize)]
pub struct DomainBlock {
    pub typname: String,   // sql_str-escaped bare name, e.g. int4_ord_ore
    pub name: String,      // raw bare name (unescaped), e.g. int4_ord_ore
    pub keys: Vec<String>, // ordered, sql_str-escaped key tokens (envelope + ciphertext + term keys)
    // sql_str-escaped keys whose payload must be a non-empty array (the ORE term
    // `ob`). Derived from the domain's terms exactly like `keys`, so the template
    // stays term-agnostic — it renders a non-empty-array CHECK per key without
    // hardcoding `ob`. Empty for non-ORE domains. See issue #262.
    pub nonempty_array_keys: Vec<String>,
}

#[derive(serde::Serialize)]
pub struct TypesContext {
    pub token: String,
    pub domains: Vec<DomainBlock>,
}

/// Build the per-domain block data (port of `render_domain_block`'s value logic,
/// minus comment prose and the CHECK skeleton — those are template-resident).
pub fn domain_block(token: &str, domain: &DomainSpec) -> DomainBlock {
    let name = domain.name_with_token(token);

    let mut keys: Vec<String> = ENVELOPE_KEYS.iter().map(|k| sql_str(k)).collect();
    for k in Term::term_json_keys(domain.terms) {
        keys.push(sql_str(k));
    }

    DomainBlock {
        // typname is sql_str-escaped defensively: the escaping boundary stays
        // Rust-side even though real catalog names carry no quotes.
        typname: sql_str(&name),
        name,
        keys,
        // Derived from the terms the same way `keys` is — the rule lives on
        // `Term::nonempty_array_key`, not here.
        nonempty_array_keys: Term::nonempty_array_keys(domain.terms)
            .into_iter()
            .map(sql_str)
            .collect(),
    }
}

/// One SQL parameter (name + SQL type), shared by wrapper and
/// unsupported-operator signatures and their `@param` docs tags.
#[derive(serde::Serialize)]
pub struct SqlParam {
    pub name: &'static str, // "a", "b", or "selector"
    pub ty: String,
}

/// One generated function entry. The serde tag drives the template's three-way
/// switch; the unsupported-operator arm is never merged with the others (footgun
/// separation — its body must always raise).
#[derive(serde::Serialize)]
#[serde(tag = "kind")]
pub enum FnEntry {
    Extractor {
        ret: String,       // e.g. eql_v3.hmac_256 (selection STAYS in Rust)
        extractor: String, // e.g. eq_term
        ctor: String,      // e.g. hmac_256 (called as {{ schema }}.{{ ctor }})
    },
    Wrapper {
        op: String,            // SQL operator used in the body, e.g. =
        function_name: String, // e.g. eq
        args: [SqlParam; 2],
        call_a: String, // e.g. eql_v3.eq_term(a)   (embeds extract_arg cast logic)
        call_b: String, // e.g. eql_v3.eq_term(b::eql_v3.int4_eq)
    },
    Unsupported {
        operator_lit: String,  // sql_str(op), escaped content for the RAISE literal
        function_name: String, // e.g. lt / "->" / "#>"
        args: [SqlParam; 2],
        returns: String, // boolean / text / jsonb / domain (selection STAYS in Rust)
    },
}

#[derive(serde::Serialize)]
pub struct FunctionsContext {
    pub requires: Vec<String>, // dependency paths only; template emits "-- REQUIRE:"
    pub token: String,
    pub name: String,       // full domain name (token+suffix)
    pub dom: String,        // schema-qualified domain, e.g. eql_v3.int4_eq
    pub domain_lit: String, // sql_str(dom), defensively escaped for the RAISE literal
    pub entries: Vec<FnEntry>,
}

/// Build the inlinable index-extractor entry for a domain term.
///
/// The `RETURNS` type name equals the constructor name (`hmac_256`,
/// `ore_block_256`); qualify it with `SCHEMA` — the same schema as the
/// body's constructor call — so the declared return type and the call stay in
/// lockstep. `Term::returns()` is intentionally not used.
pub fn extractor_entry(term: Term) -> FnEntry {
    FnEntry::Extractor {
        ret: format!("{SCHEMA}.{}", term.ctor()),
        extractor: term.extractor().to_string(),
        ctor: term.ctor().to_string(),
    }
}

/// Build an inlinable comparison-wrapper entry for a supported operator.
/// `dom` is the schema-qualified domain name; `op` is the already-resolved
/// operator (the caller iterates `OPERATORS`, so no symbol re-lookup is needed).
pub fn wrapper_entry(
    dom: &str,
    op: &Operator,
    arg_a: &str,
    arg_b: &str,
    extractor: &str,
) -> FnEntry {
    FnEntry::Wrapper {
        op: op.symbol.to_string(),
        function_name: op.function_name.to_string(),
        args: [
            SqlParam {
                name: "a",
                ty: arg_a.to_string(),
            },
            SqlParam {
                name: "b",
                ty: arg_b.to_string(),
            },
        ],
        call_a: extract_arg(arg_a, extractor, dom, "a"),
        call_b: extract_arg(arg_b, extractor, dom, "b"),
    }
}

/// Build an unsupported-operator entry. Every such entry shares one uniform
/// `RAISE EXCEPTION` body; only signature facts vary. `op` is the
/// already-resolved operator (no symbol re-lookup needed).
pub fn unsupported_entry(op: &Operator, args: [SqlParam; 2], returns: &str) -> FnEntry {
    FnEntry::Unsupported {
        // operator_lit is sql_str-escaped defensively for the single-quoted RAISE literal.
        operator_lit: sql_str(op.symbol),
        function_name: op.function_name.to_string(),
        args,
        returns: returns.to_string(),
    }
}

/// One CREATE OPERATOR declaration, with the optional metadata line precomputed.
#[derive(serde::Serialize)]
pub struct OpEntry {
    pub symbol: String,
    pub function_name: String, // unqualified; schema literal lives in the template
    pub leftarg: String,
    pub rightarg: String,
    pub metadata: Option<String>, // e.g. "COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel"
}

#[derive(serde::Serialize)]
pub struct OperatorsContext {
    pub requires: Vec<String>,
    pub token: String,
    pub name: String,
    pub dom: String,
    pub operators: Vec<OpEntry>,
}

/// Build one CREATE OPERATOR entry. Planner metadata is emitted only when the
/// current domain supports the operator and the operator carries metadata (the
/// `@>`/`<@` empty-metadata case collapses to `None`).
pub fn operator_entry(op: &Operator, leftarg: &str, rightarg: &str, supported: bool) -> OpEntry {
    let metadata = if supported {
        op.metadata.render()
    } else {
        None
    };
    OpEntry {
        symbol: op.symbol.to_string(),
        function_name: op.function_name.to_string(),
        leftarg: leftarg.to_string(),
        rightarg: rightarg.to_string(),
        metadata,
    }
}

#[derive(serde::Serialize)]
pub struct AggregatesContext {
    pub requires: Vec<String>, // dependency paths only; template emits "-- REQUIRE:"
    pub token: String,
    pub name: String,
    pub dom: String,                        // schema-qualified domain, hoisted
    pub aggregates: &'static [AggregateOp], // == AGGREGATE_OPS
}

/// The schema-qualified SQL domain type name, e.g. `eql_v3.int4_eq`.
/// Port of `domain_name`.
pub fn domain_name(name: &str) -> String {
    format!("{SCHEMA}.{name}")
}

/// The extractor-call SQL for one operand, casting jsonb to the domain first.
/// Port of `_extract_arg`. `dom` is the schema-qualified domain name.
pub fn extract_arg(arg_type: &str, extractor: &str, dom: &str, arg: &str) -> String {
    if arg_type == "jsonb" {
        format!("{SCHEMA}.{extractor}({arg}::{dom})")
    } else {
        format!("{SCHEMA}.{extractor}({arg})")
    }
}

/// One aggregate operator definition (min or max). Only SQL-required facts: the
/// state-function name is the mechanical suffix `{{ a.name }}_sfunc` in the
/// template, and English comment phrases are template-resident.
#[derive(serde::Serialize)]
pub struct AggregateOp {
    pub name: &'static str,       // min / max
    pub comparator: &'static str, // < / >
}

/// The two aggregate ops in (min, max) order. Port of `AGGREGATE_OPS`.
pub const AGGREGATE_OPS: &[AggregateOp] = &[
    AggregateOp {
        name: "min",
        comparator: "<",
    },
    AggregateOp {
        name: "max",
        comparator: ">",
    },
];

/// True if any of the domain's terms provides ordering (`<` `<=` `>` `>=`),
/// gating `min`/`max` aggregate emission. Asks a per-term *capability* (not the
/// whole-domain first-term `Role`), so a `[Hm, Ore]` domain — first term `Hm`,
/// `Role::Eq` — is still correctly ord-capable and emits aggregates.
pub fn is_ord_capable(terms: &[Term]) -> bool {
    terms.iter().any(|t| t.provides_ordering())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn domain_name_qualifies_with_schema() {
        assert_eq!(domain_name("int4_eq"), "eql_v3.int4_eq");
    }

    #[test]
    fn is_ord_capable_is_true_when_any_term_provides_ordering() {
        assert!(is_ord_capable(&[Term::Ore]));
        assert!(is_ord_capable(&[Term::Hm, Term::Ore]));
        assert!(is_ord_capable(&[Term::Hm, Term::Ore, Term::Bloom]));
        assert!(!is_ord_capable(&[Term::Hm]));
        assert!(!is_ord_capable(&[Term::Bloom]));
        assert!(!is_ord_capable(&[]));
    }

    #[test]
    fn is_ord_capable_unions_across_terms() {
        // An ord term anywhere in the list makes the domain ord-capable,
        // regardless of position — consistent with operators_for_terms' union,
        // not the first-term role. (No catalog domain is multi-term today; this
        // pins the order-independent semantics for a future mixed-term domain.)
        assert!(is_ord_capable(&[Term::Hm, Term::Ore]));
        assert!(is_ord_capable(&[Term::Ore, Term::Hm]));
        assert!(!is_ord_capable(&[Term::Hm, Term::Bloom]));
    }

    #[test]
    fn environment_has_whole_file_and_partial_templates() {
        let env = environment();
        for name in [
            // One whole-file template per generated SQL file.
            "types.sql",
            "functions.sql",
            "operators.sql",
            "aggregates.sql",
            // Per-kind partials included by functions.sql.
            "functions/extractor.sql.j2",
            "functions/wrapper.sql.j2",
            "functions/unsupported.sql.j2",
        ] {
            assert!(env.get_template(name).is_ok(), "missing template {name}");
        }
    }

    #[test]
    fn operator_entry_emits_metadata_only_when_supported() {
        use crate::operator_surface::operator;

        // (symbol, domain, supported) -> expected `CREATE OPERATOR` metadata
        // clause. Adding a term that carries operator metadata is one new row
        // here, not another hand-rolled assertion block.
        let cases: &[(&str, &str, bool, Option<&str>)] = &[
            // Supported comparison operator carries its planner metadata.
            (
                "=",
                "eql_v3.int4_eq",
                true,
                Some("COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel"),
            ),
            // The same operator, unsupported on this domain → no metadata line.
            ("=", "eql_v3.int4", false, None),
            // Supported but metadata-less operator (`->`) → still no metadata.
            ("->", "eql_v3.int4_eq", true, None),
            // `@>` carries containment metadata when supported (the Bloom
            // `text_match` path).
            (
                "@>",
                "eql_v3.text_match",
                true,
                Some("COMMUTATOR = <@, RESTRICT = contsel, JOIN = contjoinsel"),
            ),
            // ... but suppressed when `@>` is a blocker (non-Bloom domains),
            // which is why the int4 reference is unchanged.
            ("@>", "eql_v3.int4_eq", false, None),
        ];

        for (symbol, dom, supported, expected) in cases {
            let entry = operator_entry(&operator(symbol), dom, dom, *supported);
            assert_eq!(entry.symbol, *symbol);
            assert_eq!(
                entry.metadata.as_deref(),
                *expected,
                "operator {symbol} on {dom} (supported={supported})",
            );
        }
    }
}
