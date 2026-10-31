---
name: web-performance
description: Core Web Vitals standard for every website and web app Karunendu (DevFoxx Labs) builds — Next.js/React, Laravel Blade or Inertia + Vite, Vue/Nuxt, Astro, plain HTML and admin panels. Pass LCP ≤ 2.5 s, INP ≤ 200 ms and CLS ≤ 0.1 at p75 on mobile; server-render the LCP element, prioritise the hero image, keep JS within budget, break long tasks, reserve space for everything, defer third parties until consent and idle, and gate regressions with Lighthouse CI plus RUM. Use when building or reviewing any page, component, image, font, script, dependency, layout, data fetching or caching change on the web, and for performance audits.
metadata:
  author: karunendu
  version: "1.0.0"
---

# Web Performance — pass Core Web Vitals on every page

**Applies to every web surface:** public sites, web apps, dashboards and admin panels in Next.js,
React, Laravel (Blade / Inertia + Vite), Vue/Nuxt, Astro and plain HTML. Admin panels are not
exempt for INP — staff use them all day.

Core Web Vitals are a ranking signal and a conversion driver, and they regress silently: one
unsized image, one blocking script or one 300 ms click handler is enough. So every change is checked
against three numbers at the **75th percentile of real users, mobile first**:

| Metric | Good | Needs improvement | Poor |
|---|---|---|---|
| **LCP** | ≤ 2.5 s | ≤ 4.0 s | > 4.0 s |
| **INP** | ≤ 200 ms | ≤ 500 ms | > 500 ms |
| **CLS** | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| TTFB (supporting) | ≤ 0.8 s | ≤ 1.8 s | > 1.8 s |

---

## 1. Workflow for every web change

1. **Before:** identify the route's LCP element and main interaction (button, filter, form submit).
2. **Build** with the rules in §2–§6 — they are defaults, not optimisations for later.
3. **Check:** Lighthouse (mobile preset) on the changed route + DevTools Performance panel with
   4× CPU throttling while doing the main interaction. Look at: LCP element and its sub-parts
   (TTFB, load delay, load time, render delay), long tasks, layout-shift culprits.
4. **Gate:** Lighthouse CI must pass (§7). If a budget must grow, say why in the change log.
5. **Record:** put the before/after LCP, CLS, TBT (lab) in the change-log entry's *Verified* line.

## 2. LCP

LCP = TTFB + resource load delay + resource load time + render delay. Fix the biggest part first.

- **Render on the server.** Public pages use SSR/SSG/ISR. The LCP element must be in the initial
  HTML — not rendered after a client `useEffect` fetch, not hidden behind a loading spinner.
- **Hero image:**
  - `<img>` (not CSS background) with `fetchpriority="high"`, `decoding="async"`, explicit size,
    `srcset` + `sizes`, AVIF/WebP. **Never** `loading="lazy"` on it.
  - Next.js: `<Image priority … sizes="100vw">` (`preload` on versions where `priority` is
    deprecated). Only **one** priority image per page.
  - Background image unavoidable → `<link rel="preload" as="image" imagesrcset=… fetchpriority="high">`.
- **TTFB:** CDN in front; cache full HTML for anonymous pages (ISR / `Cache-Control: s-maxage`,
  Laravel response cache); no N+1 queries or slow external APIs before first byte — cache, defer
  below the fold, or stream with `<Suspense>`; Brotli; HTTP/2+; 103 Early Hints if the host supports it.
- **Render-blocking:** no third-party CSS/JS in `<head>`; inline critical CSS only when small; one
  stylesheet per route via the bundler; `preconnect` to at most 1–2 critical origins (image CDN, API).
- **Fonts:** self-host WOFF2 (Next.js `next/font`, `@fontsource` in Vite), subset to used scripts
  (Latin + Devanagari only if Hindi is shown), `font-display: swap` (`optional` for body text if
  shifts appear), preload only the above-the-fold weight, max 2 families × 2–3 weights.

## 3. INP

INP = input delay + processing time + presentation delay of the worst interaction.

- **No long tasks.** Any task > 50 ms during interaction gets split:
  ```js
  async function yieldToMain() {
    if (globalThis.scheduler?.yield) return scheduler.yield();
    return new Promise((r) => setTimeout(r, 0));
  }
  for (const chunk of chunks) { process(chunk); await yieldToMain(); }
  ```
- **Paint first, work later:** update the UI (pressed state, optimistic row, spinner) synchronously,
  then do analytics, validation of big forms, storage writes in the next task.
- **React:** `useTransition` for filter/tab switches, `useDeferredValue` for search results,
  `memo`/stable props on list rows, no context value that changes on every keystroke at the app root,
  no giant client components — keep server components the default (App Router).
- **Lists & tables:** paginate or virtualise beyond ~100 rows (TanStack Virtual); debounce search
  (200–300 ms); server-side filtering for big datasets.
- **DOM size:** keep under ~1,500 nodes per view; `content-visibility: auto` +
  `contain-intrinsic-size` for long off-screen sections.
- **Heavy work** (CSV parsing, image resize, PDF, crypto) → Web Worker or the server.
- **Hydration:** islands / server components; lazy-hydrate below-the-fold widgets; don't ship a
  client component just to format a date.

## 4. CLS

- Size every media element: `width` + `height` attributes or CSS `aspect-ratio`. Same for iframes,
  embeds (YouTube, maps), ad slots and avatar placeholders.
- **Skeletons have the final size** of the content they stand in for.
- Never inject banners, toasts or "install app" bars that push content; use overlays or reserved
  slots. The **cookie consent banner is `position: fixed`** and short enough not to become the LCP.
- Animations and transitions: `transform` / `opacity` only.
- Fonts: size-matched fallback (`next/font` does it; otherwise `size-adjust`, `ascent-override`).
- Infinite scroll / "load more" appends below the viewport, never above.

## 5. JavaScript budget and third parties

| Budget (per route, compressed, mobile) | Default |
|---|---|
| Initial JS | ≤ 170 KB |
| Initial CSS | ≤ 50 KB |
| LCP image | ≤ 150 KB (AVIF/WebP) |
| Total page weight | ≤ 1.5 MB |
| Third-party requests before interaction | 0 (except consented analytics, deferred) |

- Analyse bundles: `@next/bundle-analyzer`, `rollup-plugin-visualizer` (Vite), `source-map-explorer`.
- Dynamic import heavy, below-the-fold or on-demand UI: charts, rich-text editors, maps, date pickers,
  emoji pickers, modals with big forms.
- Tree-shaken named imports: `@hugeicons/core-free-icons` named icons, `lodash-es/debounce`,
  `date-fns` functions. Never `import * as`. Prefer `Intl` over moment/large date libs.
- A new dependency states its compressed size and why the platform/existing code can't do it.
- **Third parties:** load only after the matching DPDP consent category (see `dpdp-compliance`),
  then with `defer` / `next/script strategy="lazyOnload"` / on first interaction. Chat widgets and
  YouTube/maps embeds use a **click-to-load facade** (static preview, real script on click).
- Keep pages bfcache-eligible: no `unload` listeners, no `Cache-Control: no-store` on public HTML.

## 6. Images, caching, data

- Framework pipelines: `next/image` (configure `images.remotePatterns`, AVIF), Laravel Spatie
  Media Library responsive images / conversions, `vite-imagetools`. Upload pipeline stores
  web-sized variants — never serve the 4 MB original.
- Below-the-fold images and iframes: `loading="lazy"`.
- Static assets: fingerprinted filenames + `Cache-Control: public, max-age=31536000, immutable`.
- HTML: short TTL or revalidation; API GETs: ETag / `stale-while-revalidate` where data allows.
- Data fetching: fetch on the server in parallel (`Promise.all`), not client waterfalls; prefetch
  likely next routes (`<Link prefetch>`, Inertia `prefetch`); paginate APIs.

## 7. Measure and gate

### Lab — Lighthouse CI (every PR)
Copy [templates/lighthouserc.json](templates/lighthouserc.json) to the project root, list the key
routes, and run it in CI against a production build:
```bash
npm i -D @lhci/cli
npx lhci autorun   # after `npm run build && npm start` (or `php artisan serve` + `npm run build`)
```
A failing assertion fails the build. Change thresholds only with a reason in the change log.

### Field — RUM with `web-vitals`
Copy [templates/web-vitals.ts](templates/web-vitals.ts): it reports LCP, INP, CLS, FCP and TTFB with
attribution (which element / interaction) to **your own** endpoint via `sendBeacon`.
- No personal data in the payload: route pattern (not full URL with IDs/query), metric, value,
  rating, device class, attribution selector. No user ID; the endpoint ignores session cookies and
  doesn't store IPs.
- The receiving endpoint is public → **rate-limited**, validated, size-capped (see `secure-development`).
- Sending to a third-party analytics tool instead → it's analytics: load only after consent.
- Review p75 per route weekly; also Search Console Core Web Vitals report / CrUX once traffic exists.

## 8. Stack notes

**Next.js (App Router):** server components by default; `next/image`, `next/font`, `next/script`;
`loading.tsx` skeletons with final sizes; `<Suspense>` streaming for slow sections; static or ISR for
public pages (`revalidate`); avoid `"use client"` at layout level; `optimizePackageImports` for big
icon/util packages.

**Laravel + Inertia/Vite:** SSR for public pages (Inertia SSR) or Blade; `@vite` handles preload of
the entry chunk; `Inertia::defer()` / lazy props for slow data; route-level code splitting
(`resolvePageComponent` with `import.meta.glob`); `php artisan optimize`, OPcache, response cache for
anonymous pages; eager-load relations (no N+1) and add indexes for list queries.

**Plain Blade / HTML:** `<img width height loading fetchpriority>`, `defer` on every script, one
bundled CSS, no jQuery plugin soup above the fold.

**Flutter web:** use the Wasm/CanvasKit build only where needed; show an HTML splash with the real
brand content sized correctly; lazy-load deferred libraries (`deferred as`); public marketing/SEO
pages should be a server-rendered site, not Flutter web.

## 9. Done checklist (web changes)

- [ ] LCP element server-rendered; hero image `fetchpriority="high"`, sized, modern format, not lazy
- [ ] No interaction long task > 50 ms; immediate visual feedback on every action
- [ ] Every image/iframe/embed/skeleton has its final size; banners don't push content
- [ ] Route JS within budget; heavy components dynamically imported; no new heavy dependency unexplained
- [ ] Third parties after consent + deferred / facade
- [ ] Lighthouse CI passes; numbers recorded in the change log
