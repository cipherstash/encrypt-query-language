"""Tests for the scalar operator surface definition."""
from tasks.codegen.operator_surface import (
    BLOCKER_ONLY_OPERATORS,
    KNOWN_JSONB_OPERATORS,
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


def test_known_jsonb_operators_is_union_of_the_three_lists():
    """The exported union is exactly the three enumerated lists, deduped."""
    assert KNOWN_JSONB_OPERATORS == frozenset(
        SYMMETRIC_OPERATORS + PATH_OPERATORS + BLOCKER_ONLY_OPERATORS
    )


def test_known_jsonb_operators_matches_operators_keys():
    """The union must stay in lockstep with the OPERATORS table itself, so a
    new operator added to one but not the other is caught here rather than
    leaving a hole in the storage-only blocker guarantee."""
    assert KNOWN_JSONB_OPERATORS == frozenset(OPERATORS)


def test_known_jsonb_operators_full_native_surface():
    """Pin the full native jsonb operator surface for PG 14-17. This is the
    source-of-truth the live-DB structural guard
    (tests/sqlx/.../family/jsonb_operator_surface.rs) asserts pg_operator is a
    subset of. If PG adds a jsonb operator, that DB test fails; if this list is
    edited, both must move together. The three lists are disjoint, so the union
    size equals their combined length."""
    assert KNOWN_JSONB_OPERATORS == frozenset(
        {
            # symmetric (supported wrappers)
            "=", "<>", "<", "<=", ">", ">=", "@>", "<@",
            # path
            "->", "->>",
            # blocker-only native jsonb fallbacks
            "?", "?|", "?&", "@?", "@@", "#>", "#>>", "-", "#-", "||",
        }
    )
    assert len(KNOWN_JSONB_OPERATORS) == (
        len(SYMMETRIC_OPERATORS) + len(PATH_OPERATORS) + len(BLOCKER_ONLY_OPERATORS)
    )
