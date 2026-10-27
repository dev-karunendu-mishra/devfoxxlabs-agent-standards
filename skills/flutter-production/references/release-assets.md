# Release, Assets & Platform Setup

## Launcher icon + native splash (every app)

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.webp"     # or a full-res PNG source outside bundled assets
  min_sdk_android: 21
  remove_alpha_ios: true
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo.webp"

flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/images/logo.webp"
  color_dark: "#0B0C10"                     # match the dark theme background
  image_dark: "assets/images/logo.webp"
  android_12:
    color: "#FFFFFF"
    image: "assets/images/logo.webp"
    color_dark: "#0B0C10"
    image_dark: "assets/images/logo.webp"
```

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

- The in-app `SplashScreen` matches the native splash, so there is no visual jump. It runs
  `AuthSession.restore()` and theme restore, then routes with `pushReplacementSlide`.
- Assets are WebP and declared per folder in `pubspec.yaml`. Large source images stay
  out of bundled assets.
- Package rename: `change_app_package_name` (dev dependency), `dart run change_app_package_name:main com.devfoxx.<app>`.

## Android

- `minSdk` 21+ (higher if a plugin needs it). `targetSdk` meets the current Play
  requirement.
- Edge-to-edge is the default on new Android, so rely on the SafeArea rules and never on
  opaque system bars.
- Declare only the permissions in use, each with a just-in-time rationale in the app.
  Remove unused ones that plugins add (`tools:node="remove"`).
- Release builds: R8/minify on, ProGuard keep rules tested on a real release build.
  Signing comes from a gitignored `key.properties`.
- `FLAG_SECURE` through a method channel when the app lock is on (covers recents).

## iOS

- Add every `NS*UsageDescription` string for the permissions used, in plain language.
- Set the privacy manifest and App Store privacy labels to match the data actually collected.

## Versioning and build

- `version: MAJOR.MINOR.PATCH+BUILD`. The build number always increases and is never reused.
- Flavors (`dev`, `staging`, `prod`) with `applicationIdSuffix` and separate app names and
  icons, for apps with multiple environments:
  ```bash
  flutter build appbundle --flavor prod --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=config/prod.json
  ```
  Archive `build/symbols` for crash de-obfuscation.
- Check size with `flutter build appbundle --analyze-size` after adding large dependencies.

## Pre-release checklist

- [ ] Analyzer clean, tests green, `dart format` clean.
- [ ] Release build smoke-tested on a physical device (an old Android version and the
  latest), in both 3-button and gesture navigation.
- [ ] No debug banners, debug menus, fake repositories or `print`s in release.
- [ ] Permissions audit, ProGuard verified, size checked.
- [ ] Privacy and legal: notices versioned, consent flows work, in-app account deletion
  works, Data Safety form matches (DPDP + Play policy).
- [ ] Changelog entry added. Owner tasks (store listing, keys, console setup) are listed
  in `docs/owner-todo.md`.
