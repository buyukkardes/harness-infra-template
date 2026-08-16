# Harness framework

This repo **is** the harness. Product code lives in `src/`, `public/`, driven by `specs/SPECS.md`.

## Architecture (visual)

| Diagram | What it shows |
|---------|----------------|
| **[harness-template-architecture.svg](harness-template-architecture.svg)** | Components: **your inputs**, **what ships with the template**, **your outputs & responsibilities** |
| **[harness-template-workflow.svg](harness-template-workflow.svg)** | Journey: setup → build loop → ship → merge (manual agents today) |

Pair with **[SETUP.md](SETUP.md)** for the setup checklist and **[PR-WORKFLOW.md](PR-WORKFLOW.md)** for feat-branch shipping.

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
