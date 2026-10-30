# Global Rule — Engineering Workflow: read before, record after, verify before done

Applies to every project and stack — Laravel/PHP, Node.js/NestJS, Next.js/React, Flutter/mobile,
workers and admin panels. Full standard + doc templates: the **`engineering-workflow`** skill.

## 1. Before you start
- Read the project's rules file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `.cursorrules`).
- Search `changes/CHANGELOG.md` for the area you're touching and read those entries (root cause,
  decisions, open follow-ups). Check `docs/known-gaps.md` for items in the same area.
- **Use what's already installed.** Check `composer.json` / `package.json` / `pubspec.yaml` and the
  existing pattern for the same kind of thing, and follow it. A new package only with a stated
  reason and the owner's OK (then run the dependency audit).

## 2. While building
- **S.O.L.I.D.** Small, single-purpose classes; business rules live in **one** service/model used by
  every client (web, API, mobile, admin) — never duplicated per screen or controller.
- **Fix both sides in the same change:** a change on mobile gets the matching web/API change, and
  the reverse. Only log the other side as a gap if it truly can't be done now, and say why.
- **Reusable components** from the project's design system; no one-off copies of existing widgets.
- **All backend calls go through one typed API client module** — no inline `fetch`/`axios`/`http`
  in components or screens.
- **No placeholder actions:** no button that does nothing or only shows a toast, no mock data source
  in shipped screens. Wire it to a real API or hide it.
- **No native `confirm()` / `alert()` / `prompt()`** — use the design-system dialog (e.g. shadcn
  `AlertDialog`, a Flutter bottom sheet). A dialog whose form can scroll has a fixed header/footer
  and only the body scrolls.
- **Feature flags fail closed:** a feature is on only if its flag exists and is `true`. Missing,
  not loaded, offline or non-boolean = off. Never `?? true`. The server refuses the feature's
  endpoints when off — hiding the UI is not enough. A feature that must ship on creates its flag
  in a migration.

## 3. Verify before claiming done
- Run the linters/analyzers/type-checks and the tests for what you touched; report the command and
  the result. Don't add new failures; fix pre-existing failures in the area you touched or log them.
- For UI changes, see it render (run the app / screenshot), at the smallest supported width and in
  dark mode.
- If something couldn't be verified, say so plainly. Never claim "done" on an unverified change.

## 4. Record after
- **Change log:** every task adds an entry at the top of `changes/CHANGELOG.md` in the same change
  as the code (problem, root cause, what changed, API/DB, verified, open items). Never rewrite old
  entries — add a new one that references them.
- **Known gaps — fix, don't extend:** touching a listed area resolves that item (delete it when fully
  fixed); never build on top of a listed gap. Log new gaps you can't fix now in `docs/known-gaps.md`
  with file path, impact, proposed fix and severity 🔴/🟠/🟡 — a chat/PR mention is not enough.
- **Owner TODO:** tasks only the owner can do (consoles, secrets, `.env` values, production deploys
  and migrations, flag switches, legal review, business decisions) go in `docs/owner-todo.md` under a
  dated section, and are mentioned in the reply. Never tick one off without the owner's confirmation.

Write this rule (or a pointer to it) into each project's own rules file when setting a project up.
