/// Raised for any failed API call, carrying the user-facing message the backend
/// returned (falling back to a generic one) plus, for 422 validation errors, the
/// field-level messages.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;

  /// First validation message for [field], for `InputDecoration.errorText`.
  String? fieldError(String field) => fieldErrors[field]?.first;

  @override
  String toString() => message;
}
