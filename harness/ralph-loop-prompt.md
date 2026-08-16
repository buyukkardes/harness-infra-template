# Ralph Loop prompt — Phase 4+ automation

One iteration = one agent run = one logical unit = one commit (when possible).

**Quick start (Cursor):** paste `harness/loop-prompt.txt` into chat, or use `/loop 30m` with that prompt (see docs/conventions.md).

---

## Loop prompt

Full prompt lives in **`harness/loop-prompt.txt`** (single file for copy/paste and `/loop`).

It wraps `harness/session-prompt.md` and adds Ralph exit codes + logging.

---

## Exit statuses (Tip 19)

Print **exactly one** `RALPH_EXIT=...` line at the end of each iteration:

| Code | Meaning | Human action |
|------|---------|--------------|
| `continue` | Work unit done; more Phase 4 units remain | Run next iteration |
| `done` | All loop work complete for current phase | Review logs, close loop |
| `blocked` | Wrote `state/blocked.md` | Fix blocker, clear file, restart |
| `verify` | `verify.sh` failed; no commit | `git reset --hard`, fix harness, restart |
| `noop` | No eligible unit found | Check `specs/SPECS.md` |
| `budget` | Token/time limit hit | Resume later |
| `stuck` | No commit in 3+ iterations on same unit | Fix spec or rules |

---

## Logging

After each iteration:

```bash
bash scripts/ralph-log.sh <exit_code> "<unit description>" [commit_hash]
```

Logs append to `state/logs/YYYY-MM-DDTHHMMSSZ.log`.

Review logs when debugging loop failures (Tip 20).

---

## Recovery (Tip 18)

Never hand-fix the same loop failure twice. Reset → fix harness → rerun.

```bash
git reset --hard HEAD
# fix specs/SPECS.md, AGENTS.md, harness/loop-prompt.txt, or rules
# restart loop
```

---

## Cursor `/loop`

Example (adjust interval):

```
/loop 30m Read harness/loop-prompt.txt and execute it exactly for __PROJECT_NAME__.
```

Or paste the contents of `harness/loop-prompt.txt` as the loop prompt.

Stop the loop when you see `RALPH_EXIT=done` or `RALPH_EXIT=blocked`.

---

## Other tools

- **Claude Code / Codex:** ask agent for current non-interactive loop CLI for your version
- **Manual fallback:** fresh chat + `harness/session-prompt.md` (Phase 3 style)
