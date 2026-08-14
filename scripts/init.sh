#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/lib/config.sh
source "$ROOT/scripts/lib/config.sh"
harness_load_config "$ROOT"
echo "=== harness init ==="
echo "Project: $PROJECT_NAME"
echo "Root: $ROOT"
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""
if command -v node >/dev/null 2>&1; then echo "Node: $(node -v)"; else echo "WARN: node not found"; fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Branch: $(git branch --show-current 2>/dev/null || echo detached)"
  git diff --quiet && git diff --cached --quiet && echo "Git: clean working tree" || echo "WARN: uncommitted changes"
  bash "$ROOT/scripts/install-git-hooks.sh"
else
  echo "WARN: not a git repo — run: git init"
fi
if [[ -f state/blocked.md ]]; then
  BLOCKED=$(sed -n '/^---$/,$p' state/blocked.md | sed '/<!--/,/-->/d' | grep '^## ' || true)
  [[ -z "$BLOCKED" ]] || { echo "BLOCKED"; cat state/blocked.md; exit 2; }
fi
echo ""; echo "=== Spec progress (unchecked) ==="
grep -n '\- \[ \]' specs/SPECS.md 2>/dev/null | head -15 || echo "(none)"
echo ""; echo "=== Recent handoff ==="
tail -n 8 state/progress.txt 2>/dev/null || echo "(none)"
echo ""; echo "init OK — read AGENTS.md and specs/SPECS.md"
