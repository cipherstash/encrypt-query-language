"""Per-construct SQL template functions for scalar encrypted-domain codegen."""

from dataclasses import dataclass

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


def role_phrase(terms: list[str]) -> str:
    """Proper-cased prose label for a domain with these terms — the single
    source of truth for role → human prose. Every renderer that wants to
    describe a domain's role in @brief lines reaches for this, so a rename
    in DOMAIN_ROLE_PHRASES propagates to every generated file."""
    return DOMAIN_ROLE_PHRASES[role_for_terms(terms)]


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
    phrase = role_phrase(domain.terms)
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


@dataclass(frozen=True)
class AggregateOp:
    """One aggregate operator definition (min or max)."""

    name: str        # public function name, e.g. "min"
    sfunc_name: str  # state function name, e.g. "min_sfunc"
    comparator: str  # SQL comparator used to choose the new state: "<" or ">"
    phrase: str      # short prose label used in --! @brief lines


AGGREGATE_OPS: dict[str, AggregateOp] = {
    "min": AggregateOp("min", "min_sfunc", "<", "minimum"),
    "max": AggregateOp("max", "max_sfunc", ">", "maximum"),
}


def is_ord_capable(domain: DomainSpec) -> bool:
    """True if the domain carries a comparator term (i.e. supports `<`)."""
    return role_for_terms(domain.terms) == "ord"


def render_aggregate(domain: DomainSpec, op: AggregateOp) -> str:
    """Render state function + CREATE AGGREGATE for one aggregate op on one
    domain. The ord-capability gate lives at the file-level renderer
    (`render_aggregates_file`); callers may legitimately render a single
    aggregate without re-asserting that precondition. MIN/MAX on a non-ord
    domain is structurally well-formed text but semantically meaningless —
    the file-level gate is what stops it ever reaching disk."""
    dom = domain_name(domain.name)
    sfunc_doxy = (
        f"--! @brief State function for {op.name} aggregate on {dom}.\n"
        f"--! @internal\n"
        f"--!\n"
        f"--! @param state {dom} running extremum\n"
        f"--! @param value {dom} next non-NULL value\n"
        f"--! @return {dom} the {op.phrase} of state and value\n"
    )
    # plpgsql + STRICT: PG seeds the state with the first non-NULL value and
    # skips NULL inputs. plpgsql (not sql) because aggregate state functions
    # aren't index expressions — opacity to the planner is fine — and a
    # multi-statement BEGIN/IF/END body is the natural shape.
    sfunc = (
        f"CREATE FUNCTION eql_v2.{op.sfunc_name}(state {dom}, value {dom})\n"
        f"RETURNS {dom}\n"
        f"LANGUAGE plpgsql IMMUTABLE STRICT\n"
        f"SET search_path = pg_catalog, extensions, public\n"
        f"AS $$\n"
        f"BEGIN\n"
        f"  IF value {op.comparator} state THEN\n"
        f"    RETURN value;\n"
        f"  END IF;\n"
        f"  RETURN state;\n"
        f"END;\n"
        f"$$;\n"
    )
    agg_doxy = (
        f"--! @brief Find the {op.phrase} encrypted value in a group of "
        f"{dom} values.\n"
        f"--!\n"
        f"--! Comparison routes through the domain's `{op.comparator}` "
        f"operator, which uses the ORE block term — no decryption.\n"
        f"--!\n"
        f"--! @param input {dom} encrypted values to aggregate\n"
        f"--! @return {dom} {op.phrase} of the group, or NULL if all "
        f"inputs are NULL\n"
    )
    aggregate = (
        f"CREATE AGGREGATE eql_v2.{op.name}({dom}) (\n"
        f"  sfunc = eql_v2.{op.sfunc_name},\n"
        f"  stype = {dom}\n"
        f");\n"
    )
    return sfunc_doxy + sfunc + "\n" + agg_doxy + aggregate


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
