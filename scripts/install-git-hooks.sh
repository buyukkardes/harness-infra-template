#!/usr/bin/env bash
# Install version-controlled git hooks for __PROJECT_NAME__.
# Called from scripts/init.sh; safe to run manually after clone.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "WARN: not a git repo — skipping hook install"
  exit 0
fi

HOOK_SRC="$ROOT/scripts/git-hooks/pre-commit"
chmod +x "$HOOK_SRC"

# Prefer core.hooksPath so hooks stay in version control (no copy into .git/hooks).
if git config core.hooksPath scripts/git-hooks; then
  echo "Git hook: core.hooksPath → scripts/git-hooks"
  exit 0
fi

# Fallback: copy into .git/hooks when config write is unavailable.
if cp "$HOOK_SRC" "$ROOT/.git/hooks/pre-commit" && chmod +x "$ROOT/.git/hooks/pre-commit"; then
  echo "Git hook: pre-commit copied to .git/hooks/"
  exit 0
fi

echo "WARN: could not install git hooks — run manually: bash scripts/install-git-hooks.sh"
exit 0
