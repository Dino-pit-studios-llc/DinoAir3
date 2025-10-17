/// Exceptions raised by API/data layer before being mapped to [Failure]s.
sealed class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() =>
      '${runtimeType}(statusCode: $statusCode, message: $message)';
}

/// Thrown when the remote server returns a non-success status code.
class ApiResponseException extends ApiException {
  const ApiResponseException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

/// Thrown when the request fails due to connectivity issues.
class ApiNetworkException extends ApiException {
  const ApiNetworkException({required super.message, super.details});
}

/// Thrown when the request takes longer than the configured timeout.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException({required super.message, super.details});
}

/// Thrown when response parsing fails.
class ApiParsingException extends ApiException {
  const ApiParsingException({required super.message, super.details});
}
