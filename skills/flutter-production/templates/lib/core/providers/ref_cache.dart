import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory caching for `autoDispose` providers.
extension RefCacheFor on Ref {
  /// Keeps this provider's state alive for [duration] after its last
  /// listener goes away, so revisiting a tab or screen shows the cached data
  /// instantly instead of refetching. `ref.invalidate` still forces a fresh
  /// load (after a mutation or pull-to-refresh), and the HTTP layer's ETag
  /// cache makes that refetch cheap when nothing changed.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
