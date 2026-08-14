# GitHub Actions PR review (Path C)

Phase 6 Unit 6.5 — automated review **without** Cursor linked to personal GitHub.

**How it works:** After the **verify** job passes on a pull request, the **pr-review** job runs `scripts/gha-pr-review.sh` and posts a comment via `GITHUB_TOKEN` / `gh pr comment`.

**No Cursor GitHub integration required.**

**Default (this repo):** **C1** checklist — no API keys. Diff-aware review uses **Path B** (`harness/reviewer-pr-prompt.md` in a local Cursor chat). **C2** in GHA is optional if you add `LLM_API_KEY` later.

---

## Pipeline

```text
Local agent → auto-push.sh → CI verify → pr-review job → PR comment → human merge
```

Workflow: `.github/workflows/ci.yml` (jobs `verify` + `pr-review`).

---

## Review modes

| Mode | When | Output |
|------|------|--------|
| **C1** *(default)* | No `LLM_API_KEY` secret, API/diff failure, or `REVIEW_MODE=c1` | Scripted checklist |
| **C2** *(optional)* | `LLM_API_KEY` set + API success | LLM diff-aware review (same comment format) |
| **Path B** *(recommended for diff-aware)* | Local Cursor chat after CI green | Uses company Cursor — no GitHub secret |

C1 guardrails always run first — if C1 verdict is `REQUEST CHANGES`, C2 cannot post `APPROVE` (verdict overridden).

**Not MCP:** C2 calls the LLM **HTTP API** from the GHA runner using `gh pr diff` + archived spec. No Cursor MCP servers in CI.

---

## C1 — scripted checklist

| Check | Fail verdict |
|-------|----------------|
| `tasks/<branch>/SPECS.md` exists | REQUEST CHANGES |
| `src/` changed → `tests/` should change too | REQUEST CHANGES |
| CI verify job passed | (job only runs on success) |
| Branch naming `feat/*` | suggestion only |

Implementation: `scripts/gha-pr-review.sh`  
LLM layer: `scripts/gha-pr-review-llm.sh`

---

## C2 — LLM review (Phase 8.3)

### GitHub setup

1. Repo → **Settings → Secrets and variables → Actions**
2. **New repository secret:** `LLM_API_KEY` (OpenAI or Anthropic key)
3. Optional **Variables:**
   - `LLM_PROVIDER` — `openai` (default) or `anthropic`
   - `LLM_MODEL` — override default (`gpt-4o-mini` / `claude-3-5-haiku-20241022`)
   - `LLM_MAX_DIFF_CHARS` — default `48000`; larger diffs fall back to C1

### Behaviour

- Fetches PR diff via `gh pr diff`
- Reads `tasks/<branch>/SPECS.md` and rubric from `harness/reviewer-pr-prompt.md` (embedded in prompt)
- Posts structured **Agent PR review** comment
- On API error, timeout, or oversized diff → **fallback C1** (logged in job output)

### Cost / limits

See `state/tech-debt.md` — token usage scales with diff size; defaults favour small/cheap models.

---

## Account split (company Cursor + personal GitHub)

| Component | Account |
|-----------|---------|
| Repo + GHA + PR comments | Personal GitHub |
| Local implement agent | Company Cursor (local workspace) |
| Cursor Automations (Path A) | Not used — repo not on company GitHub |
| LLM API key | Your provider account (secret in GitHub, not in repo) |

---

## Test plan

### C1 (no secret)

1. Open a `feat/*` PR with `tasks/<branch>/SPECS.md`.
2. Wait for **verify** + **pr-review**.
3. Comment footer says **C1**; checklist bullets only.

### C2 (after `LLM_API_KEY` secret)

1. Add secret (above).
2. Open or re-push a `feat/*` PR with a real diff.
3. Comment **Reviewer** line should say **C2 (LLM)** with diff-specific bullets in Spec alignment / Scope.

**Force C1 in CI:** set `REVIEW_MODE=c1` in workflow env (debug only).

### Local dry-run

Requires personal `gh auth` and an open PR:

```bash
export PR_NUMBER=8
export HEAD_REF=feat/your-branch
export HEAD_SHA="$(git rev-parse HEAD)"
bash scripts/gha-pr-review.sh                    # C1 if no key
export LLM_API_KEY="sk-..."                      # never commit
export LLM_PROVIDER=openai
bash scripts/gha-pr-review.sh                    # C2 (posts comment!)
```

Use a test PR — `bash scripts/e2e-auto-push.sh single` creates harness test PRs.

---

## Related

- Cursor paths (A/B): `docs/CURSOR-PR-REVIEW-AUTOMATION.md`
- Review-fix on REQUEST CHANGES: `harness/review-fix-prompt.md`, `docs/ORCHESTRATION.md`
- Review rubric: `harness/reviewer-pr-prompt.md`
- Ship: `scripts/auto-push.sh`
- Spec: `specs/SPECS.md` Units 6.5, 8.3
