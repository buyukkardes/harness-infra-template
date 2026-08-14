#!/usr/bin/env bash
# Append one Ralph loop iteration record to state/logs/.
#
# Usage:
#   bash scripts/ralph-log.sh <exit_code> "<unit description>" [commit_hash]
#
# Examples:
#   bash scripts/ralph-log.sh verify "Phase 4 Unit 4.2"
#   bash scripts/ralph-log.sh done "Phase 4 complete" abc1234
#
# exit_code: done | blocked | verify | noop | budget | stuck

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/state/logs"

EXIT_CODE="${1:?usage: ralph-log.sh <exit_code> <unit> [commit]}"
UNIT="${2:?usage: ralph-log.sh <exit_code> <unit> [commit]}"
COMMIT="${3:-$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "none")}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H%M%SZ")"
LOG="$ROOT/state/logs/${TIMESTAMP}.log"

{
  echo "timestamp: $TIMESTAMP"
  echo "exit: $EXIT_CODE"
  echo "unit: $UNIT"
  echo "commit: $COMMIT"
  echo "branch: $(git -C "$ROOT" branch --show-current 2>/dev/null || echo "unknown")"
} >> "$LOG"

echo "RALPH_LOG=$LOG"
echo "Logged iteration: exit=$EXIT_CODE unit=$UNIT commit=$COMMIT"
