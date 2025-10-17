/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Server-side failure (API errors, network errors, etc.)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

/// Cache failure (local storage errors)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
  }) : super(statusCode: null);
}

/// Validation failure (invalid input, etc.)
class ValidationFailure extends Failure {
  const ValidationFailure(String message)
      : super(message: message, statusCode: null);
}

/// Network failure (no internet connection)
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection',
  }) : super(message: message, statusCode: null);
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
  });
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
  }) : super(statusCode: 404);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
  }) : super(statusCode: 403);
}
