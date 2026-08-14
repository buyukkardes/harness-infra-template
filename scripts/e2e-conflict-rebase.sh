#!/usr/bin/env bash
# E2E harness for Phase 8 Unit 8.4 — local progress.txt conflict on rebase.
#
# Usage:
#   bash scripts/e2e-conflict-rebase.sh setup    # create feat/test-conflict-84 with conflict state
#   bash scripts/e2e-conflict-rebase.sh check    # verify conflict state (exit 2 from rebase script)
#   bash scripts/e2e-conflict-rebase.sh cleanup  # abort rebase, delete test branches
#
# After setup: use harness/conflict-agent-prompt.md, then rebase-parallel-pr.sh --continue
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="${1:-setup}"
BRANCH_A="feat/test-conflict-84-a"
BRANCH_B="feat/test-conflict-84-b"
MARKER=".git/e2e-conflict-84-base"

die() {
  echo "e2e-conflict-rebase FAILED: $*" >&2
  exit 1
}

in_rebase() {
  [[ -d .git/rebase-merge || -d .git/rebase-apply ]]
}

save_start_branch() {
  START_BRANCH="$(git branch --show-current)"
  [[ -n "$START_BRANCH" ]] || START_BRANCH="main"
}

restore_start() {
  if [[ -n "${START_BRANCH:-}" ]]; then
    git checkout "$START_BRANCH" 2>/dev/null || git checkout main
  fi
}

cleanup() {
  save_start_branch
  if in_rebase; then
    git rebase --abort 2>/dev/null || true
  fi
  if [[ -f "$MARKER" ]]; then
    base="$(cat "$MARKER")"
    git checkout main 2>/dev/null || true
    git reset --hard "$base" 2>/dev/null || true
  fi
  git branch -D "$BRANCH_A" 2>/dev/null || true
  git branch -D "$BRANCH_B" 2>/dev/null || true
  rm -f "$MARKER"
  restore_start
  echo "e2e-conflict-rebase cleanup OK"
}

setup() {
  save_start_branch
  if in_rebase; then
    die "rebase in progress — run cleanup first"
  fi

  BASE="$(git rev-parse HEAD)"
  echo "$BASE" >"$MARKER"

  git branch -D "$BRANCH_A" 2>/dev/null || true
  git branch -D "$BRANCH_B" 2>/dev/null || true

  git checkout -b "$BRANCH_A" "$BASE"
  {
    echo ""
    echo "2026-08-13 | $BRANCH_A | E2E conflict worker A"
    echo "Summary: Parallel worker A handoff for 8.4 E2E."
    echo "Verified: e2e-conflict-rebase setup."
    echo "Next: merge B and resolve conflict."
  } >>state/progress.txt
  git add state/progress.txt
  git commit -m "test(harness): E2E conflict worker A handoff (8.4)"

  git checkout -b "$BRANCH_B" "$BASE"
  {
    echo ""
    echo "2026-08-13 | $BRANCH_B | E2E conflict worker B"
    echo "Summary: Parallel worker B handoff for 8.4 E2E."
    echo "Verified: e2e-conflict-rebase setup."
    echo "Next: rebase after A merged."
  } >>state/progress.txt
  git add state/progress.txt
  git commit -m "test(harness): E2E conflict worker B handoff (8.4)"

  git checkout main
  git merge --no-ff "$BRANCH_A" -m "test(harness): merge E2E conflict worker A (8.4 local E2E)"
  git checkout "$BRANCH_B"

  echo ""
  echo "=== E2E setup complete ==="
  echo "Branch: $BRANCH_B (conflict pending on rebase)"
  echo "Run: bash scripts/rebase-parallel-pr.sh"
  echo "Expected: exit 2 + conflict in state/progress.txt"
  echo "Then: harness/conflict-agent-prompt.md → resolve → rebase-parallel-pr.sh --continue"
  echo "Cleanup: bash scripts/e2e-conflict-rebase.sh cleanup"
}

in_rebase() {
  [[ -d .git/rebase-merge || -d .git/rebase-apply ]]
}

check() {
  current="$(git branch --show-current)"
  [[ "$current" == "$BRANCH_B" ]] || die "checkout $BRANCH_B first (run setup)"
  if in_rebase; then
    echo "check OK — rebase in progress with conflicts (agent step)"
    git diff --name-only --diff-filter=U | sed 's/^/  conflict: /'
    exit 0
  fi
  set +e
  bash "$ROOT/scripts/rebase-parallel-pr.sh"
  code=$?
  set -e
  if [[ "$code" -eq 2 ]]; then
    echo "check OK — rebase-parallel-pr exited 2 (conflicts as expected)"
    exit 0
  fi
  die "expected exit 2 from rebase-parallel-pr, got $code"
}

case "$MODE" in
  setup) setup ;;
  check) check ;;
  cleanup) cleanup ;;
  -h|--help)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    die "unknown mode: $MODE (use setup|check|cleanup)"
    ;;
esac
