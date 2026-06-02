"""Per-construct SQL template functions for scalar encrypted-domain codegen."""

from dataclasses import dataclass

from .operator_surface import OPERATORS
from .scalars import require_scalar
from .spec import DomainSpec, TypeSpec
from .terms import (
    Term,
    extractor_for_operator as _catalog_extractor_for_operator,
    operators_for_terms,
    role_for_terms,
    term_json_keys,
)

# SQL generated-file marker, emitted as the first line of every generated SQL
# file. Must stay byte-identical to the Rust generator's AUTO_GENERATED_HEADER
# (crates/eql-codegen/src/consts.rs) so the two generators are at byte parity
# (mise run codegen:parity). The `^-- AUTOMATICALLY GENERATED FILE` first line
# is also what tasks/docs/validate/{coverage,required-tags}.sh grep on to skip
# generated SQL — keep this and that grep in lockstep.
AUTO_GENERATED_HEADER = "-- AUTOMATICALLY GENERATED FILE.\n"

# Rust counterpart, prepended to the committed `<T>_values.rs` (which has no
# template). Rust comment syntax (`//`) so the `.rs` file stays valid; must stay
# byte-identical to the Rust generator's AUTO_GENERATED_HEADER_RS.
AUTO_GENERATED_HEADER_RS = "// AUTOMATICALLY GENERATED FILE.\n"

ENVELOPE_KEYS = ["v", "i"]
CIPHERTEXT_KEY = "c"
# EQL payload-format version. The domain CHECK pins the 'v' envelope key to
# this value, matching EQL's repo-wide rule (eql_v2._encrypted_check_v,
# src/encrypted/constraints.sql). Presence of 'v' is enforced via
# ENVELOPE_KEYS; this pins its value so a stale/foreign-version payload is
# rejected on insert or cast rather than surfacing later at query time.
VERSION_KEY = "v"
ENVELOPE_VERSION = 2


def _sql_str(s: str) -> str:
    """Escape a Python string for use *inside* a single-quoted SQL string
    literal by doubling embedded single quotes.

    Use this at every `'{...}'` interpolation boundary in the render_*
    helpers — payload keys, operator symbols, domain names rendered into
    RAISE messages, etc. NOT for schema-qualified identifiers like
    ``eql_v3.foo``: those are emitted unquoted and must not be doubled.

    Today every catalog string (term keys, operator symbols) is quote-free,
    so this is a no-op on real input and output stays byte-identical. It
    exists so a future quote-bearing catalog string can never break out of
    its SQL literal — nothing else enforces the quote-free invariant."""
    return s.replace("'", "''")


# Schema housing the encrypted-domain families: the domains themselves plus
# their index-term extractors, comparison wrappers, blockers, and aggregates.
# New in v3 and distinct from the core eql_v2 schema, which still owns the
# shared index-term types the extractors return and construct
# (eql_v2.hmac_256, eql_v2.ore_block_u64_8_256).
DOMAIN_SCHEMA = "eql_v3"
# Schema owning the core index-term types/constructors the extractors reuse.
CORE_SCHEMA = "eql_v2"


def render_fixture_values_rs(spec: TypeSpec) -> str:
    """Body for tests/sqlx/src/fixtures/<T>_values.rs.

    Emits one `pub const VALUES: &[<rust_type>]` from the manifest's
    `[fixture] values`, preserving declaration order. The writer prepends the
    AUTO-GENERATED Rust header, so the body carries none."""
    kind = require_scalar(spec.token)
    values = spec.fixture_values or []
    literals = "".join(f"    {kind.render_literal(v)},\n" for v in values)
    return (
        f"//! Fixture plaintext values for the {spec.token} "
        "encrypted-domain family.\n"
        "//!\n"
        f"//! Generated from tasks/codegen/types/{spec.token}.toml "
        "`[fixture] values` —\n"
        "//! the single source of truth shared by the fixture generator\n"
        f"//! (`fixtures::eql_v2_{spec.token}`) and the matrix oracle\n"
        "//! (`ScalarType::FIXTURE_VALUES`).\n\n"
        f"/// Distinct plaintext values present in the `eql_v2_{spec.token}` "
        "fixture.\n"
        f"pub const VALUES: &[{kind.rust_type}] = &[\n"
        f"{literals}"
        "];\n"
    )

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


def _scheme_suffix(name: str, token: str, role: str) -> str | None:
    """The scheme tag of a domain name, or None for the converged name.

    The naming convention is ``<token>_<role>`` for the recommended converged
    domain and ``<token>_<role>_<scheme>`` for a scheme-explicit twin that
    pins the same role to one concrete index scheme. ``storage`` has no role
    segment, so its converged name is the bare ``<token>``.

    Generic by construction: it reads ``token`` and ``role`` rather than any
    hard-coded type or scheme string, so it works for int8/date/etc. and for
    schemes other than ``ore``. Returns the scheme segment (e.g. ``"ore"``)
    for a twin, or None when ``name`` is the converged name (or doesn't match
    the convention at all)."""
    converged = token if role == "storage" else f"{token}_{role}"
    if name == converged:
        return None
    prefix = converged + "_"
    if name.startswith(prefix):
        scheme = name[len(prefix):]
        if scheme:
            return scheme
    return None


# Roles that come in converged + scheme-explicit-twin pairs and therefore need
# a disambiguating @brief clause. Ordered domains are the case the reviewer
# flagged: int4_ord and int4_ord_ore carry identical terms (["ore"]) and would
# otherwise render an identical brief. Driven by role (generic across int8,
# date, etc.), never by a literal type/scheme name. eq and storage have a
# single name each, so no disambiguation is needed (or wanted — it'd be noise).
_TWINNABLE_ROLES = frozenset({"ord"})


def brief_role_clause(domain: DomainSpec, token: str) -> str:
    """The trailing clause distinguishing the recommended converged domain
    from a scheme-explicit twin, for use in a per-domain @brief.

    Two domains that carry identical terms (e.g. ``int4_ord`` and
    ``int4_ord_ore``, both ``["ore"]``) would otherwise render an identical
    brief. The converged name is the recommended one to reach for; the twin
    names the concrete scheme explicitly. Returns "" for roles that don't come
    in converged/twin pairs (eq, storage) and for names that match no pattern.

    Generic by construction: keyed on the term-derived role and the
    ``<token>_<role>[_<scheme>]`` name shape, never on a literal type or scheme
    string, so int8/date/etc. and non-ore schemes work unchanged."""
    role = role_for_terms(domain.terms)
    if role not in _TWINNABLE_ROLES:
        return ""
    scheme = _scheme_suffix(domain.name, token, role)
    if scheme is not None:
        return (
            f" Scheme-explicit twin pinning the {scheme} scheme; "
            f"prefer the converged {token}_{role} name."
        )
    if domain.name == f"{token}_{role}":
        return " Recommended converged name for this role."
    return ""


def domain_name(domain: str) -> str:
    """The schema-qualified SQL domain type name, e.g. ``eql_v3.int4_eq``."""
    return f"{DOMAIN_SCHEMA}.{domain}"


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
    presence = "\n        AND ".join(f"VALUE ? '{_sql_str(key)}'" for key in keys)
    checks = (
        presence
        + f"\n        AND VALUE->>'{_sql_str(VERSION_KEY)}' = '{ENVELOPE_VERSION}'"
    )
    phrase = role_phrase(domain.terms)
    clause = brief_role_clause(domain, token)
    return (
        f"  --! @brief {phrase} encrypted {token} domain.{clause}\n"
        f"  IF NOT EXISTS (\n"
        f"    SELECT 1 FROM pg_type\n"
        f"    WHERE typname = '{_sql_str(domain.name)}' "
        f"AND typnamespace = '{DOMAIN_SCHEMA}'::regnamespace\n"
        f"  ) THEN\n"
        f"    CREATE DOMAIN {dom} AS jsonb\n"
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
        f"CREATE FUNCTION {DOMAIN_SCHEMA}.{term.extractor}(a {dom})\n"
        f"RETURNS {term.returns}\n"
        f"LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE\n"
        f"AS $$ SELECT {CORE_SCHEMA}.{term.ctor}(a::jsonb) $$;\n"
    )


def _extract_arg(arg_type: str, extractor: str, domain: str, arg: str) -> str:
    """The extractor-call SQL for one operand, casting jsonb to the domain first."""
    if arg_type == "jsonb":
        return f"{DOMAIN_SCHEMA}.{extractor}({arg}::{domain})"
    return f"{DOMAIN_SCHEMA}.{extractor}({arg})"


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
        f"CREATE FUNCTION {DOMAIN_SCHEMA}.{backing}(a {arg_a}, b {arg_b})\n"
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
        f"CREATE FUNCTION {DOMAIN_SCHEMA}.{backing}(a {arg_a}, b {arg_b})\n"
        f"RETURNS boolean IMMUTABLE PARALLEL SAFE\n"
        f"AS $$ BEGIN RETURN {DOMAIN_SCHEMA}.encrypted_domain_unsupported_bool("
        f"'{_sql_str(dom)}', '{_sql_str(op)}'); END; $$\n"
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
        f"CREATE FUNCTION {DOMAIN_SCHEMA}.{backing}(a {arg_a}, selector {arg_b})\n"
        f"RETURNS {returns} IMMUTABLE PARALLEL SAFE\n"
        f"AS $$ BEGIN RAISE EXCEPTION "
        f"'operator % is not supported for %', '{_sql_str(op)}', "
        f"'{_sql_str(dom)}'; END; $$\n"
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
            f"BEGIN RETURN {DOMAIN_SCHEMA}.encrypted_domain_unsupported_bool("
            f"'{_sql_str(dom)}', '{_sql_str(op)}'); END;"
        )
    else:
        body = (
            "BEGIN RAISE EXCEPTION "
            f"'operator % is not supported for %', '{_sql_str(op)}', "
            f"'{_sql_str(dom)}'; END;"
        )
    return doxy + (
        f"CREATE FUNCTION {DOMAIN_SCHEMA}.{backing}(a {arg_a}, b {arg_b})\n"
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
    #
    # The same rationale is mirrored into the emitted SQL below so a reader of
    # the generated file (who never sees this Python) understands why it isn't
    # an inlinable LANGUAGE sql CASE.
    sfunc_rationale = (
        "-- LANGUAGE plpgsql, not sql: aggregate state functions are not index\n"
        "-- expressions, so opacity to the planner is fine, and a multi-statement\n"
        "-- BEGIN/IF/END body is the natural shape. (A LANGUAGE sql CASE would\n"
        "-- also work, but the procedural form mirrors the blocker convention.)\n"
    )
    sfunc = sfunc_rationale + (
        f"CREATE FUNCTION {DOMAIN_SCHEMA}.{op.sfunc_name}(state {dom}, value {dom})\n"
        f"RETURNS {dom}\n"
        f"LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE\n"
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
    # min/max are associative, so the state function doubles as the combine
    # function: merging two partial extrema is the same comparison. With a
    # PARALLEL SAFE sfunc/combinefunc and `parallel = safe`, PG can use partial
    # and parallel aggregation on the large GROUP BY workloads these ORE
    # aggregates exist to serve — still with no decryption. The combinefunc is
    # STRICT (it is the sfunc), so PG carries a null partial state through as
    # "no value yet", matching the serial seed-and-skip semantics.
    aggregate = (
        "-- combinefunc = sfunc: min/max are associative, so merging two partial\n"
        "-- extrema is the same comparison. PARALLEL SAFE enables partial and\n"
        "-- parallel aggregation on large GROUP BY workloads, with no decryption.\n"
        f"CREATE AGGREGATE {DOMAIN_SCHEMA}.{op.name}({dom}) (\n"
        f"  sfunc = {DOMAIN_SCHEMA}.{op.sfunc_name},\n"
        f"  stype = {dom},\n"
        f"  combinefunc = {DOMAIN_SCHEMA}.{op.sfunc_name},\n"
        f"  parallel = safe\n"
        f");\n"
    )
    return sfunc_doxy + sfunc + "\n" + agg_doxy + aggregate


def render_operator(
    op: str, backing: str, leftarg: str, rightarg: str, supported: bool
) -> str:
    """A CREATE OPERATOR declaration.

    Unsupported operators are still declared, but their backing function is a
    blocker that always raises. We emit them so the operator resolves on the
    domain (rather than silently falling through to a native jsonb operator),
    and a leading SQL comment explains the placeholder to future readers."""
    meta = OPERATORS[op]
    lines = []
    if not supported:
        lines.append(
            f"-- Placeholder: this domain's term set does not support {op}; "
            f"the backing function always raises."
        )
    lines += [
        f"CREATE OPERATOR {op} (",
        f"  FUNCTION = {DOMAIN_SCHEMA}.{backing},",
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
