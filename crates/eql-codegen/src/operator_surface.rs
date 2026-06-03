//! The generated operator surface (port of operator_surface.py).

/// One operator in the generated surface.
#[derive(Clone, Copy)]
pub struct Operator {
    pub symbol: &'static str,
    pub function_name: &'static str,
    pub signatures: &'static [OperatorSignature],
    pub metadata: OperatorMetadata,
}

/// Optional `CREATE OPERATOR` planner metadata. Pure data — whether it is
/// emitted is a per-domain decision (supported operators only), not a property
/// of the operator's category.
#[derive(Clone, Copy)]
pub struct OperatorMetadata {
    pub restrict: Option<&'static str>,
    pub join: Option<&'static str>,
    pub commutator: Option<&'static str>,
    pub negator: Option<&'static str>,
}

impl OperatorMetadata {
    /// Metadata with no planner hints — the common case for operators that carry
    /// no commutator/negator/selectivity estimators.
    pub const fn none() -> Self {
        Self {
            restrict: None,
            join: None,
            commutator: None,
            negator: None,
        }
    }

    /// Render the `CREATE OPERATOR` metadata clause, or `None` when no hint is
    /// present (the `@>`/`<@` symmetric-but-empty case collapses to `None`).
    pub fn render(self) -> Option<String> {
        let mut extras = Vec::new();
        if let Some(c) = self.commutator {
            extras.push(format!("COMMUTATOR = {c}"));
        }
        if let Some(n) = self.negator {
            extras.push(format!("NEGATOR = {n}"));
        }
        if let Some(r) = self.restrict {
            extras.push(format!("RESTRICT = {r}"));
        }
        if let Some(j) = self.join {
            extras.push(format!("JOIN = {j}"));
        }
        (!extras.is_empty()).then(|| extras.join(", "))
    }
}

/// A type position in a PostgreSQL operator overload. `Domain` renders to the
/// concrete encrypted domain being generated; every other slot renders to a
/// fixed PostgreSQL type name.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum TypeSlot {
    Domain,
    Jsonb,
    Text,
    Integer,
    TextArray,
    Jsonpath,
    Boolean,
}

impl TypeSlot {
    fn render(self, dom: &str) -> String {
        match self {
            TypeSlot::Domain => dom.to_string(),
            TypeSlot::Jsonb => "jsonb".to_string(),
            TypeSlot::Text => "text".to_string(),
            TypeSlot::Integer => "integer".to_string(),
            TypeSlot::TextArray => "text[]".to_string(),
            TypeSlot::Jsonpath => "jsonpath".to_string(),
            TypeSlot::Boolean => "boolean".to_string(),
        }
    }
}

/// One PostgreSQL-shaped operator overload: left/right argument slots and the
/// return slot.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct OperatorSignature {
    pub left: TypeSlot,
    pub right: TypeSlot,
    pub returns: TypeSlot,
}

/// An `OperatorSignature` with every slot resolved to a concrete SQL type name.
pub struct RenderedSignature {
    pub left: String,
    pub right: String,
    pub returns: String,
}

impl OperatorSignature {
    pub fn render(self, dom: &str) -> RenderedSignature {
        RenderedSignature {
            left: self.left.render(dom),
            right: self.right.render(dom),
            returns: self.returns.render(dom),
        }
    }
}

/// Terse constructor for the static signature tables below.
const fn sig(left: TypeSlot, right: TypeSlot, returns: TypeSlot) -> OperatorSignature {
    OperatorSignature {
        left,
        right,
        returns,
    }
}

/// Symmetric boolean overloads (`domain`/`jsonb` convenience pairs), shared by
/// `=`, `<>`, `<`, `<=`, `>`, `>=`, `@>`, `<@`.
const BOOL_SYMMETRIC_SIGNATURES: &[OperatorSignature] = &[
    sig(TypeSlot::Domain, TypeSlot::Domain, TypeSlot::Boolean),
    sig(TypeSlot::Domain, TypeSlot::Jsonb, TypeSlot::Boolean),
    sig(TypeSlot::Jsonb, TypeSlot::Domain, TypeSlot::Boolean),
];

/// `->` path-selector overloads (returns the domain).
const ARROW_SIGNATURES: &[OperatorSignature] = &[
    sig(TypeSlot::Domain, TypeSlot::Text, TypeSlot::Domain),
    sig(TypeSlot::Domain, TypeSlot::Integer, TypeSlot::Domain),
    sig(TypeSlot::Jsonb, TypeSlot::Domain, TypeSlot::Domain),
];

/// `->>` path-selector overloads (returns text).
const ARROW_TEXT_SIGNATURES: &[OperatorSignature] = &[
    sig(TypeSlot::Domain, TypeSlot::Text, TypeSlot::Text),
    sig(TypeSlot::Domain, TypeSlot::Integer, TypeSlot::Text),
    sig(TypeSlot::Jsonb, TypeSlot::Domain, TypeSlot::Text),
];

/// `?` key-existence overload.
const HAS_KEY_SIGNATURES: &[OperatorSignature] =
    &[sig(TypeSlot::Domain, TypeSlot::Text, TypeSlot::Boolean)];

/// `?|` / `?&` any/all-keys overloads.
const HAS_ANY_KEYS_SIGNATURES: &[OperatorSignature] = &[sig(
    TypeSlot::Domain,
    TypeSlot::TextArray,
    TypeSlot::Boolean,
)];

/// `@?` / `@@` jsonpath-predicate overloads.
const JSONPATH_SIGNATURES: &[OperatorSignature] =
    &[sig(TypeSlot::Domain, TypeSlot::Jsonpath, TypeSlot::Boolean)];

/// `#>` path-extract overload (returns jsonb).
const PATH_EXTRACT_JSONB_SIGNATURES: &[OperatorSignature] =
    &[sig(TypeSlot::Domain, TypeSlot::TextArray, TypeSlot::Jsonb)];

/// `#>>` path-extract overload (returns text).
const PATH_EXTRACT_TEXT_SIGNATURES: &[OperatorSignature] =
    &[sig(TypeSlot::Domain, TypeSlot::TextArray, TypeSlot::Text)];

/// `-` delete-key overloads.
const DELETE_SIGNATURES: &[OperatorSignature] = &[
    sig(TypeSlot::Domain, TypeSlot::Text, TypeSlot::Jsonb),
    sig(TypeSlot::Domain, TypeSlot::Integer, TypeSlot::Jsonb),
    sig(TypeSlot::Domain, TypeSlot::TextArray, TypeSlot::Jsonb),
];

/// `#-` delete-path overload.
const DELETE_PATH_SIGNATURES: &[OperatorSignature] =
    &[sig(TypeSlot::Domain, TypeSlot::TextArray, TypeSlot::Jsonb)];

/// `||` concatenation overloads (`domain`/`jsonb` convenience pairs).
const CONCAT_SIGNATURES: &[OperatorSignature] = &[
    sig(TypeSlot::Domain, TypeSlot::Domain, TypeSlot::Jsonb),
    sig(TypeSlot::Domain, TypeSlot::Jsonb, TypeSlot::Jsonb),
    sig(TypeSlot::Jsonb, TypeSlot::Domain, TypeSlot::Jsonb),
];

/// Look up the operator metadata for a symbol. Panics on an unknown symbol —
/// the generator only ever passes catalog symbols, matching Python's KeyError.
pub fn operator(symbol: &str) -> Operator {
    OPERATORS
        .iter()
        .copied()
        .find(|o| o.symbol == symbol)
        .unwrap_or_else(|| panic!("unknown operator symbol: {symbol}"))
}

/// The generated SQL function name for an operator symbol (e.g. `eq`, `"->"`).
pub fn operator_function_name(symbol: &str) -> &'static str {
    operator(symbol).function_name
}

/// Comparison-operator metadata (commutator/negator/selectivity estimators).
const fn cmp_metadata(
    restrict: &'static str,
    join: &'static str,
    commutator: &'static str,
    negator: &'static str,
) -> OperatorMetadata {
    OperatorMetadata {
        restrict: Some(restrict),
        join: Some(join),
        commutator: Some(commutator),
        negator: Some(negator),
    }
}

/// The 20-operator catalog. Order is: comparison operators, then path-selector
/// operators, then the remaining native jsonb operators.
pub const OPERATORS: &[Operator] = &[
    Operator {
        symbol: "=",
        function_name: "eq",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: cmp_metadata("eqsel", "eqjoinsel", "=", "<>"),
    },
    Operator {
        symbol: "<>",
        function_name: "neq",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: cmp_metadata("neqsel", "neqjoinsel", "<>", "="),
    },
    Operator {
        symbol: "<",
        function_name: "lt",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: cmp_metadata("scalarltsel", "scalarltjoinsel", ">", ">="),
    },
    Operator {
        symbol: "<=",
        function_name: "lte",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: cmp_metadata("scalarlesel", "scalarlejoinsel", ">=", ">"),
    },
    Operator {
        symbol: ">",
        function_name: "gt",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: cmp_metadata("scalargtsel", "scalargtjoinsel", "<", "<="),
    },
    Operator {
        symbol: ">=",
        function_name: "gte",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: cmp_metadata("scalargesel", "scalargejoinsel", "<=", "<"),
    },
    Operator {
        symbol: "@>",
        function_name: "contains",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "<@",
        function_name: "contained_by",
        signatures: BOOL_SYMMETRIC_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "->",
        function_name: "\"->\"",
        signatures: ARROW_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "->>",
        function_name: "\"->>\"",
        signatures: ARROW_TEXT_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "?",
        function_name: "\"?\"",
        signatures: HAS_KEY_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "?|",
        function_name: "\"?|\"",
        signatures: HAS_ANY_KEYS_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "?&",
        function_name: "\"?&\"",
        signatures: HAS_ANY_KEYS_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "@?",
        function_name: "\"@?\"",
        signatures: JSONPATH_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "@@",
        function_name: "\"@@\"",
        signatures: JSONPATH_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "#>",
        function_name: "\"#>\"",
        signatures: PATH_EXTRACT_JSONB_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "#>>",
        function_name: "\"#>>\"",
        signatures: PATH_EXTRACT_TEXT_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "-",
        function_name: "\"-\"",
        signatures: DELETE_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "#-",
        function_name: "\"#-\"",
        signatures: DELETE_PATH_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
    Operator {
        symbol: "||",
        function_name: "\"||\"",
        signatures: CONCAT_SIGNATURES,
        metadata: OperatorMetadata::none(),
    },
];

#[cfg(test)]
mod tests {
    use super::*;

    fn rendered_signatures(op: &str) -> Vec<(String, String, String)> {
        operator(op)
            .signatures
            .iter()
            .map(|sig| sig.render("eql_v3.int4_ord"))
            .map(|sig| (sig.left, sig.right, sig.returns))
            .collect()
    }

    #[test]
    fn signature_slots_render_for_domain() {
        let sig = OperatorSignature {
            left: TypeSlot::Domain,
            right: TypeSlot::Text,
            returns: TypeSlot::Boolean,
        };
        let rendered = sig.render("eql_v3.int4_eq");
        assert_eq!(rendered.left, "eql_v3.int4_eq");
        assert_eq!(rendered.right, "text");
        assert_eq!(rendered.returns, "boolean");
    }

    #[test]
    fn operator_catalog_carries_postgres_signatures() {
        let arrow = operator("->");
        let rendered: Vec<_> = arrow
            .signatures
            .iter()
            .map(|sig| sig.render("eql_v3.int4"))
            .map(|sig| (sig.left, sig.right, sig.returns))
            .collect();
        assert_eq!(
            rendered,
            vec![
                (
                    "eql_v3.int4".to_string(),
                    "text".to_string(),
                    "eql_v3.int4".to_string()
                ),
                (
                    "eql_v3.int4".to_string(),
                    "integer".to_string(),
                    "eql_v3.int4".to_string()
                ),
                (
                    "jsonb".to_string(),
                    "eql_v3.int4".to_string(),
                    "eql_v3.int4".to_string()
                ),
            ]
        );
    }

    #[test]
    fn equality_signatures_match_existing_symmetric_shapes() {
        assert_eq!(
            rendered_signatures("="),
            vec![
                (
                    "eql_v3.int4_ord".into(),
                    "eql_v3.int4_ord".into(),
                    "boolean".into()
                ),
                ("eql_v3.int4_ord".into(), "jsonb".into(), "boolean".into()),
                ("jsonb".into(), "eql_v3.int4_ord".into(), "boolean".into()),
            ]
        );
    }

    #[test]
    fn native_jsonb_signatures_match_existing_operator_shapes() {
        assert_eq!(
            rendered_signatures("||"),
            vec![
                (
                    "eql_v3.int4_ord".into(),
                    "eql_v3.int4_ord".into(),
                    "jsonb".into()
                ),
                ("eql_v3.int4_ord".into(), "jsonb".into(), "jsonb".into()),
                ("jsonb".into(), "eql_v3.int4_ord".into(), "jsonb".into()),
            ]
        );
        assert_eq!(
            rendered_signatures("?|"),
            vec![("eql_v3.int4_ord".into(), "text[]".into(), "boolean".into())]
        );
    }

    #[test]
    fn jsonpath_and_text_array_signatures_render() {
        // `@?` carries the jsonpath slot and `#>`/`#>>` carry the text[] slot —
        // the slot kinds not asserted by the symmetric/arrow signature tests.
        assert_eq!(
            rendered_signatures("@?"),
            vec![(
                "eql_v3.int4_ord".into(),
                "jsonpath".into(),
                "boolean".into()
            )]
        );
        assert_eq!(
            rendered_signatures("#>"),
            vec![("eql_v3.int4_ord".into(), "text[]".into(), "jsonb".into())]
        );
        assert_eq!(
            rendered_signatures("#>>"),
            vec![("eql_v3.int4_ord".into(), "text[]".into(), "text".into())]
        );
    }

    #[test]
    fn twenty_operators_total() {
        assert_eq!(OPERATORS.len(), 20);
    }

    #[test]
    fn every_operator_has_signatures() {
        assert!(
            OPERATORS.iter().all(|o| !o.signatures.is_empty()),
            "every catalog operator must declare at least one signature"
        );
    }

    #[test]
    fn no_like_operators() {
        assert!(OPERATORS
            .iter()
            .all(|o| o.symbol != "~~" && o.symbol != "~~*"));
    }

    #[test]
    fn function_names() {
        assert_eq!(operator_function_name("="), "eq");
        assert_eq!(operator_function_name("<>"), "neq");
        assert_eq!(operator_function_name("<"), "lt");
        assert_eq!(operator_function_name("<="), "lte");
        assert_eq!(operator_function_name(">"), "gt");
        assert_eq!(operator_function_name(">="), "gte");
        assert_eq!(operator_function_name("@>"), "contains");
        assert_eq!(operator_function_name("<@"), "contained_by");
        assert_eq!(operator_function_name("->"), "\"->\"");
        assert_eq!(operator_function_name("->>"), "\"->>\"");
        assert_eq!(operator_function_name("?"), "\"?\"");
        assert_eq!(operator_function_name("?|"), "\"?|\"");
        assert_eq!(operator_function_name("?&"), "\"?&\"");
        assert_eq!(operator_function_name("@?"), "\"@?\"");
        assert_eq!(operator_function_name("@@"), "\"@@\"");
        assert_eq!(operator_function_name("#>"), "\"#>\"");
        assert_eq!(operator_function_name("#>>"), "\"#>>\"");
        assert_eq!(operator_function_name("-"), "\"-\"");
        assert_eq!(operator_function_name("#-"), "\"#-\"");
        assert_eq!(operator_function_name("||"), "\"||\"");
    }

    #[test]
    fn selectivity_estimators() {
        assert_eq!(operator("=").metadata.restrict, Some("eqsel"));
        assert_eq!(operator("=").metadata.join, Some("eqjoinsel"));
        assert_eq!(operator("<>").metadata.restrict, Some("neqsel"));
        assert_eq!(operator("<").metadata.restrict, Some("scalarltsel"));
        assert_eq!(operator("<=").metadata.restrict, Some("scalarlesel"));
        assert_eq!(operator(">").metadata.restrict, Some("scalargtsel"));
        assert_eq!(operator(">=").metadata.restrict, Some("scalargesel"));
    }

    #[test]
    fn negators_and_commutators() {
        assert_eq!(operator("=").metadata.negator, Some("<>"));
        assert_eq!(operator("<>").metadata.negator, Some("="));
        assert_eq!(operator("<").metadata.commutator, Some(">"));
        assert_eq!(operator("<").metadata.negator, Some(">="));
        assert_eq!(operator(">=").metadata.commutator, Some("<="));
    }

    #[test]
    fn metadata_renders_only_when_present() {
        assert_eq!(
            operator("=").metadata.render().unwrap(),
            "COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel"
        );
        assert_eq!(operator("->").metadata.render(), None);
        assert_eq!(operator("@>").metadata.render(), None);
    }

    #[test]
    fn catalog_symbols_match_expected_order() {
        let keys: Vec<&str> = OPERATORS.iter().map(|o| o.symbol).collect();
        assert_eq!(
            keys,
            vec![
                "=", "<>", "<", "<=", ">", ">=", "@>", "<@", "->", "->>", "?", "?|", "?&", "@?",
                "@@", "#>", "#>>", "-", "#-", "||"
            ]
        );
    }
}
