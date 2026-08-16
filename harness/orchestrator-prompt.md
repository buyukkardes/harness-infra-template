# Orchestrator prompt — copy into a fresh chat (Phase 7 kickoff)

Use for **planning only** — pick two parallel units and emit worker briefs. **Do not implement** code or harness changes in the orchestrator session.

Workers use `harness/session-prompt.md` (one unit per chat). Agent runs `bash scripts/auto-push.sh --branch feat/...` per branch after each worker commits (human fallback if push blocked).

---

## Role

| Role | Session | Does |
|------|---------|------|
| **Orchestrator** | This chat | Read spec, pick 2 independent units, write worker briefs |
| **Worker A / B** | Separate chats | One unit each on `feat/*`, verify, commit |
| **Human** | Terminal + GitHub | `auto-push.sh --branch` fallback, merge PRs after GHA review |

See **`docs/harness-workflow.svg`** (Phase 8 v1 diagram) and **`specs/SPECS.md` Phase 7**.

---

## Independence rules

Two units are **parallel-safe** only when **all** of the following hold:

1. **Unchecked** — unit has at least one `- [ ]` checkbox in `specs/SPECS.md`.
2. **Implementable** — unit describes concrete deliverables (not meta-only completion handoffs like "Phase 7 complete").
3. **Disjoint file scope** — inferred **allowed files** for unit A and unit B have **empty intersection**.
4. **No sequential dependency** — neither unit requires the other's output to start (e.g. do not pair "write protocol doc" with "E2E that requires protocol doc" until the doc unit is done).

### Inferring allowed files

| Unit pattern | Default allowed files |
|--------------|----------------------|
| `Create harness/foo.md` | `harness/foo.md`, tick in `specs/SPECS.md`, `state/progress.txt` |
| `Document … in docs/BAR.md` | `docs/BAR.md`, tick + handoff as above |
| `Add scripts/baz.sh` | `scripts/baz.sh`, tick + handoff; optional `docs/` if unit says so |
| API / `feat/*` feature | `src/**`, `tests/**`, `tasks/<branch>/SPECS.md`, tick + handoff |
| Broad "update docs" | Parse bullet list; if vague, **not parallel-safe** without explicit paths |

### Hot files (API)

If two API units both need any of these, they are **not** parallel-safe:

- `src/notes/routes.ts`
- `src/notes/store.ts`
- `src/notes/types.ts`
- `src/index.ts`
- `tests/notes.test.ts`

Prefer API units that name **new** modules (e.g. `src/notes/tags.ts` + `tests/tags.test.ts`) with at most a **single shared registration line** — when in doubt, treat as overlapping and do not pair.

### Priority

Among parallel-safe pairs, prefer:

1. Same phase, lowest unit number first (e.g. 7.3 before 7.5).
2. Units explicitly marked parallel-safe or with `**Files:**` lists in the spec.
3. Mix of harness/doc/script over two API units touching hot files.

If fewer than two parallel-safe units exist, stop and report (see exit codes below).

---

## Prompt (copy below)

```
You are the orchestrator for __PROJECT_NAME__. You plan parallel work; you do NOT implement.

## Setup

1. Run: bash scripts/init.sh
2. Read state/blocked.md — if anything besides the heading/example, STOP.
3. Read specs/SPECS.md — list all units with unchecked `- [ ]` items.
4. Read state/progress.txt (last 20 lines) for context.
5. Read docs/PR-WORKFLOW.md § "When to use a PR" and Phase 7 section in specs/SPECS.md.

## Your task

1. Identify at least one pair of **parallel-safe** units using harness/orchestrator-prompt.md independence rules.
2. If no valid pair exists, print ORCHESTRATOR_EXIT=need_units and list why each candidate pair failed (file overlap or dependency).
3. Otherwise pick the **best** pair (priority rules in orchestrator-prompt.md).
4. Emit **two worker briefs** (format below). Do not edit src/, tests/, or scripts/ except optionally writing brief files under state/orchestrator/.
5. Do not tick spec checkboxes, commit, or run ship-pr.sh.

## Worker brief format (one per worker)

---
## Worker brief — <Worker A|Worker B>

**Unit:** <e.g. Phase 7 Unit 7.3>
**Branch:** feat/<short-kebab-name>
**Archive spec:** tasks/feat/<short-kebab-name>/SPECS.md (copy unit bullets before implement)

**Allowed files:**
- path/one
- path/two
- specs/SPECS.md (tick only this unit)
- state/progress.txt (handoff)

**Forbidden (other worker / shared):**
- paths the other worker owns
- any hot file listed in orchestrator-prompt.md if the other worker needs it

**Verification line:** (quote from specs/SPECS.md for this unit)

**Worker prompt:** Open a **new chat**, paste harness/session-prompt.md, add:
"Implement ONLY Phase 7 Unit X.Y. Branch feat/.... Do not touch: <forbidden list>."

**After commit:** Agent runs `bash scripts/auto-push.sh --branch feat/...` (human fallback if push blocked — see docs/AUTO-PUSH.md).

---

## Orchestrator summary

| Worker | Unit | Branch | Primary files |
|--------|------|--------|---------------|
| A | … | feat/… | … |
| B | … | feat/… | … |

**Overlap check:** <one line — e.g. "Disjoint: docs/ORCHESTRATION.md vs scripts/orchestrate-kickoff.sh">

**Human next steps:**
1. Open two worker chats with the briefs above.
2. When both branches are committed: bash scripts/auto-push.sh --branch feat/<a> and --branch feat/<b> (or agent runs; human fallback if sandbox blocks).
3. Wait for CI + GHA review on both PRs; merge when ready.

ORCHESTRATOR_EXIT=ready
```

---

## Exit codes

Print **exactly one** line at the end:

| Code | Meaning |
|------|---------|
| `ORCHESTRATOR_EXIT=ready` | Two briefs emitted; safe to start workers |
| `ORCHESTRATOR_EXIT=need_units` | Fewer than two parallel-safe units; human should add/disjoin units in SPECS.md |
| `ORCHESTRATOR_EXIT=blocked` | state/blocked.md non-empty |

Optional: write briefs to `state/orchestrator/worker-a.md` and `state/orchestrator/worker-b.md` (used by `scripts/orchestrate-kickoff.sh` in Unit 7.4).

---

## Example dry-run (Phase 7 — Units 7.3 + 7.4)

After Unit 7.2 is complete, a valid pair while 7.3 and 7.4 remain unchecked:

| Worker | Unit | Branch | Allowed files |
|--------|------|--------|---------------|
| A | 7.3 Worker protocol | `feat/orchestration-docs` | `docs/ORCHESTRATION.md`, `specs/SPECS.md`, `state/progress.txt` |
| B | 7.4 Kickoff script | `feat/orchestrate-kickoff` | `scripts/orchestrate-kickoff.sh`, `specs/SPECS.md`, `state/progress.txt`, optional `docs/` mention in script comments |

**Overlap check:** Disjoint — `docs/ORCHESTRATION.md` vs `scripts/orchestrate-kickoff.sh`. Both may tick different checkboxes in `specs/SPECS.md` (different lines).

**Not valid yet for E2E API practice:** Two CRUD-adjacent features that both edit `src/notes/routes.ts`. Add explicit `**Files:**` blocks in SPECS.md when defining parallel API units (Unit 7.5+).

---

## Related

- Worker implementation: `harness/session-prompt.md`
- PR pipeline: `docs/PR-WORKFLOW.md`
- Kickoff script (7.4): `scripts/orchestrate-kickoff.sh`
- Spec units: `specs/SPECS.md` Phase 7
