# SPECS — replace with your product spec

This file is a **placeholder**. Copy your product `SPECS.md` here (see `docs/SETUP.md`).

---

## Phase 0 — Project setup (harness)

Complete **before** product Phase 1. See **docs/SETUP.md** for full checklist.

- [ ] Run `bash scripts/setup-project.sh <name> "<description>"` (or manually edit files below)
- [ ] `harness.config.yaml` — real project name (not `__PROJECT_NAME__`)
- [ ] `package.json` + `package-lock.json` — `"name"` matches project (not `harness-lab` / `my-project`)
- [ ] `git remote origin` — points at **your** GitHub repo, not harness-infra-template
- [ ] `harness/session-prompt.md` exists (not only under `harness/harness/`)
- [ ] Copy product spec from external repo → replace this file
- [ ] `npm ci && bash scripts/verify.sh` green
- [ ] Initial commit pushed; GitHub Actions **CI** visible on repo

**Verification:** `bash scripts/init.sh` shows your project name; `npm test` does not report wrong package name.

---

*(Product phases start in your copied spec — Phase 1+)*