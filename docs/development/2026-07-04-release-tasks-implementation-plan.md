# CI-native alpha releases (SQL surface + `eql-bindings` crate) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut alpha (prerelease) versions of the EQL SQL surface alone, the `eql-bindings` crate alone, or both in version lockstep, from a single `workflow_dispatch` GitHub Actions coordinator, driven by thin `mise run release:*` tasks that only trigger and watch CI. Alpha releases carry the same assets as finals: the two `.sql` files **and** the packaged docs bundle.

**Architecture:** A coordinator workflow (`release-alpha.yml`) does all orchestration server-side: it resolves the release identity across both tag namespaces, verifies drift gates, pins + commits the crate version, builds and attaches the SQL release **in-run** via a reusable `_build-sql.yml`, builds and attaches the docs bundle **in-run** via a reusable `_build-docs.yml`, then dispatches the crate publish by triggering `release-plz.yml` against the immutable SQL tag (so crates.io Trusted Publishing still matches `workflow_ref = release-plz.yml`). Thin mise tasks only `gh workflow run` the coordinator and watch the resulting run.

**Tech Stack:** GitHub Actions (`workflow_call` reusable workflows, `workflow_dispatch`), `gh` CLI, `mise` file-based tasks (auto-discovered from `tasks/`), `release-plz` CLI, doxygen, GPG-signed commits, crates.io OIDC Trusted Publishing.

## Global Constraints

These are the spec's **verified, load-bearing facts**. Every task's requirements implicitly include them; violating any is a plan failure.

- **SQL and docs must build in-run.** A coordinator running under the automatic `GITHUB_TOKEN` **cannot** rely on any `on: release`/`on: push` fan-out — `GITHUB_TOKEN`-created Releases and pushes do **not** trigger new workflow runs. The SQL build+attach *and* the docs build+attach therefore happen inside the coordinator's own run via reusable `workflow_call`s, never by firing `release-eql.yml`.
- **The crate must publish from `release-plz.yml` as its own dispatched entry point.** crates.io Trusted Publishing matches on `workflow_ref` = the entry-point workflow filename (verified opposite to PyPI). Publishing via a reusable `workflow_call` from `release-alpha.yml` would make the identity `release-alpha.yml` and fail the OIDC token exchange. **Do not move the crate publish into a reusable workflow.** The coordinator triggers the publish with `gh workflow run release-plz.yml --ref <ref>` (the `workflow_dispatch` exception means `GITHUB_TOKEN` *can* do this).
- **`target=all` same-commit `S` is achieved by dispatching the crate publish against the immutable SQL tag.** The crate version is pinned+committed at `S`, the SQL release targets `S`, docs are built at `S`, and the crate publish is dispatched against the *tag* `eql-<identity>` that points at `S` — so both tags land on `S` with no SHA guard and no race.
- **Ordering is SQL → docs → crate.** SQL and docs are reversible (a GitHub prerelease can be deleted); a crates.io publish is irreversible. The crate publish must be dispatched only **after** a *complete* release (SQL **and** docs) has been built and attached in-run.
- **Identity `<version>-<channel>.<N>` with `N = 1 + max(N across BOTH tag namespaces)`** — SQL `eql-<v>-<ch>.N` and crate `eql-bindings-v<v>-<ch>.N` — computed from freshly-fetched tags (`fetch-depth: 0`). Deriving across both namespaces for every target prevents version divergence.
- **`release-eql.yml` builds with the `eql-`-stripped identity** (`mise run build --version "${TAG#eql-}"`) so `eql_v3.version()` reports bare semver. Empty tag → bare `mise run build` DEV default. This behaviour is preserved by the reusable.
- **Blockers/prereleases only.** The coordinator cuts prereleases only. No final-release automation, no `verify-changelog` promotion, no `CHANGELOG.md` edits — alpha entries stay under `[Unreleased]`.
- **`release-plz` config is unchanged.** No TP / OIDC / GPG changes. `release-plz set-version eql-bindings@<identity>` is the only pin mechanism (no absolute-version config field exists).
- **Branch = dispatched ref.** Alphas are cut from `eql_v3` today; the workflow runs on the `--ref` of the dispatch. `main`-channel branch protection is out of scope (future).
- **mise tasks are auto-discovered** from the `tasks/` directory (verified: `release:preview` has no `[tasks]` entry in `mise.toml`). A new executable `tasks/release/<name>.sh` with `#MISE`/`#USAGE` headers auto-registers as `release:<name>`; deleting `tasks/release/preview.sh` removes `release:preview`.

---

## File Structure

| File | Responsibility | Action |
|------|----------------|--------|
| `.github/workflows/_build-sql.yml` | Reusable (`workflow_call`) SQL build + upload-artifact + attach/create-release + Multitudes notify. Single SQL-build code path. | Create (Task 1) |
| `.github/workflows/_build-docs.yml` | Reusable (`workflow_call`) docs generate + package + upload-artifact + attach `eql-docs-*` to an existing release. Single docs-build code path. | Create (Task 2) |
| `.github/workflows/release-eql.yml` | Finals path: `verify-changelog`, delegate SQL build to `_build-sql.yml`, delegate docs to `_build-docs.yml`. | Modify (Task 3) |
| `.github/workflows/release-plz.yml` | Crate publish entry point (unchanged) + `release-pr` job gated to `main`. | Modify (Task 4) |
| `.github/workflows/release-alpha.yml` | The coordinator: resolve → pin → build-sql → build-docs → crate-publish → summary. | Create (Task 5) |
| `tasks/release/all.sh`, `tasks/release/eql.sh`, `tasks/release/bindings.sh` | Thin mise triggers: dispatch coordinator + watch by `run-name`. | Create (Task 6) |
| `tasks/release/preview.sh` | Retired. | Delete (Task 6) |
| `docs/development/releasing-an-alpha.md`, `CLAUDE.md` | Runbook + reference updated to the task/dispatch flow. | Modify (Task 7) |

---

### Task 1: Reusable SQL build — `.github/workflows/_build-sql.yml`

**Files:**
- Create: `.github/workflows/_build-sql.yml`

**Interfaces:**
- Produces (the reusable's `workflow_call` inputs — later tasks call with exactly these):
  - `ref` (string, default `''`) — git ref/SHA to check out; empty → default `github.sha`.
  - `tag` (string, default `''`) — full release tag, e.g. `eql-3.0.0-alpha.2`. Drives the build version via `${TAG#eql-}`; empty → bare `mise run build` DEV default.
  - `attach` (boolean, default `false`) — attach the two `.sql` artefacts to a release.
  - `target_commitish` (string, default `''`) — when non-empty, **create** a prerelease at this commit; when empty, **attach to an existing** release named by `tag`.
  - `prerelease` (boolean, default `false`) — only consulted on the create path.
- Consumes: `secrets: inherit` from the caller (for `MULTITUDES_ACCESS_TOKEN`, referenced only on the `github.event_name == 'release'` path).

- [ ] **Step 1: Write the full reusable workflow file**

```yaml
name: "Build SQL (reusable)"

# Reusable SQL build+attach, extracted from release-eql.yml's build-and-publish
# job. Called INLINE by:
#   - release-alpha.yml (the coordinator) — SQL must build in-run because a
#     GITHUB_TOKEN-created Release does not fire release-eql.yml's `on: release`.
#   - release-eql.yml — for final (human-created) releases, whose `on: release`
#     DOES fire (human token). One SQL-build code path, no double build.

on:
  workflow_call:
    inputs:
      ref:
        description: "Git ref/SHA to build from. Empty -> default checkout (github.sha)."
        required: false
        type: string
        default: ""
      tag:
        description: "Full release tag (e.g. eql-3.0.0-alpha.2). Empty -> DEV build, no attach."
        required: false
        type: string
        default: ""
      attach:
        description: "Attach the built .sql artefacts to a GitHub Release."
        required: false
        type: boolean
        default: false
      target_commitish:
        description: "Non-empty -> CREATE a prerelease at this commit; empty -> attach to the existing release named by `tag`."
        required: false
        type: string
        default: ""
      prerelease:
        description: "Mark the created release as a prerelease (create path only)."
        required: false
        type: boolean
        default: false

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
  MISE_VERBOSE: "1"

defaults:
  run:
    shell: bash {0}

permissions:
  contents: write

jobs:
  build:
    runs-on: blacksmith-16vcpu-ubuntu-2204
    name: Build EQL
    timeout-minutes: 5

    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.ref }}

      - uses: jdx/mise-action@v3
        with:
          version: 2026.4.0
          install: true
          cache: true

      - name: Build EQL release
        # Strip the `eql-` tag prefix so eql_v3.version() reports bare semver
        # (e.g. "3.0.0-alpha.2"). Empty TAG -> ${TAG#eql-} is "" -> DEV default.
        env:
          TAG: ${{ inputs.tag }}
        run: |
          mise run build --version "${TAG#eql-}"

      - name: Upload EQL artifacts
        uses: actions/upload-artifact@v4
        with:
          name: eql-release
          path: |
            release/cipherstash-encrypt.sql
            release/cipherstash-encrypt-uninstall.sql

      # Finals path: the release already exists (human-created); just upload the
      # two artefacts. No prerelease flag is set, so the existing release's
      # prerelease state is preserved byte-for-byte with the old behaviour.
      - name: Attach artefacts to existing release
        if: ${{ inputs.attach && inputs.target_commitish == '' }}
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ inputs.tag }}
          files: |
            release/cipherstash-encrypt.sql
            release/cipherstash-encrypt-uninstall.sql

      # Coordinator path: no release exists yet — create the prerelease at the
      # exact commit `target_commitish` and attach the two artefacts.
      - name: Create prerelease at commit
        if: ${{ inputs.attach && inputs.target_commitish != '' }}
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ inputs.tag }}
          target_commitish: ${{ inputs.target_commitish }}
          prerelease: ${{ inputs.prerelease }}
          name: ${{ inputs.tag }}
          body: "Preview (prerelease) of the standalone eql_v3 surface. See [Unreleased] in CHANGELOG.md."
          files: |
            release/cipherstash-encrypt.sql
            release/cipherstash-encrypt-uninstall.sql

      # Preserved from the original build-and-publish job. Only fires for real
      # (human) release events; for the coordinator (workflow_dispatch) and PR
      # runs the guard is false, so the secret is never referenced there.
      - name: Notify Multitudes
        if: ${{ github.event_name == 'release' }}
        run: |
          curl --request POST \
            --fail-with-body \
            --url "https://api.developer.multitudes.co/deployments" \
            --header "Content-Type: application/json" \
            --header "Authorization: ${{ secrets.MULTITUDES_ACCESS_TOKEN }}" \
            --data '{"commitSha": "${{ github.sha }}", "environmentName":"production"}'
```

- [ ] **Step 2: Validate the workflow syntax**

Run: `actionlint .github/workflows/_build-sql.yml`
(If `actionlint` is not installed: `go install github.com/rhysd/actionlint/cmd/actionlint@latest`, or `brew install actionlint`, or download the release binary.)
Expected: no output (exit 0). A reusable workflow with only `on: workflow_call` passes.

- [ ] **Step 3: Sanity-check the YAML parses**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/_build-sql.yml'))" && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/_build-sql.yml
git commit -m "ci(release): add reusable _build-sql.yml (workflow_call SQL build+attach)"
```

---

### Task 2: Reusable docs build — `.github/workflows/_build-docs.yml`

**Files:**
- Create: `.github/workflows/_build-docs.yml`

**Context (from the real `release-eql.yml` `publish-docs` job, lines ~105–156):** it checks out, runs mise-action, installs doxygen (`sudo apt-get update && sudo apt-get install -y doxygen`), runs `mise run docs:generate` then `mise run docs:generate:markdown -- <tag>` (with `set -euo pipefail` so a generate failure fails fast), `mise run docs:package <tag>`, uploads `eql-docs-*.{zip,tar.gz}`, then attaches those files to the release. **The Multitudes-notify step lives in `build-and-publish`, NOT `publish-docs`** — so this reusable has no Multitudes step. The original attach step was gated `if: startsWith(github.ref, 'refs/tags/')`; that gate is **dropped** here because the coordinator's `github.ref` is a branch (not a tag), so gating on it would suppress the alpha docs attach. Attachment is instead gated on the passed `tag` being non-empty (matching the finals-on-PR "build but don't attach" behaviour, where `tag` is empty).

**Interfaces:**
- Produces (the reusable's `workflow_call` inputs — Tasks 3 and 5 call with exactly these):
  - `ref` (string, default `''`) — git ref/SHA to build docs from; empty → default `github.sha`.
  - `tag` (string, default `''`) — full release tag, e.g. `eql-3.0.0-alpha.2`. Passed to `docs:generate:markdown`/`docs:package` and names the release to attach to. Empty → build docs, do **not** attach (PR/dispatch parity with the original).

- [ ] **Step 1: Write the full reusable workflow file**

```yaml
name: "Build docs (reusable)"

# Reusable docs build+attach, extracted from release-eql.yml's publish-docs job.
# Called INLINE by:
#   - release-alpha.yml (the coordinator) — docs must build in-run for the same
#     reason as SQL: a GITHUB_TOKEN-created Release does not fire release-eql.yml.
#   - release-eql.yml — for final (human-created) releases.
# The release the docs attach to already exists: _build-sql.yml creates it for
# alphas; a human creates it for finals. So this reusable only ATTACHES.

on:
  workflow_call:
    inputs:
      ref:
        description: "Git ref/SHA to build docs from. Empty -> default checkout (github.sha)."
        required: false
        type: string
        default: ""
      tag:
        description: "Full release tag (e.g. eql-3.0.0-alpha.2). Passed to docs:generate:markdown / docs:package and names the release to attach to. Empty -> build only, no attach."
        required: false
        type: string
        default: ""

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
  MISE_VERBOSE: "1"

defaults:
  run:
    shell: bash {0}

permissions:
  contents: write

jobs:
  publish-docs:
    runs-on: blacksmith-16vcpu-ubuntu-2204
    name: Build and Publish Documentation
    timeout-minutes: 10

    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.ref }}

      - uses: jdx/mise-action@v3
        with:
          version: 2026.4.0
          install: true
          cache: true

      - name: Install Doxygen
        run: |
          sudo apt-get update
          sudo apt-get install -y doxygen

      - name: Generate documentation
        # Fail fast: the workflow default shell is `bash {0}` (no -e), so without
        # this a failure in docs:generate would be masked by the trailing
        # docs:generate:markdown command and only surface later in docs:package.
        env:
          TAG: ${{ inputs.tag }}
        run: |
          set -euo pipefail
          mise run docs:generate
          mise run docs:generate:markdown -- "${TAG}"

      - name: Package documentation
        env:
          TAG: ${{ inputs.tag }}
        run: |
          mise run docs:package "${TAG}"

      - name: Upload documentation artifacts
        uses: actions/upload-artifact@v4
        with:
          name: eql-docs
          path: |
            release/eql-docs-*.zip
            release/eql-docs-*.tar.gz

      # Attach only when a real release tag was passed. Empty tag (PR / bare
      # dispatch of release-eql.yml) builds docs without attaching, matching the
      # original `if: startsWith(github.ref,'refs/tags/')` behaviour without
      # relying on github.ref (which is a branch under the coordinator).
      - name: Publish documentation to release
        if: ${{ inputs.tag != '' }}
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ inputs.tag }}
          files: |
            release/eql-docs-*.zip
            release/eql-docs-*.tar.gz
```

- [ ] **Step 2: Validate the workflow syntax**

Run: `actionlint .github/workflows/_build-docs.yml`
Expected: no output (exit 0).

- [ ] **Step 3: Sanity-check the YAML parses**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/_build-docs.yml'))" && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/_build-docs.yml
git commit -m "ci(release): add reusable _build-docs.yml (workflow_call docs build+attach)"
```

---

### Task 3: Refactor `release-eql.yml` to call the reusables

**Files:**
- Modify: `.github/workflows/release-eql.yml` (replace the `build-and-publish` job's `steps` with a `uses:` call to `_build-sql.yml`; replace the `publish-docs` job's `steps` with a `uses:` call to `_build-docs.yml`; leave `verify-changelog` unchanged)

**Interfaces:**
- Consumes: `_build-sql.yml` inputs (Task 1: `ref`, `tag`, `attach`, `target_commitish`, `prerelease`) and `_build-docs.yml` inputs (Task 2: `ref`, `tag`).

- [ ] **Step 1: Replace the `build-and-publish` job body**

Replace the entire `build-and-publish:` job (currently a `runs-on`/`steps` job) with a reusable call. **Keep the exact `if:` guard.**

```yaml
  build-and-publish:
    name: Build EQL
    # `!startsWith(...'eql-bindings')` excludes the eql-bindings crate tags
    # (eql-bindings-v*) cut by release-plz, which are not SQL-surface releases.
    if: ${{ github.event_name != 'release' || (contains(github.event.release.tag_name, 'eql') && !startsWith(github.event.release.tag_name, 'eql-bindings')) }}
    permissions:
      contents: write
    secrets: inherit
    uses: ./.github/workflows/_build-sql.yml
    with:
      # Finals: build the checked-out release commit (default), attach to the
      # existing human-created release, never re-create it.
      ref: ""
      tag: ${{ github.event_name == 'release' && github.event.release.tag_name || '' }}
      attach: ${{ github.event_name == 'release' && startsWith(github.ref, 'refs/tags/') }}
      target_commitish: ""
      prerelease: false
```

- [ ] **Step 2: Replace the `publish-docs` job body**

Replace the entire `publish-docs:` job (currently a `runs-on`/`steps` job) with a reusable call. **Keep the exact `if:` guard.**

```yaml
  publish-docs:
    name: Build and Publish Documentation
    # `!startsWith(...'eql-bindings')` excludes the eql-bindings crate tags
    # (eql-bindings-v*) cut by release-plz, which are not SQL-surface releases.
    if: ${{ github.event_name != 'release' || (contains(github.event.release.tag_name, 'eql') && !startsWith(github.event.release.tag_name, 'eql-bindings')) }}
    permissions:
      contents: write
    uses: ./.github/workflows/_build-docs.yml
    with:
      # Finals: build docs at the release commit (default checkout), attach to
      # the existing human-created release. Empty tag on PR -> build, no attach.
      ref: ""
      tag: ${{ github.event_name == 'release' && github.event.release.tag_name || '' }}
```

Keep the `verify-changelog` job exactly as-is. **Keep the top-level `on`, `env`, `defaults`, and `permissions` unchanged** (the reusable jobs still run under them).

- [ ] **Step 3: Confirm no behaviour change for finals (read-through)**

Verify by inspection:
- A `release: published` event with an `eql-…` (non-`eql-bindings`) tag →
  - `build-and-publish` calls `_build-sql.yml` with `tag = tag_name`, `attach = true`, `target_commitish = ""` → **"Attach artefacts to existing release"** step → same two `.sql` files on the same release, prerelease flag untouched, Multitudes fires. Identical.
  - `publish-docs` calls `_build-docs.yml` with `ref = ""` (checkout the release commit = `github.sha`), `tag = tag_name` → builds docs at the release commit and attaches `eql-docs-*` to the existing release. Identical to the old job (which attached because `github.ref` was `refs/tags/…`).
- A `pull_request` run (workflow file changed) → both jobs run with `tag = ''` → build only, no attach (docs build, `if: inputs.tag != ''` false). Identical to before.

- [ ] **Step 4: Validate**

Run: `actionlint .github/workflows/release-eql.yml && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-eql.yml'))" && echo OK`
Expected: `OK`, no actionlint errors. (actionlint resolves both local `uses:` calls and checks `with:` inputs against Tasks 1 and 2 — a typo'd input name fails here.)

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/release-eql.yml
git commit -m "ci(release): route release-eql.yml SQL + docs builds through reusables"
```

---

### Task 4: Gate `release-plz.yml`'s `release-pr` job to `main`

**Files:**
- Modify: `.github/workflows/release-plz.yml` (add one `if:` to the `release-pr` job)

**Interfaces:**
- Produces: a `release-plz.yml` whose `release` job still publishes on any ref (branch-agnostic), but whose `release-pr` job runs **only** on `refs/heads/main`. The coordinator dispatches this workflow against a **tag**, so `release-pr` is skipped → no stray release PR.

- [ ] **Step 1: Add the `if:` guard to `release-pr`**

In the `release-pr:` job, add an `if:` as the first key after `name:`:

```yaml
  release-pr:
    name: "Release PR"
    # Only open/refresh the release PR on push-to-main. A workflow_dispatch
    # against a tag (the coordinator's crate-publish path) or a feature branch
    # must publish WITHOUT opening a stray recursive release PR.
    if: github.ref == 'refs/heads/main'
    runs-on: blacksmith-16vcpu-ubuntu-2204
    needs: release
    steps:
      # ... unchanged ...
```

Leave the `release:` job, `concurrency`, `permissions`, `on`, and everything else unchanged.

- [ ] **Step 2: Verify the gate logic (read-through)**

- Push to `main` → `github.ref == 'refs/heads/main'` → `release-pr` runs (unchanged).
- Coordinator `gh workflow run release-plz.yml --ref eql-3.0.0-alpha.2` → ref is `refs/tags/…` → `release-pr` **skipped**; `release` still runs, checks out the tag, publishes.
- Manual `workflow_dispatch` on `main` → ref is `refs/heads/main` → `release-pr` runs.

- [ ] **Step 3: Validate**

Run: `actionlint .github/workflows/release-plz.yml && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-plz.yml'))" && echo OK`
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release-plz.yml
git commit -m "ci(release): gate release-plz release-pr job to refs/heads/main"
```

---

### Task 5: The coordinator — `.github/workflows/release-alpha.yml`

**Files:**
- Create: `.github/workflows/release-alpha.yml`

**Interfaces:**
- Consumes: `_build-sql.yml` (Task 1) and `_build-docs.yml` (Task 2) via `workflow_call`; `release-plz.yml` (Task 4) via `gh workflow run` (the crate publish entry point).
- Produces (relied on by Task 6's mise tasks): `workflow_dispatch` inputs `target` / `version` / `channel` / `pre` / `dry_run`; a `run-name` that embeds `<target>` and the resolved-or-partial identity so the mise task can find the exact run; `concurrency: { group: release-alpha }`.

**Job graph:**

```
resolve ──> pin ──> build-sql ──> build-docs ──> crate-publish ──> summary
   │         │          │             │              │
   └─────────┴──────────┴─────────────┴──────────────┘  (each gated by target + dry_run)
```

- `resolve` — always. Derive identity across both namespaces (or accept `pre`); target-specific existence/invariant guards; run drift gates `types:check` + `codegen:parity`. On `dry_run`, print the plan and stop.
- `pin` — `all`/`bindings` only, non-dry: `release-plz set-version`, GPG-signed commit staging crate files, push → commit `S`.
- `build-sql` — `all`/`eql` only, non-dry: reusable call. For `all`, checks out `S` and creates the prerelease at `S`; for `eql`, at branch `github.sha`.
- `build-docs` — `all`/`eql` only, non-dry, **after** `build-sql` (the release must exist to attach docs): reusable call at the same commit `build-sql` used, attaching `eql-docs-*` to the SQL release.
- `crate-publish` — `all`/`bindings` only, non-dry, **after** `build-sql` **and** `build-docs` for `all`: `gh workflow run release-plz.yml --ref <tag|branch>`. A docs failure aborts before the crate ships.
- `summary` — always: link the coordinator run and the dispatched `release-plz.yml` run.

- [ ] **Step 1: Write the coordinator header, inputs, permissions, concurrency, run-name**

```yaml
name: "Release alpha (coordinator)"

# CI-native prerelease coordinator for the two EQL artefacts (SQL surface +
# eql-bindings crate). Alphas ship the same assets as finals: two .sql files
# AND the packaged docs bundle. Runs on the DISPATCHED REF. See
# docs/development/2026-07-04-release-tasks-design.md for the full rationale.

on:
  workflow_dispatch:
    inputs:
      target:
        description: "all | eql | bindings"
        required: true
        type: choice
        options: [all, eql, bindings]
        default: all
      version:
        description: "Base SemVer, e.g. 3.0.0"
        required: false
        type: string
        default: "3.0.0"
      channel:
        description: "alpha | beta | rc"
        required: false
        type: choice
        options: [alpha, beta, rc]
        default: alpha
      pre:
        description: "Exact identity (e.g. 3.0.0-alpha.2), bypassing N derivation"
        required: false
        type: string
        default: ""
      dry_run:
        description: "Resolve + verify + print plan; mutate nothing"
        required: false
        type: boolean
        default: false

# The mise task finds THIS run by the identity + target in run-name (never -L1).
# When `pre` is given the identity is exact; otherwise N is derived server-side,
# so run-name carries version-channel (+ target), and the watcher disambiguates
# by createdAt recency.
run-name: >-
  release-alpha ${{ inputs.target }} ${{ inputs.pre != '' && inputs.pre || format('{0}-{1}', inputs.version, inputs.channel) }}${{ inputs.dry_run && ' [dry-run]' || '' }}

permissions:
  contents: write   # pin push + prerelease creation + docs/sql attach
  actions: write    # gh workflow run release-plz.yml (dispatch)

concurrency:
  # Serialise coordinator runs. The crate publish is separately serialised by
  # release-plz.yml's own `release-plz` group. Never cancel a release mid-flight.
  group: release-alpha
  cancel-in-progress: false

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
  MISE_VERBOSE: "1"

defaults:
  run:
    shell: bash {0}
```

- [ ] **Step 2: Write the `resolve` job**

```yaml
jobs:
  resolve:
    name: Resolve identity + verify
    runs-on: blacksmith-16vcpu-ubuntu-2204
    timeout-minutes: 15
    outputs:
      identity: ${{ steps.derive.outputs.identity }}
      sql_tag: ${{ steps.derive.outputs.sql_tag }}
      crate_tag: ${{ steps.derive.outputs.crate_tag }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch all tags
        run: git fetch --tags --force

      - name: Validate inputs
        env:
          CHANNEL: ${{ inputs.channel }}
          TARGET: ${{ inputs.target }}
        run: |
          set -euo pipefail
          case "$CHANNEL" in alpha|beta|rc) ;; *) echo "::error::invalid channel '$CHANNEL'"; exit 1 ;; esac
          case "$TARGET" in all|eql|bindings) ;; *) echo "::error::invalid target '$TARGET'"; exit 1 ;; esac

      - name: Derive identity + guards
        id: derive
        env:
          TARGET: ${{ inputs.target }}
          VERSION: ${{ inputs.version }}
          CHANNEL: ${{ inputs.channel }}
          PRE: ${{ inputs.pre }}
        run: |
          set -euo pipefail

          sql_prefix="eql-${VERSION}-${CHANNEL}."
          crate_prefix="eql-bindings-v${VERSION}-${CHANNEL}."

          # Highest N under a tag prefix, or empty. `.` in the prefix is escaped
          # so it can't match arbitrary characters in the sed pattern.
          highest() {
            local prefix="$1" esc
            esc="${prefix//./\\.}"
            git tag --list "${prefix}*" \
              | sed -n "s/^${esc}\([0-9]\{1,\}\)$/\1/p" \
              | sort -n | tail -1
          }

          if [[ -n "$PRE" ]]; then
            identity="$PRE"
          else
            case "$TARGET" in
              all|eql)
                sql_n=$(highest "$sql_prefix");   sql_n=${sql_n:-0}
                crate_n=$(highest "$crate_prefix"); crate_n=${crate_n:-0}
                if (( sql_n >= crate_n )); then n=$(( sql_n + 1 )); else n=$(( crate_n + 1 )); fi
                identity="${VERSION}-${CHANNEL}.${n}"
                ;;
              bindings)
                # Default: the latest SQL alpha lacking a crate counterpart.
                esc="${sql_prefix//./\\.}"
                found=""
                for n in $(git tag --list "${sql_prefix}*" | sed -n "s/^${esc}\([0-9]\{1,\}\)$/\1/p" | sort -rn); do
                  if ! git rev-parse -q --verify "refs/tags/${crate_prefix}${n}" >/dev/null; then
                    found="$n"; break
                  fi
                done
                if [[ -z "$found" ]]; then
                  echo "::error::no ${sql_prefix}N SQL release is awaiting a crate publish (nothing to do for target=bindings)"; exit 1
                fi
                identity="${VERSION}-${CHANNEL}.${found}"
                ;;
            esac
          fi

          sql_tag="eql-${identity}"
          crate_tag="eql-bindings-v${identity}"

          # Target-specific guards.
          case "$TARGET" in
            all)
              if git rev-parse -q --verify "refs/tags/${sql_tag}"   >/dev/null; then echo "::error::${sql_tag} already exists";   exit 1; fi
              if git rev-parse -q --verify "refs/tags/${crate_tag}" >/dev/null; then echo "::error::${crate_tag} already exists"; exit 1; fi
              ;;
            eql)
              if git rev-parse -q --verify "refs/tags/${sql_tag}" >/dev/null; then echo "::error::${sql_tag} already exists"; exit 1; fi
              ;;
            bindings)
              # Lockstep invariant: a crate version never ships without a
              # matching SQL release of the SAME version.
              if ! git rev-parse -q --verify "refs/tags/${sql_tag}" >/dev/null; then
                echo "::error::${sql_tag} SQL release must exist before publishing the crate (lockstep invariant)"; exit 1
              fi
              if git rev-parse -q --verify "refs/tags/${crate_tag}" >/dev/null; then echo "::error::${crate_tag} already exists"; exit 1; fi
              ;;
          esac

          echo "identity=${identity}"   >> "$GITHUB_OUTPUT"
          echo "sql_tag=${sql_tag}"     >> "$GITHUB_OUTPUT"
          echo "crate_tag=${crate_tag}" >> "$GITHUB_OUTPUT"

      - uses: jdx/mise-action@v3
        with:
          version: 2026.4.0
          install: true
          cache: true

      - name: Verify drift gates (types:check + codegen:parity)
        # Both are DB-free: they regenerate the committed bindings / SQL surface
        # and `git diff` against the checkout. A drift here means the shipped
        # src/v3 would not match the catalog — abort before any mutation.
        run: |
          set -euo pipefail
          mise run types:check
          mise run codegen:parity

      - name: Print plan
        env:
          TARGET: ${{ inputs.target }}
          DRY: ${{ inputs.dry_run }}
        run: |
          set -euo pipefail
          {
            echo "## Release plan"
            echo ""
            echo "| field | value |"
            echo "|---|---|"
            echo "| target | ${TARGET} |"
            echo "| identity | ${{ steps.derive.outputs.identity }} |"
            echo "| sql_tag | ${{ steps.derive.outputs.sql_tag }} |"
            echo "| crate_tag | ${{ steps.derive.outputs.crate_tag }} |"
            echo "| ref | ${{ github.ref_name }} @ ${{ github.sha }} |"
            echo "| dry_run | ${DRY} |"
          } >> "$GITHUB_STEP_SUMMARY"
```

Notes on `set -e` safety: every guard uses `if <cmd>; then …; fi` (not `<cmd> && { fail; }`), so a `git rev-parse` returning non-zero does not abort the script.

- [ ] **Step 3: Write the `pin` job**

```yaml
  pin:
    name: Pin crate version (commit S)
    runs-on: blacksmith-16vcpu-ubuntu-2204
    needs: resolve
    if: ${{ !inputs.dry_run && (inputs.target == 'all' || inputs.target == 'bindings') }}
    timeout-minutes: 15
    outputs:
      commit_sha: ${{ steps.commit.outputs.commit_sha }}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.ref_name }}   # the dispatched branch; push target
          fetch-depth: 0

      - name: Import GPG key
        uses: crazy-max/ghaction-import-gpg@v7
        with:
          gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
          git_user_signingkey: true
          git_commit_gpgsign: true

      - uses: jdx/mise-action@v3
        with:
          version: 2026.4.0
          install: true
          cache: true

      - name: Install release-plz CLI
        # cargo-binstall is a mise tool (fast prebuilt fetch, no source build).
        run: cargo binstall --no-confirm release-plz

      - name: Pin + commit + push (commit S)
        id: commit
        env:
          IDENTITY: ${{ needs.resolve.outputs.identity }}
          BRANCH: ${{ github.ref_name }}
        run: |
          set -euo pipefail
          release-plz set-version "eql-bindings@${IDENTITY}"
          git add crates/eql-bindings/Cargo.toml crates/eql-bindings/CHANGELOG.md Cargo.lock
          git commit -S -m "chore(release): pin eql-bindings to ${IDENTITY}"
          git push origin "HEAD:${BRANCH}"
          echo "commit_sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
```

- [ ] **Step 4: Write the `build-sql` reusable-call job**

```yaml
  build-sql:
    name: Build + release SQL (in-run)
    needs: [resolve, pin]
    # all/eql only, non-dry. For `all`, pin must have succeeded; for `eql`, pin
    # is skipped (SQL without a crate is allowed).
    if: >-
      ${{ !cancelled() && !inputs.dry_run
          && (inputs.target == 'all' || inputs.target == 'eql')
          && needs.resolve.result == 'success'
          && (needs.pin.result == 'success' || needs.pin.result == 'skipped') }}
    permissions:
      contents: write
    secrets: inherit
    uses: ./.github/workflows/_build-sql.yml
    with:
      # all: build + release AT commit S (the pin commit). eql: at branch HEAD.
      ref:              ${{ inputs.target == 'all' && needs.pin.outputs.commit_sha || '' }}
      tag:              ${{ needs.resolve.outputs.sql_tag }}
      attach:           true
      target_commitish: ${{ inputs.target == 'all' && needs.pin.outputs.commit_sha || github.sha }}
      prerelease:       true
```

- [ ] **Step 5: Write the `build-docs` reusable-call job**

```yaml
  build-docs:
    name: Build + attach docs (in-run)
    needs: [resolve, pin, build-sql]
    # all/eql only, non-dry. build-sql must have SUCCEEDED first: the docs attach
    # to the SQL release, which build-sql creates. A docs failure here blocks the
    # (irreversible) crate publish downstream.
    if: >-
      ${{ !cancelled() && !inputs.dry_run
          && (inputs.target == 'all' || inputs.target == 'eql')
          && needs.build-sql.result == 'success' }}
    permissions:
      contents: write
    uses: ./.github/workflows/_build-docs.yml
    with:
      # Same commit build-sql used: pin commit S for `all`, branch HEAD for `eql`.
      ref: ${{ inputs.target == 'all' && needs.pin.outputs.commit_sha || github.sha }}
      tag: ${{ needs.resolve.outputs.sql_tag }}
```

- [ ] **Step 6: Write the `crate-publish` job**

```yaml
  crate-publish:
    name: Dispatch crate publish (release-plz.yml)
    runs-on: blacksmith-16vcpu-ubuntu-2204
    needs: [resolve, pin, build-sql, build-docs]
    # all/bindings only, non-dry. For `all`, a COMPLETE release (SQL + docs) must
    # exist first — build-sql AND build-docs must have succeeded — before the
    # irreversible crate publish. For `bindings`, build-sql/build-docs are skipped
    # (the SQL release + its docs already exist from an earlier target=eql/all run).
    if: >-
      ${{ !cancelled() && !inputs.dry_run
          && (inputs.target == 'all' || inputs.target == 'bindings')
          && needs.pin.result == 'success'
          && (needs.build-sql.result == 'success' || needs.build-sql.result == 'skipped')
          && (needs.build-docs.result == 'success' || needs.build-docs.result == 'skipped') }}
    timeout-minutes: 10
    steps:
      - name: Dispatch release-plz.yml against the pinned commit
        # crates.io Trusted Publishing matches workflow_ref = release-plz.yml, so
        # the crate MUST publish from release-plz.yml as its own entry point.
        # `workflow_dispatch` is the GITHUB_TOKEN suppression exception, so this
        # actually starts a run. For `all` we dispatch against the immutable SQL
        # tag (== commit S); for `bindings` against the branch (head == pin S).
        env:
          GH_TOKEN: ${{ github.token }}
          SQL_TAG: ${{ needs.resolve.outputs.sql_tag }}
          BRANCH: ${{ github.ref_name }}
          TARGET: ${{ inputs.target }}
        run: |
          set -euo pipefail
          if [[ "$TARGET" == "all" ]]; then
            ref="$SQL_TAG"
          else
            ref="$BRANCH"
          fi
          echo "Dispatching release-plz.yml --ref ${ref}"
          gh workflow run release-plz.yml --ref "$ref"
          {
            echo "## Crate publish dispatched"
            echo ""
            echo "Dispatched \`release-plz.yml\` against \`${ref}\`."
            echo "Watch it separately: it runs as its own entry point (TP matches)."
          } >> "$GITHUB_STEP_SUMMARY"
```

- [ ] **Step 7: Write the `summary` job**

```yaml
  summary:
    name: Summary
    runs-on: blacksmith-16vcpu-ubuntu-2204
    needs: [resolve, pin, build-sql, build-docs, crate-publish]
    if: always()
    steps:
      - name: Emit run summary
        env:
          TARGET: ${{ inputs.target }}
          DRY: ${{ inputs.dry_run }}
        run: |
          set -euo pipefail
          {
            echo "## release-alpha result"
            echo ""
            echo "- target: \`${TARGET}\` (dry_run=${DRY})"
            echo "- identity: \`${{ needs.resolve.outputs.identity }}\`"
            echo "- sql_tag: \`${{ needs.resolve.outputs.sql_tag }}\`"
            echo "- crate_tag: \`${{ needs.resolve.outputs.crate_tag }}\`"
            echo "- resolve: ${{ needs.resolve.result }} | pin: ${{ needs.pin.result }} | build-sql: ${{ needs.build-sql.result }} | build-docs: ${{ needs.build-docs.result }} | crate-publish: ${{ needs.crate-publish.result }}"
            echo ""
            echo "Coordinator run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            echo "The crate publish (if dispatched) runs as a SEPARATE release-plz.yml run — watch it in the Actions tab."
          } >> "$GITHUB_STEP_SUMMARY"
```

- [ ] **Step 8: Validate the coordinator**

Run: `actionlint .github/workflows/release-alpha.yml && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-alpha.yml'))" && echo OK`
Expected: `OK`. actionlint checks: the `uses: ./.github/workflows/_build-sql.yml` and `_build-docs.yml` inputs match Tasks 1 & 2; `needs` references exist; expression syntax valid.

- [ ] **Step 9: Commit**

```bash
git add .github/workflows/release-alpha.yml
git commit -m "ci(release): add release-alpha.yml coordinator (SQL + docs in-run, then crate)"
```

---

### Task 6: Thin mise triggers + retire `preview.sh`

**Files:**
- Create: `tasks/release/all.sh`, `tasks/release/eql.sh`, `tasks/release/bindings.sh` (auto-register as `release:all` / `release:eql` / `release:bindings`)
- Delete: `tasks/release/preview.sh` (retires `release:preview`)

**Interfaces:**
- Consumes: `release-alpha.yml` inputs (Task 5): `target`, `version`, `channel`, `pre`, `dry_run`; and the `run-name` shape `release-alpha <target> <pre|version-channel> …`.
- Each task forwards `--version`/`--channel`/`--pre`/`--dry-run` and watches the run it started by matching the `run-name` (never `gh run list -L1`).

Design note — the three scripts are intentionally near-identical (only `target=` differs), so the dispatch+watch logic is inlined in each rather than sourced from a shared helper. mise auto-discovers **every** file under `tasks/`, so a sourced `tasks/release/_lib.sh` would register as a phantom `release:_lib` task; inlining ~30 thin lines avoids that. This matches the existing self-contained `preview.sh` pattern.

- [ ] **Step 1: Write `tasks/release/all.sh`**

```bash
#!/usr/bin/env bash
#MISE description="Cut an alpha of BOTH artefacts in lockstep: dispatch release-alpha.yml (target=all) and watch the run"
#USAGE flag "--version <version>" help="Base SemVer, e.g. 3.0.0" default="3.0.0"
#USAGE flag "--channel <channel>" help="Preview channel: alpha | beta | rc" default="alpha"
#USAGE flag "--pre <pre>" help="Exact identity (e.g. 3.0.0-alpha.2), bypassing N derivation" default=""
#USAGE flag "--ref <ref>" help="Git ref to dispatch against" default=""
#USAGE flag "--dry-run" help="Resolve + verify + print plan; mutate nothing"

set -euo pipefail

# Thin trigger: this does NOTHING release-relevant locally. It dispatches the
# CI-native coordinator (.github/workflows/release-alpha.yml) with target=all
# and watches THAT run. Same-commit lockstep + all safety live in CI.

target="all"
version="${usage_version:-3.0.0}"
channel="${usage_channel:-alpha}"
pre="${usage_pre:-}"
ref="${usage_ref:-}"
dry_run="${usage_dry_run:-false}"

err() { echo "error: $*" >&2; exit 1; }

case "$channel" in alpha|beta|rc) ;; *) err "invalid --channel '$channel' (expected: alpha | beta | rc)" ;; esac
command -v gh >/dev/null 2>&1 || err "gh CLI not found (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || err "gh is not authenticated; run 'gh auth login'"

[[ -n "$ref" ]] || ref="$(git rev-parse --abbrev-ref HEAD)"

# Correlation string that MUST appear in the coordinator's run-name (see
# release-alpha.yml). When --pre is given the identity is exact; otherwise the
# coordinator derives N server-side, so we correlate on version-channel + target
# and pick the newest matching run created after dispatch.
correlation="${pre:-${version}-${channel}}"

dispatched_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "==> Dispatching release-alpha.yml (target=${target}) on ref ${ref}"
gh workflow run release-alpha.yml --ref "$ref" \
  -f target="$target" \
  -f version="$version" \
  -f channel="$channel" \
  ${pre:+-f pre="$pre"} \
  $([[ "$dry_run" == "true" ]] && printf -- '-f dry_run=true')

echo "==> Locating the dispatched run (by run-name '${target} ${correlation}', not -L1)"
run_id=""
for _ in $(seq 1 30); do
  run_id=$(gh run list --workflow release-alpha.yml --event workflow_dispatch \
    --json databaseId,displayTitle,createdAt \
    --jq "[.[] | select(.createdAt >= \"${dispatched_at}\") | select(.displayTitle | contains(\"${target} ${correlation}\"))] | sort_by(.createdAt) | last | .databaseId")
  [[ -n "$run_id" && "$run_id" != "null" ]] && break
  sleep 2
done
[[ -n "$run_id" && "$run_id" != "null" ]] || err "could not find the dispatched release-alpha run"

echo "==> Watching run ${run_id}"
gh run watch "$run_id" --exit-status
echo "==> Coordinator run finished. For target=all, the crate publish runs as a SEPARATE release-plz.yml run — watch it in the Actions tab."
```

- [ ] **Step 2: Write `tasks/release/eql.sh`**

Identical to `all.sh` except the `#MISE description`, `target`, and the trailing note. Full file:

```bash
#!/usr/bin/env bash
#MISE description="Cut an alpha of the SQL surface + docs only: dispatch release-alpha.yml (target=eql) and watch the run"
#USAGE flag "--version <version>" help="Base SemVer, e.g. 3.0.0" default="3.0.0"
#USAGE flag "--channel <channel>" help="Preview channel: alpha | beta | rc" default="alpha"
#USAGE flag "--pre <pre>" help="Exact identity (e.g. 3.0.0-alpha.2), bypassing N derivation" default=""
#USAGE flag "--ref <ref>" help="Git ref to dispatch against" default=""
#USAGE flag "--dry-run" help="Resolve + verify + print plan; mutate nothing"

set -euo pipefail

target="eql"
version="${usage_version:-3.0.0}"
channel="${usage_channel:-alpha}"
pre="${usage_pre:-}"
ref="${usage_ref:-}"
dry_run="${usage_dry_run:-false}"

err() { echo "error: $*" >&2; exit 1; }

case "$channel" in alpha|beta|rc) ;; *) err "invalid --channel '$channel' (expected: alpha | beta | rc)" ;; esac
command -v gh >/dev/null 2>&1 || err "gh CLI not found (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || err "gh is not authenticated; run 'gh auth login'"

[[ -n "$ref" ]] || ref="$(git rev-parse --abbrev-ref HEAD)"
correlation="${pre:-${version}-${channel}}"

dispatched_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "==> Dispatching release-alpha.yml (target=${target}) on ref ${ref}"
gh workflow run release-alpha.yml --ref "$ref" \
  -f target="$target" \
  -f version="$version" \
  -f channel="$channel" \
  ${pre:+-f pre="$pre"} \
  $([[ "$dry_run" == "true" ]] && printf -- '-f dry_run=true')

echo "==> Locating the dispatched run (by run-name '${target} ${correlation}', not -L1)"
run_id=""
for _ in $(seq 1 30); do
  run_id=$(gh run list --workflow release-alpha.yml --event workflow_dispatch \
    --json databaseId,displayTitle,createdAt \
    --jq "[.[] | select(.createdAt >= \"${dispatched_at}\") | select(.displayTitle | contains(\"${target} ${correlation}\"))] | sort_by(.createdAt) | last | .databaseId")
  [[ -n "$run_id" && "$run_id" != "null" ]] && break
  sleep 2
done
[[ -n "$run_id" && "$run_id" != "null" ]] || err "could not find the dispatched release-alpha run"

echo "==> Watching run ${run_id}"
gh run watch "$run_id" --exit-status
echo "==> Done. SQL prerelease + docs cut; no crate published (target=eql)."
```

- [ ] **Step 3: Write `tasks/release/bindings.sh`**

Identical to `eql.sh` except `#MISE description`, `target="bindings"`, and the trailing note. Full file:

```bash
#!/usr/bin/env bash
#MISE description="Publish the eql-bindings crate for an EXISTING SQL alpha: dispatch release-alpha.yml (target=bindings) and watch the run"
#USAGE flag "--version <version>" help="Base SemVer, e.g. 3.0.0" default="3.0.0"
#USAGE flag "--channel <channel>" help="Preview channel: alpha | beta | rc" default="alpha"
#USAGE flag "--pre <pre>" help="Exact identity (e.g. 3.0.0-alpha.2), bypassing N derivation" default=""
#USAGE flag "--ref <ref>" help="Git ref to dispatch against" default=""
#USAGE flag "--dry-run" help="Resolve + verify + print plan; mutate nothing"

set -euo pipefail

# target=bindings requires a matching eql-<identity> SQL release (which already
# carries its docs) to already exist — the lockstep invariant, enforced
# server-side in release-alpha.yml.

target="bindings"
version="${usage_version:-3.0.0}"
channel="${usage_channel:-alpha}"
pre="${usage_pre:-}"
ref="${usage_ref:-}"
dry_run="${usage_dry_run:-false}"

err() { echo "error: $*" >&2; exit 1; }

case "$channel" in alpha|beta|rc) ;; *) err "invalid --channel '$channel' (expected: alpha | beta | rc)" ;; esac
command -v gh >/dev/null 2>&1 || err "gh CLI not found (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || err "gh is not authenticated; run 'gh auth login'"

[[ -n "$ref" ]] || ref="$(git rev-parse --abbrev-ref HEAD)"
correlation="${pre:-${version}-${channel}}"

dispatched_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "==> Dispatching release-alpha.yml (target=${target}) on ref ${ref}"
gh workflow run release-alpha.yml --ref "$ref" \
  -f target="$target" \
  -f version="$version" \
  -f channel="$channel" \
  ${pre:+-f pre="$pre"} \
  $([[ "$dry_run" == "true" ]] && printf -- '-f dry_run=true')

echo "==> Locating the dispatched run (by run-name '${target} ${correlation}', not -L1)"
run_id=""
for _ in $(seq 1 30); do
  run_id=$(gh run list --workflow release-alpha.yml --event workflow_dispatch \
    --json databaseId,displayTitle,createdAt \
    --jq "[.[] | select(.createdAt >= \"${dispatched_at}\") | select(.displayTitle | contains(\"${target} ${correlation}\"))] | sort_by(.createdAt) | last | .databaseId")
  [[ -n "$run_id" && "$run_id" != "null" ]] && break
  sleep 2
done
[[ -n "$run_id" && "$run_id" != "null" ]] || err "could not find the dispatched release-alpha run"

echo "==> Watching run ${run_id}"
gh run watch "$run_id" --exit-status
echo "==> Coordinator finished. The crate publish runs as a SEPARATE release-plz.yml run — watch it in the Actions tab."
```

- [ ] **Step 4: Make the scripts executable and delete `preview.sh`**

```bash
chmod +x tasks/release/all.sh tasks/release/eql.sh tasks/release/bindings.sh
git rm tasks/release/preview.sh
```

- [ ] **Step 5: Verify mise task registration**

Run: `mise tasks ls | grep -E '^release:'`
Expected: `release:all`, `release:bindings`, `release:eql` present; `release:preview` **absent**.

- [ ] **Step 6: Lint the scripts**

Run: `shellcheck tasks/release/all.sh tasks/release/eql.sh tasks/release/bindings.sh`
Expected: no errors. (If `shellcheck` is unavailable, `bash -n tasks/release/*.sh` at minimum — expected: no syntax errors.)

- [ ] **Step 7: Commit**

```bash
git add tasks/release/all.sh tasks/release/eql.sh tasks/release/bindings.sh
git commit -m "ci(release): add thin release:{all,eql,bindings} mise triggers; retire release:preview"
```

---

### Task 7: Documentation updates

**Files:**
- Modify: `docs/development/releasing-an-alpha.md` (replace the manual/`release:preview` runbook with the task/dispatch flow)
- Modify: `CLAUDE.md` (swap `release:preview` → the three new tasks; note they trigger `release-alpha.yml`)
- Grep-and-fix any remaining stray `release:preview` references

- [ ] **Step 1: Rewrite `docs/development/releasing-an-alpha.md`**

Replace the "Scripted path (recommended)", "Steps (manual equivalent)", and "Releasing `eql-bindings` in lockstep" sections with the CI-native flow. Key content to include (keep the "What ships", "Why a prerelease is different", "Smoke-test", and "Promoting to a final release" sections, updated where they mention `release:preview`):

- **What ships (unchanged for alphas):** the two `.sql` files **and** the packaged docs bundle (`eql-docs-*.zip`/`.tar.gz`) — the coordinator builds both in-run, so a coordinator-cut alpha carries the same assets as a final release.
- **The three tasks** and what each dispatches:
  - `mise run release:all` → coordinator `target=all`: pins the crate to `<identity>`, commits+pushes (commit `S`), builds+attaches the SQL prerelease at `S`, builds+attaches docs at `S`, then dispatches `release-plz.yml` against the `eql-<identity>` tag to publish the crate at `S`. Both tags land on `S`.
  - `mise run release:eql` → `target=eql`: SQL prerelease + docs only (no crate). SQL-without-crate is allowed.
  - `mise run release:bindings` → `target=bindings`: publishes the crate for an **already-existing** `eql-<identity>` SQL release (which already carries its docs); fails if none exists.
- **Flags**: `--version` (default `3.0.0`), `--channel` (`alpha`|`beta`|`rc`), `--pre` (exact identity, bypass `N`), `--ref` (default current branch), `--dry-run` (resolve+verify+print plan, mutate nothing).
- **Always `--dry-run` first.** Example:
  ```bash
  mise run release:all --dry-run
  mise run release:all                    # -> eql-3.0.0-alpha.N (+ docs) + eql-bindings-v3.0.0-alpha.N on one commit
  mise run release:eql --channel beta     # -> eql-3.0.0-beta.N (SQL + docs only)
  mise run release:bindings --pre 3.0.0-alpha.2   # publish the crate for an existing eql-3.0.0-alpha.2
  ```
- **Identity derivation** happens **server-side** across both tag namespaces (`N = 1 + max(SQL N, crate N)`), from freshly-fetched tags — no stale local tags.
- **Two runs to watch for `target=all`/`target=bindings`**: the mise task watches the coordinator run; the crate publish is a **separate** `release-plz.yml` run (fire-and-forget) — watch it in the Actions tab. The failure direction (crate fails after SQL+docs shipped) is the safe one (SQL-without-crate).
- **Ordering guarantee:** SQL → docs → crate. A docs-build failure aborts before the irreversible crate publish, so a crate never ships against an incomplete release.
- **The prerequisite for the crate**: crates.io Trusted Publishing is configured for `Workflow: release-plz.yml`; the coordinator dispatches that workflow so the OIDC identity still matches. Do not move the crate publish into the coordinator.
- Remove all `mise run release:preview`, `--tag`, and `--target <sha>` references; the manual `gh release create` steps; and the entire hand-coordinated lockstep procedure (it is now the coordinator's job). Keep the "Smoke-test the alpha" and "Promoting to a final release later" sections, updating the tag examples to `eql-3.0.0-alpha.N`.

- [ ] **Step 2: Update `CLAUDE.md`**

In the "Release & changelog discipline" section (around line 243), replace the **Prerelease** bullet:

Old:
```
- **Prerelease (alpha / beta / rc):** run `mise run release:preview` (`tasks/release/preview.sh`). ...
```
New (match the surrounding tone/density):
```
- **Prerelease (alpha / beta / rc):** run `mise run release:all` (both artefacts in lockstep), `mise run release:eql` (SQL surface + docs only), or `mise run release:bindings` (crate for an existing SQL alpha). Each is a thin trigger that dispatches the CI-native coordinator `.github/workflows/release-alpha.yml` (`workflow_dispatch`) and watches the run — nothing release-relevant runs locally. The coordinator derives the `<version>-<channel>.<N>` identity server-side across both tag namespaces, verifies the drift gates, and (for `all`) pins+commits the crate, builds+attaches the SQL prerelease and the docs bundle in-run, then dispatches the crate publish so both land on one commit. Always `--dry-run` first; `--pre` sets an exact identity; `--ref`/`--channel`/`--version` tune the dispatch. It does **not** touch `CHANGELOG.md` (previews stay under `[Unreleased]`). Full runbook: **`docs/development/releasing-an-alpha.md`**.
```

Also update the lockstep paragraph immediately below it: replace "This is a manual coordination procedure" with a note that lockstep is now automated by `mise run release:all` / the `release-alpha.yml` coordinator (same-commit `eql-bindings-v<identity>` ↔ `eql-<identity>`), and update the line-291-area pointer ("For an alpha/beta/rc, use `mise run release:preview` instead") to name the three new tasks.

- [ ] **Step 3: Grep for stray references**

Run:
```bash
grep -rn "release:preview\|tasks/release/preview" --include="*.md" --include="*.toml" --include="*.sh" . | grep -v node_modules
```
Expected: **no matches** (all migrated). Fix any that remain.

- [ ] **Step 4: Commit**

```bash
git add docs/development/releasing-an-alpha.md CLAUDE.md
git commit -m "docs(release): document CI-native release:{all,eql,bindings} flow; drop release:preview"
```

---

### Task 8: End-to-end validation (staged rollout)

**Files:** none (execution + observation only). This task cannot be fully dry-run: a crates.io publish is irreversible, so a **real alpha is the only true end-to-end test**. Validate in increasing order of irreversibility.

**Precondition:** the branch (`feat/release-tasks`, or wherever this lands) must be **pushed** — `gh workflow run` reads the workflow file from the dispatched ref, so `release-alpha.yml` must exist on that ref.

- [ ] **Step 1: Static validation of all workflows**

Run: `actionlint .github/workflows/_build-sql.yml .github/workflows/_build-docs.yml .github/workflows/release-eql.yml .github/workflows/release-plz.yml .github/workflows/release-alpha.yml`
Expected: no output (exit 0).

- [ ] **Step 2: `dry_run` each target (mutates nothing)**

```bash
mise run release:eql --dry-run
mise run release:all --dry-run
mise run release:bindings --dry-run   # expect a fast failure if no SQL alpha awaits a crate
```
Expected: each dispatches a coordinator run that resolves an identity, prints the plan to the run summary, and **creates no tags/releases/commits**. Confirm via the run's "Release plan" summary. `release:bindings --dry-run` with no eligible SQL release should fail in `resolve` with the lockstep-invariant error — that is correct.

- [ ] **Step 3: Cross-namespace `N` check (read the resolved plan)**

With an `eql-3.0.0-alpha.5` tag present and no crate alpha tag:
- `mise run release:bindings --pre 3.0.0-alpha.5 --dry-run` → resolves (matching SQL exists).
- `mise run release:all --dry-run` → plan shows identity `3.0.0-alpha.6` (`N = 1 + max(5, 0)`).
- `mise run release:bindings --version 3.0.0 --channel alpha --dry-run` (no `--pre`) → resolves to the latest SQL alpha lacking a crate (`alpha.5`).

- [ ] **Step 4: Throwaway `target=eql` smoke release (SQL + docs)**

```bash
mise run release:eql
```
Expected: coordinator run succeeds; a prerelease `eql-3.0.0-alpha.N` is created on the branch HEAD with `cipherstash-encrypt.sql`, `cipherstash-encrypt-uninstall.sql`, **and** the `eql-docs-*.zip`/`.tar.gz` bundle attached; **no crate published**; **no `release-pr`** anywhere. Verify:
```bash
gh release view eql-3.0.0-alpha.N          # two .sql assets + eql-docs-*, marked prerelease
gh run list --workflow release-plz.yml -L 3   # confirm NO new release-plz run fired
```
Then delete the throwaway release + tag if it was only a smoke test:
```bash
gh release delete eql-3.0.0-alpha.N --cleanup-tag --yes
```

- [ ] **Step 5: Docs-failure aborts the crate (fault-injection, optional)**

Confirm the ordering guarantee by observation: in any `target=all` run where `build-docs` fails, `crate-publish` must be **skipped** (its `if` requires `needs.build-docs.result == 'success'`). Read a run's job graph to confirm `crate-publish` did not start when `build-docs` was red. (Do not deliberately break docs on a real publish; verify from run history or a scratch branch.)

- [ ] **Step 6: Real `target=all` end-to-end**

```bash
mise run release:all
```
Expected and to verify:
- Both tags land on the **same commit `S`**:
  ```bash
  git fetch --tags
  git rev-list -n1 eql-3.0.0-alpha.N
  git rev-list -n1 eql-bindings-v3.0.0-alpha.N   # equal to the above
  ```
- The SQL prerelease + docs bundle were built+attached **in-run** (`build-sql` and `build-docs` jobs green) **before** the crate dispatch.
- The crate publish ran as a **separate `release-plz.yml` run** (workflow_dispatch), its `release` job green, `release-pr` **skipped** (ref is a tag), and the crates.io **TP token exchange succeeded** (publish ran under `workflow_ref = release-plz.yml`). Confirm:
  ```bash
  gh run list --workflow release-plz.yml -L 3      # the dispatched run present
  gh run view <that-run-id>                         # release: success, release-pr: skipped
  ```
- `gh release view eql-3.0.0-alpha.N` lists the two `.sql` files + `eql-docs-*`.
- The `eql-bindings@3.0.0-alpha.N` version is live on crates.io.

- [ ] **Step 7: Watch-correctness under overlap (optional)**

Dispatch two distinguishable runs close together (e.g. `mise run release:eql --dry-run` and `mise run release:all --dry-run`) and confirm each mise invocation watches **its own** run (matched by `<target> <correlation>` in `run-name`), not whichever finished last via `-L1`.

---

## Self-Review

**Spec coverage** (Companion changes + docs-required decision + Verification):
1. `_build-sql.yml` reusable → Task 1. ✅
2. `_build-docs.yml` reusable (docs on alphas, per user decision) → Task 2. ✅
3. `release-eql.yml` refactor (both `build-and-publish` → `_build-sql.yml` and `publish-docs` → `_build-docs.yml`, finals parity) → Task 3. ✅
4. `release-plz.yml` `release-pr` gated to `main` → Task 4. ✅
5. `release-alpha.yml` coordinator (inputs, concurrency, run-name, both-namespace identity, all/eql/bindings flows, **in-run docs via `build-docs`**, crate publish via `gh workflow run release-plz.yml --ref <tag>`, SQL→docs→crate ordering, bindings "matching SQL must exist" guard) → Task 5. ✅
6. Three thin `tasks/release/*.sh` + mise wiring, watch-by-run-name, retire `preview.sh` → Task 6. ✅
7. Doc updates (`releasing-an-alpha.md`, `CLAUDE.md`, stray-ref grep) → Task 7. ✅
8. Verification (dry_run per target, cross-namespace N, bindings invariant, target=all same-commit + docs + TP + no stray release-pr, target=eql with docs, docs-failure aborts crate, watch correctness) → Task 8. ✅

**Global-constraint fidelity:** SQL and docs build in-run (reusables called inline, never event fan-out); crate publishes from `release-plz.yml` as its own dispatched entry point (TP untouched); same-commit `S` via dispatch against the immutable SQL tag; SQL→docs→crate ordering enforced by `crate-publish` needing both `build-sql` **and** `build-docs` success; identity across both namespaces; prereleases only. ✅

**Type/name consistency:** `_build-sql.yml` inputs (`ref`/`tag`/`attach`/`target_commitish`/`prerelease`) and `_build-docs.yml` inputs (`ref`/`tag`) are each defined once (Tasks 1, 2) and used identically in Tasks 3 and 5. Coordinator outputs (`identity`/`sql_tag`/`crate_tag`, `pin.commit_sha`) and the `build-docs`/`build-sql` `needs` chain are produced and consumed consistently. The `run-name` correlation (`<target> <pre|version-channel>`) matches the mise watcher's `contains("${target} ${correlation}")` filter in Task 6.

---

## Risks and open questions

1. **Docs bundle preserved in-run (resolved).** Per the user's decision, alpha releases carry the docs bundle. The coordinator's `build-docs` job (Task 5) calls the reusable `_build-docs.yml` (Task 2) after `build-sql` succeeds, building docs at the same commit and attaching `eql-docs-*` to the SQL release; `crate-publish` gates on `build-docs` success, so the crate never ships against a docs-less release. **Cost:** each alpha coordinator run adds a doxygen install (`sudo apt-get install -y doxygen`) plus `docs:generate` / `docs:generate:markdown` / `docs:package` (the `publish-docs` timeout is 10 min). No database is required for docs generation. This is the same work finals already do.

2. **Watch ambiguity for identical concurrent dispatches.** `run-name` is fixed at dispatch time and cannot embed a server-derived `N`, so two simultaneous dispatches with **identical** inputs and no `--pre` share a correlation string; the watcher then relies on `createdAt` recency and could attach to the sibling run. The spec's "watch correctness" test uses **distinguishable** inputs (different target/pre), which works. Realistic single-operator use is fine. **Mitigation if it ever bites:** add a hidden `dispatch_id` input echoed into `run-name` — but that adds an input beyond the spec's locked list, so it is deliberately not in this plan.

3. **`release-plz set-version` availability.** The pin job installs `release-plz` via `cargo binstall --no-confirm release-plz` (cargo-binstall is already a mise tool). If binstall has no prebuilt for the runner, it falls back to a source build (slow) or fails. **Alternative if flaky:** pin `"cargo:release-plz" = "<version>"` in `mise.toml [tools]`. Flagged, not chosen, to avoid touching the toolchain manifest unless needed.

4. **`pin` pushes to the branch with `GITHUB_TOKEN`.** This works on the unprotected `eql_v3` branch (correct per spec). On a protected `main` (future) the push is blocked — explicitly out of scope ("Future: the `main` channel").

5. **Cannot fully rehearse the crates.io publish.** `--dry-run` and a throwaway `target=eql` cover everything reversible (now including docs), but the OIDC/TP token exchange and the irreversible publish are only exercised by a real `target=all`/`target=bindings`. The staged rollout in Task 8 (dry-run → throwaway `eql` → real `all`) is the safest available path; the first real `all` should use a low, disposable `N`.

6. **`softprops/action-gh-release` prerelease semantics on the finals path.** The plan keeps the finals SQL attach step free of a `prerelease` input (preserving today's behaviour of not altering the existing release's prerelease flag); the docs reusable likewise only attaches. This was verified against the current file's steps. If a future action-v2 default ever starts clobbering an unset `prerelease`, the finals path would need an explicit passthrough — noted as a watch-item, not a current change.
