# UI, Layout Safety & Interaction Patterns

A screen with an overflow, clipped text, or content under system UI is **not done**,
whatever it looks like on your emulator.

## 1. SafeArea and insets

- Every `Scaffold.body` is wrapped in `SafeArea` (or uses the app's scaffold wrapper that
  does it).
- **Full-bleed exception** (hero image, video, onboarding background): the background
  ignores insets, but every interactive overlay (back, title, actions, CTAs) still sits
  inside `SafeArea` or is offset by `MediaQuery.paddingOf(context).top`.
- **Bottom CTAs, payment bars and duty switches** use `AppBottomBar`
  (`templates/lib/core/widgets/app_bottom_bar.dart`):
  `bottom = max(16, MediaQuery.viewPaddingOf(context).bottom) + MediaQuery.viewInsetsOf(context).bottom`.
  - With the Samsung / Android 3-button bar (48–56 dp), nothing is hidden.
  - With gesture nav (0–16 dp), there is no oversized gap.
  - With the keyboard open, the bar floats above it.
- **Explicit padding gotcha:** a `ListView` / `CustomScrollView` adds the system inset
  on its own *only until you pass `padding:`*. On pushed screens without a
  `bottomNavigationBar`, use
  `EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(context).bottom)`.
- Navigation drawers, bottom nav shells and app bars all respect SafeArea.
- Read insets with `MediaQuery.paddingOf / viewPaddingOf / viewInsetsOf / sizeOf`, not
  `MediaQuery.of(context).x`, which rebuilds on every change.

## 2. Bottom sheets (`templates/lib/core/widgets/app_modal_sheet.dart`)

```dart
showAppModalSheet<void>(
  context: context,
  builder: (ctx) => const ReasonForm(),
);
```

- They always go through `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent)`.
- The content root is `SafeArea(top: false)` with bottom padding
  `max(16, viewPadding.bottom) + viewInsets.bottom` (`safeBottomInset(context)` in `core/utils/sheet_insets.dart`).
- Rounded top corners (24). The house style is a floating circular ✕ close button
  centered above the sheet with no drag-handle bar (sarthi / taxiyaa). If an app
  already uses a drag handle, keep that app consistent.
- Max height is about 90% of the screen, and the content scrolls.

## 3. Overflow protection

- **Every `Text` inside a `Row`** goes in `Expanded`/`Flexible` with `maxLines` +
  `overflow: TextOverflow.ellipsis`, unless it is provably short (`00:12`).
- Use `Wrap` for chips, tags and badges that can grow.
- No fixed `height` on containers that hold text. Use `minHeight` constraints and
  padding. Fixed sizes are only for icons, avatars, dividers and `AspectRatio` media.
- Screen-fraction sizes only for decorative or hero media, and always clamped:
  `(MediaQuery.sizeOf(context).height * 0.36).clamp(240, 360)`.
- A body that can exceed the viewport scrolls. For "fill the screen, but scroll if needed"
  layouts:
  ```dart
  CustomScrollView(slivers: [
    SliverFillRemaining(hasScrollBody: false, child: Column(children: [..., const Spacer(), cta])),
  ]);
  ```
- Never `ListView(shrinkWrap: true)` inside a scroll view for long content. Compose
  slivers instead. Short skeleton lists inside another scroll view use `shrinkWrap: true`
  + `NeverScrollableScrollPhysics()`.
- `Expanded`/`Spacer` never go inside an unbounded-axis parent.
- Forms: `resizeToAvoidBottomInset: true` (the default), body in `SingleChildScrollView`,
  `onTapOutside: (_) => FocusScope.of(context).unfocus()`.
- Custom dialogs: `ConstrainedBox(maxHeight: 0.8 × screen)` + `SingleChildScrollView`.
- Text scale is clamped to 1.0–1.5 in `MaterialApp.builder`, and layouts must be clean
  at 1.5. Never clamp below 1.0.
- Do not hide overflow with `ClipRect` / `FittedBox` / `OverflowBox`. Fix the layout.
- Target: no `RenderFlex overflowed` down to **320 px** wide (320×568). Verify with the
  layout matrix test in [testing-quality.md](./testing-quality.md).

## 4. Forms: full screen or bottom sheet, never a dialog

| Kind | Pattern |
|---|---|
| Large form (several fields or sections, KYC, checkout, profile edit, create or edit entity) | New full screen (`context.pushSlide(XFormScreen())`) |
| Quick 1–2-field entry, picker, reason, OTP, variant selector, address switcher | `showAppModalSheet` |
| Destructive confirmation ("Delete?", "Discard changes?", "Go offline?") | `AlertDialog` (the only allowed dialog) |

Full-screen form rules:
- A sticky save bar in `AppBottomBar`, with a busy spinner and a disabled state while saving.
- An unsaved-changes guard:
  `PopScope(canPop: !_dirty, onPopInvokedWithResult: (didPop, _) async { if (!didPop && await _confirmDiscard()) navigator.pop(); })`.
- Validate with `Form` + `TextFormField.validator` and
  `AutovalidateMode.onUserInteraction`. Server `422` errors go under each field.
- Long Markdown descriptions edited on the web with a rich editor use the app's
  `RichTextEditorField` (Flutter Quill ↔ Markdown). Short fields stay plain text.

## 5. Multi-step flows: one `AppStepWizard`

Every wizard (booking, onboarding, KYC, create blog, checkout) uses the single shared
component (`lib/core/widgets/app_step_wizard.dart`):
- An AppBar back arrow that steps backwards and leaves only from step 1 (through the discard guard).
- A segmented progress header, "Step X of N: Label" (no Material `Stepper`, no numbered circles).
- Steps in an `enum` with labels. One `StatefulWidget` switches the body. There is no
  route per step, and going back never loses earlier answers.
- Each step starts with a heading (a large question) and a one-line hint. Single choices
  are full-width choice cards (icon circle, title, description, radio).
- One full-width primary button, **Next**, and the final action label on the last step.
  It is disabled until the step is valid. An optional Back/Next footer
  (`showBackNextFooter: true`) is for long flows.
- A review step before submit, where tapping a row jumps to its step.
- Entry points may preselect values but never skip steps.
- To change the design, change it **only** inside `AppStepWizard`.

## 6. Buttons

- Rounded rectangle, `BorderRadius.circular(12)` (10–14), min height 48–52, CTAs full
  width (`minimumSize: Size(double.infinity, 52)`). Configure this in
  `elevatedButtonTheme` / `filledButtonTheme` / `outlinedButtonTheme`.
- **No `StadiumBorder`, no `circular(50/999)` pill CTAs.** Chips and tags use radius 6–8
  (filter chips: height 30, radius 6, h-padding 12, font 11).
- Touch targets are at least 48×48 dp. Every icon-only button has a `tooltip` / semantic label.

## 7. Navigation and transitions

- Slide transitions everywhere: `pageTransitionsTheme` uses `SlidePageTransitionsBuilder()`
  for all `TargetPlatform`s, plus `context.pushSlide(page)`, `pushReplacementSlide` and
  `pushAndRemoveUntilSlide` (`templates/lib/core/navigation/slide_page_route.dart`).
- Bottom-up slide (`SlideDirection.bottomToTop`) is for full-screen modal flows.
- Use `PopScope` for back handling (Android predictive back), not `WillPopScope`.
- After login or logout: `pushAndRemoveUntilSlide(..., (_) => false)`.
- Apps on go_router: `app_router.dart` is the single route source. Routes follow
  `/feature`, `/feature/add`, `/feature/:id`, `/feature/:id/edit`. Use `extra:` only for
  non-serialisable objects.

## 8. Loading, empty and error states

- Loading: `AutoSkeleton` shaped like the real content. Use `skeletonItem` +
  `skeletonItemCount` for lists, or wrap the real widget tree with `enabled: isLoading`.
  Don't use a bare `CircularProgressIndicator` for content areas (a button busy
  spinner is fine).
  ```dart
  AutoSkeleton(
    enabled: true,
    skeletonItem: Container(
      height: 86,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: const ListTile(title: Text('Placeholder title'), subtitle: Text('Placeholder subtitle')),
    ),
    skeletonItemCount: 4,
    child: const SizedBox.shrink(),
  )
  ```
- Empty: an icon, a title, one helpful line and an action ("Browse products", "Book a ride").
- Error: an icon, "Could not load X", the `ApiException.message`, and a **Retry** button
  that invalidates the source provider.

## 9. Recurring screen patterns (astrogaon standard; reuse when the app has them)

- **Detail screen with cover:** one `CoverBanner(url:, fallback:)` (blurred fill, feathered
  edges, top scrim). Height `(h * 0.36).clamp(240, 360)`. Plain white back and share
  `IconButton`s with a shadow. The title fades into the app bar on scroll. Content starts
  on a rounded sheet overlapping the banner. Share sends the title plus the public web
  URL with `sharePositionOrigin`.
- **Filterable lists:** one shared `FilterSheet` (tinted header, sections with "Clear",
  option grid with "All" first, Sort By last, Reset plus **Apply Filters** in a safe
  footer). Choices are staged and sent in one request on Apply. Options come from the API.
  Quick-filter chips edit the same provider state.
- **Brand wordmark:** a `<Brand>Wordmark` widget that picks the dark or light asset by
  theme. Never `Text('brand')`.
- **Contact actions:** `url_launcher` for `tel:`, `https://wa.me/<number>?text=…` and
  map intents. Show a SnackBar if the app can't launch.

## 10. Accessibility and motion

- WCAG AA contrast. Status is never shown by color alone. Decorative images use
  `excludeFromSemantics: true`.
- Respect `MediaQuery.disableAnimationsOf(context)`.
- Use `RepaintBoundary` around video and heavy animations. Use `*Transition` /
  `AnimatedBuilder` widgets, not `setState` animation loops. No `BackdropFilter` inside
  list items.
