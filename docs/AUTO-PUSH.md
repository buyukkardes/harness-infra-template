# Automated push (Phase 8 Unit 8.2)

Replace manual `git push` in the terminal with an **agent-run script** or **GHA follow-up**. PR creation reuses `open-pr.yml`, `gh pr create`, or `auto-push.yml`.

**Remote:** your GitHub repo `YOUR_USER/__PROJECT_NAME__` (see `docs/SETUP.md` step 4)  
**Account split:** Company Cursor local sandbox may block push — see fallbacks below.

---

## Paths compared

| Path | Who runs push | When to use |
|------|----------------|-------------|
| **A — auto-push.sh** *(v1 default)* | Agent or Cloud Agent | After worker commit; supports `--branch` for parallel workers |
| **B — GHA auto-push.yml** | GitHub Actions | After branch exists on origin; verify + ensure PR on runner |
| **C — Cloud Agent VM** | Cloud Agent with git + gh | Same as A, on Cursor Cloud with credentials |
| **D — human ship-pr** | You in terminal | Sandbox/auth blocked; same script, your shell |

Path **A + B** is implemented for this repo (`--gha` dispatches workflow after local push).

---

## Path A — `scripts/auto-push.sh` (default)

```bash
# Current branch
bash scripts/auto-push.sh --dry-run
bash scripts/auto-push.sh

# Parallel workers — explicit branch (avoids wrong-branch ship)
bash scripts/auto-push.sh --branch feat/orchestration-docs
bash scripts/auto-push.sh --branch feat/orchestrate-kickoff

# Push + dispatch GHA verify/PR job
bash scripts/auto-push.sh --gha
```

**Preflight:** `feat/*`, `tasks/<branch>/SPECS.md`, clean tree, `bash scripts/verify.sh` green.

**Auth:** personal `gh auth login` on the machine running the script. Push uses git + gh credentials (no secrets in repo).

**Worker handoff:** After commit, agent runs `auto-push.sh` (not raw `git push`). If push fails, handoff: `Human: bash scripts/auto-push.sh --branch feat/...`

`scripts/ship-pr.sh` delegates to `auto-push.sh` for backward compatibility.

---

## Path B — GHA `auto-push.yml`

**Does not upload local commits.** Branch must already be on `origin` (via Path A, C, or D).

```bash
gh workflow run auto-push.yml -f branch=feat/my-feature
gh run list --workflow=auto-push.yml
```

Workflow: checkout branch → `verify.sh` → open PR if missing.

Optional: `bash scripts/auto-push.sh --gha` pushes locally then dispatches this workflow.

**Secrets:** uses default `GITHUB_TOKEN` (contents read, pull-requests write). No extra secret required for ensure-PR. For future bot-only push from GHA, add `AUTO_PUSH_PAT` — see `state/tech-debt.md`.

---

## Path C — Cloud Agent

1. Run worker on **Cursor Cloud Agent** with repo checkout and **personal GitHub** git/gh auth configured on the VM.
2. After commit: `bash scripts/auto-push.sh` (same as Path A).
3. Optionally `--gha` for runner-side verify.

Document credentials in Cursor Cloud settings — never commit tokens.

**Why Cloud Agent:** Local company Cursor sandbox often cannot push; Cloud VM can hold personal `gh` auth.

---

## Path D — Human fallback

Same commands as Path A in your terminal:

```bash
git checkout feat/my-feature
bash scripts/auto-push.sh
```

If only push is needed: `git push -u origin HEAD` — `open-pr.yml` may open PR when `tasks/<branch>/SPECS.md` exists.

---

## Pipeline update

```text
Worker commit → auto-push.sh (--branch) → origin/feat/* → open-pr.yml or gh pr create
                                         → CI verify → pr-review → human merge
```

Parallel workers: one `auto-push.sh --branch ...` per feature branch (can be separate agent sessions).

---

## E2E tests (Units 8.2a / 8.2b)

**Agent-run only** — one command per unit; no manual branch/spec/ship checklist.

| Unit | Command | Branches | What it proves |
|------|---------|----------|----------------|
| **8.2a** | `bash scripts/e2e-auto-push.sh single` | `feat/test-auto-push-82a` | Full auto-push → one PR |
| **8.2b** | `bash scripts/e2e-auto-push.sh parallel` | `feat/test-auto-push-82b-a`, `-82b-b` | `--branch` ships two PRs from one session |

**Agent prompt:** `harness/e2e-auto-push-prompt.md`

```bash
# Sandbox / no gh auth — structure + dry-run only:
bash scripts/e2e-auto-push.sh single --dry-run-only --offline

# Full E2E (requires gh auth + network):
bash scripts/e2e-auto-push.sh single
bash scripts/e2e-auto-push.sh parallel

# Push + wait for CI (optional):
bash scripts/e2e-auto-push.sh single --wait-ci
```

**Exit codes (stdout):**

| Line | Meaning |
|------|---------|
| `E2E_EXIT=ready` | Push + PR(s) OK |
| `E2E_EXIT=need_gh_auth` | Run `gh auth login`, re-run script |
| `E2E_EXIT=need_push_human` | Sandbox blocked push — human runs printed `auto-push.sh --branch` |
| `E2E_EXIT=failed` | Script error |

**Log:** append-only `docs/e2e-auto-push-log.md`  
**Markers:** `docs/e2e-auto-push-82a.md`, `docs/e2e-auto-push-82b-*.md` (disjoint — safe parallel merge)

Human: merge test PR(s) when green, or close without merge if harness-only validation.

---

## Related

- PR checklist: `docs/PR-WORKFLOW.md`
- Orchestration: `docs/ORCHESTRATION.md`
- Workflow: `.github/workflows/auto-push.yml`, `.github/workflows/open-pr.yml`
- Spec: `specs/SPECS.md` Unit 8.2
