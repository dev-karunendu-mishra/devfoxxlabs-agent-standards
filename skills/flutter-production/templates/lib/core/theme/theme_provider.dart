import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_session.dart';
import 'app_theme_mode.dart';

const _themeStorageKey = 'app_theme_mode';

/// Persists the user's theme choice.
abstract class ThemeRepository {
  Future<AppThemeMode> loadThemeMode();
  Future<void> saveThemeMode(AppThemeMode mode);
}

/// Secure-storage implementation with timeout protection.
class SecureThemeRepository implements ThemeRepository {
  SecureThemeRepository({SecureKeyValueStore? store})
    : _store = store ?? AuthSession.store;

  final SecureKeyValueStore _store;

  @override
  Future<AppThemeMode> loadThemeMode() async {
    try {
      final code = await _store
          .read(_themeStorageKey)
          .timeout(const Duration(seconds: 2));
      return AppThemeModeX.fromCode(code);
    } on Object {
      return AppThemeMode.system;
    }
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      await _store.write(_themeStorageKey, mode.code);
    } on Object {
      // Not fatal: the choice still applies for this session.
    }
  }
}

/// In-memory fake for tests.
class FakeThemeRepository implements ThemeRepository {
  AppThemeMode _mode = AppThemeMode.system;

  @override
  Future<AppThemeMode> loadThemeMode() async => _mode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => _mode = mode;
}

final themeRepositoryProvider = Provider<ThemeRepository>(
  (ref) => SecureThemeRepository(),
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => AppThemeMode.system;

  /// Call once on splash.
  Future<void> restoreTheme() async {
    final saved = await ref.read(themeRepositoryProvider).loadThemeMode();
    if (saved != state) state = saved;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref.read(themeRepositoryProvider).saveThemeMode(mode);
  }

  /// System → Light → Dark → System.
  Future<void> toggleTheme() => setThemeMode(switch (state) {
    AppThemeMode.system => AppThemeMode.light,
    AppThemeMode.light => AppThemeMode.dark,
    AppThemeMode.dark => AppThemeMode.system,
  });
}

final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

/// Flutter [ThemeMode] for `MaterialApp.themeMode`.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(appThemeModeProvider).flutterThemeMode,
);
