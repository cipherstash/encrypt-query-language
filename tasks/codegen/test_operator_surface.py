"""Tests for the scalar operator surface definition."""
from tasks.codegen.operator_surface import (
    BLOCKER_ONLY_OPERATORS,
    OPERATORS,
    PATH_OPERATORS,
    SYMMETRIC_OPERATORS,
    backing_function,
)


def test_twenty_operators_total():
    """The surface covers supported wrappers plus native jsonb fallbacks."""
    assert len(OPERATORS) == 20


def test_eight_symmetric_operators():
    """8 symmetric boolean operators."""
    assert SYMMETRIC_OPERATORS == ["=", "<>", "<", "<=", ">", ">=", "@>", "<@"]


def test_two_path_operators():
    """2 path operators."""
    assert PATH_OPERATORS == ["->", "->>"]


def test_ten_blocker_only_jsonb_fallback_operators():
    """Native jsonb operators not otherwise supported are blocker-only."""
    assert BLOCKER_ONLY_OPERATORS == [
        "?",
        "?|",
        "?&",
        "@?",
        "@@",
        "#>",
        "#>>",
        "-",
        "#-",
        "||",
    ]


def test_no_like_operators():
    """The surface excludes ~~ and ~~* (int4 has no LIKE support)."""
    assert "~~" not in OPERATORS
    assert "~~*" not in OPERATORS


def test_backing_function_names():
    """Each operator maps to its eql_v2 backing function name."""
    assert backing_function("=") == "eq"
    assert backing_function("<>") == "neq"
    assert backing_function("<") == "lt"
    assert backing_function("<=") == "lte"
    assert backing_function(">") == "gt"
    assert backing_function(">=") == "gte"
    assert backing_function("@>") == "contains"
    assert backing_function("<@") == "contained_by"
    assert backing_function("->") == '"->"'
    assert backing_function("->>") == '"->>"'
    assert backing_function("?") == '"?"'
    assert backing_function("?|") == '"?|"'
    assert backing_function("?&") == '"?&"'
    assert backing_function("@?") == '"@?"'
    assert backing_function("@@") == '"@@"'
    assert backing_function("#>") == '"#>"'
    assert backing_function("#>>") == '"#>>"'
    assert backing_function("-") == '"-"'
    assert backing_function("#-") == '"#-"'
    assert backing_function("||") == '"||"'


def test_selectivity_estimators():
    """Symmetric ops carry RESTRICT/JOIN selectivity estimators."""
    assert OPERATORS["="].restrict == "eqsel"
    assert OPERATORS["="].join == "eqjoinsel"
    assert OPERATORS["<>"].restrict == "neqsel"
    assert OPERATORS["<"].restrict == "scalarltsel"
    assert OPERATORS["<="].restrict == "scalarlesel"
    assert OPERATORS[">"].restrict == "scalargtsel"
    assert OPERATORS[">="].restrict == "scalargesel"


def test_negators_and_commutators():
    """= / <> are negators; range ops commute as documented."""
    assert OPERATORS["="].negator == "<>"
    assert OPERATORS["<>"].negator == "="
    assert OPERATORS["<"].commutator == ">"
    assert OPERATORS["<"].negator == ">="
    assert OPERATORS[">="].commutator == "<="
