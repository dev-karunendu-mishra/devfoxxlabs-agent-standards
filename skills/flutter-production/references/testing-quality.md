# Testing & Quality Gates

## Gates (run them; never claim results you didn't see)

```bash
dart format .                 # or: dart format --line-length 120 lib/ test/ where the project uses 120
flutter analyze               # must print: No issues found!
flutter test                  # must print: All tests passed!
```

- Run long test suites in the background and read the final summary. Don't trust an
  early "completed".
- Report failures with their output. Don't mark a task done while anything is red.
- For UI changes, also exercise the golden path plus one edge case (empty, validation
  error, long text) on a device or emulator when one is available.

## analysis_options.yaml

Start from `templates/analysis_options.yaml`: `flutter_lints` plus strict-casts and
strict-raw-types, and the extra lints from feellive (`prefer_const_*`,
`use_build_context_synchronously: error`, `cancel_subscriptions`, `close_sinks`,
`unawaited_futures`, `avoid_print`, `prefer_single_quotes`, `require_trailing_commas`,
`directives_ordering`, `use_colored_box`, `use_decorated_box`, `sized_box_for_whitespace`).
- Don't relax lints to make code pass. Any `// ignore:` needs a reason on the same line.
- Exclude generated files (`**/*.g.dart`, `**/*.freezed.dart`) and `build/`.

## What to test for each feature

| Layer | Test |
|---|---|
| Model | `fromJson` with full, partial and null fields (safe defaults), `toJson` round-trip |
| Repository | Parses the envelope; throws `ApiException` on non-2xx; sends the right path/body (use `HttpOverrides` or a fake `ApiClient`) |
| Provider | Source loads; derived filter/search output; invalidation after a mutation; optimistic update and rollback |
| Screen | Loading shows a skeleton → data renders; error shows Retry and Retry re-calls the repo; empty state; form validation and 422 field errors; unsaved-changes guard |
| Wizard | Walks every step, asserts "Step N of T", the submitted body and back-step behaviour |
| Filter sheet | Nothing is requested before Apply; Apply sends one request with every param; Reset and close behave |
| Layout | `testLayoutMatrix` at 320×568 … 600×960 × text scale {1.0, 1.5}, and with the keyboard for input screens. `tester.takeException()` must be null |
| Security | App lock: locks on resume, fails closed on exception, `keepUnlockedDuring` doesn't lock |

## Fakes, not mocks of the network

```dart
class _FakeCouponsRepository extends CouponsRepository {
  const _FakeCouponsRepository({this.fail = false});
  final bool fail;

  @override
  Future<List<Coupon>> fetchCoupons() async {
    if (fail) throw const ApiException('Server down', statusCode: 500);
    return const [Coupon(id: 1, code: 'WELCOME100', value: 100, isActive: true)];
  }
}

Widget _app(CouponsRepository repo) => ProviderScope(
      retry: (_, _) => null, // REQUIRED: Riverpod 3 auto-retries failures, so error states never show in tests otherwise
      overrides: [couponsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const CouponsScreen()),
    );

testWidgets('shows coupons', (tester) async {
  await tester.pumpWidget(_app(const _FakeCouponsRepository()));
  await tester.pump();             // loading → data
  expect(find.text('WELCOME100'), findsOneWidget);
});
```

- **Riverpod 3 retries failing providers automatically** (with backoff). Every test
  `ProviderScope` sets `retry: (_, _) => null`, or error-state tests only ever see the
  skeleton. Production sets one policy on the root scope (see state-riverpod.md). Never
  put a retry function on a single provider, because it overrides the test scope.
- Fake data inside `test/` is allowed (the no-mock-data rule is for `lib/`).
- Override platform-bound pieces: `AuthSession.debugOverrideStore(InMemoryKeyValueStore())`,
  `FakeThemeRepository`, fake `BiometricService`, fake `PaymentCheckout`, and
  `LocalApiCache.instance.clearForTesting()` in `setUp`.
- Tests are deterministic: no real network, no `sleep`, and `pumpAndSettle` only for
  finite animations. `AutoSkeleton` shimmer is an infinite animation, so use `pump()`
  with durations while it shows.
- Every bug fix gets a regression test.

## Layout matrix helper

Copy `templates/test/helpers/layout_matrix.dart`:

```dart
testLayoutMatrix('Coupons screen has no overflow', (tester) async {
  await tester.pumpWidget(_app(const _FakeCouponsRepository()));
  await tester.pump();
}, keyboard: false);
```

## Performance checklist

- Use `const` everywhere it's valid, `ListView.builder` / slivers with stable `ValueKey(id)`
  keys, and `select` for narrow rebuilds.
- Use `Isolate.run` for heavy work (large JSON, image resize, crypto, PDF building).
- Decode images at display size (`memCacheWidth`, `cacheWidth`).
- Defer non-critical init until after the first frame. Cold start should stay under 2 s
  on a mid-range phone.
- Judge performance in `--profile`, never in debug.
