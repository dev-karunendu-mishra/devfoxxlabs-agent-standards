# Change Log — How It Works

`changes/CHANGELOG.md` is the running record of every change made to this repo: what changed, in
which feature, and why. Git history shows *which lines* changed; this log keeps the *context* — the
problem, the root cause, the decision, and what is still open — so anyone (a developer or an AI
agent) can pick up a feature without re-discovering it.

A change that spans more than one repo (e.g. app + admin, app + API) gets an entry in each repo's
log, linked to the other.

## When to add an entry

Add one entry per task, in the same change/commit as the code — fixes, new features, corrections
to earlier work, API changes, migrations, dependency changes, build/deploy changes. Skip only
trivial edits (typos, formatting).

If a later change corrects or reverses an earlier entry, add a new entry and reference the old one
(`Corrects: 2026-10-17 — …`). Never rewrite old entries; the history of decisions is the point.

## Entry format

Newest entries go at the top, under the `---` line in `CHANGELOG.md`.

```markdown
## YYYY-MM-DD — <Area> › <Feature>: <one-line summary>

- **Type:** Feature | Fix | Correction | Refactor | API | Migration | Dependency | Build
- **Problem / goal:** what was wrong or needed, in user terms.
- **Root cause:** (fixes only) why it happened.
- **What changed:** the behaviour after the change; key decisions and why.
- **Files:** the main files touched (not every file).
- **API / DB:** new or changed endpoints, fields, migrations — or "none".
- **Related:** the matching entry in the other repo, PR/commit, earlier entries.
- **Verified:** tests/analysis run and their result; manual checks.
- **Open / follow-ups:** anything not done, known limits, next steps.
```

Use a stable **Area** name so entries can be searched (`Auth`, `Bookings`, `Payments`, `Settings`,
`Build`, …). Add a new area name only when no existing one fits.

## Using it for context

Before working on a feature:

1. Search the log for the area or feature, e.g. `grep -n "Bookings" changes/CHANGELOG.md`.
2. Read the matching entries, newest first — especially **Root cause**, decisions in
   **What changed**, and **Open / follow-ups**.
3. Check the other repo's log for the same area when the feature spans repos.

## Housekeeping

- Keep entries short: a reader should get the context in under a minute.
- Write absolute dates (`2026-10-17`), never "yesterday" or "last week".
- When `CHANGELOG.md` gets long (around 1,500 lines), move the oldest year into
  `changes/archive/CHANGELOG-<year>.md` and keep searching both.
