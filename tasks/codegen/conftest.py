"""pytest discovery anchor for the codegen package.

Tests import via `from tasks.codegen.<module> import ...`; pytest runs
from the repo root (where `tasks/__init__.py` exists), so no `sys.path`
manipulation is needed.
"""
