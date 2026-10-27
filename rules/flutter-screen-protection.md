---
trigger: always_on
description: Mandatory Safe Area protection and Overflow prevention rules for Flutter mobile screens.
---

# Flutter Screen Protection & Overflow Prevention Rules

This rule is **always active** for Flutter development in `apps/mobile`.

## 1. Safe Area Protection (MANDATORY)

Every Flutter screen, modal, and persistent UI element must prevent notches, dynamic islands, camera cutouts, status bars, and home indicators from covering or clipping content:

1. **Scaffold Body:** Wrap `Scaffold.body` in `SafeArea(child: ...)` by default.
   - For full-bleed screens (e.g. hero banners behind status bar), ensure all interactive widgets (back buttons, headers, CTAs, list content) are protected by `SafeArea` or `MediaQuery.paddingOf(context)`.
2. **Bottom Navigation & Persistent Buttons:**
   - Any `Scaffold.bottomNavigationBar`, sticky bottom bar, or floating CTA button must be wrapped in `SafeArea(top: false, child: ...)`.
   - Never allow the iOS home indicator or Android navigation pill to overlap tap targets.
3. **Bottom Sheets & Dialogs:**
   - Always wrap `showModalBottomSheet` content in `SafeArea(child: ...)`.
   - Protect against keyboard insets using `MediaQuery.viewInsetsOf(context)`.

---

## 2. Overflow Protection (MANDATORY)

`RenderFlex overflowed` yellow-and-black stripes are strictly prohibited:

1. **Scrollability by Default:**
   - Wrap screen bodies in `SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), ...)` or `ListView` / `CustomScrollView`.
2. **Row & Horizontal Protection:**
   - **NEVER** place unconstrained dynamic `Text` directly inside a `Row`.
   - **ALWAYS** wrap `Text` inside a `Row` in `Expanded` or `Flexible`, and specify `maxLines` and `overflow: TextOverflow.ellipsis`.
3. **Keyboard Resilience:**
   - Keep `resizeToAvoidBottomInset: true` on `Scaffold`.
   - Ensure form inputs are contained inside a scrollable view so they scroll into view above the virtual keyboard.
4. **Dialogs & Modals:**
   - Constrain dialog height with `ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8))` and `SingleChildScrollView`.
5. **Fixed-Height Cards:**
   - In horizontal carousel cards (e.g. `height: 185`), strictly constrain text to `maxLines: 1` or `2` with `overflow: TextOverflow.ellipsis`.

---

## 3. Backend-Driven Dynamic Data (MANDATORY)

Every Flutter screen, section, carousel, list, and widget **must** get its live data from the backend server (`apps/weblaravel` API `/api/v1/...`):

1. **No Static Data in Production UI:** Hardcoding cards or lists directly in Flutter widget files is prohibited. All live sections (Acharyas / Featured Experts, Ganga Aarti Promo, Panchang, Horoscopes, Services, Temples) must fetch data via `ApiClient` / `GuestProvider` / domain providers.
2. **Server-Driven Consistency:** Replicate WebLaravel (`FeaturedExperts.php`, `HomeController.php`, etc.) so Web and Mobile share identical authoritative sources of truth.
3. **Deterministic Offline Fallbacks Only:** Hardcoded constants or local assets are solely permitted as graceful degradation fallbacks if network requests fail or while cache is hydrating.
4. **Dynamic Media Resolution:** Support both remote URLs and root-relative paths (`/images/...`, `/bg/...`) resolved against `ApiEndpoints.baseUrl` with local asset fallbacks.

---

## 4. Universal Sacred Background & Standardized AppBar System (MANDATORY)

1. **Universal Sacred Background:** Every screen body in `apps/mobile` **must** use `Image.asset('assets/bg/app_bg.png', fit: BoxFit.cover, width: double.infinity, height: double.infinity)` as the base background layer in a `Stack` (or `AppBackgroundWrapper`), with `Scaffold(backgroundColor: Colors.transparent)` so the sacred saffron background motif (mandala, lotus, sparkling stars, temple silhouette) renders consistently across screens.
2. **Standardized AppBar System:** App bars **must** follow the exact Customer Home header standard: `AppBar(titleSpacing: 0, elevation: 0, backgroundColor: Colors.transparent, leading: IconButton(icon: Icon(Icons.menu_rounded, size: 26, color: AppColors.primaryOrange), onPressed: onOpenDrawer), title: Row(children: [AppLogo(size: 34), SizedBox(width: 8), Column(children: [Text('$greetingText,'), Text(firstName)])]), actions: [NotificationsBell, WalletPill])`.

---

## 5. Auto Skeleton Loading Rules (MANDATORY)

1. **Auto Skeleton Wrapping:** Every Flutter screen, list, section, and card that fetches or renders dynamic backend data **must** wrap its content/body in `AppSkeleton(isLoading: isLoading, child: ...)` using `auto_skeleton` via [`AppSkeleton`](file:///e:/DevFoxxLabsProjects/astrogaon/apps/mobile/lib/shared/widgets/app_skeleton.dart).
2. **Test Compatibility:** `AppSkeleton` automatically bypasses animation tickers during Flutter widget tests (`isTestEnvironment`) to guarantee 100% test suite execution stability.

---

## 6. Image Optimization & Caching Rules (MANDATORY)

1. **Image Caching:** All remote network images and URLs **must** use cached network image loaders (e.g. `CachedNetworkImage` or [`ExpertAvatar`](file:///e:/DevFoxxLabsProjects/astrogaon/apps/mobile/lib/shared/widgets/expert_avatar.dart)) to eliminate redundant network fetches and ensure smooth performance.
2. **Memory & Disk Cache Bounds:** Network images **must** specify memory and disk cache constraints (`memCacheWidth`, `memCacheHeight`, `maxWidthDiskCache`, `maxHeightDiskCache`) sized appropriately for the display target to prevent memory bloat and OOM crashes.
3. **Fallbacks & Error Placeholders:** Every image loader **must** provide graceful fallback placeholders (e.g. local asset placeholders, `AppSkeleton`, or `Icons.error`) when loading or on network error.

---

## 7. Pre-Commit Quality Checks

Always run before finishing:
- `flutter analyze` (must have 0 errors, 0 warnings, 0 lints)
- `flutter test` (all unit and widget tests must pass)

