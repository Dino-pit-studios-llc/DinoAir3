/// Core failure abstraction used across layers to represent domain-safe
/// error states (mapped from exceptions in data/services layers).
sealed class Failure {
  const Failure({this.message, this.cause});
  final String? message; // Developer-oriented or diagnostic message.
  final Object? cause; // Original exception (not exposed to UI directly).
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message, super.cause});
}

class ApiFailure extends Failure {
  const ApiFailure({super.message, super.cause, this.statusCode});
  final int? statusCode;
}

class CacheFailure extends Failure {
  const CacheFailure({super.message, super.cause});
}

class ParsingFailure extends Failure {
  const ParsingFailure({super.message, super.cause});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message, super.cause});
}

/// Input validation failure surfaced before reaching downstream layers.
class ValidationFailure extends Failure {
  const ValidationFailure({super.message, super.cause});
}
