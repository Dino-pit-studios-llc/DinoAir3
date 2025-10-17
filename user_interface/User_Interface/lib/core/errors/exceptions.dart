/// Core exceptions for data layer operations.
///
/// These exceptions are thrown by data sources and should be caught
/// and mapped to [Failure] objects in repository implementations.

/// Base exception for data layer operations.
class DataException implements Exception {
  final String message;
  final int? statusCode;
  final Object? details;

  const DataException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() =>
      'DataException(statusCode: $statusCode, message: $message)';
}

/// Thrown when a server/API call fails.
class ServerException extends DataException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.details,
  });

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, message: $message)';
}

/// Thrown when local cache operations fail.
class CacheException extends DataException {
  const CacheException({
    required super.message,
    super.details,
  });

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Thrown when data parsing/serialization fails.
class ParseException extends DataException {
  const ParseException({
    required super.message,
    super.details,
  });

  @override
  String toString() => 'ParseException(message: $message)';
}
