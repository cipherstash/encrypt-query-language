#!/usr/bin/env bash
#MISE description="Cut an alpha of SQL + docs + ALL language binding packages in lockstep: dispatch release-alpha.yml (target=all) and watch"
#USAGE flag "--version <version>" help="Base SemVer, e.g. 3.0.0" default="3.0.0"
#USAGE flag "--channel <channel>" help="Preview channel: alpha | beta | rc" default="alpha"
#USAGE flag "--pre <pre>" help="Exact identity (e.g. 3.0.0-alpha.2), bypassing N derivation" default=""
#USAGE flag "--ref <ref>" help="Git branch to dispatch against (the crate pin is pushed here)" default=""
#USAGE flag "--dry-run" help="Resolve + verify + print plan; mutate nothing"

set -euo pipefail

# Thin trigger: nothing release-relevant runs locally. It dispatches the
# CI-native coordinator (.github/workflows/release-alpha.yml) with target=all and
# watches THAT run. Same-commit lockstep + all safety live in CI.

target="all"
version="${usage_version:-3.0.0}"
channel="${usage_channel:-alpha}"
pre="${usage_pre:-}"
ref="${usage_ref:-}"
dry_run="${usage_dry_run:-false}"

err() { echo "error: $*" >&2; exit 1; }

# --- Validate (mirrors the coordinator's resolve guards) ---------------------
case "$channel" in alpha|beta|rc) ;; *) err "invalid --channel '$channel' (expected: alpha | beta | rc)" ;; esac
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || err "invalid --version '$version' (expected X.Y.Z)"
if [[ -n "$pre" ]]; then
  [[ "$pre" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(alpha|beta|rc)\.[0-9]+$ ]] || err "invalid --pre '$pre' (expected X.Y.Z-(alpha|beta|rc).N)"
fi

command -v gh >/dev/null 2>&1 || err "gh CLI not found (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || err "gh is not authenticated; run 'gh auth login'"

# target=all pins+pushes language package versions, so require an explicit branch.
if [[ -z "$ref" ]]; then
  err "missing --ref <branch> (target=all pushes language package pins to that branch)"
fi

# Unique correlation id echoed into the coordinator's run-name so we watch the
# EXACT run we started.
dispatch_id="$(uuidgen 2>/dev/null || echo "$$-$RANDOM-$(date +%s)")"

args=(--ref "$ref" -f target="$target" -f version="$version" -f channel="$channel" -f dispatch_id="$dispatch_id")
[[ -n "$pre" ]] && args+=(-f pre="$pre")
[[ "$dry_run" == "true" ]] && args+=(-f dry_run=true)

echo "==> Dispatching release-alpha.yml (target=${target}, dispatch_id=${dispatch_id}) on ref ${ref}"
gh workflow run release-alpha.yml "${args[@]}"

echo "==> Locating the dispatched run by dispatch_id (unambiguous)"
run_id=""
for _ in $(seq 1 30); do
  run_id=$(gh run list --workflow release-alpha.yml --event workflow_dispatch \
    --json databaseId,displayTitle \
    --jq "[.[] | select(.displayTitle | contains(\"${dispatch_id}\"))] | first | .databaseId")
  [[ -n "$run_id" && "$run_id" != "null" ]] && break
  sleep 2
done
[[ -n "$run_id" && "$run_id" != "null" ]] || err "could not find the dispatched run (dispatch_id=${dispatch_id})"

echo "==> Watching run ${run_id}"
gh run watch "$run_id" --exit-status
echo "==> Coordinator finished. Rust and TypeScript package publishes run as SEPARATE release workflows - watch them in the Actions tab."
