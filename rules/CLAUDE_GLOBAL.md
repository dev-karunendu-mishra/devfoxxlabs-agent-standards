# Global Rule — India DPDP Compliance First (every web app, Flutter/mobile app, backend)

Applies to every project I build for users in India — websites, web apps, Flutter / mobile apps,
and backends/APIs — whatever the stack. Legal & data-protection compliance under the
**Digital Personal Data Protection Act, 2023 (DPDP Act)** and the **DPDP Rules, 2025** is a
foundation, not a feature: build it **first**, then start the other features.

## Order of work

1. **New project:** before any other feature, set up the legal & consent foundation below
   (notices, consent capture, consent ledger, withdrawal, rights, grievance, cookie/tracker gating).
2. **Existing project:** before adding features, audit it against the checklist below, list the
   gaps to me, then fix them (or confirm with me which to fix first).
3. **Every later feature** that collects new personal data, adds a tracker/SDK/third-party
   processor, or adds a new purpose must update the notices, the consent purposes and the ledger
   in the same change.
4. Never invent legal facts. Company name, address, Grievance Officer name/email/phone, support
   emails — read them from config/env and ask me for the real values; until then use clearly
   marked placeholders. Say plainly that the texts need a lawyer's review (this is not legal advice).

## Checklist (implement all that apply)

### 1. Notices (one source, versioned)
- Pages: **Privacy Notice**, **Terms of Service**, **Refund & Cancellation Policy** (if any payment),
  **Cookie Policy** (if the website uses cookies/storage beyond strictly necessary),
  **Partner/Vendor Terms** (if a marketplace).
- Store each notice once (JSON/Markdown/DB) with `version` + `last_updated`; serve the same
  text to the website and the apps (e.g. `GET /legal`, `GET /legal/{slug}`). No copy-pasted
  texts that drift. Contact details come from config (placeholders filled at render time).
- Privacy Notice (DPDP s.5 + Rules) must state, in plain language: who the Data Fiduciary is;
  each item of personal data and its specific purpose; legal basis (consent / legitimate use);
  every processor / third party it reaches; cross-border transfer; retention per data type;
  the user's rights and how to use them; how to withdraw consent; the Grievance Officer /
  contact with response times; the right to complain to the **Data Protection Board of India**;
  children's data; breach notification; changes to the notice.
- Readable in the app **without signing in** (Privacy & Legal screen) and linked in the web footer.
  Offer English + Hindi (other Eighth-Schedule languages on request).

### 2. Consent — free, specific, informed, unambiguous, unbundled
- Separate purposes: **required** (account/service) vs **optional** (marketing, analytics,
  advertising, personalisation…). Optional = **off by default**.
- Sign-up: an **unticked** checkbox the user ticks, with links to Privacy Notice + Terms;
  the **server validates** it (not HTML-only). One-tap sign-in (OTP/social) shows
  "By continuing you agree to the Terms and Privacy Notice" next to the button.
- Never bundle optional consent into the required one; never pre-tick; silence, scrolling or
  continued use is never consent.

### 3. Consent ledger (proof with timestamps)
- Append-only table (never update/delete rows except when legally erasing the account), e.g.
  `consent_records`: `user_id` (nullable), `visitor_id` (anonymous, for cookie choices),
  `purpose`, `status` (granted | denied | withdrawn), `method` (checkbox | signup_notice |
  cookie_banner | preferences | consent_settings), `source` (web | android | ios),
  `notice_version` (e.g. `terms@2026-10-18;privacy@2026-10-18`), `ip_address`, `user_agent`,
  `created_at`.
- Record at **every** account-creation path (email, OTP, social, admin-invited), every optional
  consent change (including notification/marketing toggles), and every cookie-banner decision.
- Users can see their own consents + history (when, where, which version) in the app/website.

### 4. Withdrawal as easy as giving
- App/website "Your consents" screen with switches for optional purposes; marketing toggles in
  notification settings stay in sync with the ledger.
- Website footer on every page: **"Cookie preferences"** to reopen the banner.
- Withdrawal takes effect immediately: stop the processing, delete tracker cookies/storage,
  unload/reload without the tracker. Required (account) consent is withdrawn by deleting the account.

### 5. Website cookies & trackers
- **No** analytics, ads, pixels, session-replay or chat widgets load or send anything before
  the matching category is accepted (load scripts from JS after consent; don't rely on
  "consent mode" pings).
- Banner: **Reject all** with the same prominence as **Accept all**, plus **Customize** per
  category; closing = reject. Strictly necessary cookies need no consent.
- Cookie Policy lists every cookie/storage key, purpose, category and lifetime.

### 6. Mobile apps (Flutter etc.)
- No analytics/ads/attribution SDK initialised before consent. OS permissions (location,
  camera, contacts, notifications, microphone) requested just-in-time with a clear reason.
- A **Privacy & Legal** screen (reachable for guests and from Settings + drawer/menu):
  all notices with version/date, "Your consents" (state + timestamped history + switches),
  "Make a privacy request", Grievance Officer card, shortcuts to download data / deactivate /
  **delete account in-app** (also required by Play Store / App Store).

### 7. Data Principal rights (DPDP ss.11–14)
- Access (summary of data, purposes, who it was shared with) / export; correction & completion;
  erasure (except records the law requires — say which); **nomination**; withdrawal; grievance.
- In-app/web request form → grievance inbox with acknowledgement; free of charge; identity check.
- Grievance Officer + timelines in config (e.g. acknowledge within 48 h, resolve within 30 days);
  escalation to the Data Protection Board.

### 8. Children
- Default 18+. If minors can use it: verifiable parental consent; no tracking, behavioural
  monitoring or targeted ads aimed at children.

### 9. Security, retention, breach
- Reasonable security safeguards: HTTPS, hashed passwords, encrypted secrets/tokens, least-privilege
  access, access logs; don't log personal data unnecessarily.
- Written retention schedule per data type + scheduled deletion/anonymisation jobs; keep
  consent records and security logs as long as needed to prove compliance.
- Breach runbook: notify the Data Protection Board and every affected user without delay
  (DPDP Rules: initial intimation promptly, detailed report within 72 hours) — record who/what/when.
- Third-party processors listed in the Privacy Notice; data shared only for the stated purpose;
  no transfer to countries restricted by the Central Government.

### 10. Verification (part of "done")
- Tests: sign-up fails without consent; ledger rows written for each path with version + time;
  optional consents off by default; withdrawal recorded and effective; legal endpoints/pages
  render; no tracker requests before consent (browser check for the web).
- Keep the change log entry for the legal work like any other feature.

# Global Rule — Icons: Hugeicons (free) everywhere

Applies to every frontend I build — web (React / Next.js / any JS framework) and Flutter / mobile apps.

- Use **only Hugeicons, free set** (Stroke Rounded):
  - **Web / React / Next.js:** `@hugeicons/react` (`HugeiconsIcon` component) + `@hugeicons/core-free-icons` (named imports, tree-shaken).
  - **Flutter:** the `hugeicons` package from pub.dev.
- Never add another icon library (lucide, heroicons, react-icons, font-awesome, Material Icons / `Icons.*`, Cupertino icons, etc.) and never draw ad-hoc inline SVG icons. Brand logos/illustrations are assets, not icons.
- Never use Hugeicons Pro packages (`@hugeicons-pro/*`) unless I say a Pro licence is available.
- If an existing project uses a different icon library, list it and ask before migrating.
- Icon-only buttons need an accessible label (`aria-label` / `Semantics` / `tooltip`); decorative icons are hidden from screen readers.
- Write this rule into each project's own rules/design-system doc when setting the project up.

# Global Rule — Security by Design (every app, every stack)

Applies to everything I build: Laravel/PHP, Node.js/NestJS/Express, Next.js/React, Flutter/mobile,
any API, worker, admin panel or AI feature. Security is built **with** each feature, not audited
afterwards. Think like an attacker (hacker / fraudster / cyber-criminal) before writing the code.
Full checklist + per-stack rules: the **`secure-development`** skill — load it for any feature,
endpoint, auth flow, upload, payment, AI feature, dependency or deploy change, and for audits.

## Every task
1. **Threat-model first (2 min):** assets (money, personal data, KYC, admin power, paid API credits),
   actors (guest, other user, expert/vendor, compromised admin, a tampered mobile app, webhooks),
   entry points, abuse cases. Write it in the change log/PR entry.
2. **Build the defences in the same change** and add **negative tests** for each abuse case
   (other user → 403/404, tampered price → server price, no token → 401, over limit → 429, bad file → 422).
3. **Before finishing:** dependency audit (`composer audit`, `npm audit --omit=dev`, OSV/pub), check
   the diff for secrets/debug code, log anything unfinished in the project's gaps file with 🔴/🟠/🟡,
   and put owner-only steps (key rotation, console settings) on the owner TODO. Never claim "100% secure".
4. Touching code with a known hole: fix it or log it; never build a feature on top of it.

## Non-negotiables
- **Authorization on the server, deny by default:** every route authenticated unless deliberately
  public; admin routes role-checked; **every client-sent ID checked for ownership and for belonging to
  the other IDs in the request**. Hiding UI is not authorization. Tokens for one app/scope are refused elsewhere.
- **Never trust the client** for price, amount, discount, fee, payout, role, status, user_id, verified
  flags. The server computes money; payments verified by signature on the server, idempotent, row-locked.
  No mock/test/skip-payment paths, demo users or seeders reachable in production.
- **Auth:** MFA mandatory for admins on every sign-in path; every path (password, OTP, social, restore,
  API) enforces the same checks; only **verified** phone/email can sign in or recover; OTPs random,
  hashed, single-use, short-lived, attempt-limited; revoke other sessions on password/email/role change.
- **Input/output:** server-side allow-list validation on every input; ORM/bound parameters only; no
  `eval`/shell/unserialize with input; mass-assignment protection; escape output, sanitise every raw
  HTML/SVG (server-side too for SSR), JSON in `<script>` hex-encoded.
- **Rate limits** on every public write, auth/OTP, AI/SMS/email/paid-API and expensive endpoint
  (per user + per IP, daily caps); a test fails if a public write route has no throttle.
- **Files:** allow-listed types, server-chosen random names, private disk + signed URLs for private
  files, no script execution in upload dirs, `nosniff` on serving. **No fetching user-supplied URLs** (SSRF).
- **Secrets:** never in git, `.env.example`, logs, frontend bundles (`NEXT_PUBLIC_*`/`VITE_*`) or apps;
  a leaked secret is rotated. Fail closed when a required secret is missing. Production: debug off,
  generic errors, web root = `public/`, no API docs/debug tools for guests.
- **Web:** security headers + CSP, CSRF on, CORS allow-list, no admin route maps / internal data in page props.
- **Mobile:** the app is attacker-controlled — all rules on the server; tokens in secure storage; HTTPS
  only; own release keystore (never debug-signed), R8, `--obfuscate --split-debug-info`,
  `allowBackup=false`; no tokens/OTPs/PII in logs (`kDebugMode`); links from content only via a
  scheme allow-list (`https`, `tel`, `mailto`).
- **AI:** model output is untrusted; tools take the user from the session, not the model; cap cost.
- **Logs:** security events yes, secrets/OTPs/tokens/full bank numbers/KYC never; mask identifiers.
- **Dependencies:** lockfiles, audits in CI, no critical/high shipped; least-privilege keys; MFA on
  every provider account; off-site encrypted backups.
- **Defence in depth, four layers, no single point of failure:** *prevent* (these rules) → *enforce
  automatically* (CI gates) → *detect* (security logs + alerts) → *recover* (rotation, immutable
  backups, runbook). Every abuse case names the layer that stops it; "nothing" = not done.
- **Risk tiers:** auth, payments/wallet/payouts, admin powers, KYC, uploads, webhooks and AI tools are
  **High**: full threat model, race tests for money, second review (`/security-review`), kill-switch flag.
- **Enforcement gates in every project** (set up at start, or log as a gap): secret scan (gitleaks),
  dependency audit, SAST (Semgrep OWASP rules), guard tests (admin routes role-checked, public writes
  throttled, headers present, no debug-signed/cleartext mobile builds), ZAP baseline on staging,
  MobSF before store uploads, pentest of High-tier flows before launch and every 6–12 months.
- **Fraud & takeover:** new-device alerts, payout hold 24–72 h after email/phone/password/payout-account
  changes, velocity limits on payouts/refunds/coupons, admin review (two-person for large amounts).
- **Resilience:** CDN/WAF in front with origin hidden, timeouts + size caps everywhere, circuit breakers
  for third parties, fail-closed flags to switch abused features off, phishing-resistant MFA on every
  owner console.
- Also covered in the skill: OAuth/JWT/webhook replay, host-header/cache poisoning, SSTI, XXE, PDF-generator
  SSRF, CSV/email/log injection, Unicode spoofing, float money, timing attacks, GraphQL/WebSocket,
  queue jobs, Firebase/Supabase/S3 rules, DNS/SPF/DKIM/DMARC, encryption at rest, people & process.
- Honesty: no system is 100% hack-proof. The target is **no known high/critical issue, every layer in
  place and gated in CI**. That stops the attacks behind the large majority of real breaches, and
  limits and recovers from the rest.
- Write this rule (or a pointer to it) into each project's own rules file when setting a project up.

# Global Rule — Database Safety: know the environment, never break data, always ACID

Applies to every database task in every stack (Laravel/Eloquent + `sql/*.sql`, Prisma/TypeORM/
Sequelize/Knex/Drizzle, raw SQL, Redis, Flutter sqflite/drift): migrations, schema changes, seeders,
data fixes, imports, writes, transactions, backups. Full standard: the **`database-safety`** skill.

- **Environment first, every time:** before any DB command, state which environment it hits
  (local / staging / production) and how you checked (`php artisan about`, `DB_HOST`/`DB_DATABASE`,
  `DATABASE_URL` host, flavor). Unknown or remote host = treat as **production**.
- **Production & staging are never broken:** no `migrate:fresh/refresh/reset`, `db:wipe`,
  `prisma migrate reset`, `DROP`, `TRUNCATE`, or `UPDATE`/`DELETE` without `WHERE`, and no demo seeders
  there. Destructive steps only on the owner's explicit request + fresh verified backup + rollback plan.
  Guard it in code (`DB::prohibitDestructiveCommands(app()->isProduction())`; Prisma `migrate deploy` only).
- **Schema changes are additive and backward-compatible:** nullable/defaulted columns, expand →
  migrate (batched backfill) → contract (drop only later, after old app versions stop using it);
  idempotent (`IF NOT EXISTS`/`hasColumn`), reversible `down()`, never edit an already-run migration;
  migrations reach staging/production only through the deploy pipeline; keep project SQL files in sync.
- **Integrity in the database:** PK/FK (deliberate `ON DELETE`), `UNIQUE` for business rules (one
  payment per gateway ID, one booking per slot), `NOT NULL`, `CHECK`; money `DECIMAL`/paise, never float;
  UTC times; InnoDB only.
- **ACID on every write:**
  - **A**: multi-row/table writes in one transaction. No payment/SMS/email/HTTP calls inside it; side
    effects run after commit (`afterCommit`, outbox).
  - **C**: invariants enforced by constraints and conditional updates (`… WHERE status='pending'`,
    check affected rows).
  - **I**: shared rows (balance, stock, slots, coupons) locked (`lockForUpdate` / `FOR UPDATE`) or
    updated atomically; idempotency keys with UNIQUE indexes; deadlocks retried.
  - **D**: durable engine settings; off-site, encrypted, versioned backups with a tested restore;
    Redis/cache is never the source of truth.
- **Production data changes:** count first → backup → dry run on staging → owner OK → run in a
  transaction with a row-count check → verify (`migrate:status`, counts, error tracker) → change log.
- Never copy real personal data to local/staging unmasked, and never paste rows into chat or logs.
- Tests: throwaway DB only; migrations tested on existing rows and on the real engine for schema changes;
  rollback-on-failure and idempotency tests for money paths.
- Write this rule (or a pointer to it) into each project's own rules file when setting a project up.

# Global Rule — Engineering Workflow: read before, record after, verify before done

Applies to every project and stack. Full standard + doc templates: the **`engineering-workflow`** skill.

- **Read first:** the project's rules file, the `changes/CHANGELOG.md` entries for the area, and
  `docs/known-gaps.md`. **Use what's already installed** and the existing pattern; a new package
  only with a stated reason and my OK.
- **Build:** S.O.L.I.D; each business rule in **one** service used by web, API, mobile and admin;
  fix web + mobile + API in the same change; reuse design-system components; all backend calls
  through the typed API client; no placeholder buttons or mock data in shipped screens; no native
  `confirm()`/`alert()`; long dialogs scroll only in the body.
- **Feature flags fail closed:** on only if the flag exists and is `true` (never `?? true`); the
  server refuses the endpoints when off; a feature that ships on creates its flag in a migration.
- **Verify before "done":** run lint/analyze/type-check/tests and report command + result; no new
  failures; see UI changes render (320 px, dark mode); say plainly what couldn't be verified.
- **Record after:** a `changes/CHANGELOG.md` entry per task in the same change (never rewrite old
  ones); fix known gaps you touch, log new ones with path/impact/fix/🔴🟠🟡; owner-only tasks go in
  `docs/owner-todo.md` under a dated section and are never ticked off without my confirmation.
- Write this rule (or a pointer to it) into each project's own rules file when setting a project up.
