---
name: secure-development
description: Security-by-design standard for every app Karunendu (DevFoxx Labs) builds — Laravel/PHP, Node.js/NestJS/Express, Next.js/React, Flutter/mobile, any API, worker or admin panel. Threat-model each feature like an attacker, build the defences in the same change, and prove them with tests. Based on OWASP ASVS 5.0, OWASP Top 10 / API Security Top 10, OWASP MASVS and CWE Top 25. Use whenever implementing, reviewing or auditing any feature, endpoint, screen, upload, payment, auth flow, AI feature, dependency or deploy config.
metadata:
  author: karunendu
  version: "1.0.0"
---

# Secure Development — build it like an attacker is watching

**Applies to every project and every stack:** Laravel / PHP, Node.js (NestJS, Express), Next.js / React, Flutter / mobile, any API, worker, cron, admin panel or AI feature.

Security is part of the implementation, not a later audit. A feature is **not done** until its abuse cases have been thought through, defended in code and covered by tests. Work like a penetration tester reviewing your own change: ask *"how would someone steal, cheat, spy or break this?"* before asking *"does it work?"*

Standards behind these rules: OWASP ASVS 5.0 (target **Level 2** for anything with accounts or money, **L3** for payments/health/identity documents), OWASP Top 10 (web) and API Security Top 10, OWASP MASVS (mobile), OWASP LLM Top 10, CWE Top 25, NIST SSDF (SP 800-218), CIS Controls v8, and the India DPDP Act 2023 / CERT-In directions (see the `dpdp-compliance` skill).

### How this gets close to "un-hackable"
No system is 100% hack-proof: zero-days, a provider breach or a tricked employee can always happen. What these rules aim for is that **no single mistake becomes a breach**. Every attack has to get past four layers, and each one is required:

1. **Prevent:** secure defaults and the checklists below. They close the holes behind most real breaches: broken access control, stolen or reused credentials, misconfiguration, leaked secrets, unpatched dependencies, injection, and business-logic abuse.
2. **Enforce automatically** (§19): CI gates, guard tests and scanners, so a rule can't be forgotten. A rule that exists only as text will eventually be broken.
3. **Detect:** security logs, alerts and fraud signals (§12, §17), so an attack in progress is seen in minutes, not months.
4. **Recover:** containment, key rotation, immutable backups and a practised runbook (§12, §18), so even a successful attack is limited and reversible.

Every feature must state which layer stops each abuse case. If the answer is "nothing", the feature isn't done.

### Risk tiers: how deep to go
| Tier | Examples | Required |
|---|---|---|
| **High** | auth/login/OTP, payments, wallet, payouts, refunds, admin powers, KYC/ID files, permissions/roles, file upload, webhooks, AI tools with data access, crypto/secrets | Full threat model, negative tests for every abuse case, race-condition test for money, second review (human or a separate review agent run with `/code-review` or `/security-review`), entry in the security log |
| **Medium** | any new endpoint or form with personal data, chat, search, notifications, new third-party SDK | Threat model, authz + validation + throttle tests |
| **Low** | read-only public content, styling, copy | Checklist glance, no secrets/debug in diff |

---

## 0. Workflow — every task

1. **Before coding — 2-minute threat model** of the feature (write it in the PR/changelog entry, not in chat only):
   - *Assets*: what is valuable here (money, wallet balance, personal data, KYC files, admin power, AI/SMS/email credits)?
   - *Actors*: guest, customer, other customer, expert/vendor, admin, compromised admin, the mobile client itself (it is attacker-controlled), third-party webhooks.
   - *Entry points*: every route, form field, query param, header, file, webhook, queue message, deep link, push payload, AI prompt.
   - *Abuse cases* (STRIDE): spoof identity, tamper with price/role/IDs, repudiate (no audit trail), leak data, deny service / run up costs, gain privilege.
2. **While coding:** apply the checklists below. Choose the secure default; anything weaker needs a written reason.
3. **Tests are part of done:** at least one negative test per abuse case (wrong user → 403/404, tampered price → server price used, no token → 401, over limit → 429, bad file → 422).
4. **Before finishing:** run the dependency audit, grep your diff for secrets / debug output, and list any security item you could not finish in the project's gaps/backlog file with severity 🔴/🟠/🟡. Never claim "secure" — say what was checked.
5. **Existing code you touch:** if you see a vulnerability nearby, fix it in the same change or log it. Never build a new feature on top of a known hole.

---

## 1. Authorization — the #1 real-world bug (OWASP A01 / API1 BOLA / API5 BFLA)

- **Deny by default.** Every route is authenticated unless it is deliberately public; every admin route has an explicit role/permission check on the **server** (middleware/guard/policy). Hiding a button is not authorization.
- **Object-level checks on every ID** from the client (`/bookings/{id}`, `conversation_id`, `media_id`, `payout_method_id`…): load it *through the current user* (`$user->bookings()->findOrFail($id)`, `where({ id, userId })`) or check ownership in a policy. Return 404 (or 403) for someone else's object.
- **Never trust client-sent ownership or role fields**: `user_id`, `customer_id`, `role`, `is_admin`, `status`, `is_verified`, `price`, `amount`, `discount`, `commission`. Derive them from the session and the database.
- **Relationship checks**: an ID must belong to the *other* IDs in the same request (the service belongs to this expert; the slot belongs to this service; the coupon applies to this booking). *(Real bug: a booking endpoint took any `service_id`, so a ₹1 service priced a premium session.)*
- **Function-level**: list every route with its effective middleware (`php artisan route:list -v`, Nest guards, Next.js middleware/route handlers) and add a test that fails if an `admin/*` route lacks the admin check. Watch for duplicate route definitions — the last one wins.
- **Token audience/scope**: tokens issued for one app or purpose (SSO for a store, `profile:read`) must be refused by APIs meant for another. Check scopes/client type in middleware.
- **Multi-tenant / role areas** (expert, vendor, temple admin): scope every query by the tenant; never `Model::find($id)` alone inside a tenant area.
- Real-time channels (WebSocket/Pusher/Reverb/Socket.IO) authorize each channel subscription the same way as HTTP.

## 2. Authentication, sessions & account recovery (A07)

- Passwords: Argon2id/bcrypt via the framework; min 8, max 128; breached-password check in production; no composition rules that weaken UX. Never log, email or return passwords.
- **Admin / staff accounts: MFA mandatory** on *every* sign-in path (web, API, social, OTP). Short admin token lifetime (≤ 24 h) and re-auth for dangerous actions.
- **Every sign-in path enforces the same rules** (2FA, ban, email verified, onboarding gate): password, OTP, social, magic link, session restore, API. *(Real bug: phone-OTP login skipped 2FA.)*
- **Only verified identifiers sign you in.** Phone/email used for OTP login, account linking or recovery must have been verified by a code. Changing them requires a code to the new value. Social login links to an existing account only if the provider verified the email.
- OTP / codes: ≥ 6 digits, random (`random_int`, `crypto.randomInt`, `Random.secure`), hashed at rest, single-use, ≤ 10 min, ≤ 5 attempts, resend cooldown + hourly cap, throttled per identifier **and** per IP. Never log codes, even in "SMS not configured" fallbacks.
- Same response for "account exists / doesn't exist" on login, reset and deletion flows where practical (no user enumeration); if UX needs it, throttle hard.
- On password change, email change, 2FA reset, role change or "sign out everywhere": **revoke other tokens and sessions**, notify the old email.
- Sessions/cookies: `HttpOnly`, `Secure`, `SameSite=Lax` (or Strict), regenerate the session ID on login and privilege change, sensible idle/absolute timeouts.
- Mobile tokens: short-lived access + refresh with rotation where the stack allows; revoke on logout server-side.

## 3. Input, injection & output encoding (A03, A05 2025)

- Validate **every** input on the server with an allow-list schema (Laravel `FormRequest`/`validate`, Zod/class-validator/Joi in Node, `zod` in Next.js server actions): type, length (`max`), range, enum, format. Client-side validation is UX only.
- **SQL**: only the ORM/query builder or bound parameters. Never concatenate input into SQL, `orderBy`, column names or `whereRaw` — allow-list sortable columns.
- **NoSQL / Mongo**: reject objects where strings are expected (`{"$gt": ""}`); cast types.
- **Command/code**: never pass input to `exec`, `shell_exec`, `child_process`, `eval`, `new Function`, `unserialize`, `pickle`, YAML `load` with tags. Use argument arrays (`Process::run([...])`, `spawn(cmd, args)`).
- **XSS**: rely on the framework's auto-escaping (`{{ }}`, JSX). Every `{!! !!}`, `dangerouslySetInnerHTML`, `v-html`, `innerHTML`, `Html()` widget needs a sanitiser (DOMPurify on the client **and** a server sanitiser for SSR/stored HTML; `enshrined/svg-sanitize` for SVG). JSON inside `<script>` must be encoded with `JSON_HEX_TAG|JSON_HEX_AMP|JSON_HEX_APOS|JSON_HEX_QUOT` (PHP) or `serialize-javascript`/escape `<` (JS). *(Real bug: `</script>` in a vendor's address broke out of JSON-LD.)*
- Markdown → HTML: disable raw HTML or sanitise the output; keep the parser patched.
- **Mass assignment**: `$fillable` (never `$guarded = []`), DTOs/`whitelist: true` in Nest, explicit field picks in Next.js. Never `Model::create($request->all())`.
- Path inputs: never build file paths from input; if unavoidable, `realpath` + prefix check, reject `..`, NUL bytes and absolute paths.
- Regex on user input: avoid catastrophic backtracking (ReDoS); cap input length first.
- Deserialisation of untrusted data: JSON only.

## 4. Business logic & money (the bugs scanners never find)

- **The server computes every price, fee, discount, tax, payout and balance** from its own records. The client may send *choices* (which service, which coupon), never *amounts*.
- Payments: create the order on the server, verify the gateway signature (`hash_equals` / `timingSafeEqual`) on the server, tie the order to the user and the object, make verify/webhook **idempotent** (unique payment ID, status check under a row lock), and only then mark paid. Webhooks fail **closed** when the secret is empty.
- **Race conditions**: balance debits, coupon redemptions, stock/slot booking and payouts run inside a DB transaction with `lockForUpdate` / `SELECT … FOR UPDATE` or an atomic conditional update; add unique constraints (one booking per slot, one redemption per user). Test two concurrent requests where it matters.
- Limits are enforced on the server: max quantity, max duration, date ranges (no past dates, no year 9999), allowed status transitions (state machine — `pending → paid → completed`, never `cancelled → paid`).
- Never ship "mock", "test", "debug" or "skip payment" code paths reachable in production (`payment_method=mock`, `?debug=1`, seeders inside controllers, demo users with known passwords).
- Refunds/credits: only to the original method or wallet, never more than paid, recorded in an append-only ledger.
- Anything that sends SMS/email/push, calls a paid API (AI, TTS, maps, OTP) or creates gateway orders is a **cost target**: throttle per user and per IP, add daily caps, require login where possible, set billing alerts at the provider.

## 5. Rate limiting & abuse (API4 / API6)

- Every public write endpoint has a throttle; auth/OTP/reset endpoints have strict ones (≈5–10/min per identifier + per IP); expensive reads (search, exports, AI) too. Add a guard test that fails when a new public write route has no throttle.
- Pagination limits are capped on the server (`min(50, limit)`); exports are async and rate-limited.
- Forms open to guests: honeypot and/or Cloudflare Turnstile; cap message sizes; never send mail to an arbitrary address more than once per hour.
- Request body size limits at the server/proxy; upload size limits per field.

## 6. Files & uploads

- Allow-list extensions **and** MIME (`mimes:jpg,png,webp,pdf`); never accept SVG/HTML/JS/PHP from users. Laravel's `image` rule, `file-type` sniffing in Node.
- Store under a **random name** chosen by the server, with the extension mapped from the validated MIME. Never use the client file name in the path.
- Private files (KYC, invoices, chat attachments, medical/ID documents) on a private disk/bucket, served through an ownership check or **short-lived signed URLs**. Never in `public/`.
- Uploaded/public storage must not execute scripts (`.htaccess` / nginx `location` deny for `php|phtml|phar|pl|py|cgi|sh`).
- Serve user files with `X-Content-Type-Options: nosniff`, `Content-Disposition: attachment` (except images/PDF inline), and `Content-Security-Policy: sandbox`.
- Images: re-encode/strip metadata (EXIF GPS) for public photos; cap pixel dimensions (decompression bombs).
- Archives: never extract user zips without path and size checks (zip slip, zip bombs).

## 7. SSRF & outbound requests

- Never fetch a URL the user supplied. If a feature truly needs it: allow-list hosts, `https` only, resolve DNS and block private/loopback/link-local/metadata ranges (`10/8, 172.16/12, 192.168/16, 127/8, 169.254/16, ::1, fc00::/7`), no redirects to other hosts, timeouts and size caps.
- Outbound HTTP clients always have timeouts and TLS verification on (never `verify => false`, `rejectUnauthorized: false`, `badCertificateCallback => true`).
- Don't forward user cookies/tokens to third parties.

## 8. Secrets & configuration (A02 / A05)

- No secrets in code, git, `.env.example`, mobile apps, frontend bundles (`NEXT_PUBLIC_*`, `VITE_*`, Flutter `--dart-define` are **public**), logs, error messages or screenshots. Only publishable keys go to clients (Razorpay key ID, Firebase config — restricted in the console).
- `.env`, keystores, `key.properties`, service-account JSON, `*.pem` are git-ignored; scan staged changes for secrets (gitleaks/trufflehog or `git grep` for `sk_live|rzp_live|AKIA|-----BEGIN|AIza`). A secret that ever reached git is **rotated**, not just deleted.
- Production: `APP_DEBUG=false` / `NODE_ENV=production`, generic error pages, `LOG_LEVEL=warning`, document root = `public/` only, no `phpinfo`, no stray scripts, no source maps with secrets, no `/docs` or Swagger for guests, no Telescope/Horizon/debug bars without admin auth.
- Fail **closed** when a required secret/config is missing (webhooks, signature checks, feature flags off by default).
- Least-privilege credentials: separate DB users per app, no `GRANT`/`FILE`, write-only backup keys, scoped API keys, separate keys per environment.

## 9. Security headers, CORS & browser (web)

- Headers on every response: `Strict-Transport-Security` (prod, HTTPS), `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (only what's used), `X-Frame-Options`/CSP `frame-ancestors`, and a **CSP** (start Report-Only, then enforce; nonces for inline scripts).
- CSRF protection on for all cookie-authenticated state changes; exemptions only for signature-verified webhooks.
- CORS: explicit allow-list of your own origins; never `*` with credentials; no reflecting the `Origin` header.
- Don't ship internal maps to the browser: full route lists (Ziggy `@routes`), admin endpoint names, feature internals, other users' data in page props/`__NEXT_DATA__`/Inertia props. Send each role only what it needs; `$hidden` / `select` / DTOs for models.
- Third-party scripts (analytics, ads, chat) load only after consent (DPDP) and only from allow-listed hosts; prefer Subresource Integrity for static CDN files.
- Open redirects: redirect only to relative paths or allow-listed hosts.

## 10. Mobile apps (Flutter / native) — OWASP MASVS

- **The app is in the attacker's hands**: anything in it (code, strings, endpoints, flags) is readable. All rules live on the server; the app only displays.
- Tokens in `flutter_secure_storage` (Keychain/Keystore), never `SharedPreferences` or plain files. Clear tokens, caches and sensitive files on logout.
- HTTPS only: no `usesCleartextTraffic`, no ATS exceptions, no `badCertificateCallback`. Consider certificate/public-key pinning for high-value apps (with a rotation plan and backup pins).
- Android: release signed with your own upload key (never the debug key), Play App Signing, `minifyEnabled` + R8, `android:allowBackup="false"` (or extraction rules excluding auth/cache), exported components only when needed and protected, no `READ_EXTERNAL_STORAGE`-style broad permissions.
- Build releases with `--obfuscate --split-debug-info=<dir>`; keep symbols privately.
- No secrets, tokens, OTPs, full URLs with query strings or personal data in logs — `debugPrint`/`print`/`console.log` reach logcat/console in release; guard with `kDebugMode` and mask.
- Links/deep links from server content, push payloads or chat: allow-list schemes (`https`, `tel`, `mailto`) and validate routes before navigating; never open `intent:`, `upi://pay`, `file:` or arbitrary custom schemes from content. Verify App Links / Universal Links.
- WebViews: JavaScript off unless needed, no `addJavascriptInterface`/JS channels for untrusted pages, restrict navigation to your hosts.
- Permissions just-in-time with a clear reason; biometric/App Lock backed by the OS (`local_auth`) and re-locks on background.
- Sensitive screens (KYC, payments, chat, OTP): consider `FLAG_SECURE` / app-switcher blur.
- Root/jailbreak detection and Play Integrity / App Attest for high-value actions (payments, payouts) where it's worth it — as a signal, never the only control.

## 11. AI / LLM features (OWASP LLM Top 10)

- Treat model output as untrusted input: escape/sanitise before rendering, validate before acting, never `eval` it or pass it to SQL/shell.
- Tools/functions the model can call get the user identity **from the session**, never from model arguments; tools are read-only unless the user confirms.
- Prompt injection: content from users, web pages, documents or emails can contain instructions — keep system prompts free of secrets and never let retrieved content change permissions.
- Cost/abuse: throttle per user and IP, cap prompt and history length, daily caps, provider spend alerts.
- Don't send personal data to AI providers beyond what the feature needs; list the provider in the Privacy Notice (DPDP).

## 12. Logging, monitoring & incident response (A09)

- Log security events (login success/failure, MFA, password/email change, role change, admin actions, payment verification failures, permission denials) with user ID, IP and time — **never** passwords, OTPs, tokens, full card/bank numbers, KYC data or message bodies. Mask identifiers (`XXXX1234`, first 8 chars of tokens).
- Append-only audit log for admin actions and money movements.
- Error tracking (Sentry) with PII scrubbing (`send_default_pii=false`); alerts on error spikes, 401/403/429 spikes, webhook signature failures.
- Breach runbook: contain, rotate secrets, revoke sessions, preserve logs, notify the Data Protection Board and affected users (DPDP: promptly, detailed report within 72 h).

## 13. Dependencies & supply chain (A06 / A03 2025)

- Lockfiles committed; install with `npm ci` / `composer install --no-dev` / `flutter pub get` from the lockfile in CI.
- Run `composer audit`, `npm audit --omit=dev --audit-level=high` (or `pnpm audit`), `dart pub outdated`/OSV scanner before every release and in CI; enable Dependabot/Renovate. Fix critical/high before shipping.
- Before adding a package: maintained, widely used, no install scripts you don't need, licence OK. Prefer the platform/framework feature over a new dependency.
- Pin GitHub Actions to commit SHAs or trusted major versions; secrets only in CI secret stores; least-privilege `GITHUB_TOKEN` permissions.

## 14. Infrastructure & deploy

- HTTPS everywhere (HSTS), TLS 1.2+; database and Redis not reachable from the internet; SSH by key only; hosting panel + every provider account (Cloud, payments, SMS, AI, DNS, Git) on MFA.
- Backups: off-site, encrypted, write-only credentials, restore tested quarterly.
- File permissions: no 777; `.env` 600; web server can't write to code directories.
- Separate staging and production data; never copy real personal data into dev/staging without masking.

## 15. Advanced attack classes: check when the feature touches them

- **OAuth / SSO / social login:** exact `redirect_uri` match (no wildcards), `state` and **PKCE** always, check `nonce` for OIDC, verify `iss`/`aud`/`exp` and the signature with the provider's JWKS, never accept `alg: none` or HS/RS confusion, short authorization-code lifetime, and scope-limited tokens per client.
- **JWT:** a fixed algorithm, a short expiry, `kid` looked up only in your own key set, no sensitive data in the payload (it is only base64), a revocation strategy (deny-list or short access token + refresh rotation with reuse detection).
- **Webhooks:** verify the signature over the *raw* body; reject old timestamps (> 5 min) to stop replays; store event IDs to de-duplicate; allow-list the sender IPs if the provider publishes them; respond fast, then process in a queue.
- **Host header / cache poisoning:** set `APP_URL`/trusted hosts and trusted proxies explicitly; build password-reset and email links from config, never from the request `Host`; never cache responses that vary by auth or cookies; add `Vary` correctly.
- **Request smuggling / proxy issues:** keep the proxy and web server patched; reject ambiguous `Content-Length` + `Transfer-Encoding`; trust `X-Forwarded-*` only from the known proxy.
- **Template injection (SSTI):** never render user input *as a template* (Blade `Blade::render`, Twig, Handlebars, Jinja, `eval` in email templates). Pass it as data only.
- **XXE / XML:** disable external entities (`libxml_disable_entity_loader`, `XMLParser` safe defaults); prefer JSON. The same applies to SVG and DOCX/XLSX parsing.
- **PDF / HTML-to-image generators** (wkhtmltopdf, Puppeteer, Browsershot, dompdf): user HTML can read `file://` and internal URLs (SSRF). Disable local file access and the network, or sanitise to a strict subset.
- **CSV / Excel export injection:** prefix cells starting with `= + - @ \t \r` with `'`.
- **Email / header injection:** strip CR/LF from anything placed in headers (subject, from-name, reply-to); send through the framework mailer.
- **Log injection:** strip CR/LF from user values written to logs; never log raw request bodies.
- **Unicode / normalisation tricks:** normalise (NFKC) and lowercase emails/usernames before uniqueness checks; block confusable or zero-width characters in display names shown to other users (impersonating "AstroGaon Support").
- **Integer, decimal and rounding:** money in integer paise or `DECIMAL`/`bcmath`, never floats; reject negative quantities and amounts; check for overflow; round once, on the server.
- **Timing attacks:** constant-time comparison for tokens, signatures, OTPs and API keys; the same work for "user exists / doesn't exist".
- **Enumeration / IDOR by guessing:** sequential IDs are fine *only* with ownership checks. For public share links use random IDs (UUIDv4/ULID + a secret token) and add expiry.
- **GraphQL:** depth and complexity limits, introspection off in production, per-field authorization, no batching attacks on login.
- **WebSockets / SSE:** authenticate the handshake, authorize every channel, validate every message, limit message rate and size, check `Origin`.
- **Queues, cron and background jobs:** jobs re-check permissions and state when they run (the user may have been banned since); jobs are idempotent; never put secrets in job payloads; queue dashboards behind admin auth.
- **Cloud / BaaS rules:** Firebase/Firestore/Storage security rules, Supabase RLS and S3/R2 bucket policies are **deny-all by default**, with tests in the emulator; no public-write buckets; no listing.
- **Subdomain & DNS:** remove DNS records for deleted services (subdomain takeover), use registrar lock and DNSSEC where possible, and enforce SPF + DKIM + DMARC (`p=quarantine`→`reject`) so nobody can send mail as your domain.
- **Clickjacking & UI redress:** `frame-ancestors 'self'` (or `'none'`) on every page; confirmation step for destructive actions.
- **Client-side storage (web):** no tokens in `localStorage` when a cookie session works; nothing sensitive in `sessionStorage`, IndexedDB or service-worker caches; `Cache-Control: no-store` on authenticated pages and API responses with personal data.

## 16. Cryptography & data protection

- Use the platform's vetted libraries: Laravel `Crypt`/`encrypted` casts, libsodium, Node `crypto` (AES-256-GCM), Web Crypto. Never write your own crypto, never use ECB/MD5/SHA1 for security, and never reuse IVs/nonces.
- **Encrypt at rest** the fields whose leak would hurt: KYC/ID numbers, bank account/UPI, 2FA secrets, OAuth refresh tokens, chat attachments, health/birth details where sensitive. Keep keys out of the database (env / KMS) and plan key rotation.
- Hash what you only need to compare (OTPs, API keys, reset tokens) with SHA-256/HMAC or a password hash.
- **Data minimisation:** don't collect what you don't need, mask by default in UIs and APIs (`XXXX1234`), and delete on schedule (DPDP retention). Data you don't hold can't leak.
- TLS 1.2+ everywhere, including internal service-to-service calls and database connections over a network.
- Random values only from a CSPRNG (`random_bytes`, `Str::random`, `crypto.randomBytes`, `Random.secure()`), never `rand()`/`Math.random()` for anything security-related.

## 17. Fraud, account takeover & abuse monitoring

- **Credential stuffing / brute force:** throttle per account *and* per IP *and* globally; progressive delays; CAPTCHA/Turnstile after a few failures; breached-password check; alert on spikes of failed logins.
- **New-device / new-location sign-in:** notify the user (email/push) with a "this wasn't me" link that signs out everywhere and locks the account.
- **Sensitive-change cooling-off:** after a change of email, phone, password or payout account, **hold payouts for 24–72 h** and notify the old contact. This is the step that turns most account takeovers into no loss.
- **Velocity and anomaly checks on money:** cap payouts per day/week, flag first payouts to new bank/UPI accounts, many refunds or coupon uses from one device or IP, many accounts from one device, and wallet top-up → instant withdrawal patterns. Large refunds and payouts get **admin review**; very large ones get **two-person approval**.
- **Coupons / referral / free-credit abuse:** one per user *and* per device/phone/payment method; server-side limits under a lock; watch for disposable emails.
- **Bots & scraping:** rate limits plus bot protection (Cloudflare Bot Fight/Turnstile) on sign-up, OTP, search and listing APIs; don't expose bulk endpoints that return everyone's data.
- **Impersonation & social engineering of users:** support never asks for OTPs or passwords (say so in the app); official messages come only through the in-app channel and verified domains; block contact details and payment links in chats if off-platform payment fraud is a risk.
- **Monitoring:** one dashboard/alert set for failed logins, OTP sends, 403/429 rates, payout requests, refunds, admin actions and webhook signature failures, with alerts to the owner's phone/email.

## 18. Resilience: stay up under attack

- **DDoS / traffic floods:** put a CDN/WAF in front (Cloudflare with managed WAF rules, rate-limit rules and "under attack" mode ready); hide the origin IP and allow origin traffic only from the CDN.
- **Application DoS:** timeouts on every outbound call and DB query; cap request body, upload, page and export sizes; queue heavy work; circuit breakers/fallbacks for third parties (AI, SMS, payments, astrology engine), so one slow provider doesn't take the site down.
- **Graceful degradation:** features behind fail-closed flags can be switched off instantly when abused (OTP login, AI chat, sign-ups).
- **Ransomware / destructive attacks:** off-site, **immutable or versioned** backups (object lock / versioning) with credentials the web server can't use to delete them; database point-in-time recovery; a tested restore with a known RTO/RPO.
- **Dependency on one account:** owner and admin access to hosting, DNS, registrar, Git, payments and cloud is protected with **hardware-key or app-based MFA** and recovery codes stored offline, and at least two trusted admins on critical consoles so one lost account doesn't lock you out.

## 19. Enforcement: make the rules automatic

Rules on paper don't stop attacks; gates do. Every project gets these. Set them up when the project starts, or add them the first time you work on an existing project, and log what's missing in the gaps file:

- **Pre-commit / CI secret scanning:** `gitleaks` (or trufflehog) on every push; the pipeline fails on a finding.
- **Dependency audit in CI:** `composer audit`, `npm audit --omit=dev --audit-level=high` / `pnpm audit`, `osv-scanner` for Dart/others. The build fails on critical/high. Turn on Dependabot/Renovate alerts.
- **Static analysis (SAST):** Semgrep with the `p/owasp-top-ten`, `p/php`/`p/laravel`, `p/javascript`/`p/typescript`/`p/react`/`p/nextjs`, `p/nodejs` rule sets (plus PHPStan/Larastan, ESLint `eslint-plugin-security`, `dart analyze` with strict lints). Fail on high-severity findings.
- **Guard tests** that check whole classes of mistakes, not single bugs:
  - every admin route has the admin middleware;
  - every public write route has a throttle;
  - no route accepts `amount`/`price`/`role` from the client without a server override;
  - security headers are present;
  - debug and docs routes are closed to guests;
  - the Android manifest has no cleartext and no `allowBackup`, and the release build is not debug-signed.
- **DAST:** OWASP ZAP baseline scan against staging on each release (`zap-baseline.py`), fixing high alerts.
- **Mobile:** MobSF static scan of the release APK/IPA before each store upload.
- **Infrastructure-as-code / containers** (if used): `trivy`/`checkov` for Dockerfiles, Terraform and Kubernetes.
- **Release checklist** (blocking): production env values (debug off, secure cookies, secrets set), migrations reviewed, rollback plan, and the security definition of done (§22) ticked for High-tier changes.
- **Periodic assurance:**
  - monthly dependency and secret-rotation review;
  - quarterly restore test and access review (remove ex-staff, unused API keys);
  - a manual penetration test of High-tier flows before launch and then **every 6–12 months**;
  - publish `/.well-known/security.txt` and consider a small bug bounty once there are real users.
- **Security log in the repo:** every audit finding gets an ID, severity, fix and test (like `docs/security-audit.md`), so past holes are never re-introduced.

---

## 20. Stack quick-reference

**Laravel / PHP**
- `FormRequest` or `$request->validate()` on every input; `$fillable`; policies/`Gate`/`authorize()` or scoped relations for every model ID; `role`/`can` middleware on route groups.
- `Password::defaults()` once in a provider; `RateLimiter::for()` named limiters; `throttle:` on every public write route.
- Escape with `{{ }}`; audit every `{!! !!}`; `json_encode` with `JSON_HEX_*` inside `<script>`.
- `Storage::disk('private')` + `temporaryUrl()`/signed routes for private files; `mimes:` allow-lists.
- `hash_equals` for signatures; `lockForUpdate()` in `DB::transaction()` for money.
- Passport/Sanctum: scopes or abilities per client type; token expiry; revoke on credential change.
- `APP_DEBUG=false`, `SESSION_SECURE_COOKIE=true`, `config:cache`; no Telescope/Scramble/Swagger for guests.

**Node.js / NestJS / Express**
- `helmet`, `express-rate-limit`/`@nestjs/throttler`, `cors` with an allow-list, body size limits.
- Validation: `class-validator` with `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`, or Zod at every boundary.
- Guards for auth + roles on every controller (`@UseGuards` globally, `@Public()` to opt out); ownership checks in services.
- Prisma/TypeORM/Knex parameterised only; no `$queryRawUnsafe` with input.
- `crypto.timingSafeEqual`, `crypto.randomInt`; JWT: verify algorithm (`algorithms: ['RS256']`), issuer, audience, expiry; never `jwt.decode` for auth.
- No `child_process.exec` with input; beware prototype pollution (`Object.assign` from user JSON, `lodash.merge`); use `Map` or `Object.create(null)`.

**Next.js / React**
- Server Actions and Route Handlers are public endpoints: authenticate, authorise and validate inside each one (Zod). Middleware alone isn't authorization.
- Never expose secrets via `NEXT_PUBLIC_*`; keep server-only modules with `import 'server-only'`.
- Don't pass whole DB objects to client components (they serialise into the page); pick fields.
- CSP with nonces (`headers()`/middleware), `next.config.js` `headers()` for the rest; `images.remotePatterns` allow-list (not `**`).
- `dangerouslySetInnerHTML` only with DOMPurify; `href` from data only after scheme check (block `javascript:`).
- Cookies via `cookies().set({ httpOnly: true, secure: true, sameSite: 'lax' })`; CSRF-safe Server Actions (check `Origin`).

**Flutter / Dart**
- `flutter_secure_storage` for tokens; one `ApiClient` that attaches the token only to your own base URL; timeouts on every request.
- `kDebugMode` around logs; no secrets in `--dart-define`/assets.
- One `SafeLink`-style helper for every `launchUrl` of non-hard-coded links.
- Release: own keystore, R8, `--obfuscate --split-debug-info`, `allowBackup=false`, no cleartext, no broad storage/media permissions.
- Payment SDKs: amount and order from the server; success callback → server verification before showing "paid".

---

## 21. People & process (most breaches start with a person)

- **Owner and staff accounts:** phishing-resistant MFA (passkeys or hardware keys) on email, Git, hosting, DNS/registrar, payment gateway, cloud and app stores; a password manager; no shared logins; separate admin accounts from daily accounts.
- **Least privilege:** staff and admins get only the roles they need; review roles quarterly; remove access the same day someone leaves; rotate shared secrets after a departure.
- **Admin panel hygiene:** admin actions are logged with before/after values; dangerous actions (bulk delete, refunds above a limit, role changes, payment settings) need re-authentication and, for the biggest ones, a second admin.
- **Vendor/third-party risk:** before adding an SDK or processor, check what data it receives, where it stores it, whether it has a DPA, and that you can switch it off with a flag.
- **AI agents and contractors:** they follow these same rules; they never get production secrets or real user data in prompts; their changes go through the same CI gates and review.
- **Incident drill:** once a year, walk through the breach runbook (who rotates which key, how to switch off a feature, how to tell users and the Data Protection Board within the DPDP timelines, and CERT-In within 6 hours for reportable incidents).

---

## 22. Definition of done — security

- [ ] Risk tier chosen; threat model (assets, actors, abuse cases, and **which layer stops each**) written in the change log / PR.
- [ ] Every new route: authn + authz (role **and** object ownership + relationship checks) + validation + throttle where public.
- [ ] Money/price/role/status computed or checked on the server; races handled with locks/constraints; integer/decimal money.
- [ ] Every sign-in/recovery path enforces the same checks (MFA, verified identifiers, bans); sensitive changes revoke other sessions and hold payouts.
- [ ] No secrets, debug paths, mock payment paths or demo credentials in the diff; secret scan clean.
- [ ] Output encoded / HTML sanitised; uploads allow-listed and stored safely; no user-supplied URL fetched.
- [ ] Negative tests for every abuse case pass (401/403/404/422/429), plus guard tests and the full suite.
- [ ] Dependency audit and SAST clean for critical/high.
- [ ] Logs contain no secrets or personal data beyond what's needed; security events logged and alertable.
- [ ] High tier: second review done (human or a separate review agent run with `/security-review`), and the feature can be switched off by a fail-closed flag.
- [ ] Anything left open is in the backlog with a severity, and owner-only steps (key rotation, console settings) are on the owner's TODO list.

When reporting, say exactly what was checked and what wasn't. "100% secure" is never a claim. "No known high-risk issues, defence in depth, gates in CI, tested" is the claim to earn.
