"""The generated operator surface for a scalar encrypted-domain type.

Supported comparison operators route to inlinable wrappers when the domain
has the required term. Unsupported comparisons, path operators, and native
jsonb fallback operators route to blockers.
"""

from dataclasses import dataclass
from typing import Literal


@dataclass(frozen=True)
class Operator:
    """One operator in the generated surface."""

    symbol: str
    backing: str  # eql_v2 backing function name (bare or quoted)
    kind: Literal["symmetric", "path", "blocker_only"]
    restrict: str | None  # selectivity estimator, symmetric ops only
    join: str | None  # join selectivity estimator, symmetric ops only
    commutator: str | None
    negator: str | None


SYMMETRIC_OPERATORS = ["=", "<>", "<", "<=", ">", ">=", "@>", "<@"]
PATH_OPERATORS = ["->", "->>"]
BLOCKER_ONLY_OPERATORS = ["?", "?|", "?&", "@?", "@@", "#>", "#>>", "-", "#-", "||"]


OPERATORS: dict[str, Operator] = {
    "=":  Operator("=",  "eq",           "symmetric", "eqsel",       "eqjoinsel",       "=",  "<>"),
    "<>": Operator("<>", "neq",          "symmetric", "neqsel",      "neqjoinsel",      "<>", "="),
    "<":  Operator("<",  "lt",           "symmetric", "scalarltsel", "scalarltjoinsel", ">",  ">="),
    "<=": Operator("<=", "lte",          "symmetric", "scalarlesel", "scalarlejoinsel", ">=", ">"),
    ">":  Operator(">",  "gt",           "symmetric", "scalargtsel", "scalargtjoinsel", "<",  "<="),
    ">=": Operator(">=", "gte",          "symmetric", "scalargesel", "scalargejoinsel", "<=", "<"),
    "@>": Operator("@>", "contains",     "symmetric", None,          None,              None, None),
    "<@": Operator("<@", "contained_by", "symmetric", None,          None,              None, None),
    "->": Operator("->", '"->"',         "path",      None,          None,              None, None),
    "->>": Operator("->>", '"->>"',      "path",      None,          None,              None, None),
    "?":  Operator("?",  '"?"',           "blocker_only", None,       None,              None, None),
    "?|": Operator("?|", '"?|"',          "blocker_only", None,       None,              None, None),
    "?&": Operator("?&", '"?&"',          "blocker_only", None,       None,              None, None),
    "@?": Operator("@?", '"@?"',          "blocker_only", None,       None,              None, None),
    "@@": Operator("@@", '"@@"',          "blocker_only", None,       None,              None, None),
    "#>": Operator("#>", '"#>"',          "blocker_only", None,       None,              None, None),
    "#>>": Operator("#>>", '"#>>"',       "blocker_only", None,       None,              None, None),
    "-":  Operator("-",  '"-"',           "blocker_only", None,       None,              None, None),
    "#-": Operator("#-", '"#-"',          "blocker_only", None,       None,              None, None),
    "||": Operator("||", '"||"',          "blocker_only", None,       None,              None, None),
}


def backing_function(symbol: str) -> str:
    """Return the eql_v2 backing function name for an operator symbol."""
    return OPERATORS[symbol].backing
