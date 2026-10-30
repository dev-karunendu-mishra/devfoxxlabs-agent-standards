---
name: engineering-workflow
description: Engineering workflow standard for every app Karunendu (DevFoxx Labs) builds — Laravel/PHP, Node.js/NestJS, Next.js/React, Flutter/mobile, workers and admin panels. Read the change log and known gaps before a task, use what's already installed, follow S.O.L.I.D with one shared service per business rule, fix web and mobile in the same change, no placeholder actions or native confirm()/alert(), fail-closed feature flags, verify with real commands before claiming done, then record the change log entry, known gaps and owner TODO. Use at the start and end of every feature, fix, refactor or audit, and when setting up a new project's docs.
metadata:
  author: karunendu
  version: "1.0.0"
---

# Engineering Workflow — read before, record after, verify before done

**Applies to every project and stack.** The other standards say *what* safe code looks like
(`secure-development`, `database-safety`, `dpdp-compliance`, `flutter-production`). This one says
*how a task is run* so that the next person — or the next agent session — can pick up any feature
without re-discovering it, and so that nothing is claimed done that isn't.

Every task has four steps: **read → build → verify → record.**

---

## 1. Read before you start

1. **Project rules file** — `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `.cursorrules`. Project rules
   override the global ones where they are stricter.
2. **Change log** — search `changes/CHANGELOG.md` for the area/feature, read matching entries newest
   first (especially *Root cause*, decisions in *What changed*, and *Open / follow-ups*). When the
   feature spans repos (app + admin, app + API), read the other repo's log too.
   ```bash
   grep -n "Bookings" changes/CHANGELOG.md
   ```
3. **Known gaps** — check `docs/known-gaps.md` for items in the same area. You will either fix them
   in this change or must not build on top of them (§4).
4. **What's installed** — before writing a helper or adding a package, look for the existing one:

   | Stack | Look in | Typical existing pattern to reuse |
   |---|---|---|
   | Laravel | `composer.json`, `app/Services`, `app/Support` | Spatie packages, Form Requests, Policies, one Service per domain |
   | NestJS | `package.json`, `src/*/` | DTOs + `class-validator`, one `PrismaService`, existing guards |
   | Next.js / React | `package.json`, `components/ui`, `lib/api` | shadcn/ui, typed `lib/api/*` modules, existing form lib |
   | Flutter | `pubspec.yaml`, `lib/core` | `ApiClient`, providers, `AppModalSheet`, `AppStepWizard` |

   A new dependency needs a stated reason (what's missing from what's installed) and the owner's OK,
   then a dependency audit (`composer audit`, `npm audit --omit=dev`, OSV for pub).

## 2. Build it right

### 2.1 S.O.L.I.D and one source of truth
- Small, single-purpose classes; controllers/screens stay thin; logic lives in services/providers.
- **One rule, one place.** A business rule (who is "verified", what a plan costs, which items are
  "adoptable", default profile values) is defined in **one** model scope/service method and used by
  web, API, mobile and admin. Two copies of a rule will drift — that's how "visible on web, hidden
  on mobile" bugs happen.

### 2.2 Fix both sides in the same change
A feature or fix on one client gets the matching change on the others in the same task: mobile
screen ↔ web page ↔ API endpoint ↔ admin. If the other side truly can't be done now, log it in
`docs/known-gaps.md` with the reason — don't leave it silent.

### 2.3 Reuse the design system
- Use the project's existing components; extend one with a variant rather than copying it.
- Never use native `confirm()` / `alert()` / `prompt()`. Use the design-system dialog
  (shadcn `AlertDialog` on web, a bottom sheet / `AppModalSheet` on Flutter) for every destructive
  confirmation.
- A dialog whose form can be taller than the screen: **fixed header and footer, only the body
  scrolls** (`max-h-[90vh] flex flex-col` + `overflow-y-auto` body on web; `DraggableScrollableSheet`
  or a full-screen route on Flutter).

### 2.4 One typed API client
All backend calls go through one module per domain (`lib/api/bookings.ts`, `BookingsRepository`
in Flutter) built on the shared client. No inline `fetch`/`axios`/`http.get` in components or
screens — the shared client is where auth headers, error mapping, retries and caching live.

### 2.5 No placeholders in shipped code
- No buttons that do nothing or only show "coming soon" toasts; no `MockDataSource` / hard-coded
  lists in screens that ship. Wire it to a real endpoint, or hide it behind a fail-closed flag.
- If the endpoint doesn't exist yet, build it (or log the gap) — don't fake the data.

### 2.6 Feature flags fail closed
A flagged feature is **on only if its flag exists and is exactly `true`**. Missing, not loaded yet,
offline, error or non-boolean = **off**.

| Layer | Do | Never |
|---|---|---|
| Laravel | `FeatureFlags::enabled('x')` with no default; route middleware returns 404/403 when off | `config('features.x', true)` |
| NestJS | guard reads the flag, throws `NotFoundException` when off | `flags.x ?? true` |
| Next.js / React | `features?.x === true` | `features?.x !== false`, `?? true` |
| Flutter | `flags.enabled('x')` → `?? false` at call sites | `flags['x'] ?? true` |

- Hiding the UI is not enough: the **server refuses** the feature's endpoints when the flag is off.
- A feature that must ship **on** creates its flag row in a migration (plus the project's `sql/` file
  if it keeps one).
- Test: the feature is hidden **and** its endpoint refused when the flag is missing.
- High-risk features (payments, payouts, AI, uploads) get a flag so they can be switched off
  without a deploy (see `secure-development`).

## 3. Verify before claiming done

"Done" means you ran it and saw it work — not that it compiles in your head.

| Stack | Minimum gate |
|---|---|
| Laravel | `php artisan test` (or the touched suites), `./vendor/bin/pint --test`, PHPStan if configured |
| NestJS / Node | `npm run lint`, `npm run build` / `tsc --noEmit`, `npm test` |
| Next.js | `npm run lint`, `npm run build` (type-checks), tests if present |
| Flutter | `flutter analyze` (0 issues), `flutter test` |

- Report the exact command and the result in the reply.
- **Don't add new failures.** If the area you touched already had failing tests, fix them or log
  them as a gap — don't hide them.
- **UI changes:** run the app and look — smallest supported width (320 px on mobile), light **and**
  dark mode, empty/loading/error states.
- **Anything you couldn't verify** (no device, no credentials, needs production data): say so
  plainly and put the check on the owner TODO if only the owner can do it.

## 4. Record after

### 4.1 Change log — `changes/CHANGELOG.md`
One entry per task, at the top, **in the same change as the code**. Never rewrite old entries; a
correction is a new entry with `Corrects: <date> — …`. Format and housekeeping:
[templates/changes/README.md](templates/changes/README.md).

```markdown
## 2026-10-31 — Bookings › Reschedule: experts can move a confirmed booking once

- **Type:** Feature
- **Problem / goal:** customers asked experts to move sessions by phone; no way to do it in-app.
- **What changed:** `BookingService::reschedule()` (one place for web + API); slot locked with
  `lockForUpdate`; one reschedule per booking (DB check). Web modal + Flutter bottom sheet.
- **Files:** `app/Services/BookingService.php`, `RescheduleController.php`, `reschedule_sheet.dart`
- **API / DB:** `POST /api/v1/bookings/{id}/reschedule`; `bookings.rescheduled_at` (nullable).
- **Related:** admin repo entry 2026-10-31 — Bookings › Reschedule.
- **Verified:** `php artisan test --filter=Reschedule` 9 passed; `flutter test` 212 passed; manual on 320 px.
- **Open / follow-ups:** customer-side notification copy needs Hindi translation (known-gaps #14).
```

### 4.2 Known gaps — `docs/known-gaps.md`
- **Fix, don't extend.** Touching a listed area means resolving that item (or the part your change
  covers) in the same change; delete the item when it's fully resolved. Never build new features
  on top of a listed gap.
- **Log what you find but can't fix now:** file path, impact, proposed fix, severity —
  🔴 blocks production use · 🟠 wrong/inconsistent behaviour · 🟡 polish / tech debt.
  A mention only in chat or a PR description is not enough.
- Template: [templates/docs/known-gaps.md](templates/docs/known-gaps.md).

### 4.3 Owner TODO — `docs/owner-todo.md`
Anything only the owner can do — cloud/store consoles, API keys and `.env` values, secret rotation,
feature-flag switches, production deploys and migrations, legal review, business decisions — goes
under a dated section, and is also mentioned in your reply. Never tick an item off without the
owner's confirmation or a check you can show.
Template: [templates/docs/owner-todo.md](templates/docs/owner-todo.md).

### 4.4 Rules file
If the task set a new convention or uncovered a gotcha (a package quirk, a naming trap, a framework
pitfall), add it to the project's rules file in the same change, as a numbered rule with the *why*.

## 5. New project setup

Copy the templates into the project and point the rules file at them:

```
changes/README.md      ← templates/changes/README.md
changes/CHANGELOG.md   ← templates/changes/CHANGELOG.md
docs/known-gaps.md     ← templates/docs/known-gaps.md
docs/owner-todo.md     ← templates/docs/owner-todo.md
```

Then add the four-step workflow (or a pointer to `rules/engineering-workflow.md`) to the project's
`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, next to the DPDP, security, database and icon rules.

## 6. Done checklist

- [ ] Read the rules file, change-log entries and known gaps for the area
- [ ] Reused installed packages and existing patterns; no new dependency without the owner's OK
- [ ] Business rule in one place; web + mobile + API changed together
- [ ] No placeholders, no native dialogs, API calls through the typed client
- [ ] Flags fail closed and the server enforces them
- [ ] Lint/analyze/type-check/tests run — command + result reported; UI seen at 320 px + dark mode
- [ ] Change-log entry added; gaps fixed or logged; owner tasks on the owner TODO
