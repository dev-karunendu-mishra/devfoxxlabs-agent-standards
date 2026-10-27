import 'package:flutter/material.dart';

/// Supported theme modes for the application.
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  /// Converts [AppThemeMode] to Flutter's native [ThemeMode].
  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// User-facing display title for settings and selection modals.
  String get label {
    switch (this) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Theme';
    }
  }

  /// Subtitle description explaining each theme mode choice.
  String get description {
    switch (this) {
      case AppThemeMode.system:
        return 'Matches your device display settings';
      case AppThemeMode.light:
        return 'Clean, bright interface optimized for daylight';
      case AppThemeMode.dark:
        return 'High contrast, easy on the eyes in low light';
    }
  }

  /// Corresponding Material Icon for UI actions.
  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  /// Serialization string stored in key-value persistent storage.
  String get code {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }

  /// Parses a string [code] back into [AppThemeMode]. Defaults to [AppThemeMode.system].
  static AppThemeMode fromCode(String? code) {
    switch (code) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}
