# Releasing an `eql_v3` alpha

A concise runbook for cutting a **prerelease** (alpha/beta/rc) of EQL — primarily
the standalone `eql_v3` surface. For a final (non-prerelease) release, follow the
**"Cutting a release"** section of `CLAUDE.md` instead; the difference is called out below.

## What ships

The release workflow (`.github/workflows/release-eql.yml`, triggered by `release: published`)
builds with `mise run build --version <tag>` and attaches these artifacts to the GitHub Release:

| Artifact | What it installs |
|----------|------------------|
| `cipherstash-encrypt.sql` / `-uninstall.sql` | Full EQL (`eql_v2` + `eql_v3`) |
| `cipherstash-encrypt-supabase.sql` / `-uninstall-supabase.sql` | Supabase variant |
| `cipherstash-encrypt-v3.sql` / `-v3-uninstall.sql` | **Standalone, self-contained `eql_v3` surface** (no `eql_v2`) |

The `eql_v3` installer is the one an alpha consumer wants: it installs the `eql_v3`
schema into a database with no `eql_v2` present.

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
mise run release:preview --tag eql-3.0.0-rc.1 --target v3-publish-release-artifacts
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
   ```
   eql-3.0.0-alpha.1
   ```

2. **Sanity-check `[Unreleased]`.** Confirm the v3 entries you expect are present and coherent.
   Do **not** rename the section — the prerelease keeps them under `[Unreleased]`.

3. **Verify the build produces the v3 artifacts locally** (the same files the workflow attaches):
   ```bash
   mise run clean && mise run build
   ls -la release/cipherstash-encrypt-v3.sql release/cipherstash-encrypt-v3-uninstall.sql
   ```
   Both must be non-empty (the installer is ~750KB+; the uninstaller is small).

4. **Cut the prerelease.** Target the branch carrying the v3 surface and mark it `--prerelease`:
   ```bash
   gh release create eql-3.0.0-alpha.1 \
     --target v3-publish-release-artifacts \
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
   The release should list all six `.sql` artifacts, including
   `cipherstash-encrypt-v3.sql` and `cipherstash-encrypt-v3-uninstall.sql`.

## Smoke-test the alpha

Install the standalone v3 surface into a clean database (no `eql_v2`) and confirm it loads:

```bash
gh release download eql-3.0.0-alpha.1 -p 'cipherstash-encrypt-v3.sql'
psql "$DATABASE_URL" -f cipherstash-encrypt-v3.sql
psql "$DATABASE_URL" -c "\dn eql_v3"   # eql_v3 schema present
```

## Promoting to a final release later

When the alpha graduates to a real release, follow `CLAUDE.md` → **"Cutting a release"**:
rename `## [Unreleased]` to `## [<version>] — YYYY-MM-DD`, add a fresh empty `[Unreleased]`,
update the link references at the bottom of `CHANGELOG.md`, then cut a **non-prerelease**
GitHub release whose body is the new versioned section verbatim. The `verify-changelog`
job then enforces that the `## [<version>]` section exists at the tag.
