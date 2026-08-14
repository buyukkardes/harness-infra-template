#!/usr/bin/env bash
# Post a structured PR review comment from GitHub Actions (Phase 6 Path C, Phase 8 C2).
# Runs after the verify job succeeds on pull_request events.
#
# Required env: PR_NUMBER, HEAD_REF, GH_TOKEN (or gh auth)
# Optional env: HEAD_SHA, GITHUB_REPOSITORY, REVIEW_MODE=c1 (force checklist)
# C2 env: LLM_API_KEY, LLM_PROVIDER, LLM_MODEL, LLM_MAX_DIFF_CHARS, LLM_API_URL
#
# C2 uses direct LLM HTTP API (not MCP). Falls back to C1 if key missing or API fails.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck source=scripts/lib/config.sh
source "$ROOT/scripts/lib/config.sh"
harness_load_config "$ROOT"

# shellcheck source=scripts/gha-pr-review-llm.sh
source "$ROOT/scripts/gha-pr-review-llm.sh"

PR_NUMBER="${PR_NUMBER:?PR_NUMBER required}"
HEAD_REF="${HEAD_REF:?HEAD_REF required}"
HEAD_SHA="${HEAD_SHA:-unknown}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "gha-pr-review: $1 required" >&2
    exit 1
  }
}

require_cmd gh

SPEC_PATH="tasks/${HEAD_REF}/SPECS.md"
VERDICT="APPROVE"
BLOCKERS=()
SUGGESTIONS=()
SPEC_LINES=()
TEST_LINES=()
SCOPE_LINES=()

# --- Spec archive ---
if [[ -f "$SPEC_PATH" ]]; then
  SPEC_LINES+=("Spec archive present at \`${SPEC_PATH}\`")
  if grep -q "^\*\*Verification:\*\*" "$SPEC_PATH"; then
    ver="$(grep -A1 "^\*\*Verification:\*\*" "$SPEC_PATH" | tail -1 | sed 's/^[[:space:]]*//')"
    SPEC_LINES+=("Verification line: ${ver}")
  fi
else
  VERDICT="REQUEST CHANGES"
  BLOCKERS+=("Missing spec archive \`${SPEC_PATH}\` — copy unit spec before shipping (Tip 10)")
  SPEC_LINES+=("Spec archive **not found**")
fi

# --- Diff scope ---
CHANGED=()
while IFS= read -r line; do
  [[ -n "$line" ]] && CHANGED+=("$line")
done < <(gh pr diff "$PR_NUMBER" --name-only 2>/dev/null || true)

src_changed=0
tests_changed=0

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  SCOPE_LINES+=("No changed files reported in PR diff")
else
  SCOPE_LINES+=("${#CHANGED[@]} file(s) changed:")
  max=20
  i=0
  for f in "${CHANGED[@]}"; do
    if [[ $i -lt $max ]]; then
      SCOPE_LINES+=("- \`${f}\`")
    fi
    i=$((i + 1))
  done
  if [[ ${#CHANGED[@]} -gt $max ]]; then
    SCOPE_LINES+=("- _(… ${#CHANGED[@]} total)_")
  fi
  for f in "${CHANGED[@]}"; do
    [[ "$f" == src/* ]] && src_changed=1
    [[ "$f" == tests/* ]] && tests_changed=1
  done
fi

if [[ "$HEAD_REF" == feat/* ]]; then
  SCOPE_LINES+=("Branch follows \`feat/*\` naming")
else
  SUGGESTIONS+=("Branch \`${HEAD_REF}\` is not \`feat/*\` — use for Phase 5+ feature PRs")
fi

# --- Tests vs src ---
if [[ $src_changed -eq 1 && $tests_changed -eq 0 ]]; then
  VERDICT="REQUEST CHANGES"
  BLOCKERS+=("\`src/\` changed but no \`tests/\` files in diff — add tests per spec verification")
  TEST_LINES+=("**Gap:** code changed without test file changes")
elif [[ $src_changed -eq 1 && $tests_changed -eq 1 ]]; then
  TEST_LINES+=("\`src/\` and \`tests/\` both changed")
elif [[ $src_changed -eq 0 ]]; then
  TEST_LINES+=("No \`src/\` changes — harness/docs-only PR (tests may not apply)")
fi

build_c1_comment() {
  echo "## Agent PR review"
  echo ""
  echo "**Verdict:** ${VERDICT}"
  echo ""
  echo "**Branch:** \`${HEAD_REF}\`"
  echo "**Spec:** \`${SPEC_PATH}\`"
  echo "**Commit:** \`${HEAD_SHA}\`"
  echo "**Reviewer:** GitHub Actions (Path C — \`scripts/gha-pr-review.sh\`, C1 checklist)"
  echo ""
  echo "### Spec alignment"
  if [[ ${#SPEC_LINES[@]} -eq 0 ]]; then
    echo "- (none)"
  else
    for line in "${SPEC_LINES[@]}"; do
      echo "- ${line}"
    done
  fi
  echo ""
  echo "### Tests & verification"
  if [[ ${#TEST_LINES[@]} -eq 0 ]]; then
    echo "- (none)"
  else
    for line in "${TEST_LINES[@]}"; do
      echo "- ${line}"
    done
  fi
  echo ""
  echo "### Scope"
  if [[ ${#SCOPE_LINES[@]} -eq 0 ]]; then
    echo "- (none)"
  else
    for line in "${SCOPE_LINES[@]}"; do
      if [[ "$line" == -* ]] || [[ "$line" == _* ]]; then
        echo "${line}"
      else
        echo "- ${line}"
      fi
    done
  fi
  echo ""
  echo "### CI"
  echo "- **verify** (CI workflow): pass (this comment runs only after verify succeeds)"
  echo ""
  if [[ ${#BLOCKERS[@]} -gt 0 ]]; then
    echo "### Blockers"
    n=1
    for b in "${BLOCKERS[@]}"; do
      echo "${n}. ${b}"
      n=$((n + 1))
    done
    echo ""
  fi
  if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
    echo "### Suggestions (non-blocking)"
    for s in "${SUGGESTIONS[@]}"; do
      echo "- ${s}"
    done
    echo ""
  fi
  echo "---"
  echo "**Human merges** — this review does not merge the PR."
  echo ""
  echo "_Automated checklist review (C1). Diff-aware review: \`harness/reviewer-pr-prompt.md\` locally (Path B). Optional GHA C2: set \`LLM_API_KEY\` secret (Phase 8.3)._"
}

body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

review_mode="C1"
if llm_review_enabled; then
  echo "LLM review enabled (provider=${LLM_PROVIDER:-openai}, model=$(llm_default_model))..."
  if llm_generate_comment "$SPEC_PATH" "$PR_NUMBER" "$HEAD_REF" "$HEAD_SHA" "$VERDICT" >"$body_file"; then
    llm_enforce_c1_verdict "$body_file" "$VERDICT"
    review_mode="C2"
    echo "Using C2 LLM review body."
  else
    echo "LLM review failed — fallback to C1." >&2
    build_c1_comment >"$body_file"
  fi
else
  echo "C1 checklist review (LLM_API_KEY not set or REVIEW_MODE=c1)."
  build_c1_comment >"$body_file"
fi

echo "Posting PR review (${review_mode}, c1_verdict=${VERDICT}) on PR #${PR_NUMBER}..."
gh pr comment "$PR_NUMBER" --body-file "$body_file"
echo "Review comment posted (${review_mode})."
