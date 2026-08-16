# Session prompt — copy into a fresh chat

Use for implementation units (one logical unit per chat).

---

```
You are working in __PROJECT_NAME__. Follow AGENTS.md exactly.

1. Run: bash scripts/init.sh
2. Read state/blocked.md — if anything besides the heading/example, STOP and tell me.
3. Read specs/SPECS.md — pick the highest-priority unchecked logical unit.
4. Read docs/conventions.md and any docs linked from your chosen unit.
5. Before coding: search the codebase — confirm the unit is not already done.
6. Implement ONLY that unit. Write tests per the spec verification line.
7. Run: bash scripts/verify.sh — fix until green.
8. Tick the checkbox in specs/SPECS.md.
9. Update docs/architecture.md paths if you added files (pointers only).
10. Append handoff to state/progress.txt.
11. Commit with a detailed message (what, why, how verified).
12. On feat/* PR units: bash scripts/auto-push.sh --dry-run, then bash scripts/auto-push.sh (--branch for parallel workers).
13. If push fails: handoff must include "Human: bash scripts/auto-push.sh --branch feat/...".

If you hit a real external blocker: write state/blocked.md and stop. Do not guess.

State your chosen unit and plan before editing files.
```
