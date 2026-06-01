# Codegen reference

The SQL files under `int4/` are the original, hand-written reference implementation for the encrypted-domain scalar generator. `int4` is the **single golden master**: the generator in `tasks/codegen/` is type-generic — its SQL templates are pure token substitution, and the only type-specific rendering is the `<T>_values.rs` const — so one anchored type detects all template/term drift for every current and future scalar.

`tasks/codegen/test_against_reference.py` renders the generator's output for `int4` and asserts it matches these files byte-for-byte. If the generator diverges, either it regressed (fix `tasks/codegen/`) or the reference is being updated deliberately (commit the new `int4` reference in the same PR).

## New scalar types do not add a reference

Adding a scalar type (`int2`, `int8`, …) does **not** add a `tests/codegen/reference/<T>/` directory. A per-type baseline would be redundant: the SQL is byte-identical to `int4` modulo the type token, so it can only fail when `int4`'s baseline already would. New types are guaranteed three other ways:

- the `int4` reference here anchors the shared generator (templates + `terms.py`);
- the committed `tests/sqlx/src/fixtures/<T>_values.rs` const is pinned by the CI staleness guard (`git diff --exit-code` after `mise run codegen:domain <T>`) and by the `<T>` cases in `tasks/codegen/test_scalars.py` (the only type-specific rendering, `i16::MIN` vs `i32::MIN`);
- the SQLx `ordered_numeric_matrix!` suite exercises the generated SQL's *behaviour* against a real database — a far stronger guarantee than a byte comparison.
