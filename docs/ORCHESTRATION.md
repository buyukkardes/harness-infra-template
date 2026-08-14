# Orchestration — parallel workers (Phase 7)

One orchestrator kickoff → two independent worker sessions → two feature branches → auto-push each PR → existing CI + GHA review → human merge.

**Prerequisite:** Phase 6 complete (hybrid pipeline). **Phase 8:** auto-push (8.2), conflict agent (8.4), review-fix loop (8.6).

See **`docs/harness-workflow.svg`** (Phase 8 v1 diagram), **`specs/SPECS.md` Phase 7**, and **`docs/GETTING-STARTED.md`**.

---

## Roles

| Role | Session | Does | Does not |
|------|---------|------|----------|
| **Orchestrator** | One planning chat | Read spec, pick 2 parallel-safe units, emit worker briefs | Implement, tick checkboxes, commit, push |
| **Worker A / B** | Separate implementation chats | One unit each on `feat/*`, verify, commit, archive spec | Touch the other worker's files; merge PRs |
| **Conflict agent** | Fresh chat after rebase conflicts | Resolve shared-file conflicts, finish rebase, push | Implement new features |
| **Review-fix worker** | Fresh chat on REQUEST CHANGES | Fix blockers on same branch, verify, push | Merge PR |
| **Human** | Terminal + GitHub | `auto-push.sh` if sandbox blocks agent, merge PRs | — |

**Orchestrator prompt:** `harness/orchestrator-prompt.md`  
**Worker prompt:** `harness/session-prompt.md` plus unit-specific constraints from the worker brief.

---

## Pipeline

```text
Orchestrator (planning only)
    → Worker A on feat/foo  ─┐
    → Worker B on feat/bar  ─┼→ auto-push each → CI → C1 pr-review → human merge
                             └→ (if 2nd PR conflicts) conflict agent → rebase → push
                             └→ (if REQUEST CHANGES) review-fix worker → push
```

Each worker reuses the Phase 6 hybrid pipeline from **`docs/PR-WORKFLOW.md`** — one branch, one PR, one unit.

---

## Parallel worker rules

Two units may run in parallel **only** when the orchestrator confirms all of the following (details in **`harness/orchestrator-prompt.md`**):

1. Both units have unchecked items in `specs/SPECS.md`.
2. Both are implementable (concrete deliverables, not meta-only handoffs).
3. **Disjoint file scope** — allowed files for A and B do not overlap.
4. **No sequential dependency** — neither unit needs the other's output to start.

### Per-worker requirements

Each worker **must**:

| Requirement | Why |
|-------------|-----|
| **Own branch** (`feat/<short-kebab-name>`) | Isolated git history; one PR per unit |
| **Own chat/session** | Short context; one unit per conversation (Tip 8) |
| **Own `tasks/` archive** | `tasks/<branch>/SPECS.md` copied before ship — see **`docs/PR-WORKFLOW.md`** § Archive spec |
| **`verify.sh` before commit** | Same gate as Phase 5–6; pre-commit hook if installed |

Workers implement **only** the unit named in their brief. Forbidden paths (other worker's files, shared hot files) are listed in the brief — do not edit them.

### Allowed vs forbidden files

Worker briefs (from orchestrator or `state/orchestrator/worker-a.md` / `worker-b.md`) list:

- **Allowed files** — paths this worker may create or edit
- **Forbidden files** — paths owned by the other worker or shared API hot files

If scope is unclear, treat units as **not** parallel-safe until `specs/SPECS.md` names explicit paths.

---

## Human: ship each branch

Push and PR creation use **Phase 8.2 automated push** — agents run `scripts/auto-push.sh` (not raw `git push`).

After each worker commits on its feature branch:

```bash
bash scripts/auto-push.sh --dry-run --branch feat/<worker-branch>   # preflight
bash scripts/auto-push.sh --branch feat/<worker-branch>             # push + open PR
```

On a single-worker session, omit `--branch` when already checked out. See **`docs/AUTO-PUSH.md`**.

**When human ship is still required:** sandbox blocks push/`gh`, or `gh auth` missing — handoff: `Human: bash scripts/auto-push.sh --branch feat/...`

**Until Cloud Agent push is routine**, the human may still run the same command in their terminal (Path D in AUTO-PUSH.md).

After both PRs are open: wait for CI + **`docs/GHA-PR-REVIEW.md`** on each; merge when ready.

### Merging parallel PRs

When both workers touch shared harness files (`state/progress.txt`, `specs/SPECS.md`, `docs/llms.txt`), the **second PR to merge** often conflicts. Expected when workers append handoffs or tick spec checkboxes in parallel.

#### Option A — Conflict agent (recommended)

After the **first PR is merged** on GitHub:

```bash
git fetch origin main
git checkout feat/<second-worker-branch>
bash scripts/rebase-parallel-pr.sh --dry-run
bash scripts/rebase-parallel-pr.sh          # exit 2 if conflicts
```

If exit **2**: open **`harness/conflict-agent-prompt.md`** in a fresh Cursor chat → resolve → `bash scripts/rebase-parallel-pr.sh --continue` → `bash scripts/auto-push.sh`.

E2E practice (local only; commit/stash first; `cleanup` resets main):

```bash
bash scripts/e2e-conflict-rebase.sh setup
bash scripts/rebase-parallel-pr.sh        # expect exit 2
# … conflict agent …
bash scripts/e2e-conflict-rebase.sh cleanup
```

#### Option B — GitHub UI

1. Merge the first PR on GitHub.
2. On the second PR, use **Update branch** or rebase locally (same as Option A without agent).
3. Resolve conflicts — keep **both** append-only `progress.txt` handoffs in chronological order.
4. Ensure no conflict markers remain; `bash scripts/verify.sh` green before push.

#### When to use which

| Situation | Use |
|-----------|-----|
| `progress.txt` / `specs/SPECS.md` conflict on rebase | Conflict agent (A) |
| Disjoint docs only (8.2b E2E branches) | Usually merge both without rebase |
| Sandbox blocks push | Agent resolves; human runs `auto-push.sh` |

### Review-fix loop (REQUEST CHANGES)

When **`pr-review`** posts **REQUEST CHANGES** (missing `tasks/` archive, `src/` without `tests/`, etc.):

1. Open **`harness/review-fix-prompt.md`** in a fresh Cursor chat on the **same** `feat/*` branch.
2. Agent fixes blockers, runs `verify.sh`, commits, `auto-push.sh`.
3. CI re-runs; new review comment on push. Human merges when **APPROVE**.

No GHA trigger for fix worker in v1 — manual chat open after reading the comment.

---

## Worker session checklist

Copy for each worker chat:

1. Run `bash scripts/init.sh`
2. Read `state/blocked.md` — stop if non-empty
3. Read worker brief (orchestrator output or `state/orchestrator/worker-*.md`)
4. Checkout the named branch (create from `main` if needed)
5. Copy unit bullets to `tasks/<branch>/SPECS.md` before implementing
6. Implement **only** the named unit; stay within allowed files
7. Run `bash scripts/verify.sh` — fix until green
8. Tick this unit's checkboxes in `specs/SPECS.md`
9. Append handoff to `state/progress.txt`
10. Commit with detailed message
11. Attempt `auto-push.sh` or hand off to human (see above)

---

## Phase 10 — three parallel workers

**Goal:** Stress-test orchestration — three disjoint feature units → three PRs → merge cascade with conflict agent. Spec: **`specs/SPECS.md` Phase 10**.

### Kickoff

1. **Orchestrator** (fresh chat, `harness/orchestrator-prompt.md`): confirm units **10.2**, **10.3**, **10.4** are unchecked; verify disjoint file scopes in the Phase 10 table; emit **three** worker briefs under `state/orchestrator/` (or inline).
2. **Three worker chats** — one unit each, **do not share a branch**:
   - `feat/ui-pagination-controls` → `public/**` only
   - `feat/note-tags-api` → `src/notes/**`, `tests/**` only
   - `feat/devtools-qa-doc` → `docs/**` only
3. Each worker: verify → commit → `auto-push.sh --branch feat/...` (human push if sandbox blocks).

Workers may run **sequentially on one machine** (checkout per branch) or in **separate Cloud/local sessions** — parallel-safe by file scope, not by git worktree (worktrees = Phase 10+ optional).

### Merge cascade (Unit 10.5)

After all three PRs are open and CI + C1 have run:

```text
Suggested order (fewest cross-deps first): 10.4 doc → 10.2 UI → 10.3 API
  merge PR₁ → rebase PR₂ branch onto main → (conflict agent if exit 2) → push → merge PR₂
           → rebase PR₃ branch onto main → (conflict agent if exit 2) → push → merge PR₃
```

**Human boundary:** push fallback + **Merge** on GitHub only. Do not edit product code or leave conflict markers — escalate to conflict agent.

Record in `state/progress.txt`: PR URLs, merge order, conflict count, review-fix loops.

### Success criteria

- Three agent-implemented PRs merged
- Conflicts resolved by conflict agent (not manual edit)
- C1 APPROVE on all three (after any review-fix)
- Human did not implement features or resolve rebase conflicts by hand

---

## Related

| Topic | File |
|-------|------|
| Orchestrator planning | `harness/orchestrator-prompt.md` |
| Conflict rebase | `harness/conflict-agent-prompt.md`, `scripts/rebase-parallel-pr.sh` |
| Review-fix (REQUEST CHANGES) | `harness/review-fix-prompt.md` |
| Single-PR checklist | `docs/PR-WORKFLOW.md` |
| Kickoff script (7.4) | `scripts/orchestrate-kickoff.sh` |
| Spec units | `specs/SPECS.md` Phase 7 |
| Phase 10 parallel E2E | `specs/SPECS.md` Phase 10 |
| GHA review | `docs/GHA-PR-REVIEW.md` |
