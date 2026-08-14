# Tech debt tracker

Intentional compromises and deferred work. **Not bugs** — documented decisions so agents don't "fix" them silently.

Format:

```markdown
## Title

**Where:** file or module
**Why:** business or learning reason
**Revisit when:** condition
```

---

## In-memory store only

**Where:** `src/notes/store.ts` (Phase 2)
**Why:** Greenfield lab — avoid database setup while learning harness
**Revisit when:** Moving to brownfield project or persistence spec added

---

## Native http instead of Express

**Where:** `src/index.ts`
**Why:** Fewer dependencies; focus on harness not framework
**Revisit when:** Routing complexity grows beyond ~5 routes

---

## C2 LLM review — API cost and secrets

**Where:** `scripts/gha-pr-review.sh`, `scripts/gha-pr-review-llm.sh`, `.github/workflows/ci.yml` (Phase 8 Unit 8.3)
**Why:** C2 sends PR diff + spec to external LLM API; requires `LLM_API_KEY` GitHub secret; costs per token
**Revisit when:** Diff grows large — tune `LLM_MAX_DIFF_CHARS`, model choice, or summarize diff before LLM call
**Defaults:** `gpt-4o-mini` (OpenAI) or `claude-3-5-haiku-20241022` (Anthropic); fallback to C1 when key missing or API fails

---

## Automated push — credential scope

**Where:** Phase 8 Unit 8.2 — `docs/AUTO-PUSH.md`, `scripts/auto-push.sh`, `.github/workflows/auto-push.yml`
**Why:** Push uses personal `gh auth` locally (Path A/D) or `GITHUB_TOKEN` on GHA for verify+PR (Path B). Optional future `AUTO_PUSH_PAT` for bot-only push from runner.
**Revisit when:** Cloud Agent credentials configured; or bot push without local git push required
