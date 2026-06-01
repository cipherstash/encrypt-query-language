"""Tests for the ownership / overwrite-refusal / stale-cleanup rules."""
import pytest
from tasks.codegen.generate import REPO_ROOT
from tasks.codegen.templates import AUTO_GENERATED_HEADER, AUTO_GENERATED_HEADER_RS
from tasks.codegen.writer import (
    _MARKER,
    OwnershipError,
    is_generated,
    is_generated_rs,
    clean_generated_files,
    ensure_generated_paths_writable,
    write_generated_file,
    write_generated_rs,
)


_EXPECTED_SUFFIXES = (
    "_types.sql",
    "_functions.sql",
    "_operators.sql",
    "_aggregates.sql",
    "_extensions.sql",
)


def test_is_generated_true_for_header(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text(AUTO_GENERATED_HEADER + "SELECT 1;\n")
    assert is_generated(p) is True


def test_is_generated_false_for_handwritten(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text("-- REQUIRE: src/schema.sql\nSELECT 1;\n")
    assert is_generated(p) is False


def test_is_generated_true_for_crlf_header(tmp_path):
    p = tmp_path / "x.sql"
    p.write_bytes((_MARKER + "\r\n" + "SELECT 1;\n").encode("utf-8"))
    assert is_generated(p) is True


def test_write_generated_file_creates_with_header(tmp_path):
    p = tmp_path / "int4_types.sql"
    write_generated_file(p, "DO $$ BEGIN END $$;\n")
    text = p.read_text()
    assert text.startswith(AUTO_GENERATED_HEADER)
    assert "DO $$ BEGIN END $$;" in text


def test_write_refuses_to_overwrite_handwritten(tmp_path):
    """Refuse to clobber a hand-written file at a generated path."""
    p = tmp_path / "int4_types.sql"
    p.write_text("-- REQUIRE: src/schema.sql\n-- hand-written\n")
    with pytest.raises(OwnershipError, match="hand-written"):
        write_generated_file(p, "DO $$ BEGIN END $$;\n")


def test_preflight_refuses_handwritten_target_before_cleanup(tmp_path):
    generated = tmp_path / "int4_types.sql"
    hand = tmp_path / "int4_eq_functions.sql"
    generated.write_text(AUTO_GENERATED_HEADER + "-- old generated\n")
    hand.write_text("-- REQUIRE: src/schema.sql\n-- hand-written\n")

    with pytest.raises(OwnershipError, match=r"int4_eq_functions\.sql"):
        ensure_generated_paths_writable([generated, hand])

    assert generated.exists()
    assert hand.exists()


def test_write_overwrites_existing_generated_file(tmp_path):
    """A file that already carries the header may be overwritten."""
    p = tmp_path / "int4_types.sql"
    p.write_text(AUTO_GENERATED_HEADER + "-- old content\n")
    write_generated_file(p, "-- new content\n")
    text = p.read_text()
    assert "-- new content" in text
    assert "-- old content" not in text


def test_clean_removes_only_generated_files(tmp_path):
    """Clean deletes every generated file, keeps the rest."""
    gen1 = tmp_path / "int4_eq_functions.sql"
    gen2 = tmp_path / "int4_old_domain_functions.sql"  # stale orphan
    hand = tmp_path / "int4_jsonb_extra.sql"
    gen1.write_text(AUTO_GENERATED_HEADER + "SELECT 1;\n")
    gen2.write_text(AUTO_GENERATED_HEADER + "SELECT 2;\n")
    hand.write_text("-- REQUIRE: src/schema.sql\n-- hand-written\n")

    removed = clean_generated_files(tmp_path)

    assert not gen1.exists()
    assert not gen2.exists()  # stale orphan cleaned up
    assert hand.exists()      # hand-written file untouched
    assert set(removed) == {gen1, gen2}


def test_clean_on_empty_directory(tmp_path):
    """Clean on a greenfield directory removes nothing and does not error."""
    removed = clean_generated_files(tmp_path)
    assert removed == []


def test_write_generated_rs_creates_with_rust_header(tmp_path):
    p = tmp_path / "int4_values.rs"
    write_generated_rs(p, "pub const VALUES: &[i32] = &[];\n")
    text = p.read_text()
    assert text.startswith(AUTO_GENERATED_HEADER_RS)
    assert "pub const VALUES" in text


def test_is_generated_rs_true_for_rust_header(tmp_path):
    p = tmp_path / "int4_values.rs"
    p.write_text(AUTO_GENERATED_HEADER_RS + "pub const VALUES: &[i32] = &[];\n")
    assert is_generated_rs(p) is True


def test_is_generated_rs_false_for_handwritten(tmp_path):
    p = tmp_path / "int4_values.rs"
    p.write_text("//! hand-written\npub const VALUES: &[i32] = &[];\n")
    assert is_generated_rs(p) is False


def test_write_generated_rs_refuses_to_overwrite_handwritten(tmp_path):
    p = tmp_path / "int4_values.rs"
    p.write_text("//! hand-written\n")
    with pytest.raises(OwnershipError, match="hand-written"):
        write_generated_rs(p, "pub const VALUES: &[i32] = &[];\n")


def test_write_generated_rs_overwrites_existing_generated(tmp_path):
    p = tmp_path / "int4_values.rs"
    p.write_text(AUTO_GENERATED_HEADER_RS + "// old\n")
    write_generated_rs(p, "// new\n")
    text = p.read_text()
    assert "// new" in text
    assert "// old" not in text


def test_no_misnamed_sql_files_in_generated_dirs():
    """Files under src/encrypted_domain/<T>/ must end in one of the four
    documented suffixes — catches mistakes like `int4_extension.sql`
    (singular), which the build would silently include despite violating
    the documented convention."""
    root = REPO_ROOT / "src" / "encrypted_domain"
    misnamed = [
        path.relative_to(REPO_ROOT)
        for type_dir in root.iterdir() if type_dir.is_dir()
        for path in sorted(type_dir.glob("*.sql"))
        if not path.name.endswith(_EXPECTED_SUFFIXES)
    ] if root.is_dir() else []
    assert not misnamed, (
        f"misnamed SQL files in src/encrypted_domain/ — expected suffix in "
        f"{_EXPECTED_SUFFIXES}: {misnamed}"
    )
