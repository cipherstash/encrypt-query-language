#!/usr/bin/env python3
#MISE hide=true
"""
Doxygen XML -> structured JSON manifest for EQL's SQL API.

A machine-readable companion to xml-to-markdown.py. Same Doxygen XML, same
SQL-via-Doxygen quirk handling (parameter name/type swap, operator names in
brief text, RETURNS extraction) — this emits JSON instead of Markdown, for
downstream consumers: docs generation, agents, and drift checks against the
hand-written reference.

Reuses the extraction in xml-to-markdown.py so the manifest and the Markdown
reference can never diverge in how they read the XML.

Doxygen does not extract CREATE DOMAIN, so the manifest also parses the
generated domain SQL to emit the encrypted domain/variant matrix (the core of
the EQL v3 surface) — each domain's capability derived from its CHECK keys.

Usage: xml-to-json.py <xml_dir> [output_dir] [version] [sql_src_dir]
"""

import importlib.util
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# xml-to-markdown.py has a hyphen in its name, so it can't be `import`ed
# normally; load it by path and reuse process_function verbatim.
_spec = importlib.util.spec_from_file_location(
    "eql_xml_to_markdown", Path(__file__).parent / "xml-to-markdown.py"
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
process_function = _mod.process_function


def _strip_ticks(value):
    return value.strip("`").strip() if value else ""


def _int_or_none(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _to_entry(func):
    """Shape one extracted function into a manifest entry."""
    return {
        "name": func["name"],
        "signature": func["signature"],
        "visibility": "private" if func["is_private"] else "public",
        "brief": func["brief"],
        "description": func["detailed"],
        "params": func["params"],  # [{name, type, description}]
        "returns": {
            "type": _strip_ticks(func["return_type"]),
            "description": func["return_desc"],
        },
        "throws": func["exceptions"],
        "notes": func["notes"],
        "warnings": func["warnings"],
        "seeAlso": func["see_also"],
        "source": {"file": func["source"], "line": _int_or_none(func["line"])},
    }


# ── Encrypted domains ────────────────────────────────────────────────────────
# Doxygen does not extract CREATE DOMAIN, but the domain/variant matrix is the
# core of the EQL v3 surface. The generated `*_types.sql` (source of truth: the
# Rust catalog in crates/eql-domains) encodes each domain's capability
# STRUCTURALLY as the required CHECK keys, so we derive it directly:
#   hm = HMAC equality · ob = ORE order · op = OPE order · bf = bloom match ·
#   sv = STE-vec (JSON). v/i/c are the envelope, not index terms.
_ENVELOPE_KEYS = {"v", "i", "c", "k"}
_TERM_CAPABILITY = {
    "hm": "equality",
    "ob": "order",
    "op": "order",
    "bf": "match",
    "sv": "json",
}
# Term -> extractor function (from crates/eql-domains/src/term.rs).
_TERM_FUNCTION = {
    "hm": "eql_v3.hmac_256",
    "ob": "eql_v3.ore_block_256",
    "bf": "eql_v3.bloom_filter",
}
# Longest-first so `_ord_ore` wins over `_ord`.
_VARIANT_SUFFIXES = ("_ord_ore", "_ord_ope", "_ord", "_eq", "_match", "_search")

_DOMAIN_RE = re.compile(r"CREATE DOMAIN eql_v3\.([a-z0-9_]+)\s+AS\s+([a-z_]+)", re.I)
_KEY_RE = re.compile(r"VALUE \? '([a-z0-9]+)'")
_BRIEF_RE = re.compile(r"--!\s*@brief\s+(.*)")


def _build_domain(name, base, brief, terms, source_file, line):
    scalar_type, variant = name, ""
    for suffix in _VARIANT_SUFFIXES:
        if name.endswith(suffix):
            scalar_type, variant = name[: -len(suffix)], suffix[1:]
            break

    capabilities = []
    for term in terms:
        cap = _TERM_CAPABILITY.get(term)
        if cap and cap not in capabilities:
            capabilities.append(cap)
    if not capabilities:
        capabilities = ["storage"]

    return {
        "name": f"eql_v3.{name}",
        "type": scalar_type,
        "variant": variant,
        "base": base,
        "brief": brief,
        "terms": terms,
        "capabilities": capabilities,
        "termFunctions": [_TERM_FUNCTION[t] for t in terms if t in _TERM_FUNCTION],
        "source": {"file": str(source_file), "line": line},
    }


def parse_domains(src_dir: Path) -> list:
    """Extract eql_v3 CREATE DOMAIN definitions + their capability from the SQL."""
    if not src_dir.exists():
        print(f"Warning: SQL source dir not found: {src_dir}; skipping domains", file=sys.stderr)
        return []

    domains = []
    for sql_file in sorted(src_dir.rglob("*.sql")):
        lines = sql_file.read_text().splitlines()
        last_brief = ""
        for i, line in enumerate(lines):
            brief_match = _BRIEF_RE.search(line)
            if brief_match:
                last_brief = brief_match.group(1).strip()
            domain_match = _DOMAIN_RE.search(line)
            if not domain_match:
                continue
            name, base = domain_match.group(1), domain_match.group(2)
            # Collect CHECK keys until the block closes or the next domain begins.
            keys = []
            for follow in lines[i + 1:]:
                if _DOMAIN_RE.search(follow) or re.match(r"\s*\);", follow):
                    break
                keys.extend(_KEY_RE.findall(follow))
            terms = [k for k in dict.fromkeys(keys) if k not in _ENVELOPE_KEYS]
            domains.append(_build_domain(name, base, last_brief, terms, sql_file, i + 1))
            last_brief = ""

    domains.sort(key=lambda d: (d["type"], d["name"]))
    return domains


def build_manifest(xml_dir: Path, version: str, src_dir: Path = Path("src/v3")) -> dict:
    functions = []
    for xml_file in sorted(xml_dir.glob("*.xml")):
        if xml_file.name in ("index.xml", "Doxyfile.xml"):
            continue
        try:
            root = ET.parse(xml_file).getroot()
        except ET.ParseError as exc:
            print(f"Warning: failed to parse {xml_file.name}: {exc}", file=sys.stderr)
            continue
        for memberdef in root.findall('.//memberdef[@kind="function"]'):
            func = process_function(memberdef)
            if func:
                functions.append(func)

    functions.sort(key=lambda f: (f["is_private"], f["name"], f["signature"]))
    domains = parse_domains(src_dir)

    return {
        "$schema": "https://schemas.cipherstash.com/eql/manifest/v1.json",
        "name": "eql",
        "version": version,
        "generatedFrom": "doxygen-xml + sql-domains",
        "counts": {
            "functions": len(functions),
            "public": sum(1 for f in functions if not f["is_private"]),
            "private": sum(1 for f in functions if f["is_private"]),
            "domains": len(domains),
        },
        "functions": [_to_entry(f) for f in functions],
        "domains": domains,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: xml-to-json.py <xml_dir> [output_dir] [version] [sql_src_dir]")
        sys.exit(1)

    xml_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("docs/api/json")
    version = sys.argv[3] if len(sys.argv) > 3 else "DEV"
    src_dir = Path(sys.argv[4]) if len(sys.argv) > 4 else Path("src/v3")

    if not xml_dir.exists():
        print(f"Error: XML directory not found: {xml_dir}")
        sys.exit(1)

    manifest = build_manifest(xml_dir, version, src_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / "eql-manifest.json"
    output_file.write_text(json.dumps(manifest, indent=2) + "\n")

    counts = manifest["counts"]
    print(f"✓ Generated JSON manifest: {output_file}")
    print(
        f"  Functions: {counts['functions']} "
        f"({counts['public']} public, {counts['private']} private)"
    )
    print(f"  Domains: {counts['domains']}")


if __name__ == "__main__":
    main()
