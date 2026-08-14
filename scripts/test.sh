#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f package.json ]]; then
  echo "SKIP: no package.json yet (Phase 1 not bootstrapped)"
  exit 0
fi

npm test
