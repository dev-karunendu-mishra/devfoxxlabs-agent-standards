# Networking & Caching

## Backend contract (check before writing Flutter code)

1. Find the routes. For Laravel that's `routes/api.php` plus the controllers and
   `app/Models`. For FastAPI or Next.js, use the router files or the API contract doc
   in `docs/BACKEND_API_CONTRACT.md`.
2. If the endpoint is missing and the backend is in the workspace, create it
   **non-destructively**: add columns through a new migration, never drop or rename.
   Return JSON for `Accept: application/json`. Web and mobile share one query scope
   for filters and sorts.
3. Envelope:
   ```json
   { "success": true, "data": { }, "message": "Success", "meta": { } }
   ```
4. Status codes: `400` bad request, `401` refresh token or sign out, `403` forbidden
   (KYC not approved, suspended, wrong role), `404`, `409` conflict (stock gone, trip
   taken), `422` validation with `errors: {field: [msg]}`, `5xx` with a friendly message
   and Retry.

## ApiClient (`templates/lib/core/network/api_client.dart`)

- One class wraps `dart:io` `HttpClient`, with no extra dependency. It provides
  `get / post / patch / put / delete / postMultipart`.
- It always sends `Accept: application/json`, plus `Authorization: Bearer <token>` when
  a token exists. Tokens are read through a token reader wired to `AuthSession`.
- Timeouts are 15 s for JSON calls and 60 s for uploads. It maps
  `TimeoutException` / `SocketException` / `FormatException` to an `ApiException`
  with a human message.
- `GET`: it sends `If-None-Match` with the stored ETag. On **304** it returns the
  cached body from `LocalApiCache`. On 200 it stores the body and the ETag.
- Non-2xx responses throw `ApiException(message, statusCode, fieldErrors)`. The message
  comes from the server's `message`, falling back to a generic one.
- A 3xx on a write counts as success (Laravel `return back()`).
- Multipart takes a `List<MapEntry<String,String>>` for fields (repeated keys such as
  `tags[]`) and `List<MultipartFile>` with bytes read once by the caller.
- Base URL comes from `--dart-define=API_BASE_URL=…` (`AppConfig.apiBaseUrl`). Never hardcode
  per-environment URLs in feature code.
- `dio` + `dio_cache_interceptor` (taxiyaa) is acceptable, but expose the **same**
  `ApiClient` method signatures and `ApiException` so repositories and tests don't change.

## ApiException → UI

```dart
Text(e is ApiException ? e.message : 'Something went wrong. Please try again.')
```

- Never show raw `toString()` of non-API errors to users.
- `422`: map `fieldErrors['email']?.first` into `InputDecoration.errorText` on the field
  that owns it. In a wizard, jump back to the step that owns the field.
- `401`: clear the session, then go to login with `pushAndRemoveUntil`.

## Repositories

```dart
class CouponsRepository {
  const CouponsRepository({this.client = const ApiClient()});
  final ApiClient client;

  Future<List<Coupon>> fetchCoupons() async {
    final json = await client.get('/admin/coupons');
    final list = json['data'] as List<dynamic>? ?? const [];
    return list.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteCoupon(int id) => client.delete('/admin/coupons/$id');
}
```

- They return typed models, not `Map<String, dynamic>`, for new code.
- **Never** catch to return fake data or an empty list on error.
- They add the context identifier the backend needs (store id, lat/lng, role) as query
  params or headers.

## Models

```dart
@immutable
class Coupon {
  const Coupon({required this.id, required this.code, required this.value, required this.isActive, this.imageUrl});

  final int id;
  final String code;
  final double value;
  final bool isActive;
  final String? imageUrl;

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        id: (json['id'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        isActive: json['is_active'] as bool? ?? false,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'value': value, 'is_active': isActive, 'image_url': imageUrl};
}
```

- Use safe defaults for every field. Never crash on bad server data. Drop or flag invalid rows.
- Money is `double` from the server, formatted with `intl`. **Never compute payable
  amounts on the device.**
- `json_serializable` / `freezed` are fine where a project already uses them.

## Media URL resolution

The server may send full URLs, protocol-relative (`//cdn…`) or root-relative (`/storage/…`)
paths. Resolve them in one place (`AppNetworkImage.resolve`) against the site base URL.
Fall back to a bundled asset on null or load error.

## Image caching (`templates/lib/core/widgets/app_network_image.dart`)

- Disk and memory cache via `cached_network_image`, plus **RAM downscaling** with
  `memCacheWidth/Height` sized to the display. Reference sizes: product card 350×350,
  vehicle or banner 400×300, avatar 150×150, cart thumb 150.
- The placeholder is an `AutoSkeleton` box. The error widget is a themed icon fallback.
- `cacheKey` for signed URLs that change on every fetch.
- Ask the backend or CDN for WebP thumbnails, never full-res originals, in lists.
- The widget skips the network in widget tests, so tests don't hang on HTTP.

## Offline-first apps (drift)

- The local DB is the source of truth. Use `watch…` streams for lists and no manual
  re-fetch after writes.
- Schema changes are **additive only**: bump `schemaVersion`, add an `if (from < N)`
  block, then run `dart run build_runner build --delete-conflicting-outputs`. Destructive
  migrations need explicit user confirmation.
- Use soft-delete (`deletedAt`) for financial or audit rows. Audit tables are
  insert-only and snapshot human-readable names.
- PII stays on the device unless the user explicitly shares or exports it.

## Polling and real-time

- Poll active orders or trips every 10–15 s, or use WebSocket/SSE. Cancel timers when
  the order completes and when the screen is disposed.
- GPS heartbeats run only while the user is "online". Stop them on offline to save battery.
