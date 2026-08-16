#!/usr/bin/env bash
# Set project identity after cloning the template (or "Use this template" on GitHub).
#
# Usage:
#   bash scripts/setup-project.sh <project-name> ["Project description"]
#
# Example:
#   bash scripts/setup-project.sh task-notes "Task Notes API"
#
# Updates: harness.config.yaml, package.json, package-lock.json name fields,
# and __PROJECT_NAME__ placeholders in docs/harness prompts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

NAME="${1:-}"
DESC="${2:-Spec-driven project using the agent harness}"

if [[ -z "$NAME" ]]; then
  echo "Usage: bash scripts/setup-project.sh <project-name> [description]" >&2
  exit 1
fi

# npm package names: lowercase, hyphens
PKG_NAME="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9._-/')"
PKG_NAME="${PKG_NAME//\//-}"

substitute() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if [[ "$(uname)" == Darwin ]]; then
    sed -i '' \
      -e "s/__PROJECT_NAME__/${NAME}/g" \
      -e "s/__PROJECT_DESCRIPTION__/${DESC}/g" \
      -e "s/\"name\": \"harness-lab\"/\"name\": \"${PKG_NAME}\"/g" \
      -e "s/\"name\": \"my-project\"/\"name\": \"${PKG_NAME}\"/g" \
      -e "s/\"name\": \"harness-lab\",/\"name\": \"${PKG_NAME}\",/g" \
      "$f"
  else
    sed -i \
      -e "s/__PROJECT_NAME__/${NAME}/g" \
      -e "s/__PROJECT_DESCRIPTION__/${DESC}/g" \
      -e "s/\"name\": \"harness-lab\"/\"name\": \"${PKG_NAME}\"/g" \
      -e "s/\"name\": \"my-project\"/\"name\": \"${PKG_NAME}\"/g" \
      -e "s/\"name\": \"harness-lab\",/\"name\": \"${PKG_NAME}\",/g" \
      "$f"
  fi
}

echo "=== setup-project.sh ==="
echo "Project:     $NAME"
echo "Package:     $PKG_NAME"
echo "Description: $DESC"

# harness.config.yaml
cat > harness.config.yaml <<EOF
project:
  name: "${NAME}"
  description: "${DESC}"

stack:
  profile: node-ts

verify:
  install: "npm ci"
  test: "npm test"
  build: "npm run build"

github:
  default_branch: main
EOF

# package.json description
if [[ -f package.json ]]; then
  substitute package.json
  node -e "
    const fs=require('fs');
    const p=JSON.parse(fs.readFileSync('package.json','utf8'));
    p.name='${PKG_NAME}';
    p.description='${DESC}';
    fs.writeFileSync('package.json', JSON.stringify(p,null,2)+'\n');
  " 2>/dev/null || substitute package.json
fi

substitute package-lock.json

while IFS= read -r -d '' f; do
  case "$f" in
    *.md|*.txt|*.sh|*.mdc|*.yaml|*.yml) substitute "$f" ;;
  esac
done < <(find . -type f \
  ! -path './node_modules/*' \
  ! -path './.git/*' \
  ! -path './dist/*' \
  -print0)

# Fix nested harness/ from old bootstraps — prompts must be harness/*.md not harness/harness/*
if [[ -d harness/harness ]]; then
  echo "WARN: moving prompts from harness/harness/ → harness/"
  mv harness/harness/* harness/ 2>/dev/null || true
  rmdir harness/harness 2>/dev/null || true
fi

echo ""
echo "setup-project OK"
echo ""
echo "Next:"
echo "  1. Copy your product spec → specs/SPECS.md"
echo "  2. git remote set-url origin git@github.com:YOUR_USER/${PKG_NAME}.git  (after creating repo)"
echo "  3. npm ci && bash scripts/verify.sh"
echo "  4. git add -A && git commit -m \"chore: configure project ${NAME}\""
