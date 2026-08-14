#!/usr/bin/env bash
# Rebase feat/* onto main after a parallel PR merged first (Phase 8 Unit 8.4).
#
# Usage:
#   bash scripts/rebase-parallel-pr.sh                 # fetch + rebase current feat/*
#   bash scripts/rebase-parallel-pr.sh --branch feat/x
#   bash scripts/rebase-parallel-pr.sh --dry-run       # fetch only, show plan
#   bash scripts/rebase-parallel-pr.sh --continue      # after agent resolves conflicts
#   bash scripts/rebase-parallel-pr.sh --push          # verify + auto-push after clean rebase
#
# Exit codes:
#   0 — rebase complete, verify passed
#   1 — usage / preflight / verify failure
#   2 — conflicts remain; use harness/conflict-agent-prompt.md
#
# See: docs/ORCHESTRATION.md, harness/conflict-agent-prompt.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DRY_RUN=0
DO_CONTINUE=0
DO_PUSH=0
TARGET_BRANCH=""
BASE_BRANCH="${BASE_BRANCH:-main}"
REMOTE="${REMOTE:-origin}"

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      [[ $# -ge 2 ]] || { echo "rebase-parallel-pr: --branch requires a value" >&2; exit 1; }
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --continue)
      DO_CONTINUE=1
      shift
      ;;
    --push)
      DO_PUSH=1
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "rebase-parallel-pr: unknown option: $1" >&2
      usage 1
      ;;
  esac
done

die() {
  echo "rebase-parallel-pr FAILED: $*" >&2
  exit 1
}

conflict_die() {
  echo "rebase-parallel-pr CONFLICT: $*" >&2
  echo "" >&2
  echo "Next steps:" >&2
  echo "  1. Open harness/conflict-agent-prompt.md in a fresh Cursor chat" >&2
  echo "  2. Resolve conflicted files (no conflict markers)" >&2
  echo "  3. bash scripts/rebase-parallel-pr.sh --continue" >&2
  echo "  4. bash scripts/auto-push.sh when rebase + verify pass" >&2
  exit 2
}

in_rebase() {
  [[ -d .git/rebase-merge || -d .git/rebase-apply ]]
}

list_conflicts() {
  git diff --name-only --diff-filter=U 2>/dev/null || true
}

has_conflict_markers() {
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if grep -q '^<<<<<<< ' "$f" 2>/dev/null; then
      return 0
    fi
  done < <(list_conflicts)
  return 1
}

require_feat_branch() {
  local branch="$1"
  [[ "$branch" == feat/* ]] || die "expected feat/* branch, got: $branch"
}

require_clean_tree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    if in_rebase; then
      : # allow during --continue after staging
    else
      die "working tree has uncommitted changes — commit or stash first"
    fi
  fi
}

checkout_branch() {
  if [[ -n "$TARGET_BRANCH" ]]; then
    local current
    current="$(git branch --show-current)"
    if [[ "$current" != "$TARGET_BRANCH" ]]; then
      echo "Checking out $TARGET_BRANCH ..."
      git checkout "$TARGET_BRANCH" || die "could not checkout $TARGET_BRANCH"
    fi
  fi
}

BRANCH="$(git branch --show-current)"
if [[ -n "$TARGET_BRANCH" ]]; then
  checkout_branch
  BRANCH="$TARGET_BRANCH"
fi
[[ -n "$BRANCH" ]] || die "detached HEAD — checkout a feature branch first"
require_feat_branch "$BRANCH"

if [[ "$DO_CONTINUE" -eq 1 ]]; then
  in_rebase || die "no rebase in progress — run without --continue first"
  if has_conflict_markers; then
    echo "Conflicted files:" >&2
    list_conflicts | sed 's/^/  - /' >&2
    conflict_die "conflict markers still present"
  fi
  unstaged="$(list_conflicts)"
  if [[ -n "$unstaged" ]]; then
    echo "Conflicted files (unmerged):" >&2
    echo "$unstaged" | sed 's/^/  - /' >&2
    conflict_die "unmerged paths remain — stage resolved files with git add"
  fi
  echo "Continuing rebase..."
  if ! GIT_EDITOR=true git rebase --continue; then
    if in_rebase; then
      list_conflicts | sed 's/^/  - /' >&2 || true
      conflict_die "rebase paused on new conflicts"
    fi
    die "git rebase --continue failed"
  fi
  if in_rebase; then
    conflict_die "rebase still in progress unexpectedly"
  fi
  echo "Rebase complete."
  bash "$ROOT/scripts/verify.sh" || die "verify failed after rebase"
  if [[ "$DO_PUSH" -eq 1 ]]; then
    bash "$ROOT/scripts/auto-push.sh" ${TARGET_BRANCH:+--branch "$BRANCH"}
  fi
  echo "rebase-parallel-pr OK (--continue)"
  exit 0
fi

require_clean_tree
checkout_branch
BRANCH="$(git branch --show-current)"
require_feat_branch "$BRANCH"

echo "=== rebase-parallel-pr.sh ==="
echo "Branch: $BRANCH"
echo "Base:   $REMOTE/$BASE_BRANCH"

echo "Fetching $REMOTE/$BASE_BRANCH ..."
git fetch "$REMOTE" "$BASE_BRANCH"

if in_rebase; then
  die "rebase already in progress — resolve or abort (git rebase --abort) first"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  behind="$(git rev-list --count "HEAD..$REMOTE/$BASE_BRANCH" 2>/dev/null || echo 0)"
  ahead="$(git rev-list --count "$REMOTE/$BASE_BRANCH..HEAD" 2>/dev/null || echo 0)"
  echo "Dry run OK — would rebase $BRANCH onto $REMOTE/$BASE_BRANCH (ahead $ahead, behind $behind)"
  exit 0
fi

echo "Rebasing onto $REMOTE/$BASE_BRANCH ..."
if ! git rebase "$REMOTE/$BASE_BRANCH"; then
  if in_rebase; then
    echo "Conflicted files:" >&2
    list_conflicts | sed 's/^/  - /' >&2
    conflict_die "resolve conflicts then run with --continue"
  fi
  die "git rebase failed"
fi

echo "Rebase complete (no conflicts)."
bash "$ROOT/scripts/verify.sh" || die "verify failed after rebase"

if [[ "$DO_PUSH" -eq 1 ]]; then
  bash "$ROOT/scripts/auto-push.sh" ${TARGET_BRANCH:+--branch "$BRANCH"}
fi

echo "rebase-parallel-pr OK"
