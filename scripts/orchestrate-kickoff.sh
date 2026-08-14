#!/usr/bin/env bash
# Phase 7 single-trigger kickoff (v1).
#
# Reads specs/SPECS.md, prints the orchestrator prompt, and surfaces worker briefs
# under state/orchestrator/ when the orchestrator has already written them.
#
# Usage (from repo root):
#   bash scripts/orchestrate-kickoff.sh           # kickoff output (prompt + briefs or next steps)
#   bash scripts/orchestrate-kickoff.sh --open    # also open brief files in the default editor/viewer
#
# Does NOT commit, push, or implement code.
#
# Future automation (Phase 7+): Cursor SDK or Cloud Agent batch APIs could spawn the
# orchestrator and worker agents from this entry point. v1 is manual chat kickoff only;
# see harness/orchestrator-prompt.md and docs/ORCHESTRATION.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ORCH_DIR="state/orchestrator"
WORKER_A="${ORCH_DIR}/worker-a.md"
WORKER_B="${ORCH_DIR}/worker-b.md"
ORCH_PROMPT="harness/orchestrator-prompt.md"
SPECS="specs/SPECS.md"
OPEN_BRIEFS=0

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --open)
      OPEN_BRIEFS=1
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "orchestrate-kickoff: unknown option: $1" >&2
      usage 1
      ;;
  esac
done

die() {
  echo "orchestrate-kickoff FAILED: $*" >&2
  exit 1
}

brief_field() {
  local file="$1" key="$2"
  sed -n "s/^\*\*${key}:\*\* //p" "$file" | head -1
}

unit_id_from_brief() {
  local unit_line
  unit_line="$(brief_field "$1" "Unit")"
  if [[ "$unit_line" =~ Unit\ ([0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "?"
  fi
}

open_file() {
  local path="$1"
  if command -v open >/dev/null 2>&1; then
    open "$path"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$path"
  else
    echo "WARN: no open/xdg-open — view manually: $path" >&2
  fi
}

check_blocked() {
  if [[ ! -f state/blocked.md ]]; then
    return 0
  fi
  local blocked_content
  blocked_content="$(sed -n '/^---$/,$p' state/blocked.md | sed '/<!--/,/-->/d' | grep '^## ' || true)"
  if [[ -n "$blocked_content" ]]; then
    echo "BLOCKED: state/blocked.md has content — resolve before kickoff." >&2
    cat state/blocked.md >&2
    echo "KICKOFF_EXIT=blocked"
    exit 2
  fi
}

list_unchecked_units() {
  local current=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^###\ Unit\ ([0-9]+\.[0-9]+) ]]; then
      current="${BASH_REMATCH[1]}"
    elif [[ -n "$current" && "$line" =~ ^-\ \[\ \] ]]; then
      echo "Unit $current"
      current=""
    elif [[ "$line" =~ ^###\ Unit ]]; then
      current=""
    fi
  done < "$SPECS"
}

print_orchestrator_prompt() {
  echo "=== Orchestrator prompt ==="
  echo "Source: $ORCH_PROMPT"
  echo ""
  if [[ ! -f "$ORCH_PROMPT" ]]; then
    die "missing $ORCH_PROMPT"
  fi
  # Copy-paste block between the first pair of ``` fences under "## Prompt (copy below)"
  awk '
    /^## Prompt \(copy below\)/ { found = 1; next }
    found && /^```$/ {
      if (!in_block) { in_block = 1; next }
      else { exit }
    }
    found && in_block { print }
  ' "$ORCH_PROMPT"
}

print_brief() {
  local label="$1" file="$2"
  echo ""
  echo "=== Worker brief — $label ==="
  echo "File: $file"
  echo "---"
  cat "$file"
  echo "---"
}

check_blocked

[[ -f "$SPECS" ]] || die "missing $SPECS"

echo "=== orchestrate-kickoff.sh ==="
echo "Root: $ROOT"
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

echo "=== Unchecked units (spec snapshot) ==="
UNCHECKED="$(list_unchecked_units || true)"
if [[ -z "$UNCHECKED" ]]; then
  echo "(none — all units checked or no open checkboxes)"
else
  echo "$UNCHECKED"
fi
echo ""

BRIEFS_READY=0
if [[ -f "$WORKER_A" && -f "$WORKER_B" ]]; then
  BRIEFS_READY=1
  UNIT_A="$(unit_id_from_brief "$WORKER_A")"
  UNIT_B="$(unit_id_from_brief "$WORKER_B")"
  BRANCH_A="$(brief_field "$WORKER_A" "Branch")"
  BRANCH_B="$(brief_field "$WORKER_B" "Branch")"
  TITLE_A="$(brief_field "$WORKER_A" "Unit")"
  TITLE_B="$(brief_field "$WORKER_B" "Unit")"

  echo "=== Kickoff artifacts (two parallel units) ==="
  echo "Worker unit IDs: $UNIT_A, $UNIT_B"
  echo ""
  echo "| Worker | Unit | Branch | Brief file |"
  echo "|--------|------|--------|------------|"
  echo "| A | $TITLE_A | $BRANCH_A | $WORKER_A |"
  echo "| B | $TITLE_B | $BRANCH_B | $WORKER_B |"
  echo ""

  print_brief "Worker A" "$WORKER_A"
  print_brief "Worker B" "$WORKER_B"

  if [[ "$OPEN_BRIEFS" -eq 1 ]]; then
    open_file "$WORKER_A"
    open_file "$WORKER_B"
  fi

  echo ""
  echo "Human next steps:"
  echo "  1. Open two worker chats; paste harness/session-prompt.md + unit constraints from each brief."
  echo "  2. When both branches are committed: bash scripts/ship-pr.sh on each."
  echo "  3. Wait for CI + GHA review; human merges both PRs."
  echo ""
  echo "KICKOFF_EXIT=ready"
else
  echo "=== Worker briefs not found ==="
  echo "Expected: $WORKER_A and $WORKER_B"
  echo ""
  echo "Run an orchestrator session first (planning only — do not implement):"
  echo "  1. Copy harness/orchestrator-prompt.md into a fresh chat"
  echo "  2. Orchestrator writes briefs to $WORKER_A and $WORKER_B"
  echo "  3. Re-run: bash scripts/orchestrate-kickoff.sh"
  echo ""
  print_orchestrator_prompt
  echo ""
  echo "KICKOFF_EXIT=need_briefs"
fi

exit 0
