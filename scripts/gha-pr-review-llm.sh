#!/usr/bin/env bash
# LLM layer for GHA PR review (Phase 8 Unit 8.3 — C2).
# Sourced by scripts/gha-pr-review.sh — not run directly.
#
# Env:
#   LLM_API_KEY          — required for C2
#   LLM_PROVIDER         — openai (default) | anthropic
#   LLM_MODEL            — provider-specific default if unset
#   LLM_MAX_DIFF_CHARS   — fallback to C1 if diff larger (default 48000)
#   LLM_API_URL          — optional override
#
# Not MCP — direct HTTP from the GHA runner + gh pr diff.
set -euo pipefail

llm_review_enabled() {
  [[ -n "${LLM_API_KEY:-}" ]] && [[ "${REVIEW_MODE:-}" != "c1" ]]
}

llm_default_model() {
  case "${LLM_PROVIDER:-openai}" in
    anthropic) echo "${LLM_MODEL:-claude-3-5-haiku-20241022}" ;;
    *) echo "${LLM_MODEL:-gpt-4o-mini}" ;;
  esac
}

llm_fetch_diff() {
  local pr_number="$1"
  local max_chars="${LLM_MAX_DIFF_CHARS:-48000}"
  local diff_file
  diff_file="$(mktemp)"
  if ! gh pr diff "$pr_number" >"$diff_file" 2>/dev/null; then
    rm -f "$diff_file"
    return 1
  fi
  local size
  size="$(wc -c <"$diff_file" | tr -d ' ')"
  if [[ "$size" -gt "$max_chars" ]]; then
    echo "LLM: diff ${size} chars exceeds max ${max_chars} — fallback C1" >&2
    rm -f "$diff_file"
    return 1
  fi
  cat "$diff_file"
  rm -f "$diff_file"
}

llm_build_prompt() {
  local spec_path="$1"
  local head_ref="$2"
  local head_sha="$3"
  local c1_verdict="$4"
  local diff_text="$5"
  local spec_content="(missing)"
  if [[ -f "$spec_path" ]]; then
    spec_content="$(cat "$spec_path")"
  fi
  cat <<EOF
You are the PR reviewer for __PROJECT_NAME__. Output a single GitHub PR comment in markdown.

Rules:
- Do NOT merge or push. Human merges.
- Compare the PR diff to the archived spec.
- Use verdict APPROVE only if spec match, tests adequate, CI context OK, no blockers.
- If spec archive missing or src changed without tests, use REQUEST CHANGES.
- C1 scripted verdict is: ${c1_verdict} — do not APPROVE if C1 is REQUEST CHANGES unless you explain blockers are false positives (rare).

Use EXACTLY this structure (fill in bullets):

## Agent PR review

**Verdict:** APPROVE | REQUEST CHANGES | BLOCKED (CI)

**Branch:** \`${head_ref}\`
**Spec:** \`${spec_path}\`
**Commit:** \`${head_sha}\`
**Reviewer:** GitHub Actions C2 (LLM via \`scripts/gha-pr-review.sh\`)

### Spec alignment
- (bullets: cite specific files/lines from diff vs spec)

### Tests & verification
- (bullets: diff-specific test coverage gaps or strengths)

### Scope
- (bullets: unrelated changes or clean scope)

### CI
- verify job passed before this review ran

### Blockers
- (numbered list, or "None")

### Suggestions (non-blocking)
- (bullets, or omit section if none)

---
**Human merges** — this review does not merge the PR.

_Automated C2 review (LLM + C1 guardrails). Fallback: C1 checklist if API unavailable._

---

## Archived spec

\`\`\`markdown
${spec_content}
\`\`\`

---

## PR diff

\`\`\`diff
${diff_text}
\`\`\`
EOF
}

llm_call_openai() {
  local prompt="$1"
  local model="$2"
  local url="${LLM_API_URL:-https://api.openai.com/v1/chat/completions}"
  local payload_file response_file
  payload_file="$(mktemp)"
  response_file="$(mktemp)"
  jq -n \
    --arg model "$model" \
    --arg prompt "$prompt" \
    '{
      model: $model,
      temperature: 0.2,
      messages: [
        {role: "system", content: "You write concise, accurate GitHub PR review comments in markdown."},
        {role: "user", content: $prompt}
      ]
    }' >"$payload_file"
  local http_code
  http_code="$(curl -sS -o "$response_file" -w "%{http_code}" \
    "$url" \
    -H "Authorization: Bearer ${LLM_API_KEY}" \
    -H "Content-Type: application/json" \
    -d @"$payload_file")" || {
    rm -f "$payload_file" "$response_file"
    return 1
  }
  if [[ "$http_code" != "200" ]]; then
    echo "LLM OpenAI HTTP ${http_code}: $(head -c 500 "$response_file")" >&2
    rm -f "$payload_file" "$response_file"
    return 1
  fi
  jq -r '.choices[0].message.content // empty' "$response_file"
  rm -f "$payload_file" "$response_file"
}

llm_call_anthropic() {
  local prompt="$1"
  local model="$2"
  local url="${LLM_API_URL:-https://api.anthropic.com/v1/messages}"
  local payload_file response_file
  payload_file="$(mktemp)"
  response_file="$(mktemp)"
  jq -n \
    --arg model "$model" \
    --arg prompt "$prompt" \
    '{
      model: $model,
      max_tokens: 2048,
      messages: [{role: "user", content: $prompt}]
    }' >"$payload_file"
  local http_code
  http_code="$(curl -sS -o "$response_file" -w "%{http_code}" \
    "$url" \
    -H "x-api-key: ${LLM_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d @"$payload_file")" || {
    rm -f "$payload_file" "$response_file"
    return 1
  }
  if [[ "$http_code" != "200" ]]; then
    echo "LLM Anthropic HTTP ${http_code}: $(head -c 500 "$response_file")" >&2
    rm -f "$payload_file" "$response_file"
    return 1
  fi
  jq -r '.content[0].text // empty' "$response_file"
  rm -f "$payload_file" "$response_file"
}

llm_generate_comment() {
  local spec_path="$1"
  local pr_number="$2"
  local head_ref="$3"
  local head_sha="$4"
  local c1_verdict="$5"

  require_cmd jq
  require_cmd curl

  local diff_text
  diff_text="$(llm_fetch_diff "$pr_number")" || return 1

  local prompt model content
  prompt="$(llm_build_prompt "$spec_path" "$head_ref" "$head_sha" "$c1_verdict" "$diff_text")"
  model="$(llm_default_model)"

  case "${LLM_PROVIDER:-openai}" in
    anthropic) content="$(llm_call_anthropic "$prompt" "$model")" ;;
    *) content="$(llm_call_openai "$prompt" "$model")" ;;
  esac

  [[ -n "$content" ]] || {
    echo "LLM: empty response" >&2
    return 1
  }

  # Strip markdown fences if model wrapped the whole comment
  local fence
  fence=$'\`\`\`'
  content="${content#${fence}markdown}"
  content="${content#${fence}}"
  content="${content%${fence}}"

  printf '%s\n' "$content"
}

llm_enforce_c1_verdict() {
  local body_file="$1"
  local c1_verdict="$2"
  if [[ "$c1_verdict" != "APPROVE" ]]; then
    if grep -q '^\*\*Verdict:\*\*' "$body_file"; then
      sed -i.bak "s/^\*\*Verdict:\*\*.*/**Verdict:** REQUEST CHANGES (C1 guardrail)/" "$body_file"
      rm -f "${body_file}.bak"
    fi
  fi
}
