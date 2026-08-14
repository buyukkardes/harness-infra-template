# Work board (Phase 6 Unit 6.13)

**Source of truth:** `specs/SPECS.md` — this board is a **view only** (Tip 29). Do not duplicate spec text here.

**GitHub:** [Open PRs](https://github.com/buyukkardes/__PROJECT_NAME__/pulls) · [Actions CI](https://github.com/buyukkardes/__PROJECT_NAME__/actions)

---

## How to use

| Column | Meaning |
|--------|---------|
| **Backlog** | Unchecked units in `specs/SPECS.md` |
| **In progress** | Agent session or open `feat/*` branch |
| **In review** | PR open; wait for CI + GHA review comment |
| **Done** | Merged; ticked on `main` |

Update this file manually after each session (or when opening/merging PRs).

---

## Current focus

| Status | Unit | Notes |
|--------|------|-------|
| Done | Phase 6.1–6.11 | Pipeline + doc/entropy |
| N/A | 6.12 Parallel PRs | Deferred → **Phase 7 orchestration** |
| Done | 6.13 Work board | This file |
| Done | Phase 7.1–7.6 | Orchestrator, kickoff, E2E (PRs #6–#7) |
| Done | Phase 8 v1 | Harness automation complete |
| Done | **Phase 9 v1** | UI + pagination API (PRs #15–#20) |
| Done | **Phase 10 v1** | 3× parallel workers + merge cascade (PRs #23–#25) |
| **Next** | **Phase 10+** | Optional — note tags UI, worktrees, SDK batch |

---

## Pipeline reminder

```text
spec → orchestrator → worker(s) → commit → auto-push.sh → CI → C1 review → human merge
```

See `docs/PR-WORKFLOW.md`, `docs/GHA-PR-REVIEW.md`.

---

## Optional: GitHub Project

To use GitHub Projects instead of this markdown board: create a board linked to this repo, one card per `specs/SPECS.md` unit, link card → spec section. Keep checkboxes authoritative in `specs/SPECS.md`.
