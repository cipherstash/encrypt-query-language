#!/usr/bin/env bash
#MISE description="Regenerate an encrypted-domain type from its TOML spec"
#USAGE arg "type" help="Type token, e.g. int4 (matches tasks/codegen/types/<type>.toml)"

set -euo pipefail

TYPE=${usage_type:?type argument required}

echo "Regenerating encrypted-domain type: ${TYPE}"
mise exec python -- python -m tasks.codegen.generate "${TYPE}"
echo ""
echo "✓ Regenerated src/encrypted_domain/${TYPE}/ (gitignored)"
echo "  Note: 'mise run build' regenerates every type automatically;"
echo "  this task is for refreshing one type while iterating on its manifest."
echo "  When ready, run 'mise run clean && mise run build' then 'mise run test'."
