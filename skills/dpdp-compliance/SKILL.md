---
name: dpdp-compliance
description: India DPDP Act 2023 / DPDP Rules 2025 compliance foundation for web apps, Flutter/mobile apps and backends - privacy notice, terms, refund, cookie policy, consent capture, timestamped consent ledger, cookie banner, withdrawal, data principal rights, grievance officer. Use FIRST when starting or auditing any project for Indian users, and whenever a feature adds personal data, trackers or third-party processors.
metadata:
  author: karunendu
  version: "1.0.0"
---

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
