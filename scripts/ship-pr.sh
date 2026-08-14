#!/usr/bin/env bash
# Push the current feat/* branch and open a PR (Phase 6 hybrid pipeline).
# Phase 8.2: delegates to scripts/auto-push.sh — use auto-push.sh for --branch / --gha.
#
# Usage (from repo root, on a feature branch after commit):
#   bash scripts/ship-pr.sh
#   bash scripts/ship-pr.sh --dry-run   # preflight only; no push or PR
#
# See: docs/AUTO-PUSH.md, docs/PR-WORKFLOW.md, specs/SPECS.md Unit 6.3
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$ROOT/scripts/auto-push.sh" "$@"
