#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/lib/config.sh
source "$ROOT/scripts/lib/config.sh"
harness_load_config "$ROOT"
echo "=== verify.sh ==="
bash scripts/init.sh
if [[ -f package.json ]]; then
  NPM_CACHE="${NPM_CONFIG_CACHE:-$ROOT/.npm-cache}"
  eval "$VERIFY_INSTALL --cache \"$NPM_CACHE\""
  eval "$VERIFY_TEST"
  eval "$VERIFY_BUILD" || { echo "build failed"; exit 1; }
  echo "Build OK"
else
  echo "No package.json — harness-only verify"
fi
echo "verify OK"
