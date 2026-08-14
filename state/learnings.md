# Learnings

Reusable findings from agent sessions. After each session, skim this file — promote items into `AGENTS.md`, `.cursor/rules/`, or `docs/conventions.md`.

Format:

```markdown
## YYYY-MM-DD — short title

**Symptom:** what went wrong
**Fix:** what we changed in the harness
**Promoted to:** file path (or "pending")
```

---

## 2026-08-12 — Initial scaffold

**Symptom:** N/A (project start)
**Fix:** Created phased GETTING-STARTED.md and router AGENTS.md
**Promoted to:** docs/GETTING-STARTED.md, AGENTS.md

## 2026-08-12 — Phase 3: test-only spec units

**Symptom:** Unit 3.3 (PUT/DELETE 404) looked like it might need new route logic; handlers in `src/notes/routes.ts` already returned 404 for missing ids.
**Fix:** Before implementing, search the codebase — read existing routes/tests and confirm what is actually missing. Many Phase 3 units only add test coverage; mirror an existing test pattern (e.g. GET 404 for PUT/DELETE 404).
**Promoted to:** docs/conventions.md (Testing)

## 2026-08-12 — Phase 3: git hook install friction

**Symptom:** `bash scripts/init.sh` warns "could not install git hooks" when `git config core.hooksPath` or `.git/hooks` writes are blocked (sandbox, permissions).
**Fix:** Hook source lives at `scripts/git-hooks/pre-commit`; run `bash scripts/install-git-hooks.sh` manually after clone. Emergency bypass only: `git commit --no-verify`.
**Promoted to:** docs/conventions.md (Git)

## 2026-08-12 — Phase 3: curl QA is manual, not verify

**Symptom:** Unit 3.1 `scripts/curl-crud.sh` requires a running dev server in another terminal — it cannot run inside `bash scripts/verify.sh`.
**Fix:** Keep curl CRUD as optional manual QA (documented in script header); automated gate remains `bash scripts/verify.sh` only.
**Promoted to:** docs/conventions.md (Commands)

## 2026-08-12 — Phase 4: RALPH_EXIT=continue stops the chat

**Symptom:** After Unit 4.2 the loop chat ended with `RALPH_EXIT=continue`; felt like the loop failed or stopped early.
**Fix:** `continue` means “this unit is done, start the next iteration in a new chat.” Only `RALPH_EXIT=done` (work units 4.2–4.4 complete) or `blocked` means stop the whole loop. Meta-units 4.5–4.6 are human/checklist, not loop fodder.
**Promoted to:** docs/conventions.md (Ralph Loop)

## 2026-08-12 — Phase 4: one commit per iteration worked

**Symptom:** N/A (positive finding)
**Fix:** Three loop chats produced three commits (4.2 validation, 4.3 stats, 4.4 README) with 30 passing tests. `state/logs/` + `progress.txt` made retrospective easy.
**Promoted to:** pending (consider noting in docs/GETTING-STARTED.md Phase 4 success criteria)

## 2026-08-12 — Phase 5: PR workflow friction

**Symptom:** Agent could not `git push` or `gh pr create` from Cursor sandbox; first push to GitHub failed until empty remote repo existed; `git push origin main` rejected after human merged PRs until `git pull`; PR #3 did not auto-fill the template (template applies from `main` on *future* PRs); spec ticks belong on `main` after merge, not on the feature branch.
**Fix:** Split roles: agent branches/commits/verify locally; human pushes, opens PR, merges on GitHub, pulls `main`; agent ticks `specs/SPECS.md` and handoff on updated `main`. Document push/pull cadence in `docs/PR-WORKFLOW.md`. Archive unit spec under `tasks/<branch>/SPECS.md` before opening each PR.
**Promoted to:** docs/PR-WORKFLOW.md, AGENTS.md (PR mode)

## 2026-08-12 — Phase 6: company Cursor vs personal GitHub

**Symptom:** Cursor Automations **Select repository** only lists repos on the GitHub account linked to the Cursor login. Company Cursor + personal `buyukkardes/__PROJECT_NAME__` → repo not visible; GitHub triggers and Comment on PR cannot run on personal repo.
**Fix:** Document three paths in `docs/CURSOR-PR-REVIEW-AUTOMATION.md`: **A** same-account Cursor Automation; **B** local reviewer chat + personal `gh` after `ship-pr.sh`; **C** GitHub Actions on personal repo (Unit 6.5b). Do not assume Cursor GitHub integration matches the repo remote.
**Promoted to:** docs/CURSOR-PR-REVIEW-AUTOMATION.md, specs/SPECS.md Unit 6.5

## 2026-08-12 — Phase 6: GHA Path C PR review

**Symptom:** Path A blocked by account split; needed automated PR comment without Cursor GitHub link.
**Fix:** `pr-review` job in `ci.yml` after `verify`; `scripts/gha-pr-review.sh` posts checklist review via `GITHUB_TOKEN`. C1 scripted checks (spec archive, src/tests pairing, CI pass). Upgrade to C2 = LLM in same script later.
**Promoted to:** docs/GHA-PR-REVIEW.md, `.github/workflows/ci.yml`

## 2026-08-13 — Phase 6: full pipeline E2E on real feature (Unit 6.7)

**Symptom:** Docs-only smoke test (6.5) did not exercise `src/`+`tests/` review rules; agent `ship-pr.sh` fails in sandbox (`gh` not authenticated); human still runs one ship command after agent commit.
**Fix:** Real feature PR #5 (`GET /notes?search=`) validated full loop: agent commit → human `ship-pr.sh` → verify + pr-review on GitHub → human merge → pull `main`. GHA review correctly checks src/tests pairing. Option 2 ship protocol in AGENTS.md matches reality.
**Promoted to:** docs/PR-WORKFLOW.md, AGENTS.md, state/progress.txt

## 2026-08-13 — Phase 6: complete; parallel deferred to Phase 7

**Symptom:** Unit 6.12 (manual parallel PRs) overlaps with orchestrator vision (one kickoff, parallel workers, reviews at end).
**Fix:** Mark 6.12 N/A; add Phase 7 units 7.1–7.6 for orchestrator prompt, kickoff script, E2E. Work board via `docs/WORK-BOARD.md`. Conflict agent in Phase 7+ optional.
**Promoted to:** specs/SPECS.md Phase 7, docs/GETTING-STARTED.md, docs/WORK-BOARD.md

## 2026-08-13 — Phase 7 E2E: ship-pr on wrong branch (same shell)

**Symptom:** After parallel workers A and B committed, human ran `ship-pr.sh` twice from one terminal still checked out on Worker B's branch (`feat/orchestrate-kickoff`). Worker A's branch never appeared on GitHub — only B was pushed.
**Fix:** `ship-pr.sh` always operates on **current branch**. Before each ship: `git branch --show-current`, or one-liner `git checkout feat/<branch> && bash scripts/ship-pr.sh`. Document in orchestrator human-next-steps and worker handoffs.
**Promoted to:** docs/ORCHESTRATION.md § Human: ship each branch; docs/AUTO-PUSH.md (--branch)

## 2026-08-13 — Phase 7 E2E: parallel handoff merge conflict

**Symptom:** Both workers appended to `state/progress.txt` at the same location; second PR (#6) conflicted with main after #7 merged. Conflict markers briefly landed on `main` when merge resolution was incomplete.
**Fix:** Expected for parallel harness units sharing `progress.txt`, `specs/SPECS.md`, `docs/llms.txt`. Keep **both** append-only handoffs in chronological order. Rebase second PR onto main before merge. Phase 7+ optional: conflict-resolution agent.
**Promoted to:** docs/ORCHESTRATION.md § Merging parallel PRs

## 2026-08-14 — Phase 10: three parallel workers + merge cascade

**Symptom:** Three workers (10.2 public/, 10.3 src/notes/, 10.4 docs/) committed in parallel; merge order doc → UI → API caused rebase conflicts on `state/progress.txt` only (2nd and 3rd PR). Agent sandbox blocked `git push` / `gh` — human shipped branches. CI verify on doc PR occasionally showed long "Cleaning up orphan processes" (Node 20 deprecation warning on runner — non-fatal).
**Fix:** Disjoint file scopes worked — zero product code conflicts. Conflict agent rules (append-only progress, keep both spec ticks) sufficient. Suggested merge order: smallest harness diff first (doc → UI → API). Record PR URLs and conflict count in 10.5 handoff.
**Promoted to:** specs/SPECS.md Phase 10 success criteria, docs/ORCHESTRATION.md § Phase 10
