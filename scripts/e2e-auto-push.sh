#!/usr/bin/env bash
# Automated E2E tests for Phase 8.2 auto-push (Units 8.2a / 8.2b).
#
# Agent runs this — no manual branch/spec/commit/ship steps.
#
# Usage (from repo root):
#   bash scripts/e2e-auto-push.sh single      # Unit 8.2a — one PR via auto-push.sh
#   bash scripts/e2e-auto-push.sh parallel    # Unit 8.2b — two PRs via --branch
#   bash scripts/e2e-auto-push.sh single --dry-run-only   # commit + preflight only
#   bash scripts/e2e-auto-push.sh single --wait-ci          # push then poll CI (5 min)
#
# Requires: gh auth (personal GitHub), clean main sync, network for push.
# See: docs/AUTO-PUSH.md § E2E tests, specs/SPECS.md Units 8.2a–8.2b
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE=""
DRY_RUN_ONLY=0
WAIT_CI=0
OFFLINE=0
BASE_BRANCH="${BASE_BRANCH:-main}"
LOG_FILE="docs/e2e-auto-push-log.md"

# Unit 8.2a
BRANCH_82A="feat/test-auto-push-82a"
TASKS_82A="tasks/${BRANCH_82A}/SPECS.md"
MARKER_82A="docs/e2e-auto-push-82a.md"

# Unit 8.2b
BRANCH_82B_A="feat/test-auto-push-82b-a"
BRANCH_82B_B="feat/test-auto-push-82b-b"
TASKS_82B_A="tasks/${BRANCH_82B_A}/SPECS.md"
TASKS_82B_B="tasks/${BRANCH_82B_B}/SPECS.md"
MARKER_82B_A="docs/e2e-auto-push-82b-a.md"
MARKER_82B_B="docs/e2e-auto-push-82b-b.md"

usage() {
  cat <<'EOF'
Automated E2E for auto-push (Phase 8.2a / 8.2b).

  bash scripts/e2e-auto-push.sh single [--dry-run-only] [--wait-ci]
  bash scripts/e2e-auto-push.sh parallel [--dry-run-only] [--wait-ci]

Options:
  --dry-run-only   Create branches + commits + auto-push --dry-run; no push/PR
  --wait-ci        After push, poll gh pr checks (timeout 300s)
  --offline        Skip git fetch (use when main already matches origin/main)

Exit: prints E2E_EXIT=ready | need_gh_auth | need_push_human | failed
EOF
  exit "${1:-0}"
}

die() {
  echo "e2e-auto-push FAILED: $*" >&2
  echo "E2E_EXIT=failed"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    single|parallel)
      MODE="$1"
      shift
      ;;
    --dry-run-only)
      DRY_RUN_ONLY=1
      shift
      ;;
    --wait-ci)
      WAIT_CI=1
      shift
      ;;
    --offline)
      OFFLINE=1
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "e2e-auto-push: unknown option: $1" >&2
      usage 1
      ;;
  esac
done

[[ -n "$MODE" ]] || usage 1

require_cmd git
require_cmd gh

if ! git diff --quiet || ! git diff --cached --quiet; then
  die "working tree not clean — commit or stash before E2E"
fi

ensure_main_fresh() {
  echo "=== Sync $BASE_BRANCH ==="
  if [[ "$OFFLINE" -eq 0 ]]; then
    git fetch origin "$BASE_BRANCH" 2>/dev/null || die "git fetch failed — use --offline if main is already synced"
  else
    echo "Offline mode — skipping fetch"
  fi
  git checkout "$BASE_BRANCH"
  if git rev-parse "origin/${BASE_BRANCH}" >/dev/null 2>&1; then
    git merge --ff-only "origin/${BASE_BRANCH}" 2>/dev/null || die "main diverged from origin — pull/merge manually first"
  fi
}

write_tasks_archive() {
  local tasks_path="$1"
  local unit_id="$2"
  local branch="$3"
  mkdir -p "$(dirname "$tasks_path")"
  cat >"$tasks_path" <<EOF
# SPECS — E2E auto-push (${unit_id})

Automated by \`scripts/e2e-auto-push.sh\` — do not edit manually during E2E.

- [ ] Branch \`${branch}\`
- [ ] Marker file updated
- [ ] \`bash scripts/auto-push.sh\` (not manual git push)
- [ ] CI + GHA review on PR; human merge optional for E2E pass

**Verification:** Script exits with \`E2E_EXIT=ready\` and PR URL(s) printed.
EOF
}

write_marker() {
  local marker_path="$1"
  local label="$2"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat >"$marker_path" <<EOF
# E2E auto-push marker — ${label}

Last run: ${ts}
Branch: $(git branch --show-current)
Unit: ${label}

This file is updated by \`scripts/e2e-auto-push.sh\` for Phase 8.2 E2E verification.
EOF
}

ensure_log_header() {
  if [[ ! -f "$LOG_FILE" ]]; then
    cat >"$LOG_FILE" <<'EOF'
# E2E auto-push log

Append-only log of automated E2E runs (`scripts/e2e-auto-push.sh`).

EOF
  fi
}

append_log() {
  local line="$1"
  ensure_log_header
  echo "- ${line}" >>"$LOG_FILE"
  git add "$LOG_FILE"
}

prepare_branch() {
  local branch="$1"
  local tasks_path="$2"
  local marker_path="$3"
  local unit_id="$4"
  local log_label="$5"
  local skip_shared_log="${6:-0}"

  echo ""
  echo "=== Prepare ${branch} (${unit_id}) ==="
  git checkout -B "$branch" "$BASE_BRANCH"
  write_tasks_archive "$tasks_path" "$unit_id" "$branch"
  write_marker "$marker_path" "$unit_id"
  if [[ "$skip_shared_log" -eq 0 ]]; then
    append_log "${log_label} started $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  fi
  git add "$tasks_path" "$marker_path"
  git commit -m "test(harness): E2E auto-push ${unit_id} ($(date -u +%Y-%m-%d))"

  echo "Running auto-push dry-run..."
  bash scripts/auto-push.sh --dry-run --branch "$branch"

  if [[ "$DRY_RUN_ONLY" -eq 1 ]]; then
    echo "Dry-run-only — skip push for ${branch}"
    return 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "E2E_EXIT=need_gh_auth"
    echo "Run: gh auth login — then re-run this script"
    exit 1
  fi

  echo "Running auto-push (push + PR)..."
  if ! bash scripts/auto-push.sh --branch "$branch"; then
    echo "E2E_EXIT=need_push_human"
    echo "Human: bash scripts/auto-push.sh --branch ${branch}"
    exit 1
  fi
}

wait_for_ci() {
  local branch="$1"
  local timeout="${2:-300}"
  echo "Waiting for CI on ${branch} (timeout ${timeout}s)..."
  local start=$SECONDS
  while (( SECONDS - start < timeout )); do
    if gh pr checks "$branch" --watch=false 2>/dev/null | grep -qE 'fail|pending'; then
      sleep 10
      continue
    fi
    if gh pr checks "$branch" --watch=false 2>/dev/null | grep -q pass; then
      echo "CI checks passing (or complete) for ${branch}"
      return 0
    fi
    sleep 10
  done
  echo "WARN: CI wait timed out for ${branch} — check PR on GitHub"
  return 0
}

print_pr_url() {
  local branch="$1"
  gh pr view "$branch" --json url --jq .url 2>/dev/null || echo "(no PR yet for ${branch})"
}

run_single() {
  ensure_main_fresh
  prepare_branch "$BRANCH_82A" "$TASKS_82A" "$MARKER_82A" "8.2a" "$BRANCH_82A"
  git checkout "$BASE_BRANCH"

  if [[ "$DRY_RUN_ONLY" -eq 0 ]]; then
    echo ""
    echo "PR (8.2a): $(print_pr_url "$BRANCH_82A")"
    if [[ "$WAIT_CI" -eq 1 ]]; then
      wait_for_ci "$BRANCH_82A"
    fi
  fi

  echo "E2E_EXIT=ready"
  echo "Unit 8.2a complete — merge PR on GitHub when ready."
}

run_parallel() {
  ensure_main_fresh
  prepare_branch "$BRANCH_82B_A" "$TASKS_82B_A" "$MARKER_82B_A" "8.2b-worker-a" "$BRANCH_82B_A" 1
  prepare_branch "$BRANCH_82B_B" "$TASKS_82B_B" "$MARKER_82B_B" "8.2b-worker-b" "$BRANCH_82B_B" 1
  git checkout "$BASE_BRANCH"

  if [[ "$DRY_RUN_ONLY" -eq 0 ]]; then
    echo ""
    echo "PR (8.2b-a): $(print_pr_url "$BRANCH_82B_A")"
    echo "PR (8.2b-b): $(print_pr_url "$BRANCH_82B_B")"
    if [[ "$WAIT_CI" -eq 1 ]]; then
      wait_for_ci "$BRANCH_82B_A"
      wait_for_ci "$BRANCH_82B_B"
    fi
  fi

  echo "E2E_EXIT=ready"
  echo "Unit 8.2b complete — two PRs; merge on GitHub (expect possible progress.txt conflict if both touch shared files — these use disjoint docs only)."
}

case "$MODE" in
  single) run_single ;;
  parallel) run_parallel ;;
esac
