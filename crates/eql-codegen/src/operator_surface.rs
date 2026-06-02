//! The generated operator surface (port of operator_surface.py).

/// One operator in the generated surface.
#[derive(Clone, Copy)]
pub struct Operator {
    pub symbol: &'static str,
    pub backing: &'static str,
    pub kind: Kind,
    pub restrict: Option<&'static str>,
    pub join: Option<&'static str>,
    pub commutator: Option<&'static str>,
    pub negator: Option<&'static str>,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Symmetric,
    Path,
    BlockerOnly,
}

pub const SYMMETRIC_OPERATORS: &[&str] = &["=", "<>", "<", "<=", ">", ">=", "@>", "<@"];
pub const PATH_OPERATORS: &[&str] = &["->", "->>"];
pub const BLOCKER_ONLY_OPERATORS: &[&str] =
    &["?", "?|", "?&", "@?", "@@", "#>", "#>>", "-", "#-", "||"];

/// Look up the operator metadata for a symbol. Panics on an unknown symbol —
/// the generator only ever passes catalog symbols, matching Python's KeyError.
pub fn operator(symbol: &str) -> Operator {
    OPERATORS
        .iter()
        .copied()
        .find(|o| o.symbol == symbol)
        .unwrap_or_else(|| panic!("unknown operator symbol: {symbol}"))
}

/// The eql_v2 backing function name for an operator symbol.
pub fn backing_function(symbol: &str) -> &'static str {
    operator(symbol).backing
}

/// The 20-operator table. Order matches the SYMMETRIC/PATH/BLOCKER_ONLY lists.
pub const OPERATORS: &[Operator] = &[
    Operator {
        symbol: "=",
        backing: "eq",
        kind: Kind::Symmetric,
        restrict: Some("eqsel"),
        join: Some("eqjoinsel"),
        commutator: Some("="),
        negator: Some("<>"),
    },
    Operator {
        symbol: "<>",
        backing: "neq",
        kind: Kind::Symmetric,
        restrict: Some("neqsel"),
        join: Some("neqjoinsel"),
        commutator: Some("<>"),
        negator: Some("="),
    },
    Operator {
        symbol: "<",
        backing: "lt",
        kind: Kind::Symmetric,
        restrict: Some("scalarltsel"),
        join: Some("scalarltjoinsel"),
        commutator: Some(">"),
        negator: Some(">="),
    },
    Operator {
        symbol: "<=",
        backing: "lte",
        kind: Kind::Symmetric,
        restrict: Some("scalarlesel"),
        join: Some("scalarlejoinsel"),
        commutator: Some(">="),
        negator: Some(">"),
    },
    Operator {
        symbol: ">",
        backing: "gt",
        kind: Kind::Symmetric,
        restrict: Some("scalargtsel"),
        join: Some("scalargtjoinsel"),
        commutator: Some("<"),
        negator: Some("<="),
    },
    Operator {
        symbol: ">=",
        backing: "gte",
        kind: Kind::Symmetric,
        restrict: Some("scalargesel"),
        join: Some("scalargejoinsel"),
        commutator: Some("<="),
        negator: Some("<"),
    },
    Operator {
        symbol: "@>",
        backing: "contains",
        kind: Kind::Symmetric,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "<@",
        backing: "contained_by",
        kind: Kind::Symmetric,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "->",
        backing: "\"->\"",
        kind: Kind::Path,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "->>",
        backing: "\"->>\"",
        kind: Kind::Path,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "?",
        backing: "\"?\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "?|",
        backing: "\"?|\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "?&",
        backing: "\"?&\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "@?",
        backing: "\"@?\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "@@",
        backing: "\"@@\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "#>",
        backing: "\"#>\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "#>>",
        backing: "\"#>>\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "-",
        backing: "\"-\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "#-",
        backing: "\"#-\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
    Operator {
        symbol: "||",
        backing: "\"||\"",
        kind: Kind::BlockerOnly,
        restrict: None,
        join: None,
        commutator: None,
        negator: None,
    },
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn twenty_operators_total() {
        assert_eq!(OPERATORS.len(), 20);
    }

    #[test]
    fn operator_lists_match() {
        assert_eq!(
            SYMMETRIC_OPERATORS,
            &["=", "<>", "<", "<=", ">", ">=", "@>", "<@"]
        );
        assert_eq!(PATH_OPERATORS, &["->", "->>"]);
        assert_eq!(
            BLOCKER_ONLY_OPERATORS,
            &["?", "?|", "?&", "@?", "@@", "#>", "#>>", "-", "#-", "||"]
        );
    }

    #[test]
    fn no_like_operators() {
        assert!(OPERATORS
            .iter()
            .all(|o| o.symbol != "~~" && o.symbol != "~~*"));
    }

    #[test]
    fn backing_function_names() {
        assert_eq!(backing_function("="), "eq");
        assert_eq!(backing_function("<>"), "neq");
        assert_eq!(backing_function("<"), "lt");
        assert_eq!(backing_function("<="), "lte");
        assert_eq!(backing_function(">"), "gt");
        assert_eq!(backing_function(">="), "gte");
        assert_eq!(backing_function("@>"), "contains");
        assert_eq!(backing_function("<@"), "contained_by");
        assert_eq!(backing_function("->"), "\"->\"");
        assert_eq!(backing_function("->>"), "\"->>\"");
        assert_eq!(backing_function("?"), "\"?\"");
        assert_eq!(backing_function("?|"), "\"?|\"");
        assert_eq!(backing_function("?&"), "\"?&\"");
        assert_eq!(backing_function("@?"), "\"@?\"");
        assert_eq!(backing_function("@@"), "\"@@\"");
        assert_eq!(backing_function("#>"), "\"#>\"");
        assert_eq!(backing_function("#>>"), "\"#>>\"");
        assert_eq!(backing_function("-"), "\"-\"");
        assert_eq!(backing_function("#-"), "\"#-\"");
        assert_eq!(backing_function("||"), "\"||\"");
    }

    #[test]
    fn selectivity_estimators() {
        assert_eq!(operator("=").restrict, Some("eqsel"));
        assert_eq!(operator("=").join, Some("eqjoinsel"));
        assert_eq!(operator("<>").restrict, Some("neqsel"));
        assert_eq!(operator("<").restrict, Some("scalarltsel"));
        assert_eq!(operator("<=").restrict, Some("scalarlesel"));
        assert_eq!(operator(">").restrict, Some("scalargtsel"));
        assert_eq!(operator(">=").restrict, Some("scalargesel"));
    }

    #[test]
    fn negators_and_commutators() {
        assert_eq!(operator("=").negator, Some("<>"));
        assert_eq!(operator("<>").negator, Some("="));
        assert_eq!(operator("<").commutator, Some(">"));
        assert_eq!(operator("<").negator, Some(">="));
        assert_eq!(operator(">=").commutator, Some("<="));
    }

    #[test]
    fn known_jsonb_operators_match_table_keys() {
        let union: Vec<&str> = SYMMETRIC_OPERATORS
            .iter()
            .chain(PATH_OPERATORS)
            .chain(BLOCKER_ONLY_OPERATORS)
            .copied()
            .collect();
        let keys: Vec<&str> = OPERATORS.iter().map(|o| o.symbol).collect();
        assert_eq!(union, keys);
        assert_eq!(
            union.len(),
            SYMMETRIC_OPERATORS.len() + PATH_OPERATORS.len() + BLOCKER_ONLY_OPERATORS.len()
        );
    }
}
