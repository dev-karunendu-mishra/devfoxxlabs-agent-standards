# Project Docs & Agent Instruction Files

Every app keeps agent rules in the repo so Claude Code and Antigravity follow the same
standard.

## Files every app has

| File | Purpose |
|---|---|
| `CLAUDE.md` | Rules for Claude Code (architecture, rules 1–7, commands) |
| `GEMINI.md` | The same rules for Antigravity / Gemini. Keep it in sync with CLAUDE.md, or have both import shared files |
| `.agent/rules/*.md` (optional, feellive style) | Shared rule files with `---\ntrigger: always_on\n---` frontmatter. CLAUDE.md imports them with `@.agent/rules/00-core.md`. Edit the rule file, not the wrappers |
| `docs/PRD.md` | Product requirements, sections referenced as §N |
| `docs/BACKEND_API_CONTRACT.md` | Endpoints, envelopes, status codes |
| `docs/PERFORMANCE_AND_CACHING_GUIDE.md` | Cache durations per data type, image sizes, ETag notes |
| `docs/UI_AND_API_INTEGRATION_PLAN.md` | Which screen uses which endpoint, and the status |
| `docs/TODO_AND_KNOWN_GAPS.md` | Roadmap and gaps (one file. Don't create misspelled duplicates) |
| `docs/owner-todo.md` | Tasks only the owner can do (keys, consoles, `.env`, legal review, decisions), under dated sections. Never tick one off without the owner's confirmation |
| `changes/CHANGELOG.md` + `changes/README.md` | Change log by feature (format below) |

## CLAUDE.md / GEMINI.md skeleton for a new app

```markdown
# Development & Agent Rules — <App Name> Flutter App

## 🏗️ Project Architecture & Standards
`<app>` is a production-grade Flutter app for <who> doing <what>.
- State: flutter_riverpod 3 (Notifier / AsyncNotifier)
- HTTP: ApiClient (lib/core/network/api_client.dart) — ETag/304 cache, Bearer token, typed ApiException
- Auth: AuthSession + flutter_secure_storage; App Lock with local_auth
- Icons: hugeicons · Loading: auto_skeleton · Images: AppNetworkImage (cached_network_image + memCache)
- Structure: lib/core/{network,providers,theme,navigation,widgets,services,utils}; lib/features/<f>/{screens,widgets,providers,data,models}
- Theme tokens: <primary hex>, <surface hex>, <accent hex>, light + dark + system
- Backend: <path or URL to API routes>

## 🚫 1. No Mock Data & AutoSkeleton
## 🔌 2. Backend API check first & contract alignment
## 📱 3. UI/UX: zero overflow @320px · SafeArea + 3-button nav · forms = full screen / bottom sheet · AppStepWizard · rounded-rect buttons · slide transitions
## ⚡ 4. Riverpod & AsyncValue rules
## 🚀 5. AutoSkeleton + caching bundle for every API feature
## 🛡️ 6. Security & DPDP privacy
## ✅ 7. Quality gates: flutter analyze = 0 issues, flutter test = 100% pass
## 📒 8. Change log: read before, record after
## 🛠️ Commands
```

Fill each section from this skill's references and keep only what applies. Add
domain-specific business rules (state machines, lifecycles, money rules) as their own
numbered section. Update the file whenever a task sets a new convention, a gotcha or a
package-usage rule, in the same change. This is a living document.

## Change log format (`changes/CHANGELOG.md`)

Newest entries go at the top, one entry per task, in the same change as the code. Never
rewrite old entries. If you correct one, add a new entry with `Corrects: <date> — …`.

```markdown
## YYYY-MM-DD — <Area> › <Feature>: <one-line summary>

- **Type:** Feature | Fix | Correction | Refactor | API | Dependency | Build
- **Problem / goal:** what was wrong or needed, in user terms.
- **Root cause:** (fixes only) why it happened.
- **What changed:** behaviour after the change; key decisions and why.
- **Files:** main files touched.
- **API / DB:** endpoints used or changed (and the backend repo entry) — or "none".
- **Related:** matching backend entry, commits, earlier entries.
- **Verified:** `flutter analyze` / `flutter test` results; manual checks.
- **Open / follow-ups:** what's not done, known limits, next steps.
```

Before starting a task, search the log for the area you're touching and read those
entries, plus the backend repo's log when the API is involved.

## Working style the owner expects

- Inspect first, then propose the files you will touch, implement, verify, and track
  the work in the TODO and changelog.
- Deliver vertical slices that work (model → repo → provider → screen → tests), not
  half-built screens.
- Never invent product facts, legal facts, contact numbers or formulas. Ask, or use
  clearly marked placeholders.
- Owner-only actions go in `docs/owner-todo.md` **and** are mentioned in the reply.
