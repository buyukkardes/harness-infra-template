# Pull request workflow

Sequential PR mode for __PROJECT_NAME__ (Phase 5+). One branch, one PR, automated review after CI, **human merge**.

**Remote:** `git@github.com:YOUR_USER/__PROJECT_NAME__.git` (set after clone — see `docs/SETUP.md`)  
**CI:** `.github/workflows/ci.yml` — jobs `verify` + `pr-review` (Phase 6 Path C)

---

## Hybrid pipeline (Phase 6)

```text
┌─────────────┐   ┌──────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ Local agent │ → │ ship-pr.sh   │ → │ GitHub CI   │ → │ GHA review  │ → │ Human merge │
│ implement   │   │ push + PR    │   │ verify      │   │ PR comment  │   │ on GitHub   │
└─────────────┘   └──────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
     commit            (bridge)          automated          automated          you only
```

| Step | Who | What |
|------|-----|------|
| Spec + implement + tests | **Agent** (local Cursor) | One unit on `feat/*`; `bash scripts/verify.sh` before commit |
| Archive spec | **Agent** | `tasks/<branch>/SPECS.md` before ship |
| Ship (push + open PR) | **Agent** runs `auto-push.sh` → **Human fallback** | `bash scripts/auto-push.sh --branch feat/...` — see **`docs/AUTO-PUSH.md`** |
| CI | **GitHub Actions** | `verify` job |
| PR review comment | **GitHub Actions** | `pr-review` → `scripts/gha-pr-review.sh` — **`docs/GHA-PR-REVIEW.md`** |
| Merge | **Human** | After reading review; agent never merges |

**Account split:** Company Cursor + personal GitHub → review is Path C (GHA), not Cursor Automations. See **`docs/CURSOR-PR-REVIEW-AUTOMATION.md`**.

---

## Ship protocol (Option 2)

After commit on `feat/*`, the **agent** runs:

```bash
bash scripts/auto-push.sh --dry-run   # preflight without push
bash scripts/auto-push.sh             # push + gh pr create
# Parallel workers:
bash scripts/auto-push.sh --branch feat/<name>
```

Preflight requires: feature branch, `tasks/<branch>/SPECS.md`, clean tree, `verify.sh` green.

If push/`gh` fails (sandbox, auth): handoff must say **`Human: bash scripts/auto-push.sh --branch feat/...`**. After push, **open-pr.yml** opens a PR if missing; CI and review run automatically.

**Human shortcut** (if agent already committed): `bash scripts/auto-push.sh --branch feat/...` or `git push -u origin HEAD` (PR via open-pr.yml; no preflight).

---

## When to use a PR

| Work on | Use |
|---------|-----|
| Phase 0–4 units on `main` | Direct commits (learning history) |
| Phase 5+ feature units | Feature branch + PR |

---

## Checklist (agent or human)

Copy this flow for each PR unit in `specs/SPECS.md`.

### 1. Branch

```bash
git checkout main
git pull origin main
git checkout -b feat/<short-kebab-name>
```

Branch name must match the spec (e.g. `feat/pr-workflow-docs`).

### 2. Plan

- Read the unit in `specs/SPECS.md`
- Run `bash scripts/init.sh`
- State plan before editing

### 3. Implement

- One logical unit only
- Add/update tests per spec verification line
- Update `docs/architecture.md` paths only if structure changed

### 4. Verify (required before commit)

```bash
bash scripts/verify.sh
```

Must exit 0. Pre-commit hook runs the same script if installed.

### 5. Archive spec (Tip 10)

Before opening the PR, copy the unit spec to:

```text
tasks/<branch-name>/SPECS.md
```

Example: branch `feat/sort-notes-by-date` → `tasks/feat/sort-notes-by-date/SPECS.md`

Paste the relevant unit section (or full Phase section) so future agents can read what this PR was for.

### 6. Commit

```bash
git add -A
git commit -m "feat(scope): short description

- What changed and why
- Verified: bash scripts/verify.sh"
```

### 7. Ship (push + open PR)

**Agent (end of session):**

```bash
bash scripts/ship-pr.sh --dry-run
bash scripts/ship-pr.sh
```

**Human fallback** if agent cannot push: run `bash scripts/ship-pr.sh` from the feature branch.

Alternative: `git push -u origin HEAD` — PR may auto-open via `.github/workflows/open-pr.yml` (no ship preflight).

### 8. CI + automated review

- Wait for **verify** and **pr-review** jobs on the PR (both in CI workflow)
- Fix failures on the branch; push again (new review comment on re-run — expected)
- Read **Agent PR review** comment from `github-actions` before merging

### 9. Human merge

- Reviewer merges on GitHub (squash or merge commit — team preference)
- Delete feature branch after merge
- Pull `main` locally: `git checkout main && git pull origin main`

### 10. Handoff

- Tick unit in `specs/SPECS.md` (on `main` after merge, or note in PR if spec tick is in PR)
- Append entry to `state/progress.txt`

---

## Blockers

If blocked by external access (GitHub, secrets, etc.):

1. Write `state/blocked.md` (## heading below ---)
2. Stop — do not guess

---

## Recovery

| Problem | Action |
|---------|--------|
| CI failed on PR | Fix on branch, `bash scripts/verify.sh`, push |
| Wrong approach | Close PR, delete branch, reset or start fresh branch |
| Merge conflict | Rebase or merge `main` into branch, verify, push |

Never merge with failing CI.

---

## Related

- Agent router: `AGENTS.md` (PR mode)
- GHA PR review: `docs/GHA-PR-REVIEW.md`
- Cursor paths (A/B): `docs/CURSOR-PR-REVIEW-AUTOMATION.md`
- Review rubric (manual): `harness/reviewer-pr-prompt.md`
- Git conventions: `docs/conventions.md`
- Current units: `specs/SPECS.md` Phase 5–6
