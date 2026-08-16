# First-time setup

Use this checklist after **cloning** or **“Use this template”** on GitHub. The template is not a running product yet — you configure identity, add your spec, then implement with agents.

---

## 1. Clone and rename the folder (optional)

```bash
git clone git@github.com:YOUR_ORG/harness-infra-template.git my-app
cd my-app
```

If you used GitHub **Template**, you already have a new repo — skip creating another remote until step 4.

---

## 2. Set project identity (required)

Run the setup script — updates **all** places easy to forget:

```bash
bash scripts/setup-project.sh my-app "My application description"
```

| File | What changes |
|------|----------------|
| `harness.config.yaml` | `project.name`, `project.description` — shown by `init.sh` |
| `package.json` | `"name"`, `"description"` — **npm test output uses this** |
| `package-lock.json` | `"name"` fields — keep in sync with `package.json` |
| `harness/*.md`, docs | `__PROJECT_NAME__` placeholders → your project name |

**Manual alternative** (if you skip the script): edit at minimum:

- [ ] `harness.config.yaml`
- [ ] `package.json` → `"name"` and `"description"`
- [ ] `package-lock.json` → top-level `"name"` and `packages[""].name` (or run `npm install` after editing `package.json`)

Verify identity:

```bash
bash scripts/init.sh    # should show Project: my-app (not __PROJECT_NAME__)
npm test                # should not say harness-lab@…
```

---

## 3. Fix harness prompts path (only if `harness/harness/` exists)

Old bootstraps nested prompts incorrectly. Prompts must live at **`harness/session-prompt.md`**, not `harness/harness/…`.

```bash
mv harness/harness/* harness/ 2>/dev/null; rmdir harness/harness 2>/dev/null
ls harness/session-prompt.md   # must exist
```

`setup-project.sh` does this automatically when it finds the nested folder.

---

## 4. Git remote (required for push / CI)

Template clone still points at **harness-infra-template** until you change it:

```bash
git remote -v
git remote set-url origin git@github.com:YOUR_USER/my-app.git
```

Create an **empty** GitHub repo first (no README), then push.

---

## 5. Product spec (required)

Replace the placeholder:

```bash
cp /path/to/your-spec/SPECS.md specs/SPECS.md
# Example: task-notes-spec → https://github.com/buyukkardes/task-notes-spec
```

`specs/SPECS.md` is the **product** checklist only — no harness-development phases (PR pipeline, conflict agent, etc.). Those live in this repo’s `docs/` and `harness/` already.

---

## 6. Verify harness

```bash
npm ci
bash scripts/verify.sh
git init -b main   # if not already a repo
git add -A && git commit -m "chore: project setup"
git push -u origin main
```

On GitHub → **Actions**: you should see **CI** run on push. Workflows must be at `.github/workflows/*.yml` (not `.github/workflows/workflows/`).

---

## 7. Start building with agents

1. Fresh Cursor chat
2. Paste `harness/session-prompt.md`
3. One logical unit per chat from `specs/SPECS.md`
4. **`main`** for bootstrap units; **`feat/*`** + `bash scripts/auto-push.sh` for feature PRs

See `docs/GETTING-STARTED.md`, `docs/PR-WORKFLOW.md`.

---

## Quick reference

| I need… | Read |
|--------|------|
| Agent entry | `AGENTS.md` |
| File index | `docs/llms.txt` |
| Harness vs product | `docs/HARNESS.md` |
| PR shipping | `docs/PR-WORKFLOW.md` |
| Parallel workers | `docs/ORCHESTRATION.md` |

---

## Example: Task Notes replay

Reference spec: [task-notes-spec](https://github.com/buyukkardes/task-notes-spec).

```bash
bash scripts/setup-project.sh task-notes "Task Notes API"
cp ../task-notes-spec/SPECS.md specs/SPECS.md
npm ci && bash scripts/verify.sh
```

Built from [harness-lab](https://github.com/buyukkardes/harness-lab) Phase 10 v1.
