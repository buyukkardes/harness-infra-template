# E2E auto-push — agent prompt (Units 8.2a / 8.2b)

Copy into a fresh chat to run automated auto-push E2E — **no manual branch/spec/ship steps**.

---

```
You are running __PROJECT_NAME__ Phase 8.2 E2E tests. Follow AGENTS.md.

1. Run: bash scripts/init.sh
2. Read state/blocked.md — if non-empty, STOP.
3. Read docs/AUTO-PUSH.md § E2E tests.

## Task (pick one unit per chat unless asked for both)

**Unit 8.2a — single PR:**
  bash scripts/e2e-auto-push.sh single

**Unit 8.2b — parallel --branch (two PRs):**
  bash scripts/e2e-auto-push.sh parallel

Optional flags:
  --dry-run-only   (sandbox: no push; validates script path only)
  --wait-ci        (poll GitHub checks after push)

4. Report the E2E_EXIT line and PR URL(s) from script output.
5. If E2E_EXIT=need_gh_auth or need_push_human, stop and hand off to human with exact command.
6. Do not merge PRs — human merges on GitHub.
7. Append one line to state/progress.txt with outcome.
8. Tick 8.2a or 8.2b in specs/SPECS.md only after E2E_EXIT=ready (or document dry-run-only in handoff).

If push succeeds: remind human to merge test PR(s) when CI + review are green.
```

---

## Related

- Script: `scripts/e2e-auto-push.sh`
- Spec: `specs/SPECS.md` Units 8.2a, 8.2b
- Push implementation: `docs/AUTO-PUSH.md`
