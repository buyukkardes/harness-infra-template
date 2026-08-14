# AGENTS.md — agent router

**Read first:** `docs/llms.txt`

## Project

Configured in `harness.config.yaml`. Product work: `specs/SPECS.md` (your spec, not harness meta).

## Session protocol

1. `bash scripts/init.sh`
2. Read `state/blocked.md` — stop if blocked
3. Read `specs/SPECS.md` — highest-priority unchecked unit
4. Implement → `bash scripts/verify.sh` → tick spec → `state/progress.txt` → commit
5. `feat/*`: `auto-push.sh --dry-run` then `auto-push.sh`; human merges

## Harness docs (not product)

| Topic | File |
|-------|------|
| Framework | `docs/HARNESS.md` |
| PRs | `docs/PR-WORKFLOW.md` |
| Parallel | `docs/ORCHESTRATION.md` |
| Conflicts | `harness/conflict-agent-prompt.md` |
| Review fix | `harness/review-fix-prompt.md` |

## Boundaries

One unit per session. Verify before commit. No harness invention in product spec — harness changes go here + docs.
