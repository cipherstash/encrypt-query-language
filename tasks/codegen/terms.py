"""Fixed index-term catalog for scalar encrypted-domain codegen."""

from collections.abc import Iterable
from dataclasses import dataclass


class TermError(Exception):
    """Raised when a manifest references an unknown term."""


@dataclass(frozen=True)
class Term:
    """One fixed index term known to the scalar materializer."""

    name: str
    json_key: str
    extractor: str
    returns: str
    ctor: str
    role: str
    operators: tuple[str, ...]
    requires: tuple[str, ...]


TERM_CATALOG: dict[str, Term] = {
    "hm": Term(
        name="hm",
        json_key="hm",
        extractor="eq_term",
        returns="eql_v2.hmac_256",
        ctor="hmac_256",
        role="eq",
        operators=("=", "<>"),
        requires=("src/hmac_256/functions.sql",),
    ),
    "ore": Term(
        name="ore",
        json_key="ob",
        extractor="ord_term",
        returns="eql_v2.ore_block_u64_8_256",
        ctor="ore_block_u64_8_256",
        role="ord",
        operators=("=", "<>", "<", "<=", ">", ">="),
        requires=(
            "src/ore_block_u64_8_256/functions.sql",
            "src/ore_block_u64_8_256/operators.sql",
        ),
    ),
}


def _dedupe_preserving_order(values: Iterable[str]) -> list[str]:
    """Stable dedupe — first occurrence wins. `dict.fromkeys` preserves insert order."""
    return list(dict.fromkeys(values))


def require_terms(names: list[str]) -> list[Term]:
    """Return catalog terms for manifest names, preserving input order."""
    terms: list[Term] = []
    for name in names:
        try:
            terms.append(TERM_CATALOG[name])
        except KeyError as exc:
            raise TermError(
                f"unknown term '{name}' (expected one of {sorted(TERM_CATALOG)})"
            ) from exc
    return terms


def operators_for_terms(names: list[str]) -> list[str]:
    """Supported operators for the union of a domain's terms."""
    return _dedupe_preserving_order(
        op for term in require_terms(names) for op in term.operators
    )


def term_json_keys(names: list[str]) -> list[str]:
    """JSON payload keys required by these terms."""
    return _dedupe_preserving_order(
        term.json_key for term in require_terms(names)
    )


def term_requires(names: list[str]) -> list[str]:
    """SQL REQUIRE edges needed by these terms."""
    return _dedupe_preserving_order(
        req for term in require_terms(names) for req in term.requires
    )


def extractor_for_operator(names: list[str], op: str) -> str | None:
    """The catalog extractor that supports `op` for a domain carrying `names`."""
    for term in require_terms(names):
        if op in term.operators:
            return term.extractor
    return None


def role_for_terms(names: list[str]) -> str:
    """Generated-file role label for a domain with these terms.

    A domain with no terms is `storage`; otherwise the role comes from
    the first term's catalog role (e.g. `hm` -> `eq`, `ore` -> `ord`).
    """
    if not names:
        return "storage"
    return require_terms(names)[0].role
