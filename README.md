# harness-infra-template

Reusable **agent harness** for spec-driven development. No product domain — bring your own `specs/SPECS.md`.

## Quick start

1. Clone this repo (or use as GitHub template)
2. Set `harness.config.yaml` — project name, description
3. Copy your product spec → `specs/SPECS.md` (see [task-notes-spec](https://github.com/buyukkardes/task-notes-spec) for an example)
4. `git init && bash scripts/init.sh`
5. Agent sessions via `harness/session-prompt.md`

## Includes

- Session protocol (`AGENTS.md`, `state/`, `harness/` prompts)
- Verification gate (`scripts/verify.sh`, pre-commit hook)
- PR pipeline (`auto-push.sh`, GHA CI + C1 review)
- Parallel workers (`orchestrator-prompt.md`, `ORCHESTRATION.md`)
- Conflict agent + rebase (`conflict-agent-prompt.md`, `rebase-parallel-pr.sh`)

## Milestone 2

Checkout this repo, copy [task-notes-spec/SPECS.md](../task-notes-spec/SPECS.md), rebuild Task Notes with agents.

Built from [harness-lab](https://github.com/buyukkardes/harness-lab) Phase 10 v1.
