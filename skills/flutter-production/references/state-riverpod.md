# State Management: Riverpod 3

## Provider kinds and when to use them

| Need | Use |
|---|---|
| Singleton service (ApiClient, repository, BiometricService) | `Provider<T>` |
| Read-only API data for a screen | `FutureProvider.autoDispose<T>` + `ref.cacheFor(...)` |
| API data plus mutations (cart, duty state, active trip) | `AsyncNotifierProvider.autoDispose<N, T>` |
| Synchronous UI state (search query, filter, selected tab, theme) | `NotifierProvider<N, T>` |
| Derived / filtered views | `Provider.autoDispose<AsyncValue<List<T>>>` built from the source with `whenData` |
| Real-time DB streams (drift) | `StreamProvider.autoDispose` |

- Use `.autoDispose` by default. Drop it only for app-lifetime state (session, theme, app lock).
- **Do not** use `StateProvider` / `StateNotifierProvider` (legacy). Legacy
  `ChangeNotifierProvider` from `package:flutter_riverpod/legacy.dart` is acceptable
  only for bridging an existing `ChangeNotifier` singleton such as `AuthSession`.
- `ConsumerWidget` / `ConsumerStatefulWidget` at screen level. Use `ref.watch` in
  `build` and `ref.read` only in callbacks. Never call `ref.read` in `build`.
- Form controllers (`TextEditingController`, `GlobalKey<FormState>`) live in `State`.
  Only domain state goes in providers.
- One notifier per cohesive slice of state. Don't grow a god-notifier.

## `ref.cacheFor`: instant tab revisits

`templates/lib/core/providers/ref_cache.dart`:

```dart
extension RefCacheFor on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
```

Typical durations: profile, catalog and settings take 15–30 min. Lists and dashboards
take 3–5 min. Earnings and history take 3–5 min. Live data (active trip, dispatch,
stock at checkout) is never cached.

## Source provider → derived providers (fetch once)

```dart
final couponsRepositoryProvider = Provider<CouponsRepository>((ref) => const CouponsRepository());

final couponSearchQueryProvider = NotifierProvider<CouponSearchQueryNotifier, String>(CouponSearchQueryNotifier.new);

class CouponSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
  void clear() => state = '';
}

/// SOURCE: the only provider that calls the API.
final adminCouponsIndexProvider = FutureProvider.autoDispose<CouponsIndex>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return ref.watch(couponsRepositoryProvider).fetchIndex();
});

/// DERIVED: filtering is local and instant, with no extra request.
final adminCouponsListProvider = Provider.autoDispose<AsyncValue<List<Coupon>>>((ref) {
  final search = ref.watch(couponSearchQueryProvider).trim().toLowerCase();
  return ref.watch(adminCouponsIndexProvider).whenData(
        (index) => index.coupons.where((c) => c.code.toLowerCase().contains(search)).toList(),
      );
});
```

- After **every** mutation and in every pull-to-refresh, call
  `ref.invalidate(adminCouponsIndexProvider)`, the **source**. Invalidating a derived
  provider does not refetch.
- When the context changes (address, dark store, role, duty online/offline), invalidate
  every provider that depends on it in one place.

## AsyncValue in the UI

```dart
final async = ref.watch(adminCouponsListProvider);
return RefreshIndicator(
  onRefresh: () => ref.refresh(adminCouponsIndexProvider.future),
  child: async.when(
    data: (items) => items.isEmpty
        ? const AppEmptyView(iconWidget: HugeIcon(icon: HugeIcons.strokeRoundedTicket01, size: 56), title: 'No coupons yet', message: 'Create your first coupon.')
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(context).bottom),
            itemCount: items.length,
            itemBuilder: (_, i) => CouponCard(coupon: items[i]),
          ),
    loading: () => const CouponListSkeleton(),
    error: (e, _) => AppErrorView(
      title: 'Could not load coupons',
      error: e,
      onRetry: () => ref.invalidate(adminCouponsIndexProvider),
    ),
  ),
);
```

- Keep the old data while refreshing (`skipLoadingOnRefresh` is the default in `when`), so
  pull-to-refresh doesn't flash a skeleton.
- Every `RefreshIndicator` child must be scrollable even when empty or in error, so wrap
  those states in a `ListView` with `AlwaysScrollableScrollPhysics`.

## Mutations in AsyncNotifier

```dart
class CartNotifier extends AsyncNotifier<CartState> {
  @override
  Future<CartState> build() => ref.watch(cartRepositoryProvider).fetch();

  Future<void> setQty(String productId, int qty) async {
    final previous = state.value;
    if (previous == null) return;
    state = AsyncData(previous.withQty(productId, qty)); // optimistic
    try {
      state = AsyncData(await ref.read(cartRepositoryProvider).update(productId, qty));
    } on ApiException catch (e) {
      state = AsyncData(previous); // roll back
      rethrow; // the widget shows a SnackBar with e.message
    }
  }
}
```

- Optimistic updates for steppers and toggles, with a 300 ms debounce on the server sync
  and a rollback plus SnackBar on failure.
- Leaf widgets watch narrow slices:
  `ref.watch(cartProvider.select((c) => c.value?.qtyOf(id) ?? 0))`.
- Fast-changing values (trip timer, meter, upload progress) are read through
  `select` inside a small widget so only that label rebuilds.

## Riverpod 3 automatic retry

Failed providers are retried automatically with exponential backoff, and while that
happens the UI keeps showing loading. Set **one app-wide policy on the root
`ProviderScope`** in `main.dart` (no retry for 4xx client errors, at most 3 tries for
network or 5xx). Tests turn it off with `ProviderScope(retry: (_, _) => null)`.

```dart
// core/providers/retry_policy.dart
Duration? appRetryPolicy(int retryCount, Object error) {
  if (error is ApiException && (error.statusCode ?? 500) < 500) return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}

// main.dart
runApp(const ProviderScope(retry: appRetryPolicy, child: MyApp()));
```

Don't put a retry *function* on individual providers. A provider's own `retry:` wins
over the scope's, so tests can't switch it off and error-state tests time out
(verified). The only per-provider value allowed is `retry: (_, _) => null`, for calls
that must never repeat (payments, one-shot writes exposed as providers).

## Testing hooks

- Repositories have `const` constructors, so tests override them:
  `ProviderScope(overrides: [couponsRepositoryProvider.overrideWithValue(const _FakeCouponsRepository())])`.
- Inject fakes into anything platform-bound (secure storage, biometrics, payments, FCM).
