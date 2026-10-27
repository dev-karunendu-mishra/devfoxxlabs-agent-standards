# Stack & Architecture

## pubspec baseline (the versions used across the current apps)

```yaml
environment:
  sdk: ^3.13.3

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^3.4.3
  flutter_secure_storage: ^11.2.0
  hugeicons: ^1.2.0
  auto_skeleton: ^0.4.1
  cached_network_image: ^3.4.1
  url_launcher: ^6.3.1
  intl: ^0.20.3
  local_auth: ^3.0.2
  # add only when the app needs them:
  # pdfrx: ^2.6.5                 # view PDFs (invoices, documents)
  # pdf: ^3.13.0 / printing: ^5.15.0   # generate / print PDFs
  # image_picker: ^1.2.3  file_picker: ^13.1.0  share_plus: ^13.3.1  path_provider: ^2.1.6
  # flutter_quill: ^11.6.0  markdown_quill: ^4.3.0  markdown: ^7.3.1  flutter_markdown_plus: ^1.0.12
  # firebase_core: ^4.15.0  firebase_messaging: ^16.7.0  flutter_local_notifications: ^22.3.1
  # flutter_map: ^8.3.2  geolocator: ^14.0.1
  # drift: ^2.35.0 (+ drift_dev, build_runner)   # offline-first apps only
  # go_router: ^18.0.1                           # only for deep-link / guard-heavy apps

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.6   # (kept under dependencies in some apps; either works)
  # mocktail: ^1.0.5
```

Rules:
- Before adding **any** package, check that it is maintained, has a verified publisher
  or wide adoption, and supports current Flutter. Say why it is needed. Don't add a
  package for about 30 lines of code. No git or path deps on main (local packages such as
  `FlutterPackages/filepick` are fine while you develop them).
- Wrap third-party SDKs (payments, FCM, biometrics, maps) behind your own class in
  `core/services/` so tests can pass a fake.
- Older apps (astrogaon mobile, GymYardHQ, club-100-gym) use `provider`. **New code uses
  Riverpod.** When you touch an old `provider` app, follow its existing pattern unless
  the user asks for a migration.

## Folder layout (default, used by adminastrogaon / nutan / sarthi / taxiyaa)

```text
lib/
  main.dart
  core/
    constants/        app_constants.dart, contact numbers, ecosystem ids
    network/          api_client.dart, api_exception.dart, local_api_cache.dart, api_endpoints.dart, api_response.dart
    providers/        core_providers.dart, ref_cache.dart, app_lock_provider.dart, app_provider_observer.dart
    theme/            app_colors.dart, app_theme.dart, <app>_theme_extension.dart, app_theme_mode.dart, theme_provider.dart, theme_repository.dart
    navigation/       slide_page_route.dart
    services/         biometric_service.dart, fcm_service.dart, payment_checkout.dart
    utils/            date_formatting.dart, currency.dart, validators.dart, sheet_insets.dart
    widgets/          app_network_image.dart, app_bottom_bar.dart, app_modal_sheet.dart,
                      app_step_wizard.dart, app_state_views.dart, app_lock_gate.dart, <brand>_wordmark.dart
  features/
    <feature>/
      screens/        <feature>_screen.dart, <feature>_form_screen.dart, <feature>_detail_screen.dart
      widgets/        feature-private widgets (cards, sheets, stats headers)
      providers/      <feature>_providers.dart
      data/           <feature>_repository.dart (+ data sources)
      models/         <feature>_models.dart
```

Alternative used by vastugram and feellive (`data/ domain/ presentation/`, plus `shared/`):
use it only when the project already does. Never mix the two in one app.

Naming:
- Files `snake_case.dart`, one public widget per file (private `_Widgets` may live with it).
- Providers are named `xxxProvider`, notifiers `XxxNotifier`, and repositories
  `XxxRepository` with a `const` constructor that takes `ApiClient client = const ApiClient()`.
- Brand-prefixed shared widgets are fine (`SarthiButton`, `VastuCard`, `AstroButton`),
  but core infrastructure keeps the generic `App*` names (`AppNetworkImage`,
  `AppStepWizard`) so the rules read the same in every app.
- A feature must not import another feature's `screens/`. Share code through `core/`
  or that feature's `models/` and `providers/`.

## main.dart bootstrap

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fast, non-blocking restores. Never block the first frame on network.
  unawaited(AuthSession.instance.restore());
  // Firebase etc.: wrap in try/catch and only on supported platforms.
  runApp(const ProviderScope(retry: appRetryPolicy, child: MyApp())); // see state-riverpod.md
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'App Name',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.5,
        child: AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
      home: const SplashScreen(), // the splash decides login vs shell after restore()
    );
  }
}
```

- Make `MyApp` accept `overrides` (and optionally `navigatorKey`) so tests can pump the
  real app with fakes (the adminastrogaon pattern).
- Production apps should also route `FlutterError.onError`,
  `PlatformDispatcher.instance.onError` and a release `ErrorWidget.builder` (a branded
  fallback card, never a red screen) to the logger or crash reporter. Start the crash
  reporter only after consent if it collects personal data.
- Role-based apps pick a shell per role (`shellForRole(user.role)`) and reject roles
  the app is not for at login (`_admit`).
