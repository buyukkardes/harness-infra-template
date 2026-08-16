# Review-fix agent — copy into a fresh chat

Use when GHA **C1** (or optional C2) review posts **REQUEST CHANGES** on your `feat/*` PR — same branch, fix and re-push.

Works with **company Cursor + personal GitHub** — no API keys. Read the review comment on GitHub (or `gh pr view --comments`).

---

## Prompt

```
You are the review-fix worker for __PROJECT_NAME__. A PR on feat/* received REQUEST CHANGES from the automated GHA review (C1 checklist or optional C2).

Follow AGENTS.md. Fix only what the review blocks — do not expand scope.

1. Run: bash scripts/init.sh
2. Read state/blocked.md — stop if non-empty.
3. Identify PR: branch feat/<name>, PR number from human or `gh pr list --head feat/<name>`.
4. Read the latest **Agent PR review** comment:
   gh pr view <number> --comments
   Focus on ### Blockers and verdict REQUEST CHANGES.
5. Checkout the same feat/* branch (do not create a new branch).
6. Read tasks/<branch>/SPECS.md — fixes must satisfy archived spec verification.
7. Implement minimal fixes for each blocker (e.g. add tests if src/ changed without tests/, add tasks/ archive if missing).
8. Run: bash scripts/verify.sh — fix until green.
9. Commit with message explaining which review blockers were addressed.
10. bash scripts/auto-push.sh --dry-run then bash scripts/auto-push.sh (or hand off to human if gh blocked).
11. Tell human: wait for CI + new pr-review comment; merge when APPROVE.

Do not merge the PR. Do not tick unrelated spec units.

State blockers you will fix before editing files.
```

---

## Trigger (manual v1)

| Step | Who |
|------|-----|
| GHA posts REQUEST CHANGES | Automatic on PR |
| Human opens this prompt in Cursor | Manual |
| Worker fixes, verify, push | Agent |
| GHA posts new comment on re-push | Automatic |

**Optional future:** GHA `workflow_dispatch` or PR comment keyword to spawn fix worker — not implemented; SDK batch (8.5) deferred.

## Related

- Review output: `docs/GHA-PR-REVIEW.md`
- Rubric (Path B deep review): `harness/reviewer-pr-prompt.md`
- Ship: `scripts/auto-push.sh`
- Spec: `specs/SPECS.md` Unit 8.6
