---
name: flutter-production
description: Karunendu's (DevFoxx Labs) production-grade Flutter standard - Riverpod 3 (Notifier/AsyncNotifier), feature-first lib/core + lib/features/<f>/{screens,widgets,providers,data,models}, ApiClient with ETag cache + ref.cacheFor, AutoSkeleton loading, AppNetworkImage (cached_network_image + memCache), strict SafeArea / Samsung 3-button nav insets, zero overflow at 320px, bottom sheets and full screens instead of form dialogs, one AppStepWizard, rounded-rectangle buttons, slide transitions, Material 3 light/dark/system theme, hugeicons, flutter_secure_storage + local_auth app lock, flutter_native_splash + launcher icons, flutter analyze/test gates. Use when creating, scaffolding, auditing, refactoring or adding any feature, screen, provider, repository or widget to a Flutter / Dart mobile app.
metadata:
  author: karunendu
  version: "1.0.0"
  derived_from: adminastrogaon, nutan, sarthi_by_taxiyaa, taxiyaa, vastugram, astrogaon/apps/mobile, elitefitnessgym, feellive, GymYardHQ, club-100-gym
---

# Flutter Production Standard (DevFoxx Labs)

This is how every Flutter app in this portfolio is built. It was extracted from the
newest apps (adminastrogaon, nutan, sarthi_by_taxiyaa, taxiyaa, vastugram) and the
strict rule sets in astrogaon/apps/mobile, feellive and elitefitnessgym. Follow it
exactly unless the project's own `CLAUDE.md` / `GEMINI.md` says otherwise. Project
rules win over this skill.

## 0. Order of work (always)

1. **DPDP compliance comes first.** For any app used by people in India, apply the
   `dpdp-compliance` skill before other features: the Privacy & Legal screen
   (readable without sign-in), the unticked consent checkbox checked on the server,
   the consent ledger, withdrawal, rights requests and the Grievance Officer card,
   with no analytics SDK started before consent. Every later feature that adds
   personal data, an SDK or a processor updates the notices and consents in the same change.
2. **New app:** scaffold in this order: `pubspec` stack → `analysis_options.yaml` →
   `lib/core/` (theme, network, providers, widgets, navigation) from
   [templates/](./templates/) → auth/session → legal and consent → features.
   See [references/new-project-checklist.md](./references/new-project-checklist.md).
3. **Existing app:** before adding features, audit it against the
   [Definition of Done](#definition-of-done), list the gaps to the user, then fix
   them or ask which ones to fix first.
4. **Every feature:** check the backend API first, then build the
   model → repository → provider → screen, plus the loading/error/empty states,
   caching and tests, all **in the same change**.

## 1. Standard stack (use these; don't add alternatives without asking)

| Concern | Package / pattern |
|---|---|
| State + DI | `flutter_riverpod` **3.x**: `Notifier`, `AsyncNotifier`, `FutureProvider.autoDispose` |
| HTTP | One `ApiClient` in `lib/core/network/` (ETag / `If-None-Match`, timeouts, typed `ApiException`). `dio` is acceptable only behind the same `ApiClient` API |
| Loading UI | `auto_skeleton` (`AutoSkeleton`). Never a bare spinner for content |
| Images | `cached_network_image` via `AppNetworkImage` with `memCacheWidth/Height` |
| Secure storage | `flutter_secure_storage` (tokens, user JSON, theme, app-lock flag) |
| Biometrics | `local_auth` (app lock; fails closed) |
| Icons | `hugeicons` (`HugeIcon(icon: HugeIcons.strokeRounded…)`) + `cupertino_icons` |
| Splash / icon | `flutter_native_splash` + `flutter_launcher_icons` (dev deps) |
| Links | `url_launcher` (call, WhatsApp `wa.me`, maps, email) |
| Formatting | `intl` (`₹` via `NumberFormat.currency(locale: 'en_IN', symbol: '₹')`, Indian date formats) |
| Docs / PDF / rich text | `pdfrx` (view), `pdf` + `printing` (generate), `flutter_quill` + `markdown_quill` (Markdown editor), `flutter_markdown_plus` |
| Push | `firebase_core` + `firebase_messaging` + `flutter_local_notifications` (only after consent where needed) |
| Local DB (offline-first apps) | `drift` (additive migrations only) |
| Routing | `Navigator` + `SlidePageRoute` / `context.pushSlide` by default. Use `go_router` only for deep-link or guard-heavy apps, and then use it everywhere |

Full details and versions are in [references/stack-and-architecture.md](./references/stack-and-architecture.md).

## 2. Folder structure

```text
lib/
  main.dart                 # bootstrap only: init → ProviderScope → App
  core/
    network/                # api_client.dart, api_exception.dart, local_api_cache.dart, api_endpoints.dart
    providers/              # core_providers.dart, ref_cache.dart, app_lock_provider.dart
    theme/                  # app_colors.dart, app_theme.dart, <app>_theme_extension.dart, theme_provider.dart, app_theme_mode.dart
    navigation/             # slide_page_route.dart
    services/               # biometric_service.dart, fcm_service.dart, …
    widgets/                # AppNetworkImage, AppBottomBar, AppModalSheet, AppStepWizard, AppErrorView, AppEmptyView, wordmark/logo
    utils/                  # formatters, validators, sheet_insets.dart
  features/<feature>/
    screens/  widgets/  providers/  data/  models/
test/
  helpers/layout_matrix.dart   # size × text-scale overflow matrix
docs/  changes/CHANGELOG.md  CLAUDE.md  GEMINI.md
```

Widgets never call `ApiClient`, storage or platform channels directly. The chain is
**Repository → Provider → Widget**. Don't add use-case or service-locator layers until
two or more call sites need them.

## 3. The non-negotiable rules

Each rule links to its detail file. Treat every line as a review checklist item.

1. **No mock data, ever.** No hardcoded lists, fake prices or seed fallbacks in
   repositories, models or screens. Never catch an exception just to return fake
   data. Let it propagate so the screen shows the real error with Retry. Bundled
   assets are allowed only as offline or broken-image fallbacks.
2. **AsyncValue: handle all three states.** `when(data:, loading: AutoSkeleton…, error: AppErrorView(onRetry: () => ref.invalidate(sourceProvider)))`,
   and give every list a designed empty state with a next action. → [state-riverpod.md](./references/state-riverpod.md)
3. **The caching bundle, the same change, for every API-driven screen:**
   (a) a skeleton shaped like the real layout, (b) `GET` through `ApiClient`
   (ETag → 304 served from `LocalApiCache`) plus `ref.cacheFor(Duration)` on read
   providers, (c) every network image through `AppNetworkImage` with `memCache*` sized
   to the display (never `Image.network` / `NetworkImage`), (d) an error view with Retry
   and an empty state. Fetch each endpoint **once** in a source provider and derive
   search, filter, tab and stats views locally. After a mutation or pull-to-refresh,
   **invalidate the source provider**. → [networking-caching.md](./references/networking-caching.md)
4. **SafeArea everywhere. Nothing hides behind the Samsung 3-button bar.** The body
   is in `SafeArea`. Bottom CTAs use `AppBottomBar`: bottom padding is
   `max(16, viewPadding.bottom) + viewInsets.bottom`. Sheets use
   `showModalBottomSheet(useSafeArea: true, isScrollControlled: true)` through
   `showAppModalSheet`. An explicit `ListView(padding:)` on a pushed screen adds
   `viewPadding.bottom` itself. → [ui-layout-safety.md](./references/ui-layout-safety.md)
5. **Zero overflow** at 320×568 and text scale 1.3–1.5. Every `Text` in a `Row` goes in
   `Expanded`/`Flexible` with `maxLines` + `ellipsis`. Fixed heights only for icons,
   avatars and media. A body that can grow scrolls (`AlwaysScrollableScrollPhysics` so
   pull-to-refresh works). Never hide an overflow with clipping tricks.
6. **No dialogs for forms.** Large forms open as a **new full screen** with a sticky
   save bar, an unsaved-changes guard (`PopScope`) and 422 errors shown under each field.
   Quick 1–2-field entries and pickers use a **bottom sheet** with keyboard insets.
   `AlertDialog` is only for destructive confirmations.
7. **One multi-step design: `AppStepWizard`.** It has a segmented progress header
   ("Step X of N: Label"), back steps backwards, one full-width Next/submit button, a
   review step before submit, and keeps earlier answers. Never fork it per screen.
8. **Buttons are rounded rectangles** (`BorderRadius.circular(12)`, min height 48–52,
   full width for CTAs). No `StadiumBorder` or pill CTAs. Only chips and tags use
   small rounding (6–8). Set this once in the theme.
9. **Slide transitions** for every route: `PageTransitionsTheme` with
   `SlidePageTransitionsBuilder` on all platforms, plus `context.pushSlide(page)`.
10. **Theme: Material 3, light + dark + system,** persisted in secure storage. Colors
    come from `ColorScheme` + a `ThemeExtension` (semantic and status tokens). No
    hardcoded `Color(0x…)` in features. Brand names render through a wordmark/logo
    widget, never plain `Text`. → [theming-design-system.md](./references/theming-design-system.md)
11. **Security.** Store the token and user only in `flutter_secure_storage` behind a
    `SecureKeyValueStore` interface. `AuthSession.restore()` uses a 2–3 s timeout and
    falls back to login. App lock is opt-in, locks on resume, **fails closed**, and wraps
    pickers and share sheets in `keepUnlockedDuring`. No secrets in the binary. The
    server creates payment orders, sets amounts and verifies signatures. Never log PII.
    → [security-auth.md](./references/security-auth.md)
12. **Backend contract first.** Confirm the endpoint exists. If it doesn't and the
    backend is in the workspace, add it non-destructively. The envelope is
    `{success, data, message, meta}`. Handle 401 (refresh or logout), 403, 404,
    409 and 422 (`fieldErrors`). Models are immutable with `fromJson`/`toJson` and
    safe defaults (`(json['x'] as num?)?.toDouble() ?? 0`).
13. **Modern, safe Dart.** Use `PopScope`, not `WillPopScope`. Use
    `withValues(alpha:)`, not `withOpacity`. Use `MediaQuery.sizeOf/paddingOf/viewInsetsOf`.
    Check `if (!context.mounted) return;` after every `await`. Dispose every
    controller, timer and subscription. Use `unawaited()` for fire-and-forget calls.
    Prefer private widget classes over `_buildX()` methods. Use `const` wherever
    possible. No `!` without a proven invariant.
14. **Double-tap guards.** While an action runs, disable the button and show a busy
    state (`_saving ? null : _save`).
15. **Retry policy.** Set one `appRetryPolicy` on the root `ProviderScope` (no retry on
    4xx, max 3 tries with backoff on network or 5xx errors). Never put a retry function
    on an individual provider.
16. **Rebuild discipline.** Use `ref.watch(p.select(...))` in leaf widgets, read with
    `ref.read` only in callbacks, use `ListView.builder` for anything unbounded, and
    keep `TextEditingController`s in `State`, not in providers.

## 4. Feature recipe (apply for every new screen)

1. Read the API contract and the backend routes. Note the response shape.
2. `models/x.dart`: immutable model, `fromJson` with safe defaults, `toJson`.
3. `data/x_repository.dart`: a `const` class that takes `ApiClient`. It returns
   typed models and never catches errors to fake success.
4. `providers/x_providers.dart`: a repository `Provider`, a source
   `FutureProvider.autoDispose` / `AsyncNotifier` with `ref.cacheFor(...)`, derived
   providers for search and filter, and `Notifier`s for UI filter state.
5. `screens/x_screen.dart`: `ConsumerWidget`, `RefreshIndicator`, and
   `AsyncValue.when` with `AutoSkeleton` / `AppErrorView` / `AppEmptyView`.
   Forms are full screens. Quick edits go in sheets.
6. `test/x_test.dart`: a fake repository through
   `ProviderScope(retry: (_, _) => null, overrides: [...])`. Riverpod 3 auto-retries
   failures, so without `retry: null` error states never appear in tests.
   Cover loading → data, error → Retry, empty, and the layout matrix for the screen.
7. Run `dart format .`, `flutter analyze` (0 issues) and `flutter test` (all green),
   then add a `changes/CHANGELOG.md` entry.

Copy-ready code is in [references/feature-recipe.md](./references/feature-recipe.md),
and the core files are in [templates/lib/core/](./templates/lib/core/).

## Definition of Done

- [ ] DPDP: notices, consents and the ledger are updated if this feature touches personal data or SDKs.
- [ ] No mock data. Real API. Errors propagate.
- [ ] Loading = `AutoSkeleton` shaped like the content. Error = Retry that invalidates the source. Empty state designed.
- [ ] `ref.cacheFor` on read providers, ETag `GET`s, `AppNetworkImage` with `memCache*`.
- [ ] SafeArea on body, bottom bars, sheets and drawer. Nothing under the 3-button bar, gesture bar, notch or keyboard.
- [ ] No overflow at 320×568 at text scale 1.0 and 1.5, including with the keyboard open on input screens.
- [ ] Forms: full screen or bottom sheet, `PopScope` unsaved guard, 422 errors under the fields, double-tap guard.
- [ ] Rounded-rectangle buttons, slide transitions, theme tokens only, hugeicons, light and dark both checked.
- [ ] `context.mounted` after awaits. Everything disposed. No deprecated APIs. No PII in logs.
- [ ] `dart format .` clean, `flutter analyze` → **No issues found!**, `flutter test` → **All tests passed!** (run them; never claim results you did not see).
- [ ] `changes/CHANGELOG.md` entry added. Owner-only tasks (keys, consoles, legal review) noted in `docs/owner-todo.md` and in the reply.

## Reference index

- [references/stack-and-architecture.md](./references/stack-and-architecture.md): packages, versions, folders, naming, main.dart bootstrap
- [references/state-riverpod.md](./references/state-riverpod.md): providers, cacheFor, source vs derived, invalidation, selectors
- [references/networking-caching.md](./references/networking-caching.md): ApiClient, ApiException, ETag cache, media URL resolution, image caching
- [references/ui-layout-safety.md](./references/ui-layout-safety.md): SafeArea, insets, sheets, overflow, forms, wizard, buttons, transitions, hero banners, filter sheets
- [references/theming-design-system.md](./references/theming-design-system.md): ColorScheme + ThemeExtension, theme persistence, typography, icons, wordmark
- [references/security-auth.md](./references/security-auth.md): AuthSession, secure storage, app lock, biometrics, payments, privacy
- [references/testing-quality.md](./references/testing-quality.md): lints, fakes, widget tests, layout matrix, verification commands
- [references/release-assets.md](./references/release-assets.md): launcher icon, native splash, flavors, versioning, obfuscation, Play Store
- [references/project-docs.md](./references/project-docs.md): CLAUDE.md / GEMINI.md template, CHANGELOG format, docs folder, owner TODO
- [references/feature-recipe.md](./references/feature-recipe.md): full model → repository → provider → screen → test example
- [references/new-project-checklist.md](./references/new-project-checklist.md): step-by-step scaffold for a new app
