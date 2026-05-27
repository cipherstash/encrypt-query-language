"""Tests for per-construct SQL template functions."""

from tasks.codegen.spec import DomainSpec
from tasks.codegen.templates import (
    AGGREGATE_OPS,
    AUTO_GENERATED_HEADER,
    domain_name,
    extractor_for_operator,
    is_ord_capable,
    render_aggregate,
    render_blocker_bool,
    render_blocker_native,
    render_blocker_path,
    render_domain_block,
    render_extractor,
    render_operator,
    render_wrapper,
)
from tasks.codegen.terms import TERM_CATALOG


def test_auto_generated_header_present():
    assert "AUTO-GENERATED" in AUTO_GENERATED_HEADER
    assert "DO NOT EDIT" in AUTO_GENERATED_HEADER


def test_domain_block_storage_uses_fixed_envelope_only():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_domain_block(domain, "int4")
    assert "CREATE DOMAIN public.eql_v2_int4 AS jsonb" in sql
    assert "VALUE ? 'v'" in sql
    assert "VALUE ? 'i'" in sql
    assert "VALUE ? 'c'" in sql
    assert "VALUE ? 'hm'" not in sql
    assert "VALUE ? 'ob'" not in sql


def test_domain_block_uses_catalog_json_keys():
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_domain_block(domain, "int4")
    assert "CREATE DOMAIN public.eql_v2_int4_ord AS jsonb" in sql
    assert "VALUE ? 'ob'" in sql
    assert "VALUE ? 'ore'" not in sql


def test_extractor_is_catalog_derived_and_inlinable():
    domain = DomainSpec(name="int4_eq", terms=["hm"])
    sql = render_extractor(domain, TERM_CATALOG["hm"])
    assert "CREATE FUNCTION eql_v2.eq_term(a eql_v2_int4_eq)" in sql
    assert "RETURNS eql_v2.hmac_256" in sql
    assert "LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE" in sql
    assert "SELECT eql_v2.hmac_256(a::jsonb)" in sql
    assert "SET search_path" not in sql


def test_wrapper_uses_term_extractor_for_supported_operator():
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_wrapper(
        domain,
        op="<",
        arg_a="eql_v2_int4_ord",
        arg_b="jsonb",
        extractor="ord_term",
    )
    assert "CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord, b jsonb)" in sql
    assert "SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b::eql_v2_int4_ord)" in sql


def test_wrapper_is_inlinable_sql():
    """Wrappers must be single-statement LANGUAGE sql with no search_path pin."""
    domain = DomainSpec(name="int4_eq", terms=["hm"])
    sql = render_wrapper(
        domain,
        op="=",
        arg_a="eql_v2_int4_eq",
        arg_b="eql_v2_int4_eq",
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
        domain, op="<", arg_a="eql_v2_int4", arg_b="eql_v2_int4",
    )
    assert "CREATE FUNCTION eql_v2.lt(a eql_v2_int4, b eql_v2_int4)" in sql
    assert "encrypted_domain_unsupported_bool('eql_v2_int4', '<')" in sql
    assert "RETURNS boolean IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_path_is_not_strict():
    """Mirror of test_blocker_bool_is_not_strict for path blockers."""
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_path(
        domain, op="->", arg_a="eql_v2_int4", arg_b="text",
    )
    assert "RETURNS eql_v2_int4 IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_path_returns_domain_or_text():
    domain = DomainSpec(name="int4", terms=[])
    arrow = render_blocker_path(
        domain, op="->", arg_a="eql_v2_int4", arg_b="text",
    )
    assert 'CREATE FUNCTION eql_v2."->"(a eql_v2_int4, selector text)' in arrow
    assert "RETURNS eql_v2_int4" in arrow
    arrow2 = render_blocker_path(
        domain, op="->>", arg_a="eql_v2_int4", arg_b="text",
    )
    assert "RETURNS text" in arrow2


def test_blocker_path_for_jsonb_left_arg_returns_domain():
    """The (jsonb, dom) shape from _path_shapes still routes to the domain
    return type for `->` (only `->>` returns text)."""
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_path(
        domain, op="->", arg_a="jsonb", arg_b="eql_v2_int4",
    )
    assert 'CREATE FUNCTION eql_v2."->"(a jsonb, selector eql_v2_int4)' in sql
    assert "RETURNS eql_v2_int4" in sql


def test_blocker_native_bool_uses_helper_and_is_not_strict():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="?", arg_a="eql_v2_int4", arg_b="text", returns="boolean",
    )
    assert 'CREATE FUNCTION eql_v2."?"(a eql_v2_int4, b text)' in sql
    assert "encrypted_domain_unsupported_bool('eql_v2_int4', '?')" in sql
    assert "RETURNS boolean IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_native_jsonb_result_raises_and_is_not_strict():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="#>", arg_a="eql_v2_int4", arg_b="text[]", returns="jsonb",
    )
    assert 'CREATE FUNCTION eql_v2."#>"(a eql_v2_int4, b text[])' in sql
    assert "RETURNS jsonb IMMUTABLE PARALLEL SAFE\n" in sql
    assert "RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v2_int4'" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_native_text_result_raises_and_is_not_strict():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="#>>", arg_a="eql_v2_int4", arg_b="text[]", returns="text",
    )
    assert 'CREATE FUNCTION eql_v2."#>>"(a eql_v2_int4, b text[])' in sql
    assert "RETURNS text IMMUTABLE PARALLEL SAFE\n" in sql
    assert "LANGUAGE plpgsql" in sql
    assert "STRICT" not in sql


def test_blocker_native_concat_cross_shape():
    domain = DomainSpec(name="int4", terms=[])
    sql = render_blocker_native(
        domain, op="||", arg_a="jsonb", arg_b="eql_v2_int4", returns="jsonb",
    )
    assert 'CREATE FUNCTION eql_v2."||"(a jsonb, b eql_v2_int4)' in sql
    assert "RETURNS jsonb" in sql


def test_operator_symmetric_metadata():
    sql = render_operator(
        op="=", backing="eq",
        leftarg="eql_v2_int4_eq", rightarg="eql_v2_int4_eq",
        supported=True,
    )
    assert "CREATE OPERATOR = (" in sql
    assert "FUNCTION = eql_v2.eq" in sql
    assert "LEFTARG = eql_v2_int4_eq, RIGHTARG = eql_v2_int4_eq" in sql
    assert "NEGATOR = <>" in sql
    assert "RESTRICT = eqsel" in sql


def test_render_operator_unsupported_emits_only_function_and_args():
    """Unsupported routing must not emit NEGATOR / RESTRICT / JOIN / COMMUTATOR
    (those would lie about selectivity for a function that always raises)."""
    sql = render_operator(
        op="=", backing="eq",
        leftarg="eql_v2_int4", rightarg="eql_v2_int4",
        supported=False,
    )
    assert "CREATE OPERATOR = (" in sql
    assert "FUNCTION = eql_v2.eq" in sql
    assert "LEFTARG = eql_v2_int4, RIGHTARG = eql_v2_int4" in sql
    assert "NEGATOR" not in sql
    assert "RESTRICT" not in sql
    assert "JOIN" not in sql
    assert "COMMUTATOR" not in sql


def test_render_aggregate_min_int4_ord_emits_state_function_and_aggregate():
    """Pin the rendered shape for the canonical (int4_ord, min) case."""
    domain = DomainSpec(name="int4_ord", terms=["ore"])
    sql = render_aggregate(domain, AGGREGATE_OPS["min"])
    assert "CREATE FUNCTION eql_v2.min_sfunc(state eql_v2_int4_ord, value eql_v2_int4_ord)" in sql
    assert "RETURNS eql_v2_int4_ord" in sql
    assert "LANGUAGE plpgsql IMMUTABLE STRICT" in sql
    assert "SET search_path = pg_catalog, extensions, public" in sql
    assert "IF value < state THEN" in sql
    assert "CREATE AGGREGATE eql_v2.min(eql_v2_int4_ord) (" in sql
    assert "sfunc = eql_v2.min_sfunc" in sql
    assert "stype = eql_v2_int4_ord" in sql


def test_render_aggregate_max_uses_greater_than_comparator():
    """Symmetric pin: max uses `>` not `<`."""
    domain = DomainSpec(name="int4_ord_ore", terms=["ore"])
    sql = render_aggregate(domain, AGGREGATE_OPS["max"])
    assert "CREATE FUNCTION eql_v2.max_sfunc(state eql_v2_int4_ord_ore, value eql_v2_int4_ord_ore)" in sql
    assert "IF value > state THEN" in sql
    assert "CREATE AGGREGATE eql_v2.max(eql_v2_int4_ord_ore) (" in sql


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
        leftarg="eql_v2_int4_ord", rightarg="eql_v2_int4_ord",
        supported=True,
    )
    assert "CREATE OPERATOR @> (" in sql
    assert "FUNCTION = eql_v2.contains" in sql
    assert "COMMUTATOR" not in sql
    assert "NEGATOR" not in sql
    assert "RESTRICT" not in sql
    assert "JOIN" not in sql
