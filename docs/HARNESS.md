# Harness framework

This repo **is** the harness. Product code lives in `src/`, `public/`, driven by `specs/SPECS.md`.

## Layout

```text
specs/SPECS.md     ← YOUR product checklist (copy from external spec repo)
AGENTS.md          ← agent router
harness/           ← session, orchestrator, conflict, review prompts
scripts/           ← init, verify, auto-push, rebase
state/             ← progress, blocked, learnings
tasks/<branch>/    ← PR spec archives
.github/           ← CI + PR review
```

## Adding a product spec

Replace `specs/SPECS.md` with your product document. Example: [task-notes-spec](../task-notes-spec).

Do **not** add harness-development phases to the product spec — they live in this repo's docs already.
