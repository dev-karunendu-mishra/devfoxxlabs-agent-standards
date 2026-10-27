# Global Rule — Security by Design (Every App, Every Stack)

Applies to everything built: Laravel/PHP, Node.js/NestJS/Express, Next.js/React, Flutter/mobile, any API, worker, admin panel or AI feature. Security is built **with** each feature, not audited afterwards. Think like an attacker (hacker / fraudster / cyber-criminal) before writing the code. Full checklist + per-stack rules: the **`secure-development`** skill (`skills/secure-development/SKILL.md`).

## Every task
1. **Threat-model first (2 min):** assets (money, personal data, KYC, admin power, paid API credits), actors (guest, other user, expert/vendor, compromised admin, a tampered mobile app, webhooks), entry points, abuse cases. Write it in the change log/PR entry.
2. **Build the defences in the same change** and add **negative tests** for each abuse case (other user → 403/404, tampered price → server price, no token → 401, over limit → 429, bad file → 422).
3. **Before finishing:** dependency audit (`composer audit`, `npm audit --omit=dev`, OSV/pub), check the diff for secrets/debug code, log anything unfinished in the project's gaps file with 🔴/🟠/🟡, and put owner-only steps (key rotation, console settings) on the owner TODO. Never claim "100% secure".
4. Touching code with a known hole: fix it or log it; never build a feature on top of it.

## Non-negotiables
- **Authorization on the server, deny by default:** every route authenticated unless deliberately public; admin routes role-checked; **every client-sent ID checked for ownership and for belonging to the other IDs in the request**. Hiding UI is not authorization. Tokens for one app/scope are refused elsewhere.
- **Never trust the client** for price, amount, discount, fee, payout, role, status, user_id, verified flags. The server computes money; payments verified by signature on the server, idempotent, row-locked. No mock/test/skip-payment paths, demo users or seeders reachable in production.
- **Auth:** MFA mandatory for admins on every sign-in path; every path (password, OTP, social, restore, API) enforces the same checks; only **verified** phone/email can sign in or recover; OTPs random, hashed, single-use, short-lived, attempt-limited; revoke other sessions on password/email/role change.
- **Input/output:** server-side allow-list validation on every input; ORM/bound parameters only; no `eval`/shell/unserialize with input; mass-assignment protection; escape output, sanitise every raw HTML/SVG (server-side too for SSR), JSON in `<script>` hex-encoded.
- **Rate limits** on every public write, auth/OTP, AI/SMS/email/paid-API and expensive endpoint (per user + per IP, daily caps); a test fails if a public write route has no throttle.
- **Files:** allow-listed types, server-chosen random names, private disk + signed URLs for private files, no script execution in upload dirs, `nosniff` on serving. **No fetching user-supplied URLs** (SSRF).
- **Secrets:** never in git, `.env.example`, logs, frontend bundles (`NEXT_PUBLIC_*`/`VITE_*`) or apps; a leaked secret is rotated. Fail closed when a required secret is missing. Production: debug off, generic errors, web root = `public/`, no API docs/debug tools for guests.
- **Web:** security headers + CSP, CSRF on, CORS allow-list, no admin route maps / internal data in page props.
- **Mobile:** the app is attacker-controlled — all rules on the server; tokens in secure storage; HTTPS only; own release keystore (never debug-signed), R8, `--obfuscate --split-debug-info`, `allowBackup=false`; no tokens/OTPs/PII in logs (`kDebugMode`); links from content only via a scheme allow-list (`https`, `tel`, `mailto`).
- **AI:** model output is untrusted; tools take the user from the session, not the model; cap cost.
- **Logs:** security events yes, secrets/OTPs/tokens/full bank numbers/KYC never; mask identifiers.
- **Dependencies:** lockfiles, audits in CI, no critical/high shipped; least-privilege keys; MFA on every provider account; off-site encrypted backups.
- **Defence in depth, four layers, no single point of failure:** *prevent* (these rules) → *enforce automatically* (CI gates) → *detect* (security logs + alerts) → *recover* (rotation, immutable backups, runbook). Every abuse case names the layer that stops it; "nothing" = not done.
- **Risk tiers:** auth, payments/wallet/payouts, admin powers, KYC, uploads, webhooks and AI tools are **High**: full threat model, race tests for money, a second review, kill-switch flag.
- **Enforcement gates in every project** (set up at start, or log as a gap): secret scan (gitleaks), dependency audit, SAST (Semgrep OWASP rules), guard tests (admin routes role-checked, public writes throttled, headers present, no debug-signed/cleartext mobile builds), ZAP baseline on staging, MobSF before store uploads, pentest of High-tier flows before launch and every 6–12 months.
- **Fraud & takeover:** new-device alerts, payout hold 24–72 h after email/phone/password/payout-account changes, velocity limits on payouts/refunds/coupons, admin review (two-person for large amounts).
- **Resilience:** CDN/WAF in front with origin hidden, timeouts + size caps everywhere, circuit breakers for third parties, fail-closed flags to switch abused features off, phishing-resistant MFA on every owner console.
- Write this rule (or a pointer to it) into each project's own rules file when setting a project up.
