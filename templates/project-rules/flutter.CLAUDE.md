# Flutter Mobile Rules & Standards (Project Template)

This document defines mandatory architectural, styling, and layout standards for the Flutter mobile application. All AI coding assistants (Claude, Antigravity, Cursor, Windsurf) and developers must follow these rules.

## 1. Mandatory Safe Area Protection
- **`Scaffold.body`**: Wrap in `SafeArea(child: ...)` by default. For full-bleed screens (e.g. hero banner extending behind the status bar), ensure interactive elements (back buttons, headers, inputs, CTAs) are wrapped in `SafeArea` or padded with `MediaQuery.paddingOf(context)`.
- **Bottom Navigation & Persistent Buttons**: All `bottomNavigationBar`, sticky bottom bars, and floating CTA buttons MUST be wrapped in `SafeArea(top: false, child: ...)`. Protects tap targets from being obscured by Android gesture navigation pill or iOS home indicator.
- **Bottom Sheets & Dialogs**: Wrap `showModalBottomSheet` content in `SafeArea(child: ...)` and respect keyboard insets via `MediaQuery.viewInsetsOf(context)`.

## 2. Mandatory Overflow Protection
- **Scrollability**: Wrap scrollable screen bodies in `SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), ...)` or `ListView` / `CustomScrollView`.
- **Row Protection**: In any `Row` containing text or dynamic elements, wrap text in `Expanded` or `Flexible`, specify `maxLines`, and set `overflow: TextOverflow.ellipsis`. Never allow raw, unbounded `Text` in a `Row`.
- **Keyboard Protection**: Keep `resizeToAvoidBottomInset: true` on `Scaffold` and ensure forms are scrollable.
- **Dialogs & Modals**: Constrain dialog heights using `ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8))` with `SingleChildScrollView`.
- **Horizontal Cards**: Restrict text in fixed-height cards to `maxLines: 1` or `2` with `overflow: TextOverflow.ellipsis`.

## 3. Mandatory Dynamic Backend-Driven Data
- **No Hardcoded Content**: Production screens, carousels, lists, and widgets MUST fetch and display live data dynamically from the backend API.
- **Offline Fallbacks Only**: Local constants or bundled asset lists are only allowed as graceful offline fallbacks when network fails.
- **Dynamic Media Resolution**: Support remote URLs (`https://...`) and root-relative paths resolved against `ApiEndpoints.baseUrl` with local asset fallbacks.

## 4. UI Components & Theming
- **Icons**: Hugeicons (free, stroke rounded) only via the `hugeicons` package from pub.dev. Never use Material `Icons.*` or Cupertino icons.
- **Skeleton Loading**: Wrap dynamic loading states in `AppSkeleton(isLoading: isLoading, child: ...)`.
- **Image Caching**: Remote images must use cached network image loaders with memory and disk cache constraints (`memCacheWidth`, `memCacheHeight`).

## 5. Quality & Test Gates
- Run `flutter analyze` — must be 100% clean (0 errors, 0 warnings).
- Run `flutter test` — must pass 100% of unit and widget tests.

