import '../network/api_exception.dart';

/// App-wide Riverpod 3 retry policy, set once on the root `ProviderScope`:
/// `ProviderScope(retry: appRetryPolicy, child: MyApp())`.
///
/// - 4xx client errors (auth, validation, not found) are never retried.
/// - Network / 5xx errors: up to 3 retries with exponential backoff.
///
/// Tests pass `retry: (_, _) => null` on their own scope. Don't set a retry
/// function on individual providers: it overrides the scope and tests can't
/// turn it off.
Duration? appRetryPolicy(int retryCount, Object error) {
  if (error is ApiException && (error.statusCode ?? 500) < 500) return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}
