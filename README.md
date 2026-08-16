# harness-infra-template

Reusable **agent harness** for spec-driven development. Clone this repo (or **Use this template** on GitHub), configure your project, add your product spec, build with agents.

**Not a product** — no domain logic. Bring your own `specs/SPECS.md`.

---

## New here? Start here

| Step | Doc / command |
|------|----------------|
| **1. First-time setup** | **[docs/SETUP.md](docs/SETUP.md)** — required reading |
| **2. Set name & package.json** | `bash scripts/setup-project.sh my-app "Description"` |
| **3. Add product spec** | Copy your `SPECS.md` → `specs/SPECS.md` |
| **4. Verify** | `npm ci && bash scripts/verify.sh` |
| **5. Build** | Fresh chat + [harness/session-prompt.md](harness/session-prompt.md) |

Example product spec: [task-notes-spec](https://github.com/buyukkardes/task-notes-spec).

---

## What you must change after checkout

Do **not** start coding with placeholder values. Minimum:

| File | Why |
|------|-----|
| `harness.config.yaml` | Project name in `init.sh` |
| `package.json` | `"name"` — shows in `npm test`, CI |
| `package-lock.json` | Must match `package.json` name |
| `git remote origin` | Still points at template until you change it |

**Easiest:** run `bash scripts/setup-project.sh <name> "<description>"` — updates all of the above.

Common mistake from replay: only editing `harness.config.yaml` and forgetting **`package.json`** (still said `harness-lab`).

---

## What's included

- **Agent protocol** — `AGENTS.md`, `state/`, `harness/` prompts
- **Gates** — `scripts/verify.sh`, pre-commit hook
- **Shipping** — `auto-push.sh`, GHA CI + C1 PR review
- **Parallel work** — orchestrator, conflict agent, rebase scripts

Details: [docs/HARNESS.md](docs/HARNESS.md).

**Architecture diagrams:** [docs/harness-template-architecture.svg](docs/harness-template-architecture.svg) (components + I/O) · [docs/harness-template-workflow.svg](docs/harness-template-workflow.svg) (setup + build loop)

---

## Stack default

Node 20+, TypeScript, Vitest (`stack.profile: node-ts` in `harness.config.yaml`). Change `verify.*` commands in config for other stacks.

---

## Learn more

- [harness-lab](https://github.com/buyukkardes/harness-lab) — curriculum + reference Task Notes app
- [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) — day-to-day workflow
- [docs/PR-WORKFLOW.md](docs/PR-WORKFLOW.md) — feat branches, merge
