# Global Rule — India DPDP Compliance First

For every web app, Flutter/mobile app or backend for users in India, implement legal &
data-protection compliance under the DPDP Act, 2023 and DPDP Rules, 2025 FIRST, before
other features. Existing project: audit against this list, report gaps, fix them first.
Every later feature that adds personal data, a tracker/SDK/processor or a new purpose
updates the notices, consent purposes and ledger in the same change. Never invent company
or Grievance Officer details — read them from config/env, ask for real values, use marked
placeholders; say the texts need a lawyer's review.

Checklist (full version: the `dpdp-compliance` skill, or ~/.agents/rules/dpdp-compliance.md):
1. Notices — Privacy Notice, Terms, Refund (if payments), Cookie Policy (if web trackers),
   Vendor Terms (marketplace). One versioned source (version + last_updated) served to web
   and app (GET /legal, /legal/{slug}); readable in-app without login; footer links.
2. Consent — per purpose; required (account) vs optional (marketing/analytics/ads) off by
   default; unticked sign-up checkbox validated by the server; "By continuing you agree…"
   beside one-tap OTP/social sign-in; no bundling, no pre-ticks.
3. Consent ledger — append-only table: user_id/visitor_id, purpose, status
   (granted/denied/withdrawn), method, source (web/android/ios), notice_version, ip,
   user_agent, created_at. Write it at every sign-up path, preference change and cookie choice.
   Users can see their consents + history.
4. Withdrawal as easy as giving — consent switches in app/web; "Cookie preferences" in the
   web footer; effective immediately (stop processing, delete tracker cookies).
5. Web trackers — nothing (analytics/ads/pixels) loads before consent; Reject all as
   prominent as Accept all; Customize per category; closing = reject.
6. Mobile — no analytics/ads SDK before consent; just-in-time permissions with reasons;
   Privacy & Legal screen: notices, your consents, privacy request, Grievance Officer,
   download data, in-app account deletion.
7. Rights — access/export, correction, erasure, nomination, withdrawal, grievance; request
   form; acknowledge ~48 h, resolve ≤30 days; Data Protection Board escalation.
8. Children — 18+ default; verifiable parental consent if minors; no tracking/targeted ads.
9. Security, retention schedule + deletion jobs, breach runbook (Board + users; detailed
   report within 72 h), processors listed, no transfer to restricted countries.
10. Tests — consent required at sign-up, ledger rows with version/time, optional off by
    default, withdrawal works, no tracker requests before consent.

# Global Rule — Web Performance (Core Web Vitals)

Every website/web app passes LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 at p75 on mobile (full version:
the `web-performance` skill, or ~/.agents/rules/web-performance.md).
1. LCP element server-rendered; hero image fetchpriority="high", sized, AVIF/WebP, never lazy; CDN + cached HTML.
2. No interaction task > 50 ms: split/yield, workers, instant feedback, virtualise long lists.
3. Every image/iframe/embed/skeleton sized; nothing pushes content; animate only transform/opacity.
4. Initial JS ≤ 170 KB compressed per route; code-split; third parties only after consent, deferred.
5. Lighthouse CI gate (perf ≥ 90) + web-vitals RUM without personal data.
