"""Tests for per-construct SQL template functions."""

from tasks.codegen.spec import DomainSpec, TypeSpec
from tasks.codegen.templates import (
    AGGREGATE_OPS,
    AUTO_GENERATED_HEADER,
    AUTO_GENERATED_HEADER_RS,
    _sql_str,
    brief_role_clause,
    domain_name,
    extractor_for_operator,
    is_ord_capable,
    render_aggregate,
    render_blocker_bool,
    render_blocker_native,
    render_blocker_path,
    render_domain_block,
    render_extractor,
    render_fixture_values_rs,
    render_operator,
    render_wrapper,
)
from tasks.codegen.terms import TERM_CATALOG


def test_auto_generated_header_present():
    assert "AUTO-GENERATED" in AUTO_GENERATED_HEADER
    assert "DO NOT EDIT" in AUTO_GENERATED_HEADER


def test_rust_header_is_comment_and_marks_committed():
    # Rust uses // comments, not SQL's --, and unlike the gitignored SQL
    # surface this file is committed and CI-verified.
    assert AUTO_GENERATED_HEADER_RS.startswith("// AUTO-GENERATED")
    assert "DO NOT EDIT" in AUTO_GENERATED_HEADER_RS
    assert "committed" in AUTO_GENERATED_HEADER_RS
    # No line is an SQL-style (`--`) comment — this is Rust, not SQL.
    assert not any(
        line.startswith("--") for line in AUTO_GENERATED_HEADER_RS.splitlines()
    )


def test_render_fixture_values_rs_emits_typed_const():
    spec = TypeSpec(
        token="int4",
        domains=[],
        fixture_values=["MIN", "-1", "ZERO", "1", "MAX"],
    )
    body = render_fixture_values_rs(spec)
    assert "pub const VALUES: &[i32] = &[" in body
    assert "tasks/codegen/types/int4.toml" in body
    # Sentinels map to named consts; numeric tokens pass through.
    assert "i32::MIN," in body
    assert "i32::MAX," in body
    assert "    -1,\n" in body
    assert "    0,\n" in body  # ZERO and "1" both literal
    assert "    1,\n" in body
    # No AUTO-GENERATED header in the body — the writer prepends it.
    assert "AUTO-GENERATED" not in body


def test_render_fixture_values_rs_preserves_manifest_order():
    spec = TypeSpec(
        token="int4",
        domains=[],
        fixture_values=["MIN", "ZERO", "MAX"],
    )
    body = render_fixture_values_rs(spec)
    assert body.index("i32::MIN") < body.index("0,") < body.index("i32::MAX")


def test_domain_block_storage_uses_fixed_envelope_only():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_domain_block(domain, "int4")
    assert "CREATE DOMAIN eql_v3.int4 AS jsonb" in sql
    assert "VALUE ? 'v'" in sql
    assert "VALUE ? 'i'" in sql
    assert "VALUE ? 'c'" in sql
    assert "VALUE ? 'hm'" not in sql
    assert "VALUE ? 'ob'" not in sql


def test_domain_block_uses_catalog_json_keys():
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_domain_block(domain, "int4")
    assert "CREATE DOMAIN eql_v3.int4_ord AS jsonb" in sql
    assert "VALUE ? 'ob'" in sql
    assert "VALUE ? 'ore'" not in sql


def test_domain_block_check_pins_envelope_version():
    """Thread D: the CHECK both verifies the envelope `v` key is PRESENT and
    pins its value to the EQL payload-format version (2), matching the
    repo-wide eql_v2._encrypted_check_v rule. The v=1 payloads in
    tests/sqlx/fixtures/aggregate_minmax_data.sql belong to the separate
    composite-type (eql_v2_encrypted) aggregate stream, not these domains, so
    pinning the value here rejects stale/foreign-version payloads without
    affecting that fixture."""
    for domain in (
        DomainSpec(name="int4", terms=[]),
        DomainSpec(name="int4_eq", terms=["hm"]),
        DomainSpec(name="int4_ord", terms=["ore"]),
    ):
        sql = render_domain_block(domain, "int4")
        assert "VALUE ? 'v'" in sql              # presence checked
        assert "VALUE->>'v' = '2'" in sql        # value pinned to version 2


def test_extractor_is_catalog_derived_and_inlinable():
    domain = DomainSpec(name="int4_eq", terms=["hm"])
    sql = render_extractor(domain, TERM_CATALOG["hm"])
    assert "CREATE FUNCTION eql_v3.eq_term(a eql_v3.int4_eq)" in sql
    assert "RETURNS eql_v2.hmac_256" in sql
    assert "LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE" in sql
    assert "SELECT eql_v2.hmac_256(a::jsonb)" in sql
    assert "SET search_path" not in sql


def test_wrapper_uses_term_extractor_for_supported_operator():
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_wrapper(
        domain,
        op="<",
        arg_a="eql_v3.int4_ord",
        arg_b="jsonb",
        extractor="ord_term",
    )
    assert "CREATE FUNCTION eql_v3.lt(a eql_v3.int4_ord, b jsonb)" in sql
    assert "SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::eql_v3.int4_ord)" in sql


def test_wrapper_is_inlinable_sql():
    """Wrappers must be single-statement LANGUAGE sql with no search_path pin."""
    domain = DomainSpec(name="int4_eq", terms=["hm"])
    sql = render_wrapper(
        domain,
        op="=",
        arg_a="eql_v3.int4_eq",
        arg_b="eql_v3.int4_eq",
        extractor="eq_term",
    )
    assert "LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE" in sql
    assert "SET search_path" not in sql
    assert "LANGUAGE plpgsql" not in sql


def test_extractor_for_operator_selects_catalog_term():
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    assert extractor_for_operator(domain, "=") == "ord_term"
    assert extractor_for_operator(domain, "<") == "ord_term"


def test_extractor_for_operator_returns_none_for_unsupported_operator():
    domain = DomainSpec(name="int4_eq", terms=["hm"])
    assert extractor_for_operator(domain, "<") is None


def test_blocker_bool_is_not_strict():
    """Footgun: a STRICT blocker lets Postgres skip the body on NULL input,
    silently bypassing the 'operator not supported' raise. Assert the exact
    attribute line so any future refactor that re-adds STRICT fails loudly."""
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_bool(
        domain, op="<", arg_a="eql_v3.int4", arg_b="eql_v3.int4",
    )
    assert "CREATE FUNCTION eql_v3.lt(a eql_v3.int4, b eql_v3.int4)" in sql
    assert "encrypted_domain_unsupported_bool('eql_v3.int4', '<')" in sql
    assert "RETURNS boolean IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_path_is_not_strict():
    """Mirror of test_blocker_bool_is_not_strict for path blockers."""
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_path(
        domain, op="->", arg_a="eql_v3.int4", arg_b="text",
    )
    assert "RETURNS eql_v3.int4 IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_path_returns_domain_or_text():
    domain = DomainSpec(name="int4", terms=[])
    arrow = render_blocker_path(
        domain, op="->", arg_a="eql_v3.int4", arg_b="text",
    )
    assert 'CREATE FUNCTION eql_v3."->"(a eql_v3.int4, selector text)' in arrow
    assert "RETURNS eql_v3.int4" in arrow
    arrow2 = render_blocker_path(
        domain, op="->>", arg_a="eql_v3.int4", arg_b="text",
    )
    assert "RETURNS text" in arrow2


def test_blocker_path_for_jsonb_left_arg_returns_domain():
    """The (jsonb, dom) shape from _path_shapes still routes to the domain
    return type for `->` (only `->>` returns text)."""
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_path(
        domain, op="->", arg_a="jsonb", arg_b="eql_v3.int4",
    )
    assert 'CREATE FUNCTION eql_v3."->"(a jsonb, selector eql_v3.int4)' in sql
    assert "RETURNS eql_v3.int4" in sql


def test_blocker_native_bool_uses_helper_and_is_not_strict():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="?", arg_a="eql_v3.int4", arg_b="text", returns="boolean",
    )
    assert 'CREATE FUNCTION eql_v3."?"(a eql_v3.int4, b text)' in sql
    assert "encrypted_domain_unsupported_bool('eql_v3.int4', '?')" in sql
    assert "RETURNS boolean IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_native_jsonb_result_raises_and_is_not_strict():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="#>", arg_a="eql_v3.int4", arg_b="text[]", returns="jsonb",
    )
    assert 'CREATE FUNCTION eql_v3."#>"(a eql_v3.int4, b text[])' in sql
    assert "RETURNS jsonb IMMUTABLE PARALLEL SAFE\n" in sql
    assert "RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.int4'" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_native_text_result_raises_and_is_not_strict():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="#>>", arg_a="eql_v3.int4", arg_b="text[]", returns="text",
    )
    assert 'CREATE FUNCTION eql_v3."#>>"(a eql_v3.int4, b text[])' in sql
    assert "RETURNS text IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_native_concat_cross_shape():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="||", arg_a="jsonb", arg_b="eql_v3.int4", returns="jsonb",
    )
    assert 'CREATE FUNCTION eql_v3."||"(a jsonb, b eql_v3.int4)' in sql
    assert "RETURNS jsonb" in sql


def test_operator_symmetric_metadata():
    sql = render_operator(
        op="=", backing="eq",
        leftarg="eql_v3.int4_eq", rightarg="eql_v3.int4_eq",
        supported=True,
    )
    assert "CREATE OPERATOR = (" in sql
    assert "FUNCTION = eql_v3.eq" in sql
    assert "LEFTARG = eql_v3.int4_eq, RIGHTARG = eql_v3.int4_eq" in sql
    assert "NEGATOR = <>" in sql
    assert "RESTRICT = eqsel" in sql


def test_render_operator_unsupported_emits_only_function_and_args():
    """Unsupported routing must not emit NEGATOR / RESTRICT / JOIN / COMMUTATOR
    (those would lie about selectivity for a function that always raises)."""
    sql = render_operator(
        op="=", backing="eq",
        leftarg="eql_v3.int4", rightarg="eql_v3.int4",
        supported=False,
    )
    assert "CREATE OPERATOR = (" in sql
    assert "FUNCTION = eql_v3.eq" in sql
    assert "LEFTARG = eql_v3.int4, RIGHTARG = eql_v3.int4" in sql
    assert "NEGATOR" not in sql
    assert "RESTRICT" not in sql
    assert "JOIN" not in sql
    assert "COMMUTATOR" not in sql


def test_render_aggregate_min_int4_ord_emits_state_function_and_aggregate():
    """Pin the rendered shape for the canonical (int4_ord, min) case."""
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_aggregate(domain, AGGREGATE_OPS["min"])
    assert "CREATE FUNCTION eql_v3.min_sfunc(state eql_v3.int4_ord, value eql_v3.int4_ord)" in sql
    assert "RETURNS eql_v3.int4_ord" in sql
    assert "LANGUAGE plpgsql IMMUTABLE STRICT" in sql
    assert "SET search_path = pg_catalog, extensions, public" in sql
    assert "IF value < state THEN" in sql
    assert "CREATE AGGREGATE eql_v3.min(eql_v3.int4_ord) (" in sql
    assert "sfunc = eql_v3.min_sfunc" in sql
    assert "stype = eql_v3.int4_ord" in sql


def test_render_aggregate_max_uses_greater_than_comparator():
    """Symmetric pin: max uses `>` not `<`."""
    domain = DomainSpec(name="int4_ord_ore", terms=["ore"])
    sql = render_aggregate(domain, AGGREGATE_OPS["max"])
    assert "CREATE FUNCTION eql_v3.max_sfunc(state eql_v3.int4_ord_ore, value eql_v3.int4_ord_ore)" in sql
    assert "IF value > state THEN" in sql
    assert "CREATE AGGREGATE eql_v3.max(eql_v3.int4_ord_ore) (" in sql


def test_render_aggregate_state_function_is_not_inlinable():
    """Footgun mirror: blockers must be LANGUAGE plpgsql; the state function
    deliberately is too, so the planner can't elide an IMMUTABLE STRICT
    aggregate state call away. STRICT + plpgsql + SET search_path together."""
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_aggregate(domain, AGGREGATE_OPS["min"])
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" in sql
    # Inlinable-SQL shape — explicitly absent.
    assert "LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE" not in sql


def test_is_ord_capable_matches_role():
    assert is_ord_capable(DomainSpec(name="int4_ord", terms=["ore"])) is True
    assert is_ord_capable(DomainSpec(name="int4_ord_ore", terms=["ore"])) is True
    assert is_ord_capable(DomainSpec(name="int4_eq", terms=["hm"])) is False
    assert is_ord_capable(DomainSpec(name="int4", terms=[])) is False


def test_render_operator_for_containment_omits_commutator():
    """@> has no commutator / negator / selectivity in OPERATORS; supported=True
    must still omit those clauses."""
    sql = render_operator(
        op="@>", backing="contains",
        leftarg="eql_v3.int4_ord", rightarg="eql_v3.int4_ord",
        supported=True,
    )
    assert "CREATE OPERATOR @> (" in sql
    assert "FUNCTION = eql_v3.contains" in sql
    assert "COMMUTATOR" not in sql
    assert "NEGATOR" not in sql
    assert "RESTRICT" not in sql
    assert "JOIN" not in sql


# --- ITEM A: placeholder/blocker operator comment -------------------------


def test_render_operator_unsupported_emits_placeholder_comment():
    """Thread A: a blocker-backed (unsupported) operator must carry a leading
    SQL comment explaining it is a placeholder that raises, so a future
    reviewer doesn't wonder why an ordering op is declared on an eq-only
    domain."""
    sql = render_operator(
        op="<", backing="lt",
        leftarg="eql_v3.int4_eq", rightarg="eql_v3.int4_eq",
        supported=False,
    )
    assert sql.startswith("-- Placeholder:")
    assert "does not support <" in sql
    assert "always raises" in sql
    # The comment precedes the CREATE OPERATOR.
    assert sql.index("-- Placeholder:") < sql.index("CREATE OPERATOR")


def test_render_operator_supported_has_no_placeholder_comment():
    """Supported operators route to real wrappers — no placeholder comment."""
    sql = render_operator(
        op="=", backing="eq",
        leftarg="eql_v3.int4_eq", rightarg="eql_v3.int4_eq",
        supported=True,
    )
    assert "Placeholder" not in sql


# --- ITEM B & J: aggregate SQL rationale comments -------------------------


def test_render_aggregate_state_function_emits_plpgsql_rationale_comment():
    """Thread B: the plpgsql rationale must appear in the emitted SQL (not just
    as a Python comment) so a SQL reader sees why it isn't an inlinable
    LANGUAGE sql CASE."""
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_aggregate(domain, AGGREGATE_OPS["min"])
    assert "-- LANGUAGE plpgsql, not sql:" in sql
    assert "not index" in sql
    # The rationale precedes the state-function definition.
    assert sql.index("-- LANGUAGE plpgsql, not sql:") < sql.index(
        "CREATE FUNCTION eql_v3.min_sfunc"
    )


def test_render_aggregate_enables_parallel_and_combinefunc():
    """Thread #22: MIN/MAX aggregates declare a combine function (the state
    function itself — min/max are associative) and PARALLEL = SAFE, so PG can
    use partial/parallel aggregation on the large GROUP BY workloads these ORE
    aggregates exist to serve. The sfunc is likewise PARALLEL SAFE."""
    for op_name, sfunc in (("min", "min_sfunc"), ("max", "max_sfunc")):
        domain = DomainSpec(name="int4_ord", terms=["ore"])
        sql = render_aggregate(domain, AGGREGATE_OPS[op_name])
        # The state function must be parallel-safe...
        assert "LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE" in sql
        # ...and the aggregate must declare the combinefunc + parallel safety
        # inside the CREATE AGGREGATE option list (not merely in prose).
        aggregate_body = sql[sql.index(f"CREATE AGGREGATE eql_v3.{op_name}"):]
        assert f"combinefunc = eql_v3.{sfunc}" in aggregate_body
        assert "parallel = safe" in aggregate_body
        # The stale "intentionally disabled" omission note must be gone.
        assert "intentionally disabled" not in sql
        assert "-- No COMBINEFUNC" not in sql


# --- ITEM K: differentiated @brief for converged vs scheme-explicit -------


def test_domain_brief_distinguishes_converged_from_scheme_twin():
    """Thread K: int4_ord (converged) and int4_ord_ore (scheme twin) carry the
    same terms but must render distinct, sensible briefs."""
    ord_dom = DomainSpec(name="int4_ord", terms=["ore"])
    ore_dom = DomainSpec(name="int4_ord_ore", terms=["ore"])
    ord_sql = render_domain_block(ord_dom, "int4")
    ore_sql = render_domain_block(ore_dom, "int4")

    ord_brief = next(
        line for line in ord_sql.splitlines() if "@brief" in line
    )
    ore_brief = next(
        line for line in ore_sql.splitlines() if "@brief" in line
    )
    # Both still lead with the role phrase...
    assert "Ordered encrypted int4 domain." in ord_brief
    assert "Ordered encrypted int4 domain." in ore_brief
    # ...but the trailing clause differs and reads sensibly.
    assert ord_brief != ore_brief
    assert "Recommended converged name" in ord_brief
    assert "Scheme-explicit twin" in ore_brief
    assert "ore scheme" in ore_brief
    assert "int4_ord" in ore_brief  # points back at the converged name


def test_brief_role_clause_is_generic_over_token_and_scheme():
    """The disambiguation reads token/role/scheme from the name, not a
    hard-coded literal — so it works for other types (int8) and schemes."""
    # Converged ordered name for a different token.
    assert "Recommended converged name" in brief_role_clause(
        DomainSpec(name="int8_ord", terms=["ore"]), "int8"
    )
    # Scheme-explicit twin with a hypothetical non-ore scheme label.
    clause = brief_role_clause(
        DomainSpec(name="date_ord_lex", terms=["ore"]), "date"
    )
    assert "Scheme-explicit twin" in clause
    assert "lex scheme" in clause
    assert "date_ord" in clause


def test_brief_role_clause_empty_for_storage_and_eq():
    """Storage and eq domains have no converged/twin ambiguity (only one name
    each), so they get no disambiguating clause — brief stays unchanged."""
    assert brief_role_clause(DomainSpec(name="int4", terms=[]), "int4") == ""
    assert brief_role_clause(
        DomainSpec(name="int4_eq", terms=["hm"]), "int4"
    ) == ""


# --- THREAD 1: SQL-string interpolation hardening -------------------------


def test_sql_str_doubles_single_quotes():
    """_sql_str doubles embedded single quotes so a value can't break out of
    its SQL string literal."""
    assert _sql_str("o'brien") == "o''brien"
    assert _sql_str("a'b'c") == "a''b''c"
    # Quote-free input is unchanged — current catalog strings stay byte-stable.
    assert _sql_str("int4_eq") == "int4_eq"
    assert _sql_str("<=") == "<="


def test_blocker_escapes_quote_bearing_domain_in_rendered_sql():
    """A hypothetical quote-bearing domain name must be doubled inside the
    helper-call string literal in the rendered blocker, not interpolated raw.

    (op can't carry a quote in practice — it's looked up in the operator
    catalog — so the domain name is the live escaping path through the blocker
    string literals.)"""
    domain = DomainSpec(name="o'dom", terms=[])
    sql = render_blocker_bool(
        domain, op="<", arg_a="eql_v3.o'dom", arg_b="eql_v3.o'dom",
    )
    # The dom flows into encrypted_domain_unsupported_bool('<dom>', '<op>')
    # as a single-quoted literal — the quote must be doubled.
    assert "encrypted_domain_unsupported_bool('eql_v3.o''dom', '<')" in sql
    # The raw, unescaped single-quoted form must not appear.
    assert "'eql_v3.o'dom'" not in sql


def test_domain_block_escapes_quote_bearing_key_in_check():
    """A hypothetical quote-bearing payload key must be doubled inside the
    VALUE ? '<key>' check rather than interpolated raw."""
    # A term-free domain whose name carries a quote exercises the typname
    # literal escaping in the IF NOT EXISTS guard.
    quoted = DomainSpec(name="we'ird", terms=[])
    sql = render_domain_block(quoted, "int4")
    assert "typname = 'we''ird'" in sql
    assert "typname = 'we'ird'" not in sql
