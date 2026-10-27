import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'local_api_cache.dart';

/// One file in a multipart request. [bytes] are read once by the caller
/// (e.g. `await xfile.readAsBytes()`).
class MultipartFile {
  const MultipartFile({
    required this.fieldName,
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String fieldName;
  final String filename;
  final List<int> bytes;

  /// MIME type, e.g. `'image/jpeg'`.
  final String contentType;
}

/// Thin JSON wrapper over `dart:io` [HttpClient] (no extra dependency).
///
/// - `Accept: application/json` on every call, `Authorization: Bearer` when a
///   token is available from [tokenReader] (wired to `AuthSession` by default).
/// - `GET` revalidates with ETag / `If-None-Match`; a 304 is served from
///   [LocalApiCache].
/// - Every failure becomes an [ApiException] with a human message.
class ApiClient {
  const ApiClient({
    this.baseUrl = AppConfig.apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
  });

  final String baseUrl;
  final Duration timeout;

  /// Returns the current bearer token. Set once at startup
  /// (`ApiClient.tokenReader = () => AuthSession.instance.token;`).
  static String? Function() tokenReader = _noToken;
  static String? _noToken() => null;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) {
    final uri = _uri(path, queryParameters);
    final key = uri.toString();
    return _send(
      (c) => c.getUrl(uri),
      bearerToken: bearerToken,
      prepare: (request) {
        final etag = LocalApiCache.instance.getETag(key);
        if (etag != null && etag.isNotEmpty) {
          request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
        }
      },
      onResponse: (response, decode) async {
        if (response.statusCode == HttpStatus.notModified) {
          final cached = LocalApiCache.instance.get(key);
          if (cached != null) {
            await response.drain<void>();
            return cached;
          }
        }
        final decoded = await decode();
        final etag = response.headers.value(HttpHeaders.etagHeader);
        if (etag != null && etag.isNotEmpty) {
          LocalApiCache.instance.setETag(key, etag);
        }
        LocalApiCache.instance.put(key, decoded);
        return decoded;
      },
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object?>? body, {
    String? bearerToken,
  }) => _sendJson('POST', path, body, bearerToken);

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, Object?>? body, {
    String? bearerToken,
  }) => _sendJson('PUT', path, body, bearerToken);

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, Object?>? body, {
    String? bearerToken,
  }) => _sendJson('PATCH', path, body, bearerToken);

  Future<Map<String, dynamic>> delete(String path, {String? bearerToken}) =>
      _send((c) => c.deleteUrl(_uri(path)), bearerToken: bearerToken);

  /// `multipart/form-data` POST. [fields] is a list so repeated keys
  /// (`tags[]`) are possible. Uses a 60 s timeout for uploads.
  Future<Map<String, dynamic>> postMultipart(
    String path,
    List<MapEntry<String, String>> fields, {
    List<MultipartFile> files = const [],
    String? bearerToken,
    Duration uploadTimeout = const Duration(seconds: 60),
  }) {
    final boundary = '----app-${DateTime.now().microsecondsSinceEpoch}';
    return _send(
      (c) => c.postUrl(_uri(path)),
      bearerToken: bearerToken,
      timeoutOverride: uploadTimeout,
      timeoutMessage:
          'The upload timed out. Please check your connection and try again.',
      prepare: (request) {
        request.headers.set(
          HttpHeaders.contentTypeHeader,
          'multipart/form-data; boundary=$boundary',
        );
        request.add(_multipartBody(boundary, fields, files));
      },
    );
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path,
    Map<String, Object?>? body,
    String? bearerToken,
  ) {
    return _send(
      (c) => c.openUrl(method, _uri(path)),
      bearerToken: bearerToken,
      prepare: (request) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        if (body != null) request.add(utf8.encode(jsonEncode(body)));
      },
    );
  }

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final params = <String, String>{
      ...uri.queryParameters,
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    return uri.replace(queryParameters: params);
  }

  Future<Map<String, dynamic>> _send(
    Future<HttpClientRequest> Function(HttpClient client) open, {
    String? bearerToken,
    void Function(HttpClientRequest request)? prepare,
    Future<Map<String, dynamic>> Function(
      HttpClientResponse response,
      Future<Map<String, dynamic>> Function() decode,
    )?
    onResponse,
    Duration? timeoutOverride,
    String timeoutMessage = 'The request timed out. Please try again.',
  }) async {
    final client = HttpClient()..connectionTimeout = timeoutOverride ?? timeout;
    try {
      final request = await open(client);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = bearerToken ?? tokenReader();
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      prepare?.call(request);

      final response = await request.close().timeout(
        timeoutOverride ?? timeout,
      );
      Future<Map<String, dynamic>> decode() => _decode(response);
      return onResponse != null
          ? await onResponse(response, decode)
          : await decode();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(timeoutMessage);
    } on SocketException {
      throw const ApiException(
        'Could not reach the server. Check your internet connection.',
      );
    } on HandshakeException {
      throw const ApiException('A secure connection could not be established.');
    } on FormatException {
      throw const ApiException(
        'Received an unexpected response from the server.',
      );
    } on HttpException {
      throw const ApiException('Could not reach the server. Please try again.');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _decode(HttpClientResponse response) async {
    final status = response.statusCode;

    // Some backends answer a successful write with a redirect (Laravel
    // `return back()`); dart:io does not follow it for writes. Treat as success.
    if (status >= 300 && status < 400) {
      await response.drain<void>();
      return <String, dynamic>{};
    }

    final raw = await response.transform(utf8.decoder).join();
    final Object? parsed = raw.isEmpty ? null : jsonDecode(raw);
    final json = switch (parsed) {
      final Map<String, dynamic> map => map,
      final List<dynamic> list => <String, dynamic>{'data': list},
      _ => <String, dynamic>{},
    };

    if (status >= 200 && status < 300) return json;
    throw _errorFrom(json, status);
  }

  ApiException _errorFrom(Map<String, dynamic> json, int status) {
    final message = json['message'] as String? ?? _defaultMessage(status);
    final fieldErrors = <String, List<String>>{};
    final errors = json['errors'];
    if (errors is Map) {
      errors.forEach((key, value) {
        if (value is List) {
          fieldErrors[key.toString()] = value.map((e) => e.toString()).toList();
        } else if (value != null) {
          fieldErrors[key.toString()] = [value.toString()];
        }
      });
    }
    return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }

  static String _defaultMessage(int status) => switch (status) {
    401 => 'Your session has expired. Please sign in again.',
    403 => 'You do not have permission to do this.',
    404 => 'We could not find what you were looking for.',
    409 => 'This was changed by someone else. Please refresh and try again.',
    422 => 'Please check the highlighted fields.',
    >= 500 => 'The server had a problem. Please try again shortly.',
    _ => 'Something went wrong. Please try again.',
  };

  List<int> _multipartBody(
    String boundary,
    List<MapEntry<String, String>> fields,
    List<MultipartFile> files,
  ) {
    final bytes = <int>[];
    void line([String text = '']) => bytes
      ..addAll(utf8.encode(text))
      ..addAll(const [13, 10]);

    for (final field in fields) {
      line('--$boundary');
      line('Content-Disposition: form-data; name="${field.key}"');
      line();
      line(field.value);
    }
    for (final file in files) {
      line('--$boundary');
      line(
        'Content-Disposition: form-data; name="${file.fieldName}"; filename="${file.filename}"',
      );
      line('Content-Type: ${file.contentType}');
      line();
      bytes
        ..addAll(file.bytes)
        ..addAll(const [13, 10]);
    }
    line('--$boundary--');
    return bytes;
  }
}
