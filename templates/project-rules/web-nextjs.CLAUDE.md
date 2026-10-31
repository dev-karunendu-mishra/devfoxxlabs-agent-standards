# Web & Next.js Frontend Rules (Project Template)

## 1. UI System & Design
- **Icons**: Use ONLY Hugeicons (free set, stroke rounded): `@hugeicons/react` with `@hugeicons/core-free-icons`. Tree-shaken named imports. Never import Lucide, Heroicons, or Material Icons.
- **Component Kit**: Build upon `shadcn/ui` primitives (Radix UI + Tailwind). Never write raw unstyled HTML form controls when standard shadcn components exist.
- **Styling**: Tailwind CSS with CSS variable design tokens (`bg-background`, `text-foreground`, `border-border`).

## 2. DPDP Compliance & Cookie Gating
- **Zero Tracker Execution Before Consent**: Never load Google Analytics, Meta Pixel, Hotjar, or marketing tag scripts until the matching cookie consent category is accepted.
- **Cookie Banner**: Equal prominence for "Accept All" and "Reject All" + "Customize Preferences".
- **Cookie Preferences Link**: Persistent link in the footer on every page allowing users to change or withdraw consent at any time.
- **Notices**: Linked in the footer: Privacy Notice, Terms of Service, Refund Policy, Cookie Policy.

## 3. Core Web Vitals (see `rules/web-performance.md`)
- Targets at p75 mobile: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1. Lighthouse CI (`lighthouserc.json`) gates every PR.
- Server components by default; `"use client"` only on interactive leaves, never on layouts.
- `next/image` for every image (one `priority` hero per page, `sizes` set); `next/font` for fonts; `next/script` with `lazyOnload` for third parties after consent.
- Public pages static/ISR; slow sections streamed with `<Suspense>`; `loading.tsx` skeletons at final size.
- Dynamic-import charts, editors, maps; initial route JS ≤ 170 KB compressed; `optimizePackageImports` for icon/util packages.

## 4. Security & Best Practices
- Never expose sensitive tokens in `NEXT_PUBLIC_*` or client bundles.
- Validate all route handlers and server actions with Zod schemas.
- Content Security Policy (CSP), anti-clickjacking (`X-Frame-Options`), and CSRF tokens active.

