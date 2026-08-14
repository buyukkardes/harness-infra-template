# Entropy prompt — copy into a fresh chat (cleanup pass)

**Entropy = small, safe cleanup** — not refactors. When in doubt, log to `state/tech-debt.md` instead of deleting.

Run after doc review (6.9) or on a schedule. **Do not** auto-delete files without listing candidates first.

---

## Scope

| In scope | Out of scope |
|----------|----------------|
| Stale "Next step" / timeline prose | Rewriting routes or store |
| Missing llms.txt entries | Large progress.txt truncation |
| Orphan `tasks/` without merged branch | Deleting tasks/ archives for merged PRs |
| Duplicated harness instructions | Dependency upgrades |
| architecture.md script list drift | Feature work |

---

## Prompt (copy below)

```
You are the entropy reviewer for __PROJECT_NAME__. Prefer minimal diffs. Stop if a change needs product decisions.

## Setup

1. Read docs/llms.txt and list harness/ + scripts/ files on disk — find unlisted files.
2. Read state/progress.txt — note if handoff volume is huge (suggest trim policy, do not delete without approval).
3. List tasks/*/SPECS.md — each should correspond to a merged or open feat branch (note orphans only).
4. Read docs/GETTING-STARTED.md "Next step" and timeline — flag if clearly stale.
5. Compare docs/architecture.md harness layout vs actual scripts/.

## Entropy checklist

**Index completeness**
- New harness files listed in llms.txt?

**Stale navigation**
- GETTING-STARTED / README pointing at wrong phase?

**tasks/ hygiene**
- Empty or duplicate task folders?
- Archives for deleted branches only — flag, do not delete merged PR archives

**Doc duplication**
- Same pipeline described three times with conflicting steps — consolidate pointers, not prose copies

**Safe fixes allowed in this pass**
- Update llms.txt, architecture pointers, GETTING-STARTED next step, README one-liners
- Max 2–3 files changed unless user approves more

## Output format

---
## Entropy pass report

**Safe to fix now (max 3):**
1. `path` — one-line change

**Needs human / tech-debt:**
1. `path` — why not auto-fix

**No action:**
- (areas checked and OK)

---
Implement only the "Safe to fix now" items if the user asked you to fix in this chat.
```

---

## Related

- Doc consistency: `harness/reviewer-docs-prompt.md`
- Intentional debt: `state/tech-debt.md`
- Spec units: `specs/SPECS.md` 6.10–6.11
