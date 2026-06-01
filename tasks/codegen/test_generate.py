"""Tests for composing scalar encrypted-domain files from a manifest."""

import textwrap

import pytest

from tasks.codegen.generate import (
    generate_type,
    main,
    render_aggregates_file,
    render_functions_file,
    render_operators_file,
    render_types_file,
)
from tasks.codegen.spec import load_spec
from tasks.codegen.templates import AUTO_GENERATED_HEADER, AUTO_GENERATED_HEADER_RS
from tasks.codegen.writer import OwnershipError


INT4_TOML = textwrap.dedent("""
    [domain]
    int4 = []
    int4_eq = ["hm"]
    int4_ord_ore = ["ore"]
    int4_ord = ["ore"]
""")

INT4_FIXTURE_TOML = INT4_TOML + textwrap.dedent("""
    [fixture]
    values = ["MIN", "-1", "ZERO", "1", "MAX"]
""")

# A second, synthetic type for multi-type (--all) coverage. No [fixture] table,
# so it never touches scalars.py (which only registers int4) — it exercises the
# enumeration, not fixture rendering.
INT4X_TOML = textwrap.dedent("""
    [domain]
    int4x = []
    int4x_eq = ["hm"]
    int4x_ord = ["ore"]
""")


def _fixture_values_rs(out_root):
    return out_root / "tests" / "sqlx" / "src" / "fixtures" / "int4_values.rs"


def load(tmp_path):
    p = tmp_path / "int4.toml"
    p.write_text(INT4_TOML)
    return load_spec(p)


def test_types_file_has_all_four_domains(tmp_path):
    spec = load(tmp_path)
    sql = render_types_file(spec)
    assert "-- REQUIRE: src/schema.sql" in sql
    for dom in ("eql_v2_int4", "eql_v2_int4_eq",
                "eql_v2_int4_ord", "eql_v2_int4_ord_ore"):
        assert f"CREATE DOMAIN public.{dom} AS jsonb" in sql


def test_storage_functions_file_is_all_blockers(tmp_path):
    spec = load(tmp_path)
    storage = next(d for d in spec.domains if d.name == "int4")
    sql = render_functions_file(spec, storage)
    assert sql.count("CREATE FUNCTION") == 44
    assert "SET search_path" not in sql
    assert sql.count("LANGUAGE plpgsql") == 44
    assert sql.count("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE") == 0


def test_eq_functions_file_counts_and_extractor(tmp_path):
    spec = load(tmp_path)
    eq = next(d for d in spec.domains if d.name == "int4_eq")
    sql = render_functions_file(spec, eq)
    assert sql.count("CREATE FUNCTION") == 45
    assert "CREATE FUNCTION eql_v2.eq_term(a eql_v2_int4_eq)" in sql
    assert "RETURNS eql_v2.hmac_256" in sql
    # 1 extractor + 6 wrappers (=, <> across 3 arg-shapes) inlined as SQL;
    # 38 blockers across the remaining native jsonb surface as plpgsql.
    assert sql.count("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE") == 7
    assert sql.count("LANGUAGE plpgsql") == 38
    assert "SET search_path" not in sql


def test_ore_functions_file_counts_and_extractor(tmp_path):
    spec = load(tmp_path)
    ordered = next(d for d in spec.domains if d.name == "int4_ord")
    sql = render_functions_file(spec, ordered)
    assert sql.count("CREATE FUNCTION") == 45
    assert "CREATE FUNCTION eql_v2.ord_term(a eql_v2_int4_ord)" in sql
    assert "RETURNS eql_v2.ore_block_u64_8_256" in sql
    # 1 extractor + 18 wrappers (=, <>, <, <=, >, >= across 3 shapes);
    # 26 blockers across containment/path/native-jsonb fallback ops.
    assert sql.count("LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE") == 19
    assert sql.count("LANGUAGE plpgsql") == 26
    assert "SET search_path" not in sql


def test_operators_file_has_forty_four(tmp_path):
    spec = load(tmp_path)
    eq = next(d for d in spec.domains if d.name == "int4_eq")
    sql = render_operators_file(spec, eq)
    assert sql.count("CREATE OPERATOR") == 44


def test_generate_type_writes_expected_files(tmp_path):
    spec = load(tmp_path)
    out_dir = tmp_path / "int4"
    written = generate_type(spec, out_dir)
    names = {p.name for p in written}
    assert "int4_types.sql" in names
    for domain in ("int4", "int4_eq", "int4_ord", "int4_ord_ore"):
        assert f"{domain}_functions.sql" in names
        assert f"{domain}_operators.sql" in names
    # Aggregates only emitted for ord-capable variants — storage and eq skip.
    assert "int4_aggregates.sql" not in names
    assert "int4_eq_aggregates.sql" not in names
    assert "int4_ord_aggregates.sql" in names
    assert "int4_ord_ore_aggregates.sql" in names
    # 1 types + 4 functions + 4 operators + 2 aggregates = 11
    assert len(written) == 11
    for p in written:
        assert p.read_text().startswith(AUTO_GENERATED_HEADER)


def test_generate_type_cleans_stale_files(tmp_path):
    spec = load(tmp_path)
    out_dir = tmp_path / "int4"
    out_dir.mkdir()
    stale = out_dir / "int4_removed_functions.sql"
    stale.write_text(AUTO_GENERATED_HEADER + "-- orphan\n")
    generate_type(spec, out_dir)
    assert not stale.exists()


def test_generate_type_preserves_hand_written_extension_file(tmp_path):
    spec = load(tmp_path)
    out_dir = tmp_path / "int4"
    out_dir.mkdir()
    extension = out_dir / "int4_extensions.sql"
    body = (
        "-- REQUIRE: src/encrypted_domain/int4/int4_types.sql\n"
        "-- hand-written extension SQL\n"
    )
    extension.write_text(body)
    generate_type(spec, out_dir)
    assert extension.read_text() == body


def test_generate_type_preflights_hand_written_target_before_cleanup(tmp_path):
    spec = load(tmp_path)
    out_dir = tmp_path / "int4"
    out_dir.mkdir()
    generated = out_dir / "int4_types.sql"
    protected = out_dir / "int4_eq_functions.sql"
    original_generated = AUTO_GENERATED_HEADER + "-- old generated\n"
    original_protected = "-- REQUIRE: src/schema.sql\n-- hand-written\n"
    generated.write_text(original_generated)
    protected.write_text(original_protected)

    with pytest.raises(OwnershipError, match="hand-written"):
        generate_type(spec, out_dir)

    assert generated.read_text() == original_generated
    assert protected.read_text() == original_protected
    assert not (out_dir / "int4_eq_operators.sql").exists()


def _seed_types_dir(tmp_path, name: str = "int4.toml", body: str = INT4_TOML):
    types_dir = tmp_path / "types"
    types_dir.mkdir()
    (types_dir / name).write_text(body)
    return types_dir


def test_main_rejects_wrong_argv_length(capsys):
    rc = main(["generate.py"])
    assert rc == 2
    err = capsys.readouterr().err
    assert "Usage: generate.py <type>" in err


def test_main_errors_on_missing_manifest(tmp_path, capsys):
    types_dir = tmp_path / "types"
    types_dir.mkdir()
    rc = main(
        ["generate.py", "int4"],
        types_dir=types_dir,
        out_root=tmp_path,
    )
    assert rc == 1
    err = capsys.readouterr().err
    assert "no manifest at" in err
    assert "int4.toml" in err


def test_main_errors_on_token_mismatch(tmp_path, capsys):
    """Manifest stem must equal argv token — guards against a copy/rename."""
    types_dir = _seed_types_dir(tmp_path, name="int4.toml")
    rc = main(
        ["generate.py", "int8"],
        types_dir=types_dir,
        out_root=tmp_path,
    )
    # int8.toml doesn't exist — first failure is missing manifest, not mismatch.
    # To exercise the mismatch branch we need a manifest at int8.toml that
    # declares int4 domains (impossible — the loader infers token from stem).
    # The branch is therefore unreachable via the normal types/<token>.toml
    # convention; the assertion below just confirms the missing-manifest
    # error path fires when the names diverge.
    assert rc == 1
    err = capsys.readouterr().err
    assert "no manifest at" in err
    assert "int8.toml" in err


def test_main_happy_path_writes_files(tmp_path, capsys):
    types_dir = _seed_types_dir(tmp_path)
    rc = main(
        ["generate.py", "int4"],
        types_dir=types_dir,
        out_root=tmp_path,
    )
    assert rc == 0
    out_dir = tmp_path / "src" / "encrypted_domain" / "int4"
    assert (out_dir / "int4_types.sql").is_file()
    assert (out_dir / "int4_eq_functions.sql").is_file()
    assert (out_dir / "int4_ord_operators.sql").is_file()
    assert (out_dir / "int4_ord_aggregates.sql").is_file()
    assert (out_dir / "int4_ord_ore_aggregates.sql").is_file()
    assert not (out_dir / "int4_aggregates.sql").exists()
    assert not (out_dir / "int4_eq_aggregates.sql").exists()
    stdout = capsys.readouterr().out
    assert "generated 11 files for int4" in stdout


def test_main_emits_fixture_values_rs_when_manifest_has_fixture(tmp_path, capsys):
    types_dir = _seed_types_dir(tmp_path, body=INT4_FIXTURE_TOML)
    rc = main(["generate.py", "int4"], types_dir=types_dir, out_root=tmp_path)
    assert rc == 0
    rs = _fixture_values_rs(tmp_path)
    assert rs.is_file()
    text = rs.read_text()
    assert text.startswith(AUTO_GENERATED_HEADER_RS)
    assert "pub const VALUES: &[i32] = &[" in text
    assert "i32::MIN," in text and "i32::MAX," in text
    stdout = capsys.readouterr().out
    assert "int4_values.rs" in stdout


def test_main_omits_fixture_values_rs_when_no_fixture_table(tmp_path, capsys):
    types_dir = _seed_types_dir(tmp_path, body=INT4_TOML)
    rc = main(["generate.py", "int4"], types_dir=types_dir, out_root=tmp_path)
    assert rc == 0
    assert not _fixture_values_rs(tmp_path).exists()


def _seed_two_types(tmp_path):
    types_dir = _seed_types_dir(tmp_path, name="int4.toml", body=INT4_TOML)
    (types_dir / "int4x.toml").write_text(INT4X_TOML)
    return types_dir


def test_main_all_generates_every_type(tmp_path, capsys):
    types_dir = _seed_two_types(tmp_path)
    rc = main(["generate.py", "--all"], types_dir=types_dir, out_root=tmp_path)
    assert rc == 0
    assert (tmp_path / "src/encrypted_domain/int4/int4_types.sql").is_file()
    assert (tmp_path / "src/encrypted_domain/int4x/int4x_types.sql").is_file()
    out = capsys.readouterr().out
    assert "generated 11 files for int4" in out
    assert "codegen --all: ok (2 types: int4, int4x)" in out


def test_main_all_generates_in_sorted_order(tmp_path, capsys):
    types_dir = _seed_two_types(tmp_path)
    main(["generate.py", "--all"], types_dir=types_dir, out_root=tmp_path)
    out = capsys.readouterr().out
    assert out.index("for int4\n") < out.index("for int4x\n")


def test_main_all_errors_when_no_manifests(tmp_path, capsys):
    types_dir = tmp_path / "types"
    types_dir.mkdir()
    rc = main(["generate.py", "--all"], types_dir=types_dir, out_root=tmp_path)
    assert rc == 1
    assert "no manifests found" in capsys.readouterr().err


def test_main_all_aggregates_nonzero_on_bad_manifest(tmp_path, capsys):
    types_dir = _seed_types_dir(tmp_path, name="int4.toml", body=INT4_TOML)
    # 'broken' sorts before 'int4', so it is processed first; its domain name
    # does not start with the token, so load_spec raises SpecError.
    (types_dir / "broken.toml").write_text("[domain]\nwrongprefix = []\n")
    rc = main(["generate.py", "--all"], types_dir=types_dir, out_root=tmp_path)
    assert rc == 1
    captured = capsys.readouterr()
    assert "broken" in captured.err
    assert "codegen --all: FAILED" in captured.out
    # The good type still generated despite the broken sibling.
    assert (tmp_path / "src/encrypted_domain/int4/int4_types.sql").is_file()


def test_ordered_files_are_byte_identical_modulo_typename(tmp_path):
    spec = load(tmp_path)
    ord_domain = next(d for d in spec.domains if d.name == "int4_ord")
    ore_domain = next(d for d in spec.domains if d.name == "int4_ord_ore")

    for renderer in (render_functions_file, render_operators_file, render_aggregates_file):
        ord_sql = renderer(spec, ord_domain)
        ore_sql = renderer(spec, ore_domain)
        normalised_ord = ord_sql.replace("int4_ord_ore", "T").replace(
            "int4_ord", "T"
        )
        normalised_ore = ore_sql.replace("int4_ord_ore", "T").replace(
            "int4_ord", "T"
        )
        assert normalised_ord == normalised_ore, (
            f"{renderer.__name__}: int4_ord and int4_ord_ore must produce "
            f"byte-identical SQL modulo their typenames"
        )


def test_render_aggregates_file_only_for_ord_variants(tmp_path):
    spec = load(tmp_path)
    storage = next(d for d in spec.domains if d.name == "int4")
    eq = next(d for d in spec.domains if d.name == "int4_eq")
    ordered = next(d for d in spec.domains if d.name == "int4_ord")
    ore = next(d for d in spec.domains if d.name == "int4_ord_ore")

    assert render_aggregates_file(spec, storage) is None
    assert render_aggregates_file(spec, eq) is None
    assert render_aggregates_file(spec, ordered) is not None
    assert render_aggregates_file(spec, ore) is not None


def test_render_aggregates_file_carries_both_min_and_max(tmp_path):
    spec = load(tmp_path)
    ordered = next(d for d in spec.domains if d.name == "int4_ord")
    sql = render_aggregates_file(spec, ordered)
    assert sql is not None
    assert sql.count("CREATE FUNCTION") == 2
    assert sql.count("CREATE AGGREGATE") == 2
    assert "eql_v2.min_sfunc" in sql
    assert "eql_v2.max_sfunc" in sql
    # REQUIRE edges: types + functions + operators must all be declared.
    assert "-- REQUIRE: src/encrypted_domain/int4/int4_ord_operators.sql" in sql
    assert "-- REQUIRE: src/encrypted_domain/int4/int4_ord_functions.sql" in sql
    assert "-- REQUIRE: src/encrypted_domain/int4/int4_types.sql" in sql
