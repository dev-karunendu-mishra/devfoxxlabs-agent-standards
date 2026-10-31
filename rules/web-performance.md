# Global Rule — Web Performance: pass Core Web Vitals on every page

Applies to every website and web app — Next.js/React, Laravel (Blade / Inertia + Vite), Vue/Nuxt,
Astro, plain HTML, admin panels and Flutter web. Performance is built **with** each page and
component, not tuned afterwards. Full standard + CI templates: the **`web-performance`** skill.

## 1. Targets (field data, 75th percentile, mobile and desktop separately)
| Metric | Good | What it measures |
|---|---|---|
| **LCP** Largest Contentful Paint | ≤ 2.5 s | loading — when the main content shows |
| **INP** Interaction to Next Paint | ≤ 200 ms | responsiveness — every tap, click, key |
| **CLS** Cumulative Layout Shift | ≤ 0.1 | visual stability — nothing jumps |
| TTFB / FCP (supporting) | ≤ 0.8 s / ≤ 1.8 s | server + first paint |

Test on a **mid-range Android phone on throttled 4G** (Lighthouse mobile preset), not a dev laptop.
Lab Lighthouse score ≥ 90 for Performance on key pages is the CI gate; field data (CrUX / RUM) is
the truth.

## 2. LCP — show the main content fast
- The LCP element (hero image / heading) is in the **server-rendered HTML** — never waiting on
  client JS or an API call. Public pages: SSR/SSG/ISR, not a client-only SPA shell.
- LCP image: `fetchpriority="high"`, **never** `loading="lazy"`, preloaded if it's a CSS background
  (prefer `<img>`), responsive `srcset`/`sizes`, AVIF/WebP, sized to its display size.
- Fast TTFB: CDN in front, cache HTML where possible, Brotli/gzip, HTTP/2+, no slow DB/API calls
  blocking the first byte (cache them, stream, or move below the fold).
- No render-blocking third-party CSS/JS in `<head>`; critical CSS small; `preconnect` only to the
  1–2 origins the LCP really needs.
- Fonts: self-host (or `next/font`), WOFF2, subset, `font-display: swap` (or `optional`), preload
  only the one font used above the fold, size-adjusted fallback to avoid shifts.

## 3. INP — every interaction responds within 200 ms
- No main-thread task > 50 ms on interaction: split work, yield (`scheduler.yield()` / `setTimeout`),
  move heavy work to a Web Worker or the server.
- Show feedback immediately (pressed state, spinner, optimistic UI) and do the slow part after the
  next paint. React: `useTransition` / `useDeferredValue` for expensive re-renders; memoise big lists.
- Debounce search/filter inputs; virtualise long lists/tables (> ~100 rows); avoid layout thrashing
  (read layout, then write); `content-visibility: auto` for long off-screen sections.
- Keep hydration light: server components / islands by default, client JS only where interactive.

## 4. CLS — nothing moves after it's shown
- Every `<img>`, `<video>`, `<iframe>`, embed and ad slot has `width`/`height` or `aspect-ratio`.
- Reserve space for late content (banners, alerts, cookie bar, skeletons with the final size); never
  insert content above what the user is reading unless it's a response to their action.
- Cookie / consent banner is a **fixed overlay** (no push-down) and must not become the LCP element.
- Animate only `transform`/`opacity`; no animating `top/left/width/height/margin`.
- Web fonts with size-matched fallbacks (`size-adjust`, `next/font`) so text doesn't reflow.

## 5. JavaScript and third parties
- Budget per route (default, tune per project): **initial JS ≤ 170 KB compressed**, total page
  weight ≤ 1.5 MB on mobile. A PR that breaks the budget explains why or splits the code.
- Code-split by route and by heavy component (charts, editors, maps, date pickers) with dynamic
  import; tree-shaken named imports (icons, lodash-es, date-fns); no whole-library imports.
- Before adding a dependency, check its size (bundlephobia / `pnpm why`) and prefer the platform.
- Third-party scripts (chat, analytics, maps, video) load **after consent** (DPDP rule) and after
  interaction or idle — `defer`/`async`, `next/script` `lazyOnload`, or a click-to-load facade.
- Back/forward cache stays usable: no `unload` handlers; don't send `Cache-Control: no-store` on
  pages that don't need it.

## 6. Images, media and caching
- Use the framework image pipeline (`next/image`, Laravel image conversions / Spatie responsive
  images, Vite imagetools) — modern formats, responsive sizes, lazy below the fold.
- Static assets fingerprinted + `Cache-Control: public, max-age=31536000, immutable`; HTML short-lived
  or revalidated. API responses use ETag / `stale-while-revalidate` where safe.
- Videos: `preload="none"` + poster below the fold; never autoplay heavy video as the LCP.

## 7. Measure and gate (part of "done")
- **CI:** Lighthouse CI on key routes (home, listing, detail, checkout/sign-up) with assertions for
  LCP, CLS, TBT and the JS budget; a regression fails the build.
- **Field (RUM):** `web-vitals` library reports LCP/INP/CLS to your own endpoint with **no personal
  data** (no user ID, IP stored truncated) and a rate limit; review p75 per route weekly, plus
  CrUX / Search Console when the site has traffic.
- Any UI change: check the page in Lighthouse mobile and DevTools Performance (INP of the main
  interaction) and report the numbers in the change log entry.

Write this rule (or a pointer to it) into each web project's own rules file when setting it up.
