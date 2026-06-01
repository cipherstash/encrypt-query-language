# Codegen reference

The SQL files under `<T>/` are the original, hand-written reference implementation for each encrypted-domain scalar type.

They are the parity baseline for the generator in `tasks/codegen/`. `tasks/codegen/test_against_reference.py` renders the generator's output and asserts it matches these files byte-for-byte. If the generator diverges, either it regressed (fix `tasks/codegen/`) or the reference is being updated deliberately (commit the new reference in the same PR).
