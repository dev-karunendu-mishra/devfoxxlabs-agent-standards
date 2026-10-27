# Global Agent Rules (Cursor / Windsurf / Universal Agents)

## 1. India DPDP Compliance First
Applies to every web app, Flutter/mobile app, and backend for users in India. Legal & data-protection compliance under the DPDP Act 2023 & DPDP Rules 2025 is a foundation, not a feature: build it first before other features.
- Notices: Versioned Privacy Notice, Terms, Refund, Cookie Policy, Partner Terms served from one source (`GET /legal`). Readable in-app without login.
- Consent: Free, specific, informed, unbundled. Optional consents (analytics, marketing) OFF by default. Unticked sign-up checkbox server-validated.
- Consent Ledger: Append-only `consent_records` table with timestamp, user/visitor ID, purpose, status, method, source, notice_version, IP, user-agent.
- Withdrawal: As easy as giving. "Your consents" screen & footer "Cookie preferences". Effective immediately.
- Web trackers: Block scripts before consent. Reject all with equal prominence.
- Mobile: No tracker SDK initialized before consent. JIT permissions with plain reasons. In-app account deletion.
- Rights: Access/export, correction, erasure, nomination, grievance workflow.
- Children: 18+ default. Verifiable parental consent if minors.

## 2. Icons: Hugeicons (Free) Everywhere
Applies to every frontend (React / Next.js / Vue / Flutter / Mobile).
- Use ONLY Hugeicons, free stroke rounded set (`@hugeicons/react` or Flutter `hugeicons` package).
- Never add other icon sets (lucide, heroicons, material, fontawesome). Never hand-draw ad-hoc inline SVGs.
- Never use Pro packages without an active license.
- Ensure accessible semantics (`aria-label` or `Semantics`).

## 3. Security by Design (Every Stack)
Think like an attacker before writing code.
- 2-min threat model before every feature.
- Authorization on the server, deny by default. Verify ownership and object ID relations on every request.
- Never trust client for money, pricing, fees, or roles. Server computes all money.
- MFA mandatory for admin paths. Only verified phone/email can sign in. Single-use, short-lived OTPs.
- Server-side allow-list validation. Bound parameters/ORM only.
- Strict rate limits on all public write endpoints.
- Secure file uploads: allow-listed types, server-generated names, private disk + signed URLs. Never fetch user URLs (no SSRF).
- Zero secrets in repos, bundles, or logs.
- Mobile: tokens in secure storage, HTTPS only, release keystore, R8/obfuscation, no cleartext traffic.

## 4. Database Safety & ACID
Know where you are, never break data, always ACID.
- State and verify target environment (local / staging / production) before any database command.
- Production and staging are never wiped: no `migrate:fresh`, `db:wipe`, or unsafe resets. Guarded in code.
- Schema changes are additive & backward-compatible (expand -> migrate -> contract).
- Every multi-row write runs in a database transaction (`lockForUpdate` on shared rows).
- Never copy unmasked production PII to local/staging environments.
