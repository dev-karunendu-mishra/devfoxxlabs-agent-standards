import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/local_api_cache.dart';
import '../models/app_user.dart';

const _tokenKey = 'auth_token';
const _userKey = 'auth_user';
const _appLockKey = 'app_lock_enabled';

/// Minimal key/value contract so tests can swap in an in-memory store instead
/// of the Keychain / Keystore platform channel.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class InMemoryKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Holds the signed-in user's token and profile and persists them in secure
/// storage. `SplashScreen` awaits [restore] before choosing login vs home.
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static SecureKeyValueStore _store = const FlutterSecureKeyValueStore();

  /// Shared store, also used for theme mode and other small secure settings.
  static SecureKeyValueStore get store => _store;

  @visibleForTesting
  static void debugOverrideStore(SecureKeyValueStore store) => _store = store;

  String? _token;
  AppUser? _user;
  bool _isRestored = false;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isSignedIn => _token != null && _user != null;
  bool get isRestored => _isRestored;

  /// Loads a previously persisted session. Uses a short timeout: a platform
  /// channel that never answers must not block startup, it just falls back to
  /// the login screen.
  Future<void> restore() async {
    if (_isRestored) return;
    try {
      final token = await _store
          .read(_tokenKey)
          .timeout(const Duration(seconds: 3));
      final userJson = await _store
          .read(_userKey)
          .timeout(const Duration(seconds: 3));
      if (token != null && userJson != null) {
        _token = token;
        _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
    } on Object {
      // Corrupt or unreadable storage: start signed out instead of crashing.
      _token = null;
      _user = null;
    } finally {
      _isRestored = true;
      notifyListeners();
    }
  }

  Future<void> signIn({required String token, required AppUser user}) async {
    _token = token;
    _user = user;
    _isRestored = true;
    notifyListeners();
    await _store.write(_tokenKey, token);
    await _store.write(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> updateUser(AppUser user) async {
    _user = user;
    notifyListeners();
    await _store.write(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> signOut() async {
    _token = null;
    _user = null;
    LocalApiCache.instance.invalidate();
    notifyListeners();
    await _store.delete(_tokenKey);
    await _store.delete(_userKey);
    await _store.delete(_appLockKey);
  }

  Future<bool> isAppLockEnabled() async {
    try {
      return await _store.read(_appLockKey) == 'true';
    } on Object {
      return false;
    }
  }

  Future<void> setAppLockEnabled({required bool enabled}) async {
    if (enabled) {
      await _store.write(_appLockKey, 'true');
    } else {
      await _store.delete(_appLockKey);
    }
  }
}
