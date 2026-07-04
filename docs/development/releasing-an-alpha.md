# Releasing an `eql_v3` alpha

A concise runbook for cutting a **prerelease** (alpha/beta/rc) of EQL — primarily
the standalone `eql_v3` surface. For a final (non-prerelease) release, follow the
**"Cutting a release"** section of `CLAUDE.md` instead; the difference is called out below.

## What ships

The release workflow (`.github/workflows/release-eql.yml`, triggered by `release: published`)
builds with `mise run build --version <tag>` and attaches these artifacts to the GitHub Release:

| Artifact | What it installs |
|----------|------------------|
| `cipherstash-encrypt.sql` / `cipherstash-encrypt-uninstall.sql` | **The standalone, self-contained `eql_v3` surface** (no `eql_v2`) |
| `eql-docs-*.zip` / `eql-docs-*.tar.gz` | Packaged API documentation (from the `publish-docs` job) |

`cipherstash-encrypt.sql` is the only installer: it installs the `eql_v3`
schema into a database with no `eql_v2` present. (There is no longer a separate
`-supabase` or `-v3` artifact — the single installer *is* the self-contained v3 surface.)

## Why a prerelease is different

The `verify-changelog` job is gated to **real (non-prerelease) `eql-*` releases**:

```yaml
if: ${{ github.event_name == 'release' && contains(github.event.release.tag_name, 'eql') && github.event.release.prerelease == false }}
```

So for a prerelease you **do not** promote `[Unreleased]` → `[<version>]` in `CHANGELOG.md`.
Entries stay under `## [Unreleased]` until a final release is cut. The `build-and-publish`
and `publish-docs` jobs still run (they only require `eql` in the tag), so the artifacts are
built and attached as normal.

## Scripted path (recommended)

`mise run release:preview` (`tasks/release/preview.sh`) does steps 1, 3 and 4 below:
it derives the next preview tag, does a clean build, verifies the v3 installer/uninstaller
are present and non-empty, then creates the GitHub prerelease (which triggers the workflow).
It does **not** touch `CHANGELOG.md` — previews keep their entries under `[Unreleased]`.

The tag is `eql-<version>-<channel>.<N>`. "Preview" is the umbrella; `--channel` picks
`alpha` → `beta` → `rc` and `<N>` auto-increments per channel:

```bash
# Derive the next eql-3.0.0-alpha.N tag, build-verify, and cut against the current branch:
mise run release:preview

# See what it would do without creating anything:
mise run release:preview --dry-run

# Override the base version / channel / exact tag / target:
mise run release:preview --version 3.0.0 --channel beta   # -> eql-3.0.0-beta.1
mise run release:preview --tag eql-3.0.0-rc.1 --target eql_v3
```

| Flag | Meaning | Default |
|------|---------|---------|
| `--version` | base SemVer (the `<version>` in the tag) | `3.0.0` |
| `--channel` | preview channel: `alpha` \| `beta` \| `rc` | `alpha` |
| `--tag` | exact tag to cut, bypassing derivation | (derived) |
| `--target` | branch/commit to tag | current branch |
| `--dry-run` | print the plan, create nothing | off |

It refuses to reuse an existing tag, requires an authenticated `gh`, and requires the tag to
start with `eql-` (otherwise the workflow's build/docs jobs are skipped). After it runs, jump
to **"Confirm the workflow attached the artifacts"** and the smoke test below.

## Steps (manual equivalent)

1. **Pick a tag.** It must contain `eql` so the build/docs jobs run, and use a SemVer
   prerelease suffix:
   ```text
   eql-3.0.0-alpha.1
   ```

2. **Sanity-check `[Unreleased]`.** Confirm the v3 entries you expect are present and coherent.
   Do **not** rename the section — the prerelease keeps them under `[Unreleased]`.

3. **Verify the build produces the v3 artifacts locally** (the same files the workflow attaches):
   ```bash
   mise run clean && mise run build
   ls -la release/cipherstash-encrypt.sql release/cipherstash-encrypt-uninstall.sql
   ```
   Both must be non-empty (the installer is ~900KB+; the uninstaller is small).

4. **Cut the prerelease.** Target the branch carrying the v3 surface and mark it `--prerelease`:
   ```bash
   gh release create eql-3.0.0-alpha.1 \
     --target eql_v3 \
     --prerelease \
     --title "eql-3.0.0-alpha.1" \
     --notes "Alpha of the standalone eql_v3 surface. See [Unreleased] in CHANGELOG.md."
   ```
   (Adjust `--target` to whatever branch/commit the v3 work lives on at release time.)

5. **Confirm the workflow attached the artifacts.** Watch the run and check the release page:
   ```bash
   gh run watch
   gh release view eql-3.0.0-alpha.1
   ```
   The release should list the two `.sql` artifacts (`cipherstash-encrypt.sql`
   and `cipherstash-encrypt-uninstall.sql`) plus the packaged docs bundle.

## Smoke-test the alpha

Install the standalone v3 surface into a clean database (no `eql_v2`) and confirm it loads:

```bash
gh release download eql-3.0.0-alpha.1 -p 'cipherstash-encrypt.sql'
psql "$DATABASE_URL" -f cipherstash-encrypt.sql
psql "$DATABASE_URL" -c "\dn eql_v3"            # eql_v3 schema present
psql "$DATABASE_URL" -c "SELECT eql_v3.version();"  # reports the released semver
```

## Releasing `eql-bindings` in lockstep

The `eql-bindings` crate (`crates/eql-bindings`, published to crates.io) and the SQL surface
ship from the **same generated source**: the crate's `src/v3` payload bindings and the
`cipherstash-encrypt.sql` installer are both regenerated from `eql-domains::CATALOG`. We release
them **in version lockstep** so a published `eql-bindings-v3.0.0-alpha.N` always corresponds to
the SQL surface tagged `eql-3.0.0-alpha.N` at the **same commit**.

This is not automatic — the two release paths are deliberately decoupled (different triggers, tag
namespaces, and automation; see `release-plz.toml` and the guards in `release-eql.yml`). Lockstep
is a **manual coordination procedure** you follow per alpha.

### How the crate is published

`eql-bindings` is released by **release-plz** (`.github/workflows/release-plz.yml`), triggered by
**push to `main`** — *not* by any GitHub Release. release-plz opens/updates a "release PR"; merging
that PR publishes to crates.io (OIDC trusted publishing), creates the `eql-bindings-v<semver>` tag,
and cuts a GitHub Release. Two facts drive the lockstep procedure:

- **`release-plz release` publishes the committed `Cargo.toml` version verbatim** — it does not bump
  at release time. So the version you *commit* is the version that ships.
- **release-plz owns the version in the release PR.** It computes the next bump from conventional
  commits (via the `next_version` crate). From a prerelease base it increments the prerelease
  counter by default (`3.0.0-alpha.1` → `3.0.0-alpha.2`); it will **not** strip to `3.0.0` on its
  own. There is **no config field that sets an absolute version** — you pin with `release-plz set-version`.

### One-time config

None required. The default `git_release_type = auto` already marks a `-alpha.N` version as a
GitHub *pre-release* (verified in release-plz source), and `publish` / `git_tag_enable` /
`git_release_enable` all default `true`. Note `release_always` also defaults `true`: the `release`
job publishes any committed `Cargo.toml` version not yet on crates.io on every push to `main` — the
release PR is release-plz's ergonomic path for *proposing* the bump, not a hard publish gate.

### The lockstep procedure

The SQL alpha number **N is the driver** (the SQL surface is the primary artefact). The crate
follows it. crates.io publishes are **irreversible** (a burned version can be yanked but never
reused), so we verify both sides, cut the reversible GitHub prerelease first, and merge the
irreversible crate publish last.

1. **Decide N** — the next SQL alpha, e.g. tag `eql-3.0.0-alpha.2`.

2. **Pin the crate version on the release commit** (crate is currently `0.1.0`; lockstep jumps it
   to the matching semver):
   ```bash
   release-plz set-version eql-bindings@3.0.0-alpha.2   # edits Cargo.toml + crate CHANGELOG
   ```
   Commit and push to `main`. **Verify the release PR shows `3.0.0-alpha.2`, not a recomputed
   value** — if a later push regenerated it (e.g. to `-alpha.3`), re-run `set-version` on `main` to
   reconverge. Do **not** rely on hand-editing the PR branch; a subsequent push can overwrite it.

3. **Confirm the generated surface is in sync on that commit** — this is what guarantees the
   published crate's `src/v3` matches the shipped `cipherstash-encrypt.sql`:
   ```bash
   mise run types:check        # regenerate + git diff of crates/eql-bindings/src/v3, bindings/, schema/
   mise run codegen:parity     # regenerate + git diff of the committed SQL scalar surface
   ```
   Both must be clean. (They run in CI too, but check here before publishing anything irreversible.)

4. **Cut the SQL prerelease** at that commit (reversible — a GitHub prerelease can be deleted).
   Use an explicit `--tag` so the number matches the crate exactly:
   ```bash
   mise run release:preview --tag eql-3.0.0-alpha.2 --target <release-sha>
   ```
   This clean-builds and verifies the v3 installer/uninstaller before creating the prerelease.

5. **Merge the release-plz PR** (irreversible — publishes `eql-bindings-v3.0.0-alpha.2` to
   crates.io, tags it, cuts its prerelease GitHub Release).

Both tags — `eql-3.0.0-alpha.2` and `eql-bindings-v3.0.0-alpha.2` — now sit on one commit with
matching semver.

### Caveats

- **No absolute-version config knob.** Pinning is only via `release-plz set-version` / the committed
  `Cargo.toml`. `release-plz.toml` has increment-*influencing* fields but nothing that sets a version.
- **No prerelease-increment strategy config.** The default from `-alpha.N` is `-alpha.(N+1)`. To jump
  to stable `3.0.0`, run `set-version eql-bindings@3.0.0` explicitly — don't rely on the default.
- **The release PR keeps regenerating** on every `main` push. Pin on `main` (step 2), don't hand-edit
  the PR branch — whether a PR-branch edit survives a regeneration is undocumented.
- **release-plz is idempotent** — re-running won't republish an already-published version, so a
  failed later step won't double-publish an `-alpha.N` that already went out.
- There is **no upstream precedent** for alpha-pinning in cipherstash-suite's `RELEASING.md`; this
  procedure extends its standard conventional-commit flow.

## Promoting to a final release later

When the alpha graduates to a real release, follow `CLAUDE.md` → **"Cutting a release"**:
rename `## [Unreleased]` to `## [<version>] — YYYY-MM-DD`, add a fresh empty `[Unreleased]`,
update the link references at the bottom of `CHANGELOG.md`, then cut a **non-prerelease**
GitHub release whose body is the new versioned section verbatim. The `verify-changelog`
job then enforces that the `## [<version>]` section exists at the tag.
