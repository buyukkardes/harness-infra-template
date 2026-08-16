# Getting started

**First clone?** Read **[docs/SETUP.md](SETUP.md)** end-to-end before coding.

---

## Daily workflow

1. `bash scripts/init.sh`
2. Pick unchecked unit in `specs/SPECS.md`
3. Fresh chat → paste `harness/session-prompt.md`
4. Implement → `bash scripts/verify.sh` → tick spec → `state/progress.txt` → commit
5. **`feat/*` branches:** `bash scripts/auto-push.sh` → CI → human merge  
   **`main`:** `git push` (bootstrap / completion handoffs)

---

## Product vs harness

| Product (your spec) | Harness (this repo) |
|---------------------|---------------------|
| `specs/SPECS.md` | `AGENTS.md`, `docs/HARNESS.md` |
| `src/`, `tests/`, `public/` | `scripts/`, `harness/`, `.github/` |

Do not add harness-meta phases (PR pipeline setup, conflict agent docs) to your product spec.

---

## Links

- Setup checklist: [SETUP.md](SETUP.md)
- PR mode: [PR-WORKFLOW.md](PR-WORKFLOW.md)
- Parallel workers: [ORCHESTRATION.md](ORCHESTRATION.md)
- Example spec: [task-notes-spec](https://github.com/buyukkardes/task-notes-spec)
