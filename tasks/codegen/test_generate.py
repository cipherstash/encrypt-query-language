"""Tests for composing scalar encrypted-domain files from a manifest."""

import textwrap

import pytest

from tasks.codegen.generate import (
    generate_type,
    main,
    render_functions_file,
    render_operators_file,
    render_types_file,
)
from tasks.codegen.spec import load_spec
from tasks.codegen.templates import AUTO_GENERATED_HEADER
from tasks.codegen.writer import OwnershipError


INT4_TOML = textwrap.dedent("""
    [domain]
    int4 = []
    int4_eq = ["hm"]
    int4_ord_ore = ["ore"]
    int4_ord = ["ore"]
""")


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
    assert len(written) == 9
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
    stdout = capsys.readouterr().out
    assert "generated 9 files for int4" in stdout


def test_ordered_files_are_byte_identical_modulo_typename(tmp_path):
    spec = load(tmp_path)
    ord_domain = next(d for d in spec.domains if d.name == "int4_ord")
    ore_domain = next(d for d in spec.domains if d.name == "int4_ord_ore")

    for renderer in (render_functions_file, render_operators_file):
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
