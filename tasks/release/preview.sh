#!/usr/bin/env bash
#MISE description="Cut a preview (prerelease) of EQL: derive tag, verify build, create GitHub prerelease"
#USAGE flag "--version <version>" help="Base SemVer for the release, e.g. 3.0.0" default="3.0.0"
#USAGE flag "--channel <channel>" help="Preview channel: alpha | beta | rc" default="alpha"
#USAGE flag "--tag <tag>" help="Exact tag to cut (overrides --version/--channel derivation)" default=""
#USAGE flag "--target <target>" help="Branch or commit to tag" default=""
#USAGE flag "--dry-run" help="Print what would happen without creating the release"

set -euo pipefail

# Cut a PREVIEW (prerelease) of EQL — alpha, beta, or rc — primarily the
# standalone eql_v3 surface. "Preview" is the umbrella; --channel picks alpha/beta/rc.
#
# This scripts steps 1, 3 and 4 of docs/development/releasing-an-alpha.md:
#   - derive the next preview tag (eql-<version>-<channel>.<N>)
#   - verify the build produces the v3 installer/uninstaller
#   - create the GitHub prerelease (which triggers .github/workflows/release-eql.yml)
#
# It deliberately does NOT touch CHANGELOG.md: previews keep their entries
# under [Unreleased] (the verify-changelog job is gated to prerelease == false).

# mise exposes USAGE flags as environment variables; default for bare `bash`.
version="${usage_version:-3.0.0}"
channel="${usage_channel:-alpha}"
tag="${usage_tag:-}"
target="${usage_target:-}"
dry_run="${usage_dry_run:-false}"

err() { echo "error: $*" >&2; exit 1; }

# Validate the channel against the allowlist before it flows into tag/notes.
case "$channel" in
  alpha|beta|rc) ;;
  *) err "invalid --channel '${channel}' (expected: alpha | beta | rc)" ;;
esac

command -v gh >/dev/null 2>&1 || err "gh CLI not found (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || err "gh is not authenticated; run 'gh auth login'"

# --- Derive the tag --------------------------------------------------------
# If an exact --tag was given, use it. Otherwise find the highest existing
# eql-<version>-<channel>.<N> tag and increment N (starting at 1).
if [[ -z "$tag" ]]; then
  prefix="eql-${version}-${channel}."
  # Highest existing N for this base+channel, or 0 if none.
  last_n=$(git tag --list "${prefix}*" \
    | sed -n "s/^${prefix}\([0-9]\{1,\}\)$/\1/p" \
    | sort -n | tail -1)
  next_n=$(( ${last_n:-0} + 1 ))
  tag="${prefix}${next_n}"
fi

[[ "$tag" == eql-* ]] || err "tag must start with 'eql-' (got '$tag') or the build/docs jobs won't run"

if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
  err "tag '${tag}' already exists"
fi

# Default the release target to the current branch.
if [[ -z "$target" ]]; then
  target=$(git rev-parse --abbrev-ref HEAD)
fi

# --- Verify the build produces the v3 artifacts ----------------------------
echo "==> Building (clean) to verify v3 artifacts for ${tag}"
mise run clean
mise run build --version "${tag}"

v3_installer="release/cipherstash-encrypt-v3.sql"
v3_uninstaller="release/cipherstash-encrypt-v3-uninstall.sql"
for f in "$v3_installer" "$v3_uninstaller"; do
  [[ -s "$f" ]] || err "expected non-empty build artifact missing: $f"
done
echo "==> v3 artifacts present:"
ls -la "$v3_installer" "$v3_uninstaller"

# --- Create the prerelease -------------------------------------------------
notes="Preview (${channel}) of the standalone eql_v3 surface. See [Unreleased] in CHANGELOG.md."

if [[ "$dry_run" == "true" ]]; then
  echo "==> DRY RUN — would create prerelease:"
  echo "    gh release create ${tag} --target ${target} --prerelease --title ${tag}"
  exit 0
fi

echo "==> Creating GitHub prerelease ${tag} (target: ${target})"
gh release create "${tag}" \
  --target "${target}" \
  --prerelease \
  --title "${tag}" \
  --notes "${notes}"

echo "==> Done. The release workflow attaches artifacts on tag push."
echo "    Watch:  gh run watch"
echo "    Verify: gh release view ${tag}"
