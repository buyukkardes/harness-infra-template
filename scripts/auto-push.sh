#!/usr/bin/env bash
# Automated push entry point (Phase 8.2).
#
# Agents and Cloud Agents run this after commit — replaces manual git push + ship-pr.
#
# Usage (from repo root):
#   bash scripts/auto-push.sh                              # current feat/* branch
#   bash scripts/auto-push.sh --branch feat/my-feature     # explicit branch (parallel workers)
#   bash scripts/auto-push.sh --dry-run
#   bash scripts/auto-push.sh --gha                        # push locally, then GHA verify + ensure PR
#
# Preflight: feat/* branch, tasks/<branch>/SPECS.md, verify.sh green, clean tree.
# See: docs/AUTO-PUSH.md, docs/PR-WORKFLOW.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DRY_RUN=0
USE_GHA=0
TARGET_BRANCH=""
BASE_BRANCH="${BASE_BRANCH:-main}"

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      [[ $# -ge 2 ]] || { echo "auto-push: --branch requires a value" >&2; exit 1; }
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --gha)
      USE_GHA=1
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "auto-push: unknown option: $1" >&2
      usage 1
      ;;
  esac
done

die() {
  echo "auto-push FAILED: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed"
}

require_cmd git
require_cmd gh

if ! git diff --quiet || ! git diff --cached --quiet; then
  die "working tree has uncommitted changes — commit or stash first"
fi

if [[ -n "$TARGET_BRANCH" ]]; then
  CURRENT="$(git branch --show-current)"
  if [[ "$CURRENT" != "$TARGET_BRANCH" ]]; then
    echo "Checking out $TARGET_BRANCH ..."
    git checkout "$TARGET_BRANCH" || die "could not checkout $TARGET_BRANCH"
  fi
fi

BRANCH="$(git branch --show-current)"
[[ -n "$BRANCH" ]] || die "detached HEAD — checkout a feature branch first"

if [[ "$BRANCH" != feat/* ]]; then
  die "must be on a feat/* branch (current: $BRANCH)"
fi

SPEC_PATH="tasks/${BRANCH}/SPECS.md"
[[ -f "$SPEC_PATH" ]] || die "missing spec archive: $SPEC_PATH (copy unit spec before shipping)"

echo "=== auto-push.sh ==="
echo "Branch: $BRANCH"
echo "Spec:   $SPEC_PATH"
echo "Base:   $BASE_BRANCH"

echo "Running verify..."
bash scripts/verify.sh

TEMPLATE=".github/pull_request_template.md"
[[ -f "$TEMPLATE" ]] || die "missing $TEMPLATE"

PR_BODY="$(sed "s|tasks/feat/<branch-name>/SPECS.md|${SPEC_PATH}|g" "$TEMPLATE")"
PR_TITLE="$(git log -1 --pretty=%s)"
[[ -n "$PR_TITLE" ]] || PR_TITLE="${BRANCH##feat/}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo ""
  echo "Dry run OK — preflight passed."
  echo "Would push: origin $BRANCH"
  echo "Would ensure PR: base=$BASE_BRANCH title=$PR_TITLE"
  if [[ "$USE_GHA" -eq 1 ]]; then
    echo "Would trigger workflow: auto-push.yml branch=$BRANCH"
  fi
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  die "gh is not authenticated — run: gh auth login (human fallback; see docs/AUTO-PUSH.md)"
fi

echo "Pushing to origin/$BRANCH ..."
git push -u origin "$BRANCH"

if gh pr view "$BRANCH" --json url --jq .url >/dev/null 2>&1; then
  PR_URL="$(gh pr view "$BRANCH" --json url --jq .url)"
  echo "PR already open: $PR_URL"
else
  echo "Opening pull request ..."
  PR_URL="$(gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "$PR_TITLE" --body "$PR_BODY")"
  echo "PR opened: $PR_URL"
fi

if [[ "$USE_GHA" -eq 1 ]]; then
  echo "Triggering GHA auto-push workflow (verify + ensure PR on runner) ..."
  gh workflow run auto-push.yml -f "branch=${BRANCH}"
  echo "Workflow dispatched — check: gh run list --workflow=auto-push.yml"
fi

echo "Next: wait for CI, then GHA review. Human merges."
