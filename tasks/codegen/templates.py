"""Per-construct SQL template functions for scalar encrypted-domain codegen."""

from .operator_surface import OPERATORS
from .spec import DomainSpec
from .terms import (
    Term,
    extractor_for_operator as _catalog_extractor_for_operator,
    operators_for_terms,
    role_for_terms,
    term_json_keys,
)

AUTO_GENERATED_HEADER = (
    "-- AUTO-GENERATED — DO NOT EDIT.\n"
    "-- Regenerated automatically by `mise run build`; "
    "also `mise run codegen:domain <type>` to refresh one type.\n"
    "-- Source of truth: tasks/codegen/types/<type>.toml\n"
    "-- This file is gitignored; never commit it.\n"
)

ENVELOPE_KEYS = ["v", "i"]
CIPHERTEXT_KEY = "c"

OPERATOR_PHRASES: dict[str, str] = {
    "=":  "Equality",
    "<>": "Inequality",
    "<":  "Less-than",
    "<=": "Less-than-or-equal",
    ">":  "Greater-than",
    ">=": "Greater-than-or-equal",
    "@>": "Contains",
    "<@": "Contained-by",
}

DOMAIN_ROLE_PHRASES: dict[str, str] = {
    "storage": "Storage-only",
    "eq":      "Equality-only",
    "ord":     "Ordered",
}


def domain_name(domain: str) -> str:
    """The public SQL domain type name."""
    return f"eql_v2_{domain}"


def _arg_label(dom: str, arg_type: str) -> str:
    """Doxygen brief shape qualifier for one operand: 'domain' if it's
    the encrypted-domain type, otherwise the literal SQL type."""
    return "domain" if arg_type == dom else arg_type


def _shape_qualifier(dom: str, arg_a: str, arg_b: str) -> str:
    """Doxygen brief parenthetical. Empty for the canonical (dom, dom) shape."""
    if arg_a == dom and arg_b == dom:
        return ""
    return f" ({_arg_label(dom, arg_a)}, {_arg_label(dom, arg_b)})"


def render_domain_block(domain: DomainSpec, token: str) -> str:
    """One idempotent IF NOT EXISTS CREATE DOMAIN block, prefixed by a
    per-domain --! @brief derived from role + token."""
    dom = domain_name(domain.name)
    keys = ENVELOPE_KEYS + [CIPHERTEXT_KEY] + term_json_keys(domain.terms)
    checks = "\n        AND ".join(f"VALUE ? '{key}'" for key in keys)
    phrase = DOMAIN_ROLE_PHRASES[role_for_terms(domain.terms)]
    return (
        f"  --! @brief {phrase} encrypted {token} domain.\n"
        f"  IF NOT EXISTS (\n"
        f"    SELECT 1 FROM pg_type\n"
        f"    WHERE typname = '{dom}' "
        f"AND typnamespace = 'public'::regnamespace\n"
        f"  ) THEN\n"
        f"    CREATE DOMAIN public.{dom} AS jsonb\n"
        f"      CHECK (\n"
        f"        jsonb_typeof(VALUE) = 'object'\n"
        f"        AND {checks}\n"
        f"      );\n"
        f"  END IF;\n"
    )


def render_extractor(domain: DomainSpec, term: Term) -> str:
    """The inlinable index-term extractor for a domain term."""
    dom = domain_name(domain.name)
    doxy = (
        f"--! @brief Index extractor for the {dom} variant.\n"
        f"--! @param a {dom}\n"
        f"--! @return {term.returns}\n"
    )
    return doxy + (
        f"CREATE FUNCTION eql_v2.{term.extractor}(a {dom})\n"
        f"RETURNS {term.returns}\n"
        f"LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE\n"
        f"AS $$ SELECT eql_v2.{term.ctor}(a::jsonb) $$;\n"
    )


def _extract_arg(arg_type: str, extractor: str, domain: str, arg: str) -> str:
    """The extractor-call SQL for one operand, casting jsonb to the domain first."""
    if arg_type == "jsonb":
        return f"eql_v2.{extractor}({arg}::{domain})"
    return f"eql_v2.{extractor}({arg})"


def render_wrapper(
    domain: DomainSpec, op: str, arg_a: str, arg_b: str, extractor: str
) -> str:
    """An inlinable comparison wrapper for a supported operator."""
    dom = domain_name(domain.name)
    backing = OPERATORS[op].backing
    call_a = _extract_arg(arg_a, extractor, dom, "a")
    call_b = _extract_arg(arg_b, extractor, dom, "b")
    doxy = (
        f"--! @brief {OPERATOR_PHRASES[op]} wrapper for {dom}"
        f"{_shape_qualifier(dom, arg_a, arg_b)}.\n"
        f"--! @param a {arg_a}\n"
        f"--! @param b {arg_b}\n"
        f"--! @return boolean\n"
    )
    return doxy + (
        f"CREATE FUNCTION eql_v2.{backing}(a {arg_a}, b {arg_b})\n"
        f"RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE\n"
        f"AS $$ SELECT {call_a} {op} {call_b} $$;\n"
    )


def render_blocker_bool(
    domain: DomainSpec, op: str, arg_a: str, arg_b: str
) -> str:
    """A boolean-returning blocker. NEVER STRICT, ALWAYS LANGUAGE plpgsql
    so the RAISE survives inlining and planner-time elision; see CLAUDE.md
    footguns and the encrypted-domain spec §4."""
    dom = domain_name(domain.name)
    backing = OPERATORS[op].backing
    doxy = (
        f"--! @brief Blocker for {op} on {dom}"
        f"{_shape_qualifier(dom, arg_a, arg_b)}.\n"
        f"--! @param a {arg_a}\n"
        f"--! @param b {arg_b}\n"
        f"--! @return boolean (never returns; always raises)\n"
    )
    return doxy + (
        f"CREATE FUNCTION eql_v2.{backing}(a {arg_a}, b {arg_b})\n"
        f"RETURNS boolean IMMUTABLE PARALLEL SAFE\n"
        f"AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool("
        f"'{dom}', '{op}'); END; $$\n"
        f"LANGUAGE plpgsql;\n"
    )


def render_blocker_path(
    domain: DomainSpec, op: str, arg_a: str, arg_b: str
) -> str:
    """A path-operator blocker. NEVER STRICT, ALWAYS LANGUAGE plpgsql
    so the RAISE survives inlining and planner-time elision; see CLAUDE.md
    footguns and the encrypted-domain spec §4."""
    dom = domain_name(domain.name)
    backing = OPERATORS[op].backing
    returns = "text" if op == "->>" else dom
    doxy = (
        f"--! @brief Blocker for {op} on {dom} "
        f"({_arg_label(dom, arg_a)}, {_arg_label(dom, arg_b)}).\n"
        f"--! @param a {arg_a}\n"
        f"--! @param selector {arg_b}\n"
        f"--! @return {returns} (never returns; always raises)\n"
    )
    return doxy + (
        f"CREATE FUNCTION eql_v2.{backing}(a {arg_a}, selector {arg_b})\n"
        f"RETURNS {returns} IMMUTABLE PARALLEL SAFE\n"
        f"AS $$ BEGIN RAISE EXCEPTION "
        f"'operator % is not supported for %', '{op}', '{dom}'; END; $$\n"
        f"LANGUAGE plpgsql;\n"
    )


def render_blocker_native(
    domain: DomainSpec, op: str, arg_a: str, arg_b: str, returns: str
) -> str:
    """A blocker for a native jsonb fallback operator. NEVER STRICT, ALWAYS
    LANGUAGE plpgsql. Boolean blockers delegate to the shared helper so lint
    recognition and messages stay uniform; other return types raise directly.
    """
    dom = domain_name(domain.name)
    backing = OPERATORS[op].backing
    doxy = (
        f"--! @brief Blocker for {op} on {dom}"
        f"{_shape_qualifier(dom, arg_a, arg_b)}.\n"
        f"--! @param a {arg_a}\n"
        f"--! @param b {arg_b}\n"
        f"--! @return {returns} (never returns; always raises)\n"
    )
    if returns == "boolean":
        body = (
            "BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool("
            f"'{dom}', '{op}'); END;"
        )
    else:
        body = (
            "BEGIN RAISE EXCEPTION "
            f"'operator % is not supported for %', '{op}', '{dom}'; END;"
        )
    return doxy + (
        f"CREATE FUNCTION eql_v2.{backing}(a {arg_a}, b {arg_b})\n"
        f"RETURNS {returns} IMMUTABLE PARALLEL SAFE\n"
        f"AS $$ {body} $$\n"
        f"LANGUAGE plpgsql;\n"
    )


def extractor_for_operator(domain: DomainSpec, op: str) -> str | None:
    """Return the catalog extractor that supports op for this domain."""
    return _catalog_extractor_for_operator(domain.terms, op)


def supported_operators(domain: DomainSpec) -> list[str]:
    """Supported operators for this domain."""
    return operators_for_terms(domain.terms)


def render_operator(
    op: str, backing: str, leftarg: str, rightarg: str, supported: bool
) -> str:
    """A CREATE OPERATOR declaration."""
    meta = OPERATORS[op]
    lines = [
        f"CREATE OPERATOR {op} (",
        f"  FUNCTION = eql_v2.{backing},",
        f"  LEFTARG = {leftarg}, RIGHTARG = {rightarg}",
    ]
    if supported and meta.kind == "symmetric":
        extras = []
        if meta.commutator:
            extras.append(f"COMMUTATOR = {meta.commutator}")
        if meta.negator:
            extras.append(f"NEGATOR = {meta.negator}")
        if meta.restrict:
            extras.append(f"RESTRICT = {meta.restrict}")
        if meta.join:
            extras.append(f"JOIN = {meta.join}")
        if extras:
            lines[-1] += ","
            lines.append("  " + ", ".join(extras))
    lines.append(");")
    return "\n".join(lines) + "\n"
