import 'package:flutter/foundation.dart';

/// In-memory API response cache keyed by full request URI.
///
/// - Stores the last JSON body per URI so a `304 Not Modified` can be served
///   instantly.
/// - Stores the ETag per URI for `If-None-Match` revalidation.
///
/// Cleared on sign-out so one user's data never shows for the next.
class LocalApiCache {
  LocalApiCache._();
  static final LocalApiCache instance = LocalApiCache._();

  final Map<String, String> _eTags = {};
  final Map<String, Map<String, dynamic>> _jsonCache = {};
  final Map<String, DateTime> _timestamps = {};

  void setETag(String uri, String etag) => _eTags[uri] = etag;

  String? getETag(String uri) => _eTags[uri];

  void put(String uri, Map<String, dynamic> data) {
    _jsonCache[uri] = data;
    _timestamps[uri] = DateTime.now();
  }

  /// Cached body for [uri]; expired entries (older than [ttl]) are dropped.
  Map<String, dynamic>? get(String uri, {Duration? ttl}) {
    final data = _jsonCache[uri];
    if (data == null) return null;
    final storedAt = _timestamps[uri];
    if (ttl != null &&
        storedAt != null &&
        DateTime.now().difference(storedAt) > ttl) {
      invalidate(uri);
      return null;
    }
    return data;
  }

  /// Drops one URI, or everything when [uri] is null.
  void invalidate([String? uri]) {
    if (uri != null) {
      _jsonCache.remove(uri);
      _timestamps.remove(uri);
      _eTags.remove(uri);
    } else {
      _jsonCache.clear();
      _timestamps.clear();
      _eTags.clear();
    }
  }

  @visibleForTesting
  void clearForTesting() => invalidate();
}
