# New Project Checklist

Work through these in order. Ask the user for anything marked **ASK**, and use clearly
marked placeholders until you have it.

1. **Facts (ASK):** app name, package id (`com.devfoxx.<app>`), target users, roles,
   backend (Laravel / FastAPI / Next.js / Supabase / offline-only) and its repo path,
   brand colors and logo, contact numbers, company legal details for DPDP.
2. **Create:** `flutter create --org com.devfoxx --project-name <app> --platforms android,ios <app>`
   (add `web` only if needed. The dart:io `ApiClient` does not run on web, so use the
   dio version there).
3. **pubspec:** the baseline from [stack-and-architecture.md](./stack-and-architecture.md),
   then `flutter pub get`.
4. **Lints:** copy `templates/analysis_options.yaml`.
5. **Core:** copy `templates/lib/core/**` and `templates/lib/features/auth/data/auth_session.dart`,
   then rename the brand bits:
   - `core/config/app_config.dart`: `API_BASE_URL` / `WEB_BASE_URL` dart-defines
   - `core/network/`: `api_client.dart`, `api_exception.dart`, `local_api_cache.dart`
   - `core/providers/`: `ref_cache.dart`, `core_providers.dart`, `retry_policy.dart`
   - `core/navigation/slide_page_route.dart`
   - `core/theme/`: `app_colors.dart`, `app_theme.dart`, `app_theme_extension.dart`,
     `app_theme_mode.dart`, `theme_provider.dart`
   - `core/widgets/`: `app_network_image.dart`, `app_bottom_bar.dart`, `app_modal_sheet.dart`,
     `app_state_views.dart`, `app_step_wizard.dart`
   - `core/utils/`: `sheet_insets.dart`, `currency.dart`
   - `core/services/biometric_service.dart`
6. **Bootstrap:** `main.dart` as in [stack-and-architecture.md](./stack-and-architecture.md),
   plus a `SplashScreen` that restores the session and theme and then routes.
7. **DPDP foundation (before features):** run the `dpdp-compliance` skill. That covers the
   Privacy & Legal screen for guests and signed-in users, `GET /legal` notices, the
   consent checkbox, the consent ledger API, "Your consents", the privacy request form,
   the Grievance card, and in-app account deletion.
8. **Auth:** login (OTP / email / Google) with the legal line, `AuthSession.signIn`, logout,
   401 handling, and an optional App Lock in Settings.
9. **Shell:** bottom nav or drawer with SafeArea. Five tabs maximum. Extra destinations go
   in the drawer.
10. **Branding:** logo and wordmark assets (WebP), `flutter_launcher_icons`,
    `flutter_native_splash`, then run both generators.
11. **Tests:** `test/helpers/layout_matrix.dart`, a smoke test that pumps the app with fakes,
    and tests for the theme repository and auth session.
12. **Docs:** `CLAUDE.md` + `GEMINI.md` from [project-docs.md](./project-docs.md),
    `docs/` files, `changes/CHANGELOG.md` + `README.md`, `docs/owner-todo.md`.
13. **Verify:** `dart format .`, `flutter analyze` (No issues found!), `flutter test` (All
    tests passed!). Then add the first changelog entry ("Build › Scaffold").
14. Now build features with the recipe in [feature-recipe.md](./feature-recipe.md).
