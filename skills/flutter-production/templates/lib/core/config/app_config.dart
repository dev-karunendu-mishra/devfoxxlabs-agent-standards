/// Build-time configuration. Pass values with
/// `--dart-define=API_BASE_URL=https://example.com/api/v1` or
/// `--dart-define-from-file=config/<flavor>.json`. Never hardcode per-environment
/// URLs or keys in feature code.
class AppConfig {
  AppConfig._();

  // TODO(brand): replace the defaults with the real API and site URLs.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://example.com/api/v1',
  );

  /// Public website, used to resolve root-relative media paths and share links.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://example.com',
  );
}
